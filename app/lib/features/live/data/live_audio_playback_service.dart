import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// Abstract interface for audio playback.
abstract class AudioPlaybackService {
  bool get isPlaying;
  Stream<bool> get playbackStateStream;

  /// Queue a chunk of raw PCM 16-bit 24kHz mono audio received from Gemini.
  void enqueue(Uint8List audioData, String mimeType);

  /// Stop playback immediately (for barge-in / interruption).
  Future<void> stopImmediately();

  /// Flush the queue without stopping the player.
  void flushQueue();

  /// Release all resources.
  void dispose();
}

/// Plays raw PCM 16-bit 24kHz mono audio from Gemini Live by continuously
/// feeding chunks to [flutter_pcm_sound]'s hardware audio buffer.
///
/// Architecture: chunks queue up as they arrive from the WebSocket. The
/// [_onFeed] callback is invoked by flutter_pcm_sound whenever the hardware
/// buffer falls below [_feedThreshold] frames, at which point we drain the
/// queue into the buffer. This produces truly gapless output, unlike the
/// prior [just_audio] per-chunk WAV approach that introduced 20-50ms gaps.
class LiveAudioPlaybackService implements AudioPlaybackService {
  static const int _sampleRate = 24000;
  static const int _channelCount = 1;

  /// Feed callback fires when remaining buffered frames fall below this.
  /// 200ms at 24kHz = 4800 frames. Gives enough lead-time to prevent
  /// underruns even under main-thread load, while keeping latency low.
  static const int _feedThreshold = 4800;

  final _queue = Queue<Uint8List>();
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isSetup = false;

  final _stateController = StreamController<bool>.broadcast();

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playbackStateStream => _stateController.stream;

  LiveAudioPlaybackService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await FlutterPcmSound.setup(
        sampleRate: _sampleRate,
        channelCount: _channelCount,
      );
      await FlutterPcmSound.setFeedThreshold(_feedThreshold);
      FlutterPcmSound.setFeedCallback(_onFeed);
      _isSetup = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Mimz][Audio] PCM setup error: $e');
    }
  }

  /// Invoked by flutter_pcm_sound when the hardware buffer needs more data.
  /// Drains the pending chunk queue and feeds all available PCM frames.
  void _onFeed(int remainingFrames) {
    if (_isDisposed) return;

    if (_queue.isEmpty) {
      // Buffer drained, nothing left to play — playback is idle.
      if (_isPlaying) {
        _isPlaying = false;
        if (!_isDisposed) _stateController.add(false);
      }
      return;
    }

    // Feed all queued chunks at once. flutter_pcm_sound accumulates them
    // internally, so we can batch-feed without risk of overflow.
    while (_queue.isNotEmpty && !_isDisposed) {
      final chunk = _queue.removeFirst();
      final pcm = _toPcmArray(chunk);
      FlutterPcmSound.feed(pcm);
    }
  }

  /// Convert raw Gemini PCM bytes (16-bit LE) to a [PcmArrayInt16] for the
  /// flutter_pcm_sound plugin. Avoids sample-by-sample copy by reusing the
  /// underlying byte buffer directly.
  PcmArrayInt16 _toPcmArray(Uint8List pcmBytes) {
    return PcmArrayInt16(
      bytes: pcmBytes.buffer.asByteData(
        pcmBytes.offsetInBytes,
        pcmBytes.lengthInBytes,
      ),
    );
  }

  @override
  void enqueue(Uint8List audioData, String mimeType) {
    if (_isDisposed || !_isSetup) return;
    _queue.add(audioData);

    final wasIdle = !_isPlaying;
    if (wasIdle) {
      _isPlaying = true;
      _stateController.add(true);
      // Kickstart: trigger the feed callback immediately via start(),
      // which calls onFeedSamplesCallback(0) to begin draining the queue.
      FlutterPcmSound.start();
    }
    // If already playing, flutter_pcm_sound will call _onFeed again when
    // the buffer falls below threshold — no action needed here.
  }

  @override
  Future<void> stopImmediately() async {
    _queue.clear();
    if (_isPlaying) {
      _isPlaying = false;
      if (!_isDisposed) _stateController.add(false);
    }
    try {
      if (_isSetup) {
        // Release tears down the native audio session.
        await FlutterPcmSound.release();
        // Re-setup so the service is ready for the next session.
        _isSetup = false;
        await _init();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Mimz][Audio] stopImmediately error: $e');
    }
  }

  @override
  void flushQueue() {
    _queue.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _queue.clear();
    _isPlaying = false;
    _stateController.close();
    FlutterPcmSound.setFeedCallback(null);
    try {
      FlutterPcmSound.release();
    } catch (_) {}
  }
}
