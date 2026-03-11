import 'package:flutter/material.dart';
import '../tokens.dart';

class MimzCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool hasBorder;
  final VoidCallback? onTap;

  const MimzCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? MimzColors.white,
      borderRadius: BorderRadius.circular(MimzRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        child: Container(
          padding: padding ?? const EdgeInsets.all(MimzSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MimzRadius.lg),
            border: hasBorder
                ? Border.all(color: MimzColors.borderLight)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
