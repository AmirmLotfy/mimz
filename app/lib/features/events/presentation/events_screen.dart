import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/events_provider.dart';
import '../../../data/models/event.dart';

/// Events screen — wired with eventsProvider and tappable cards
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final activeEvent = ref.watch(activeEventProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Events')),
      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: MimzColors.textTertiary, size: 48),
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
              padding: const EdgeInsets.all(MimzSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeEvent != null) ...[
                    Text('HAPPENING NOW', style: MimzTypography.caption.copyWith(
                      color: MimzColors.persimmonHit, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: MimzSpacing.md),
                    _EventCard(
                      event: activeEvent,
                      isLive: true,
                      onTap: () => _showEventDetail(context, activeEvent, isLive: true),
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
                              onTap: () => _showEventDetail(context, entry.value),
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

  void _showEventDetail(BuildContext context, MimzEvent event, {bool isLive = false}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: MimzColors.cloudBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MimzRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(MimzSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MimzColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.md,
                  vertical: MimzSpacing.xs,
                ),
                margin: const EdgeInsets.only(bottom: MimzSpacing.md),
                decoration: BoxDecoration(
                  color: MimzColors.persimmonHit,
                  borderRadius: BorderRadius.circular(MimzRadius.sm),
                ),
                child: Text('🔴 LIVE NOW', style: MimzTypography.caption.copyWith(
                  color: MimzColors.white, fontWeight: FontWeight.w700,
                )),
              ),
            Text(event.title, style: MimzTypography.displaySmall),
            const SizedBox(height: MimzSpacing.md),
            Text(event.description, style: MimzTypography.bodyMedium.copyWith(
              color: MimzColors.textSecondary,
            )),
            const SizedBox(height: MimzSpacing.base),
            Row(
              children: [
                Icon(Icons.people, color: MimzColors.mossCore, size: 18),
                const SizedBox(width: MimzSpacing.sm),
                Text('${event.participants} players', style: MimzTypography.bodySmall),
              ],
            ),
            const SizedBox(height: MimzSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isLive ? 'Joining "${event.title}"...' : 'Registered for "${event.title}"!'),
                      backgroundColor: MimzColors.mossCore,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MimzRadius.md),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MimzColors.mossCore,
                  foregroundColor: MimzColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                ),
                child: Text(
                  isLive ? 'JOIN NOW' : 'REGISTER',
                  style: MimzTypography.buttonText.copyWith(color: MimzColors.white),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final MimzEvent event;
  final bool isLive;
  final VoidCallback? onTap;

  const _EventCard({required this.event, this.isLive = false, this.onTap});

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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${event.participants}', style: MimzTypography.headlineSmall),
                Text('players', style: MimzTypography.bodySmall),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, color: MimzColors.textTertiary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
