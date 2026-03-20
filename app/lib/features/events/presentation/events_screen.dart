import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../providers/events_provider.dart';
import '../../world/providers/game_state_provider.dart';
import '../../../data/models/event.dart';
import '../../../data/models/game_state.dart';
import '../../../services/haptics_service.dart';

String? _zoneDetailForEvent(String eventId, List<EventZoneModel> zones) {
  for (final zone in zones) {
    if (zone.eventId == eventId) {
      return '${zone.regionLabel} • x${zone.rewardMultiplier.toStringAsFixed(1)} rewards';
    }
  }
  return null;
}

/// Events screen — wired with eventsProvider and tappable cards
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull ?? const <MimzEvent>[];
    final activeEvent = ref.watch(activeEventProvider);
    final eventZones = ref.watch(eventZonesProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Events')),
      body: eventsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventsAsync.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(MimzSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: MimzColors.error, size: 40),
                        const SizedBox(height: MimzSpacing.md),
                        Text('Could not load events', style: MimzTypography.headlineSmall),
                      ],
                    ),
                  ),
                )
              : events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, color: MimzColors.textTertiary, size: 48),
                  const SizedBox(height: MimzSpacing.md),
                  Text('No events scheduled', style: MimzTypography.headlineSmall),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    'Check back soon for live events!',
                    style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: MimzSpacing.base,
                right: MimzSpacing.base,
                top: MimzSpacing.base,
                bottom: MimzSpacing.base + 100, // padding for floating pill
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eventZones.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(MimzSpacing.base),
                      decoration: BoxDecoration(
                        color: MimzColors.white,
                        borderRadius: BorderRadius.circular(MimzRadius.lg),
                        border: Border.all(color: MimzColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORLD ZONES',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.mistBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: MimzSpacing.sm),
                          ...eventZones.take(2).map((zone) => Padding(
                                padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
                                child: Text(
                                  '${zone.title} • ${zone.regionLabel} • ${zone.districtEffect}',
                                  style: MimzTypography.bodySmall.copyWith(
                                    color: MimzColors.textSecondary,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: MimzSpacing.xl),
                  ],
                  if (activeEvent != null) ...[
                    Text('HAPPENING NOW', style: MimzTypography.caption.copyWith(
                      color: MimzColors.persimmonHit, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: MimzSpacing.md),
                    _EventCard(
                      event: activeEvent,
                      zoneDetail: _zoneDetailForEvent(activeEvent.id, eventZones),
                      isLive: true,
                      onTap: () => _showEventDetail(context, ref, activeEvent, isLive: true),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
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
                            child: _EventCard(
                              event: entry.value,
                              zoneDetail: _zoneDetailForEvent(entry.value.id, eventZones),
                              onTap: () => _showEventDetail(context, ref, entry.value),
                            )
                                .animate(delay: Duration(milliseconds: 200 * entry.key))
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1),
                          )),
                ],
              ),
            ),
    );
  }

  void _showEventDetail(BuildContext context, WidgetRef ref, MimzEvent event, {bool isLive = false}) {
    ref.read(hapticsServiceProvider).selection();
    context.push(
      '/events/detail',
      extra: {'event': event, 'isLive': isLive},
    );
  }
}

class _EventCard extends StatelessWidget {
  final MimzEvent event;
  final bool isLive;
  final VoidCallback? onTap;
  final String? zoneDetail;

  const _EventCard({
    required this.event,
    this.isLive = false,
    this.onTap,
    this.zoneDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  if (zoneDetail != null && zoneDetail!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        zoneDetail!,
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mistBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${event.participants}', style: MimzTypography.headlineSmall),
                Text('players', style: MimzTypography.bodySmall),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: MimzColors.textTertiary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
