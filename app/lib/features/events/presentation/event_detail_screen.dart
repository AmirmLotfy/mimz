import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/event.dart';
import '../../../design_system/tokens.dart';
import '../../../services/haptics_service.dart';
import '../providers/events_provider.dart';
import '../../world/providers/game_state_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final MimzEvent event;
  final bool isLive;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.isLive = false,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _joining = false;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _leaderboardLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _leaderboardLoading = true);
    try {
      final entries = await ref
          .read(apiClientProvider)
          .getEventLeaderboard(widget.event.id);
      if (mounted) setState(() => _leaderboard = entries);
    } catch (_) {
      // Non-fatal — leaderboard may not exist yet
    } finally {
      if (mounted) setState(() => _leaderboardLoading = false);
    }
  }

  Future<void> _joinOrRegister() async {
    setState(() => _joining = true);
    ref.read(hapticsServiceProvider).mediumImpact();
    try {
      if (widget.isLive) {
        await ref.read(apiClientProvider).participateInEvent(widget.event.id);
      } else {
        await ref.read(apiClientProvider).joinEvent(widget.event.id);
      }
      ref.invalidate(gameStateProvider);
      ref.invalidate(eventsProvider);
      if (!mounted) return;
      ref.read(hapticsServiceProvider).success();
      if (widget.isLive) {
        context.push(
          '/play/event/${widget.event.id}?title=${Uri.encodeComponent(widget.event.title)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registered for "${widget.event.title}"!'),
            backgroundColor: MimzColors.mossCore,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ref.read(hapticsServiceProvider).error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not join event: $e')),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final zones = ref.watch(eventZonesProvider);
    final dynamic zone = zones.cast<dynamic>().firstWhere(
          (candidate) => candidate?.eventId == event.id,
          orElse: () => null,
        );
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Event Details'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isLive)
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
                        child: Text(
                          'LIVE NOW',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(event.title, style: MimzTypography.displaySmall),
                    const SizedBox(height: MimzSpacing.md),
                    Text(
                      event.description.isNotEmpty
                          ? event.description
                          : 'No additional event details are available yet.',
                      style: MimzTypography.bodyMedium.copyWith(
                        color: MimzColors.textSecondary,
                      ),
                    ),
                    if (event.status == EventStatus.upcoming &&
                        event.startsAt != null &&
                        event.startsAt!.isAfter(DateTime.now()))
                      Padding(
                        padding: const EdgeInsets.only(top: MimzSpacing.lg),
                        child: StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, _) {
                            final diff =
                                event.startsAt!.difference(DateTime.now());
                            if (diff.isNegative) {
                              return const SizedBox.shrink();
                            }
                            final days = diff.inDays;
                            final hours = diff.inHours % 24;
                            final minutes = diff.inMinutes % 60;
                            final parts = <String>[
                              if (days > 0) '${days}d',
                              if (hours > 0) '${hours}h',
                              '${minutes}m',
                            ];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MimzSpacing.base,
                                vertical: MimzSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    MimzColors.mistBlue.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(MimzRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      color: MimzColors.mistBlue, size: 20),
                                  const SizedBox(width: MimzSpacing.sm),
                                  Text(
                                    'Starts in ${parts.join(' ')}',
                                    style:
                                        MimzTypography.headlineSmall.copyWith(
                                      color: MimzColors.mistBlue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: MimzSpacing.lg),
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: MimzColors.mossCore, size: 18),
                        const SizedBox(width: MimzSpacing.sm),
                        Text('${event.participants} players',
                            style: MimzTypography.bodySmall),
                      ],
                    ),
                    if (zone != null) ...[
                      const SizedBox(height: MimzSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(MimzSpacing.base),
                        decoration: BoxDecoration(
                          color: MimzColors.mossCore.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(MimzRadius.lg),
                          border: Border.all(
                            color: MimzColors.mossCore.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WORLD ZONE',
                              style: MimzTypography.caption.copyWith(
                                color: MimzColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: MimzSpacing.xs),
                            Text(
                              'Region • ${zone.regionLabel}',
                              style: MimzTypography.headlineSmall,
                            ),
                            const SizedBox(height: MimzSpacing.xs),
                            Text(
                              zone.districtEffect.isNotEmpty
                                  ? 'District effect • ${zone.districtEffect}'
                                  : 'District effect • This event is affecting the district grid right now.',
                              style: MimzTypography.bodySmall.copyWith(
                                color: MimzColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: MimzSpacing.sm),
                            Text(
                              'Reward lane • x${zone.rewardMultiplier.toStringAsFixed(zone.rewardMultiplier % 1 == 0 ? 0 : 1)}',
                              style: MimzTypography.caption.copyWith(
                                color: MimzColors.mossCore,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: MimzSpacing.xl),
                    Text('Leaderboard', style: MimzTypography.headlineSmall),
                    const SizedBox(height: MimzSpacing.md),
                    if (_leaderboardLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(MimzSpacing.lg),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_leaderboard.isEmpty)
                      Text(
                        'No scores yet — be the first to play!',
                        style: MimzTypography.bodySmall.copyWith(
                          color: MimzColors.textSecondary,
                        ),
                      )
                    else
                      ..._leaderboard.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final item = entry.value;
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: MimzSpacing.sm),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$rank.',
                                  style: MimzTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: rank <= 3
                                        ? MimzColors.mossCore
                                        : MimzColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item['displayName'] as String? ?? 'Explorer',
                                  style: MimzTypography.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item['score'] ?? 0} pts',
                                style: MimzTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MimzColors.mossCore,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MimzSpacing.xl,
                MimzSpacing.md,
                MimzSpacing.xl,
                MimzSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _joining ? null : _joinOrRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MimzColors.mossCore,
                    foregroundColor: MimzColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                    ),
                  ),
                  child: Text(
                    _joining
                        ? 'Please wait...'
                        : (widget.isLive ? 'PLAY NOW' : 'REGISTER'),
                    style: MimzTypography.buttonText
                        .copyWith(color: MimzColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
