# Map Performance Notes

## Identified Bottlenecks

### 1. Hex Coordinate Recalculation
- **Issue**: `_HexDistrictPainter` in `world_home_screen.dart` recalculates the Cartesian coordinates (`px`, `py`) from Axial coordinates (`q`, `r`) for every cell *on every single pixel repaint* during the growth pulse animation (at 60fps).
- **Solution**: Compute Cartesian coordinates exactly once and store them. Update only when `district.sectors` changes.

### 2. Individual Draw Calls
- **Issue**: The current code loops over every cell and does `canvas.drawPath()` twice (once for fill, once for stroke) and `canvas.drawCircle()` for the structure. A district with 50 sectors generates 150 draw calls per frame.
- **Solution**: 
  - Sub-paths should be combined into a single master `Path` beforehand if possible, or batched via `drawVertices`.
  - For the outer boundary, compute the outer edge path mathematically and stroke it *once*.

### 3. Glow Mask Filter
- **Issue**: `MaskFilter.blur(BlurStyle.normal, 4)` is applied inside an animated stroke that pulses at 60fps.
- **Solution**: Blur is notoriously slow on mobile GPUs. Remove `MaskFilter.blur` entirely and replace it with a pre-rendered image asset (a glowing halo PNG) that is simply scaled up, or use a pseudo-glow radial gradient which is far cheaper to compute.

### 4. Overlapping Transparent Layers
- **Issue**: Too many full-screen semi-transparent containers (like the growth flash overlay).
- **Solution**: Restrict the size of semi-transparent pulsing containers to just the bounding box of the district, not `Positioned.fill`.

### 5. `AnimatedBuilder` Abuse
- **Issue**: The entire `CustomPaint(size: Size(300, 360))` widget is wrapped inside an `AnimatedBuilder` that scales it. This triggers a repaint of the map geometry every frame.
- **Solution**: If scaling the whole cluster, wrap the static `CustomPaint` in a `RepaintBoundary` and scale the resulting layer instead of repainting the polygons.

## Optimization Strategy

1. **Extract Geometry Engine**: Move math off the UI thread where possible, or aggressively memoize it.
2. **Repaint Boundaries**: Wrap the static base grid in a `RepaintBoundary`. Wrap the interactive district layer in another.
3. **Optimized Pulse**: The pulse animation must not force a layout or geometry recalculation.
