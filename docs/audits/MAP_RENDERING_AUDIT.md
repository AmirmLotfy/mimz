# Map Rendering Audit

## 1. Map Rendering Quality
- **Current State**: Uses a basic `_WorldGridPainter` rendering a static, light grey grid on a solid background color (`MimzColors.cloudBase`). The district is rendered with `_HexDistrictPainter` which paints colored hexagons based on an axial coordinate spiral algorithm.
- **Issues**:
  - The map is very basic and lacks a premium feel.
  - No camera/viewport controls (InteractiveViewer or similar). The map is currently fixed in place on the screen.
  - The map controls (My Location, Layers, +, -) are static buttons that don't actually do anything.
- **Goal**: Implement a real pan/zoom interactive map layer (using `InteractiveViewer` or a custom gesture system since we are rendering custom hexes), improve the background grid or style to feel more "premium branded", and ensure the map fits the brand. The base map needs less noise but more texture.

## 2. District Visualization
- **Current State**: Hex cells fade out toward the edges based on a distance calculation. The center has a dark border, outer cells are lighter. An "anchor" dot sits on the center cell.
- **Issues**:
  - Simple mathematical fade looks okay but could be much richer.
  - No empty/unowned cells are rendered. The world feels empty outside the district.
  - The structure placement cue (anchor dot) is extremely subtle and not visually impressive.
- **Goal**: Render a beautiful, readable cluster. Add subtle background styling for unowned/locked adjacent territory to show potential growth. Improve the border around the owned territory to be a crisp, continuous boundary line rather than individual hex strokes.

## 3. Growth Feedback
- **Current State**: Upon returning from a quiz with a new sector, a 1.2s pulse animation triggers. The pulse scales the entire hex cluster slightly and draws a blurred outer glow (`MaskFilter.blur`) that expands and fades out.
- **Issues**:
  - Requires the user to remember what the map looked like before to know *where* it grew.
  - The new hex cell itself just pops into existence.
  - The scaling effect on the whole cluster is a bit unnatural for a map.
- **Goal**: The animation needs to be more specific. The new cell(s) should fade/scale in individually. A shockwave or ink-reveal effect centered on the newly acquired cells, rather than pulsing the whole map. A floating text "+1 Sector" near the new growth.

## 4. Overlays
- **Current State**:
  - Top HUD has district name, sector count, area, and profile button.
  - Live Event chip floats below the top HUD.
  - Huge "PLAY" button floats over the center of the map.
  - Side map controls (My Location, etc) float on the right.
  - Bottom sheet (`DraggableScrollableSheet`) sits at the bottom, peeking up.
- **Issues**:
  - The giant "PLAY" button blocks the actual center of the map / the most important part of the district.
  - Overlays overlap in a confusing way (the Live Event chip, the Play button, the Map Controls, and the Bottom Sheet leave very little safe area for the district itself).
  - Bottom sheet and map are disconnected. Dragging the sheet up covers the map but doesn't shift the map's focal point.
- **Goal**: Relocate the PLAY button (maybe into the bottom sheet peek area, or pin it cleanly above the sheet). Organize the HUD so the map is the undisputed hero.

## 5. Camera / Viewport Logic
- **Current State**: No camera. The district is statically centered in a 300x360 CustomPaint box inside an `AnimatedBuilder` that translates/scales it.
- **Issues**:
  - As the district grows to 50+ sectors, it will overflow the screen or overlap UI.
  - Cannot pan to see the edges of a large district.
  - Cannot zoom in to see structure details.
- **Goal**: Wrap the map in an `InteractiveViewer`. Implement a map controller (or simple translation/scale state) to track the camera. When the bottom sheet expands, animate the camera offset so the district remains visible in the top half of the screen.

## 6. Performance
- **Current State**: The `_HexDistrictPainter` recalculates the axial coordinates for all cells on every paint frame during the 1.2s pulse animation.
- **Issues**:
  - Re-calculating `sqrt(3) * hexRadius` and the spiral math on every frame.
  - Painting every hex individually. If the district has 100 sectors, that's 200 draw calls (fill + stroke) per frame during a 60fps animation.
  - Using `MaskFilter.blur` inside an animation loop is very expensive on mobile GPUs and frequently causes dropped frames.
- **Goal**: Pre-calculate hex screen coordinates. Batch rendering (use `drawPath` with a combined path for the fills, or `drawVertices`). Remove `MaskFilter.blur` from the animation loop, or cache it to an image/picture first. Use `RepaintBoundary` appropriately.

## 7. State Synchronization
- **Current State**: Post-quiz, `claimRewards` is called, state updates, navigating back to world triggers the pulse based on `districtGrowthEventProvider` having a value.
- **Issues**:
  - Navigation transition and the 1.2s pulse animation overlap, causing a janky start to the animation. Wait for the route transition to complete before starting the growth pulse.
- **Goal**: Perfect the timing. Route transition finishes -> slight pause -> dramatic growth animation.
