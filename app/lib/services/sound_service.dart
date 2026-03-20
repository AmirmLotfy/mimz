import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Sound design hooks for key game moments.
///
/// Attempts to load .mp3 assets from assets/audio/; falls back
/// to system haptics when assets are missing.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  final _players = <String, AudioPlayer>{};
  bool _initialized = false;

  static const _assets = {
    'correct': 'assets/audio/correct.mp3',
    'wrong': 'assets/audio/wrong.mp3',
    'xp': 'assets/audio/xp_award.mp3',
    'streak': 'assets/audio/streak_fire.mp3',
    'growth': 'assets/audio/district_growth.mp3',
    'victory': 'assets/audio/victory_fanfare.mp3',
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    for (final entry in _assets.entries) {
      try {
        final player = AudioPlayer();
        await player.setAsset(entry.value);
        await player.setVolume(0.6);
        _players[entry.key] = player;
      } catch (_) {
        // Asset missing — haptic-only fallback
      }
    }
  }

  Future<void> _play(String key) async {
    final player = _players[key];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
      } catch (_) {}
    }
  }

  Future<void> playXpAward() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await _play('xp');
  }

  Future<void> playCorrectAnswer() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.selectionClick();
    await _play('correct');
  }

  Future<void> playWrongAnswer() async {
    await HapticFeedback.heavyImpact();
    await _play('wrong');
  }

  Future<void> playDistrictGrowth() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
    await _play('growth');
  }

  Future<void> playStreak() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 60));
    }
    await _play('streak');
  }

  Future<void> playVictory() async {
    await HapticFeedback.heavyImpact();
    await _play('victory');
  }

  Future<void> playSessionStart() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.lightImpact();
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
