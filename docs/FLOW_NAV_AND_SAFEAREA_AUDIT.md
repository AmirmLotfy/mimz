# Flow, Navigation, and SafeArea Audit

## Findings
1. **Bottom Navigation**: The app currently uses the standard Flutter `BottomNavigationBar` via `AppShell`. It is fixed to the bottom, has a border, and looks dated. It lacks the modern 2026 floating pill aesthetic.
2. **Safe Areas**: `SafeArea` is used indiscriminately wrapping entire `Scaffold` bodies (e.g., in `WelcomeScreen`, `WorldHomeScreen`, `ProfileScreen`, `LiveQuizScreen`). 
   - This causes arbitrary padding at the top and bottom of edge-to-edge designs (like maps or immersive UI).
   - If a floating bottom nav is introduced, wrapping everything in `SafeArea` will double-pad the bottom.
3. **Routing**: `GoRouter` setup is mostly solid with redirection guards. However, we need to ensure deep-linking from settings or permissions handles Edge Cases (like "permanently denied").

## Action Plan
- **Bottom Nav**: Convert `AppShell`'s bottom nav into a floating pill widget inside a `Stack`. Add blurred backgrounds and proper padding.
- **Safe Areas**: 
   - Remove `SafeArea` wrapping the `body` on screens meant to be edge-to-edge.
   - Use `SliverSafeArea` or manual `MediaQuery.of(context).padding` combined with the floating pill height to pad lists/scroll views so content scrolls *behind* the floating nav but doesn't get obscured when at rest.
- **Routing Polishes**: Verify routing guards after fixing permissions.
