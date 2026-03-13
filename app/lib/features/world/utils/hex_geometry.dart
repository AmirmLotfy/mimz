import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/district.dart';

/// Pre-calculates and caches complex hex geometry to keep the UI thread fast during map animations.
class HexGeometry {
  final List<HexCell> cells;
  final int newSectorsCount;
  final double hexRadius;
  final Offset centerOffset;

  late final double hexWidth;
  late final double hexHeight;

  late final Path basePath;       // The unified path of the OLD territory
  late final Path fullPath;       // The unified path of ALL territory
  late final Path internalGridPath;
  late final List<Offset> cellCenters;
  late final List<Offset> newCellCenters; // Just the centers of the new cells
  late final Rect bounds;
  late final Offset newGrowthCenter;

  HexGeometry({
    required this.cells,
    this.newSectorsCount = 0,
    required this.hexRadius,
    this.centerOffset = Offset.zero,
  }) {
    hexHeight = hexRadius * 2;
    hexWidth = sqrt(3) * hexRadius;
    _calculate();
  }

  void _calculate() {
    cellCenters = [];
    newCellCenters = [];
    
    Path base = Path();
    Path full = Path();
    final gridPath = Path();

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    double growthSumX = 0;
    double growthSumY = 0;

    final baseCount = cells.length - newSectorsCount;

    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      // Convert axial to pixel (pointy-top hex)
      final px = centerOffset.dx + hexWidth * (cell.q + cell.r / 2.0);
      final py = centerOffset.dy + hexHeight * 0.75 * cell.r;

      cellCenters.add(Offset(px, py));

      minX = min(minX, px - hexRadius);
      maxX = max(maxX, px + hexRadius);
      minY = min(minY, py - hexRadius);
      maxY = max(maxY, py + hexRadius);

      final hexPath = _createHexPath(px, py, hexRadius - 0.5);
      final isNew = i >= baseCount;

      if (isNew) {
        newCellCenters.add(Offset(px, py));
        growthSumX += px;
        growthSumY += py;
      } else {
        if (i == 0) {
          base = hexPath;
        } else {
          base = Path.combine(PathOperation.union, base, hexPath);
        }
      }

      if (i == 0) {
        full = hexPath;
      } else {
        full = Path.combine(PathOperation.union, full, hexPath);
      }
      
      // We only want grid lines inside the base for now, or across all. Let's do all.
      gridPath.addPath(_createHexPath(px, py, hexRadius), Offset.zero);
    }

    basePath = base;
    fullPath = full;
    internalGridPath = gridPath;
    bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    
    if (newSectorsCount > 0 && newCellCenters.isNotEmpty) {
      newGrowthCenter = Offset(growthSumX / newSectorsCount, growthSumY / newSectorsCount);
    } else {
      newGrowthCenter = centerOffset;
    }
  }

  Path _createHexPath(double cx, double cy, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
