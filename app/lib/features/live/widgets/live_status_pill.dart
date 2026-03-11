import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../domain/live_connection_phase.dart';
import '../providers/live_providers.dart';

/// Compact pill indicator showing live session status.
///
/// Pulses when the model is speaking, shows mic icon when user is speaking,
/// and displays reconnect state.
class LiveStatusPill extends ConsumerWidget {
  const LiveStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveSessionStateProvider).valueOrNull;
    if (state == null || state.phase == LiveConnectionPhase.idle) {
      return const SizedBox.shrink();
    }

    final (icon, label, color) = _pillData(state.phase);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: MimzSpacing.sm),
          Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.phase == LiveConnectionPhase.modelSpeaking)
            ...[
              const SizedBox(width: MimzSpacing.sm),
              _PulseDot(color: color),
            ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  (IconData, String, Color) _pillData(LiveConnectionPhase phase) {
    return switch (phase) {
      LiveConnectionPhase.fetchingToken => (Icons.hourglass_top, 'CONNECTING', MimzColors.textSecondary),
      LiveConnectionPhase.connecting    => (Icons.wifi, 'CONNECTING', MimzColors.textSecondary),
      LiveConnectionPhase.handshaking   => (Icons.wifi, 'HANDSHAKING', MimzColors.textSecondary),
      LiveConnectionPhase.connected     => (Icons.wifi, 'LIVE', MimzColors.mossCore),
      LiveConnectionPhase.modelSpeaking => (Icons.volume_up, 'MIMZ SPEAKING', MimzColors.persimmonHit),
      LiveConnectionPhase.userSpeaking  => (Icons.mic, 'LISTENING', MimzColors.mossCore),
      LiveConnectionPhase.waitingForToolResult => (Icons.hourglass_bottom, 'PROCESSING', MimzColors.dustyGold),
      LiveConnectionPhase.reconnecting  => (Icons.refresh, 'RECONNECTING', MimzColors.textSecondary),
      LiveConnectionPhase.ended         => (Icons.stop_circle, 'ENDED', MimzColors.textSecondary),
      LiveConnectionPhase.failed        => (Icons.error_outline, 'ERROR', MimzColors.persimmonHit),
      _ => (Icons.circle, 'IDLE', MimzColors.textSecondary),
    };
  }
}

class _PulseDot extends StatelessWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
