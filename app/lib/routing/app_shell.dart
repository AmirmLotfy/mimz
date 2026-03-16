import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/haptics_service.dart';
import '../design_system/tokens.dart';

/// App shell with bottom navigation — wraps main tabbed screens
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/world')) return 0;
    if (location.startsWith('/play')) return 1;
    if (location.startsWith('/squad')) return 2;
    if (location.startsWith('/events')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    ref.read(hapticsServiceProvider).selection();
    switch (index) {
      case 0:
        context.go('/world');
      case 1:
        context.go('/play');
      case 2:
        context.go('/squad');
      case 3:
        context.go('/events');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      extendBody: true, // Allow content to flow behind the pill
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: MimzSpacing.xl, right: MimzSpacing.xl, bottom: MimzSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: MimzColors.deepInk.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.sm),
                  decoration: BoxDecoration(
                    color: MimzColors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: MimzColors.borderLight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.public_outlined,
                        activeIcon: Icons.public,
                        label: 'WORLD',
                        isActive: currentIndex == 0,
                        onTap: () => _onTap(context, ref, 0),
                      ),
                      _NavItem(
                        icon: Icons.play_circle_outline,
                        activeIcon: Icons.play_circle,
                        label: 'PLAY',
                        isActive: currentIndex == 1,
                        onTap: () => _onTap(context, ref, 1),
                      ),
                      _NavItem(
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        label: 'SQUAD',
                        isActive: currentIndex == 2,
                        onTap: () => _onTap(context, ref, 2),
                      ),
                      _NavItem(
                        icon: Icons.event_outlined,
                        activeIcon: Icons.event,
                        label: 'EVENTS',
                        isActive: currentIndex == 3,
                        onTap: () => _onTap(context, ref, 3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'ME',
                        isActive: currentIndex == 4,
                        onTap: () => _onTap(context, ref, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? MimzColors.mossCore : MimzColors.textSecondary;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: MimzTypography.caption.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
