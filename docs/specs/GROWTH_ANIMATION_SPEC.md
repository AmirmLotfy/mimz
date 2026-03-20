# Growth Animation Specification

## Current Flaws
- The "pulse" animation simply scales the entire district up and down, and flashes the screen with a light lime tint. 
- It triggers immediately after `claimRewards()` returns, but before the navigation transition (from ResultScreen -> WorldScreen) finishes fading in, meaning the user misses the first half of the animation.
- It doesn't highlight exactly *where* the growth occurred. The new hex just pops in simultaneously with the scale animation.

## Desired Premium Sequence

When the user returns from a successful quiz round:

1. **Wait for Visibility**: The animation controller must delay slightly until the route transition to the map is complete.
2. **Focus / Snap**: Ensure the camera (`InteractiveViewer`) is centered on the district. If not centered, smoothly pan to the district in ~400ms.
3. **The Reveal**:
   - The *existing* territory holds steady.
   - The *new* hex cell(s) appear scaled down at 0.5 and fade in while scaling up to 1.0.
   - A bright `MimzColors.acidLime` outline traces around the *newly attached* edge.
4. **The Ripple**: A subtle shockwave (a rapidly expanding thick ring fading to 0 opacity) erupts from the center of the newly added sectors outwards across the base grid.
5. **Score Float**: A small "+1 Sector" text identifier floats up from the newly added cell and fades out.

## Implementation Details

```dart
// The district provider needs to track *what just changed*
class DistrictState {
  final District district;
  final List<HexCell> newCellsThisSession; // So the painter knows which to animate
  // ...
}
```

- We will modify `worldProvider.claimRewards()` to tag the newly generated hexes so the UI can apply the "newly born" animation sequence specifically to them.
- We will replace the whole-district scale pulse with a targeted cell pop + radial ripple.
