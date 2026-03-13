import 'package:flutter/services.dart';

/// Sound design hooks for key game moments.
///
/// Uses system sounds + haptic patterns as audio-tactile feedback.
/// Upgrade path: swap `_playSystemSound` for an audioplayers call
/// once assets are added to pubspec.yaml.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  // ── XP Award ────────────────────────────────────────────
  /// Light double-tap — rewarding, quick
  Future<void> playXpAward() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  // ── Correct Answer ──────────────────────────────────────
  /// Medium impact then selection — "YES!" feel
  Future<void> playCorrectAnswer() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  // ── Wrong Answer ────────────────────────────────────────
  /// Heavy single thud — negative feedback
  Future<void> playWrongAnswer() async {
    await HapticFeedback.heavyImpact();
  }

  // ── District Growth ─────────────────────────────────────
  /// Triple escalating impacts — dramatic district expansion
  Future<void> playDistrictGrowth() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  // ── Streak ──────────────────────────────────────────────
  /// Rapid triple-tap — streak sensation
  Future<void> playStreak() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  // ── Session Start ───────────────────────────────────────
  Future<void> playSessionStart() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.lightImpact();
  }
}
