import 'dart:async';
import 'dart:typed_data';
// TODO: Uncomment when audio packages are ready
// import 'package:record/record.dart';
// import 'package:just_audio/just_audio.dart';

enum AudioState { idle, recording, playing }

/// Manages microphone input and audio output for Gemini Live sessions
class AudioService {
  // TODO: Uncomment when audio packages are ready
  // final AudioRecorder _recorder = AudioRecorder();
  // final AudioPlayer _player = AudioPlayer();

  final _stateController = StreamController<AudioState>.broadcast();
  Stream<AudioState> get stateStream => _stateController.stream;

  final _audioDataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioDataController.stream;

  AudioState _state = AudioState.idle;
  AudioState get state => _state;

  StreamSubscription? _recordSubscription;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    // TODO: return await _recorder.hasPermission();
    return true;
  }

  /// Start recording from microphone
  /// Returns a stream of PCM audio chunks
  Future<void> startRecording() async {
    if (_state == AudioState.recording) return;

    // TODO: Implement real audio recording
    // final stream = await _recorder.startStream(RecordConfig(
    //   encoder: AudioEncoder.pcm16bits,
    //   sampleRate: 16000,
    //   numChannels: 1,
    // ));
    //
    // _recordSubscription = stream.listen((data) {
    //   _audioDataController.add(Uint8List.fromList(data));
    // });

    _setState(AudioState.recording);
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (_state != AudioState.recording) return;

    await _recordSubscription?.cancel();
    // TODO: await _recorder.stop();

    _setState(AudioState.idle);
  }

  /// Play audio data from Gemini response
  Future<void> playAudio(List<int> audioData, {String mimeType = 'audio/pcm;rate=24000'}) async {
    if (_state == AudioState.playing) return;

    _setState(AudioState.playing);

    // TODO: Implement real audio playback
    // For PCM data, write to a temp file and play
    // final tempDir = await getTemporaryDirectory();
    // final file = File('${tempDir.path}/gemini_response.pcm');
    // await file.writeAsBytes(audioData);
    // await _player.setFilePath(file.path);
    // await _player.play();
    // await _player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);

    // Simulate playback duration
    await Future.delayed(const Duration(seconds: 1));

    _setState(AudioState.idle);
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    // TODO: await _player.stop();
    _setState(AudioState.idle);
  }

  void _setState(AudioState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    stopRecording();
    stopPlayback();
    _stateController.close();
    _audioDataController.close();
    // TODO: _recorder.dispose();
    // TODO: _player.dispose();
  }
}
