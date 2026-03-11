import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/tokens.dart';

/// App shell with bottom navigation — wraps main tabbed screens
class AppShell extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: MimzColors.white,
          border: Border(
            top: BorderSide(color: MimzColors.borderLight, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) {
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
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: MimzColors.white,
          selectedItemColor: MimzColors.mossCore,
          unselectedItemColor: MimzColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.public_outlined),
              activeIcon: Icon(Icons.public),
              label: 'WORLD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: 'PLAY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'SQUAD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'EVENTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'ME',
            ),
          ],
        ),
      ),
    );
  }
}
