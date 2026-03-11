import 'package:flutter/material.dart';
import '../tokens.dart';

class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onEnable;
  final VoidCallback? onDismiss;
  final String enableLabel;
  final String dismissLabel;
  final bool isGranted;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onEnable,
    this.onDismiss,
    this.enableLabel = 'Enable',
    this.dismissLabel = 'Maybe later',
    this.isGranted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(
          color: isGranted ? MimzColors.mossCore : MimzColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MimzSpacing.sm),
                decoration: BoxDecoration(
                  color: isGranted
                      ? MimzColors.mossCore.withValues(alpha: 0.1)
                      : MimzColors.persimmonHit.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(MimzRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? MimzColors.mossCore : MimzColors.persimmonHit,
                  size: 20,
                ),
              ),
              const SizedBox(width: MimzSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: MimzTypography.headlineSmall,
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle, color: MimzColors.mossCore, size: 24),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          Text(description, style: MimzTypography.bodyMedium),
          const SizedBox(height: MimzSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDismiss != null && !isGranted)
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    dismissLabel,
                    style: MimzTypography.bodyMedium.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                ),
              if (!isGranted) ...[
                const SizedBox(width: MimzSpacing.sm),
                ElevatedButton(
                  onPressed: onEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MimzColors.mossCore,
                    foregroundColor: MimzColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MimzSpacing.lg,
                      vertical: MimzSpacing.md,
                    ),
                    elevation: 0,
                  ),
                  child: Text(enableLabel, style: MimzTypography.buttonText.copyWith(
                    color: MimzColors.white,
                    fontSize: 14,
                  )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
