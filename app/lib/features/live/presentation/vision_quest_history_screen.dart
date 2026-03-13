import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';

/// Vision Quest History gallery — shows past submissions
class VisionQuestHistoryScreen extends StatelessWidget {
  const VisionQuestHistoryScreen({super.key});

  // Demo history entries — in production wire to Firestore vision_quests collection
  static const _history = [
    _VisionEntry(
      label: 'Architecture detail',
      blueprint: 'Solarium Wing',
      tier: 'MASTER',
      timestamp: '2 hours ago',
      xp: 250,
    ),
    _VisionEntry(
      label: 'Urban geometry',
      blueprint: 'Observatory Tower',
      tier: 'RARE',
      timestamp: 'Yesterday',
      xp: 150,
    ),
    _VisionEntry(
      label: 'Nature texture',
      blueprint: 'Garden Atrium',
      tier: 'COMMON',
      timestamp: '2 days ago',
      xp: 80,
    ),
    _VisionEntry(
      label: 'Light reflection',
      blueprint: 'Glass Spire',
      tier: 'RARE',
      timestamp: '3 days ago',
      xp: 150,
    ),
    _VisionEntry(
      label: 'Structural detail',
      blueprint: 'Iron Foundry',
      tier: 'COMMON',
      timestamp: '4 days ago',
      xp: 80,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        title: const Text('Vision Quest History'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
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
                _StatPill(label: 'TOTAL', value: '${_history.length}', color: MimzColors.deepInk),
                _StatPill(
                  label: 'MASTER',
                  value: '${_history.where((e) => e.tier == 'MASTER').length}',
                  color: MimzColors.dustyGold,
                ),
                _StatPill(
                  label: 'RARE',
                  value: '${_history.where((e) => e.tier == 'RARE').length}',
                  color: MimzColors.mistBlue,
                ),
                _StatPill(
                  label: 'XP EARNED',
                  value: '${_history.fold(0, (sum, e) => sum + e.xp)}',
                  color: MimzColors.mossCore,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Gallery grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                mainAxisSpacing: MimzSpacing.md,
                crossAxisSpacing: MimzSpacing.md,
              ),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final entry = _history[index];
                return _VisionCard(entry: entry, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionCard extends StatelessWidget {
  final _VisionEntry entry;
  final int index;
  const _VisionCard({required this.entry, required this.index});

  Color get _tierColor {
    switch (entry.tier) {
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
            // Image placeholder with texture
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
                        entry.tier,
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
                    entry.blueprint,
                    style: MimzTypography.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.label,
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '+${entry.xp} XP',
                        style: MimzTypography.caption.copyWith(
                          color: _tierColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entry.timestamp,
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
        Text(
          value,
          style: MimzTypography.headlineMedium.copyWith(color: color),
        ),
        Text(label, style: MimzTypography.caption),
      ],
    );
  }
}

class _VisionEntry {
  final String label;
  final String blueprint;
  final String tier;
  final String timestamp;
  final int xp;
  const _VisionEntry({
    required this.label,
    required this.blueprint,
    required this.tier,
    required this.timestamp,
    required this.xp,
  });
}
