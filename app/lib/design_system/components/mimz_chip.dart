import 'package:flutter/material.dart';
import '../tokens.dart';

class MimzChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDelete;

  const MimzChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.isSelected = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? (backgroundColor ?? MimzColors.acidLime)
        : MimzColors.surfaceLight;
    final fg = isSelected
        ? (textColor ?? MimzColors.deepInk)
        : MimzColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.md,
          vertical: MimzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MimzRadius.pill),
          border: Border.all(
            color: isSelected ? bg : MimzColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: MimzSpacing.xs),
            ],
            Text(
              label,
              style: MimzTypography.labelLarge.copyWith(color: fg),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: MimzSpacing.xs),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 14, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
