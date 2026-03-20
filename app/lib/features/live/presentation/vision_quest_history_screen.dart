import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../design_system/tokens.dart';

/// Provider: fetches vision quest history from backend
final visionQuestHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getVisionQuestHistory();
});

class VisionQuestHistoryScreen extends ConsumerWidget {
  const VisionQuestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(visionQuestHistoryProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        title: const Text('Vision Quest History'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Failed to load history. Try again later.'),
        ),
        data: (history) => _HistoryBody(history: history),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryBody({required this.history});

  int get _totalXp =>
      history.fold<int>(0, (sum, e) => sum + (e['xpAwarded'] as int? ?? 0));

  String _tierFor(Map<String, dynamic> entry) {
    final score = (entry['score'] as num? ?? 0).toDouble();
    if (score >= 90) return 'MASTER';
    if (score >= 70) return 'RARE';
    return 'COMMON';
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterCount = history.where((e) => _tierFor(e) == 'MASTER').length;
    final rareCount = history.where((e) => _tierFor(e) == 'RARE').length;

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.all(MimzSpacing.base),
          padding: const EdgeInsets.all(MimzSpacing.base),
          decoration: BoxDecoration(
            color: MimzColors.white,
            borderRadius: BorderRadius.circular(MimzRadius.lg),
            border: Border.all(color: MimzColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill(label: 'TOTAL', value: '${history.length}', color: MimzColors.deepInk),
              _StatPill(label: 'MASTER', value: '$masterCount', color: MimzColors.dustyGold),
              _StatPill(label: 'RARE', value: '$rareCount', color: MimzColors.mistBlue),
              _StatPill(label: 'XP EARNED', value: '$_totalXp', color: MimzColors.mossCore),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        // Gallery grid or empty state
        Expanded(
          child: history.isNotEmpty
              ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    mainAxisSpacing: MimzSpacing.md,
                    crossAxisSpacing: MimzSpacing.md,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _VisionCard(
                      entry: history[index],
                      tier: _tierFor(history[index]),
                      formattedDate: _formatDate(history[index]['startedAt'] as String?),
                      index: index,
                    );
                  },
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(MimzSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: MimzColors.mistBlue.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: MimzSpacing.md),
                        Text(
                          'No vision quests yet',
                          style: MimzTypography.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: MimzSpacing.sm),
                        Text(
                          'Complete a Vision Quest to see your discoveries here.',
                          style: MimzTypography.bodyMedium
                              .copyWith(color: MimzColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _VisionCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String tier;
  final String formattedDate;
  final int index;
  const _VisionCard({
    required this.entry,
    required this.tier,
    required this.formattedDate,
    required this.index,
  });

  Color get _tierColor {
    switch (tier) {
      case 'MASTER':
        return MimzColors.dustyGold;
      case 'RARE':
        return MimzColors.mistBlue;
      default:
        return MimzColors.mossCore;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = entry['targetLabel'] as String? ?? 'Vision Quest';
    final xp = entry['xpAwarded'] as int? ?? 0;

    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.lg),
          border: Border.all(color: MimzColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _tierColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MimzRadius.lg),
                  topRight: Radius.circular(MimzRadius.lg),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: _tierColor.withValues(alpha: 0.4),
                      size: 40,
                    ),
                  ),
                  Positioned(
                    top: MimzSpacing.sm,
                    right: MimzSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MimzSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _tierColor,
                        borderRadius: BorderRadius.circular(MimzRadius.sm),
                      ),
                      child: Text(
                        tier,
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MimzSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MimzTypography.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '+$xp XP',
                        style: MimzTypography.caption.copyWith(
                          color: _tierColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 80 * index))
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MimzTypography.headlineMedium.copyWith(color: color)),
        Text(label, style: MimzTypography.caption),
      ],
    );
  }
}
