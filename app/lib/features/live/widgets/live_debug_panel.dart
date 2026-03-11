import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/tokens.dart';
import '../providers/live_providers.dart';

/// Dev-mode debug panel showing session internals.
///
/// Toggle visibility with a long-press or via a dev settings flag.
/// Shows: connection phase, session ID, transcript lengths, reconnect count,
/// tool call state, and event timeline milestones.
class LiveDebugPanel extends ConsumerWidget {
  const LiveDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveSessionStateProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final logger = ref.watch(liveSessionLoggerProvider);
    if (!logger.isEnabled) return const SizedBox.shrink();

    final milestones = logger.milestones;

    return Container(
      margin: const EdgeInsets.all(MimzSpacing.sm),
      padding: const EdgeInsets.all(MimzSpacing.md),
      decoration: BoxDecoration(
        color: MimzColors.deepInk.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(MimzRadius.md),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: MimzColors.acidLime,
          height: 1.4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('── MIMZ LIVE DEBUG ──'),
            Text('phase: ${state.phase.name}'),
            Text('mode: ${state.mode.name}'),
            Text('session: ${state.sessionId ?? 'none'}'),
            Text('mic: ${state.isMicActive} | play: ${state.isPlaybackActive} | cam: ${state.isCameraActive}'),
            Text('reconnects: ${state.reconnectAttempts}'),
            Text('model_tx: ${state.modelTranscript.length} chars'),
            Text('user_tx: ${state.userTranscript.length} chars'),
            if (state.activeToolName != null)
              Text('tool: ${state.activeToolName} (${state.activeToolCallId})'),
            if (state.error != null)
              Text('error: ${state.error!.code.name}',
                  style: const TextStyle(color: MimzColors.persimmonHit, fontFamily: 'monospace', fontSize: 10)),
            const SizedBox(height: 4),
            Text('── MILESTONES ──'),
            ...milestones.entries.map((e) =>
                Text('${e.key}: ${e.value ?? '-'}'),
            ),
          ],
        ),
      ),
    );
  }
}
