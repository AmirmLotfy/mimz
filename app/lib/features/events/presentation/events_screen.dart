import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/events_provider.dart';
import '../../../data/models/event.dart';

/// Events screen — wired with eventsProvider
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final activeEvent = ref.watch(activeEventProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Events')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MimzSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeEvent != null) ...[
              Text('HAPPENING NOW', style: MimzTypography.caption.copyWith(
                color: MimzColors.persimmonHit, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: MimzSpacing.md),
              _EventCard(event: activeEvent, isLive: true)
                  .animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.xl),
            ],
            Text('UPCOMING', style: MimzTypography.caption),
            const SizedBox(height: MimzSpacing.md),
            ...events
                .where((e) => e.status == EventStatus.upcoming)
                .toList()
                .asMap()
                .entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: MimzSpacing.md),
                      child: _EventCard(event: entry.value)
                          .animate(delay: Duration(milliseconds: 200 * entry.key))
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1),
                    )),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final MimzEvent event;
  final bool isLive;

  const _EventCard({required this.event, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: isLive
            ? Border.all(color: MimzColors.persimmonHit, width: 1.5)
            : Border.all(color: MimzColors.borderLight),
        boxShadow: isLive
            ? [BoxShadow(color: MimzColors.persimmonHit.withValues(alpha: 0.1), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isLive
                  ? MimzColors.persimmonHit.withValues(alpha: 0.1)
                  : MimzColors.mossCore.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            child: Icon(
              isLive ? Icons.wifi_tethering : Icons.event,
              color: isLive ? MimzColors.persimmonHit : MimzColors.mossCore,
            ),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MimzSpacing.sm,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: MimzColors.persimmonHit,
                      borderRadius: BorderRadius.circular(MimzRadius.sm),
                    ),
                    child: Text('LIVE', style: MimzTypography.caption.copyWith(
                      color: MimzColors.white, fontWeight: FontWeight.w700, fontSize: 10,
                    )),
                  ),
                Text(event.title, style: MimzTypography.headlineSmall),
                if (event.description.isNotEmpty)
                  Text(event.description, style: MimzTypography.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${event.participants}', style: MimzTypography.headlineSmall),
              Text('players', style: MimzTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
