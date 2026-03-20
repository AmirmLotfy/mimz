# Branding and Splash Audit

## Findings
1. **Duplicate Splash Logos**: The Android `launch_background.xml` and iOS `LaunchScreen.storyboard` define hardcoded center logos, which display before the Flutter engine starts, and then Flutter draws its own animated `SplashScreen`, leading to a jarring double-logo effect.
2. **Logo Aspect Ratios**: In `AuthScreen`, the logo (`logo-dark.png`) is forced into a fixed 80x80 square container. If the logo isn't perfectly square, it gets squeezed or awkwardly padded.
3. **Usage of `BoxFit`**: `BoxFit.contain` is used but sometimes restricted by hardcoded widths/heights, causing the logo to appear too small or distorted in some contexts.

## Action Plan
- **Android**: Remove the logo bitmap from `app/src/main/res/drawable/launch_background.xml` and `drawable-v21/launch_background.xml`. Just retain the solid color (`@android:color/white` or equivalent `cloudBase` hex).
- **iOS**: Remove the image view from `Runner/Base.lproj/LaunchScreen.storyboard`.
- **Flutter**: Refactor `AuthScreen` and `WelcomeScreen` to let the logo size itself naturally or constrain width without constraining height, preserving its native aspect ratio. Ensure `SplashScreen` handles the single premium reveal.
