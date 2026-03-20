# District Visualization Specification

## Rendering Strategy
To ensure smooth 60fps performance on mobile, we will move away from rendering individual hexagons via separate draw calls. 

### 1. Pre-computation and Caching
- Hex coordinates (q, r) should be translated to screen pixel offsets (x, y) exactly once when the district state changes.
- The base map of unowned hexes (the "world grid") should be rendered using a tiled or batched approach, or drawn once to a `Picture` and cached.

### 2. Owned Territory Rendering
- **Fill**: Instead of drawing N individual filled hexes, we will construct a single unified `Path` representing the entire owned territory. This path will be filled with a solid or subtly gradient color.
- **Boundary**: The stroke will be applied to the unified `Path`, creating a clean, continuous outer boundary without internal cell borders segmenting the core territory.
- **Internal Details**: We will overlay a subtle, low-opacity internal hex grid strictly *within* the owned territory using `Path.combine(PathOperation.intersect, ...)` to give it the "hex" texture without harsh borders.

### 3. Visual Hierarchy
- **Base Grid**: Very subtle, dark-mode style grid lines.
- **Unowned Area**: Transparent.
- **Owned Area**: Filled with `MimzColors.deepInk` tinted slightly with `MimzColors.mossCore`, with a sharp, glowing `MimzColors.mossCore` stroke.
- **Structures**: Replaced the subtle "dot" with actual distinct icons or specialized hex renders for built structures.

## Implementation Steps
1. Create a `HexGeometry` utility class to manage calculations and path combining.
2. Refactor `_HexDistrictPainter` to use `HexGeometry.getUnifiedPath()` for the territory shape.
3. Apply `ShaderMask` or gradient fills to the unified path.
