import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tokens.dart';
import '../../services/haptics_service.dart';

enum MimzButtonVariant { primary, secondary, accent, ghost }

class MimzButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final MimzButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  const MimzButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MimzButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: 56,
      child: _buildButton(ref),
    );
  }

  Widget _buildButton(WidgetRef ref) {
    switch (variant) {
      case MimzButtonVariant.primary:
        return ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : () {
            ref.read(hapticsServiceProvider).mediumImpact();
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MimzColors.mossCore,
            foregroundColor: MimzColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            elevation: 0,
          ),
          child: _buildChild(MimzColors.white),
        );
      case MimzButtonVariant.secondary:
        return OutlinedButton(
          onPressed: (isLoading || onPressed == null) ? null : () {
            ref.read(hapticsServiceProvider).selection();
            onPressed?.call();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: MimzColors.mossCore,
            side: const BorderSide(color: MimzColors.mossCore),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
          ),
          child: _buildChild(MimzColors.mossCore),
        );
      case MimzButtonVariant.accent:
        return ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : () {
            ref.read(hapticsServiceProvider).mediumImpact();
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MimzColors.persimmonHit,
            foregroundColor: MimzColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            elevation: 0,
          ),
          child: _buildChild(MimzColors.white),
        );
      case MimzButtonVariant.ghost:
        return TextButton(
          onPressed: (isLoading || onPressed == null) ? null : () {
            ref.read(hapticsServiceProvider).selection();
            onPressed?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: MimzColors.mossCore,
          ),
          child: _buildChild(MimzColors.mossCore),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: MimzSpacing.sm),
          Text(label, style: MimzTypography.buttonText),
        ],
      );
    }
    return Text(label, style: MimzTypography.buttonText);
  }
}
