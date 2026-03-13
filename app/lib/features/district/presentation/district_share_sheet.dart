import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../data/models/district.dart';

/// District share bottom sheet — lets the user share their district card
class DistrictShareSheet extends StatefulWidget {
  final District district;
  const DistrictShareSheet({super.key, required this.district});

  @override
  State<DistrictShareSheet> createState() => _DistrictShareSheetState();
}

class _DistrictShareSheetState extends State<DistrictShareSheet> {
  bool _copied = false;

  String get _shareText =>
      '🏙 My district "${widget.district.name}" has ${widget.district.sectors} sectors '
      'and Prestige Level ${widget.district.prestigeLevel} on Mimz! '
      'Join me: mimz.app/district/${widget.district.name.toLowerCase().replaceAll(' ', '-')}';

  void _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.district;
    return Container(
      decoration: const BoxDecoration(
        color: MimzColors.cloudBase,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MimzRadius.xl),
        ),
      ),
      padding: const EdgeInsets.all(MimzSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MimzColors.borderLight,
              borderRadius: BorderRadius.circular(MimzRadius.pill),
            ),
          ),
          const SizedBox(height: MimzSpacing.xl),

          // District card preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MimzSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MimzColors.mossCore, MimzColors.mistBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(MimzRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: MimzColors.mossCore.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hexagon, color: Colors.white, size: 20),
                    const SizedBox(width: MimzSpacing.sm),
                    Text(
                      'MIMZ DISTRICT',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MimzSpacing.lg),
                Text(
                  district.name.isNotEmpty ? district.name : 'Verdant Reach',
                  style: MimzTypography.displayMedium.copyWith(
                    color: MimzColors.white,
                  ),
                ),
                const SizedBox(height: MimzSpacing.md),
                Row(
                  children: [
                    _ShareStat(
                      label: 'SECTORS',
                      value: '${district.sectors}',
                    ),
                    const SizedBox(width: MimzSpacing.xl),
                    _ShareStat(
                      label: 'PRESTIGE',
                      value: 'Lv.${district.prestigeLevel}',
                    ),
                    const SizedBox(width: MimzSpacing.xl),
                    _ShareStat(
                      label: 'GROWTH',
                      value: '${district.growthRate}%',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: MimzSpacing.xl),

          // Share actions
          Text(
            'SHARE YOUR DISTRICT',
            style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: MimzSpacing.md),
          Row(
            children: [
              // Copy link
              Expanded(
                child: GestureDetector(
                  onTap: _copyLink,
                  child: AnimatedContainer(
                    duration: 300.ms,
                    padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: _copied
                          ? MimzColors.mossCore
                          : MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                      border: Border.all(color: MimzColors.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.link,
                          color: _copied ? MimzColors.white : MimzColors.deepInk,
                          size: 18,
                        ),
                        const SizedBox(width: MimzSpacing.sm),
                        Text(
                          _copied ? 'Copied!' : 'Copy Link',
                          style: MimzTypography.headlineSmall.copyWith(
                            color: _copied
                                ? MimzColors.white
                                : MimzColors.deepInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MimzSpacing.md),
              // Share via system
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Native share sheet — requires share_plus package
                    // For now show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Share: $_shareText'),
                        backgroundColor: MimzColors.mossCore,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: MimzColors.mossCore,
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, color: MimzColors.white, size: 18),
                        const SizedBox(width: MimzSpacing.sm),
                        Text(
                          'Share',
                          style: MimzTypography.headlineSmall.copyWith(
                            color: MimzColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.xl),
        ],
      ),
    );
  }
}

/// Convenience method to show the district share sheet
void showDistrictShareSheet(BuildContext context, District district) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DistrictShareSheet(district: district),
  );
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  const _ShareStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: MimzTypography.headlineMedium.copyWith(
            color: MimzColors.white,
          ),
        ),
        Text(
          label,
          style: MimzTypography.caption.copyWith(
            color: MimzColors.white.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
