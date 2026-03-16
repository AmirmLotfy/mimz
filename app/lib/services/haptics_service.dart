import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

/// Centralized service for haptic feedback.
/// Respects user preferences from SettingsService.
class HapticsService {
  final Ref _ref;
  
  HapticsService(this._ref);

  Future<void> _trigger(Future<void> Function() feedback) async {
    final enabled = await _ref.read(settingsServiceProvider).getHaptic();
    if (enabled) {
      await feedback();
    }
  }

  /// Light click for standard UI selections.
  void selection() => _trigger(() => HapticFeedback.selectionClick());

  /// Light impact for subtle warnings/nudges.
  void lightImpact() => _trigger(() => HapticFeedback.lightImpact());

  /// Medium impact for primary actions.
  void mediumImpact() => _trigger(() => HapticFeedback.mediumImpact());

  /// Strong impact for destructive or high-energy actions.
  void heavyImpact() => _trigger(() => HapticFeedback.heavyImpact());

  /// Brief vibration for success/achievement.
  void success() => _trigger(() => HapticFeedback.vibrate());

  /// Distinct failure cue.
  void error() => _trigger(() => HapticFeedback.heavyImpact());
}

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return HapticsService(ref);
});
