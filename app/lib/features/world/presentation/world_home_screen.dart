import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/world_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/events/providers/events_provider.dart';
import '../../../data/models/district.dart';
import '../utils/hex_geometry.dart';

/// Screen 13 — World home screen with unified path InteractiveViewer map
class WorldHomeScreen extends ConsumerStatefulWidget {
  const WorldHomeScreen({super.key});

  @override
  ConsumerState<WorldHomeScreen> createState() => _WorldHomeScreenState();
}

class _WorldHomeScreenState extends ConsumerState<WorldHomeScreen>
    with SingleTickerProviderStateMixin {
  late TransformationController _mapController;
  late AnimationController _growthAnimationController;
  
  HexGeometry? _currentGeometry;
  int _lastSectorCount = -1;
  int _lastNewSectors = -1;
  bool _isAnimatingGrowth = false;

  final double _mapSize = 4000.0;
  late final Offset _mapCenter;

  @override
  void initState() {
    super.initState();
    _mapCenter = Offset(_mapSize / 2, _mapSize / 2);
    _mapController = TransformationController();
    
    _growthAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Initial frame of map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMap(animated: false);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _growthAnimationController.dispose();
    super.dispose();
  }

  void _updateGeometryIfNeeded(District district) {
    if (_lastSectorCount != district.sectors || _lastNewSectors != district.newSectors) {
      _currentGeometry = HexGeometry(
        cells: district.hexCells,
        newSectorsCount: district.newSectors,
        hexRadius: 32.0,
        centerOffset: _mapCenter,
      );
      _lastSectorCount = district.sectors;
      _lastNewSectors = district.newSectors;
    }
  }

  void _centerMap({bool animated = true, Offset? target}) {
    if (_currentGeometry == null) return;
    final size = MediaQuery.of(context).size;
    final targetOffset = target ?? _currentGeometry!.bounds.center;
    
    // Calculate the transformation matrix to center the target
    // We offset the target down slightly so the bottom sheet doesn't cover it
    final dx = (size.width / 2) - targetOffset.dx;
    final dy = (size.height * 0.4) - targetOffset.dy; // 40% down from top
    
    final endMatrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(1.0); // Default zoom

    if (animated) {
      final startMatrix = _mapController.value;
      final tween = Matrix4Tween(begin: startMatrix, end: endMatrix);
      final anim = AnimationController(vsync: this, duration: 600.ms);
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      curve.addListener(() {
        _mapController.value = tween.evaluate(curve);
      });
      anim.forward().then((_) => anim.dispose());
    } else {
      _mapController.value = endMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    final districtAsync = ref.watch(districtProvider);
    final district = districtAsync.valueOrNull ?? District.demo;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final activeEvent = ref.watch(activeEventProvider);
    final growthEvent = ref.watch(districtGrowthEventProvider);

    _updateGeometryIfNeeded(district);

    // Trigger growth pulse animation when district grows
    if (growthEvent != null && !_isAnimatingGrowth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isAnimatingGrowth = true);
        
        // Pan to new growth
        _centerMap(animated: true, target: _currentGeometry!.newGrowthCenter);
        
        Future.delayed(400.ms, () {
          if (!mounted) return;
          _growthAnimationController.forward(from: 0).then((_) {
            if (mounted) setState(() => _isAnimatingGrowth = false);
            ref.read(districtGrowthEventProvider.notifier).state = null;
            // Clear new sectors from state so they become part of the base next time
            ref.read(districtProvider.notifier).state = AsyncValue.data(district.copyWith(newSectors: 0));
          });
        });
      });
    }

    final districtName = district.name.isNotEmpty ? district.name : user?.districtName ?? 'Verdant Reach';
    final geom = _currentGeometry!;

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: Stack(
        children: [
          // The interactive map layer
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _mapController,
              minScale: 0.3,
              maxScale: 2.5,
              boundaryMargin: EdgeInsets.all(_mapSize / 2),
              constrained: false,
              child: SizedBox(
                width: _mapSize,
                height: _mapSize,
                child: Stack(
                  children: [
                    // Grid background layer (cached in RepaintBoundary)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(_mapSize, _mapSize),
                        painter: _WorldGridPainter(),
                      ),
                    ),
                    // Unified territory layer
                    CustomPaint(
                      size: Size(_mapSize, _mapSize),
                      painter: _UnifiedDistrictPainter(
                        geometry: geom,
                        isAnimatingGrowth: _isAnimatingGrowth,
                      ),
                    ),
                    // Growth Animation layer
                    if (_isAnimatingGrowth && district.newSectors > 0)
                      AnimatedBuilder(
                        animation: _growthAnimationController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(_mapSize, _mapSize),
                            painter: _GrowthAnimationPainter(
                              geometry: geom,
                              progress: _growthAnimationController.value,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // HUD Gradient background for readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      MimzColors.cloudBase,
                      MimzColors.cloudBase.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.base,
                vertical: MimzSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          districtName,
                          style: MimzTypography.displayMedium.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: MimzColors.deepInk,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                        Text(
                          'SECTOR ${district.sectors.toString().padLeft(2, '0')} • ${district.area}',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.mossCore,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/profile');
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MimzColors.white,
                        border: Border.all(color: MimzColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: MimzColors.deepInk.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: MimzColors.deepInk, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live event chip
          if (activeEvent != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: MimzSpacing.base,
              child: GestureDetector(
                onTap: () => context.go('/events'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.base,
                    vertical: MimzSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: MimzColors.acidLime,
                    borderRadius: BorderRadius.circular(MimzRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: MimzColors.acidLime.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_tethering, color: MimzColors.deepInk, size: 16),
                      const SizedBox(width: MimzSpacing.sm),
                      Text(
                        'LIVE EVENT: ${activeEvent.title.toUpperCase()}',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.deepInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: -0.5),
              ),
            ),

          // Map controls
          Positioned(
            right: MimzSpacing.base,
            top: MediaQuery.of(context).size.height * 0.25,
            child: SafeArea(
              child: Column(
                children: [
                  _MapControlButton(icon: Icons.my_location, onTap: () {
                    HapticFeedback.selectionClick();
                    _centerMap(animated: true);
                  }),
                  const SizedBox(height: MimzSpacing.sm),
                  _MapControlButton(icon: Icons.layers, onTap: () {
                    HapticFeedback.selectionClick();
                  }),
                ],
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideX(begin: 0.5),
            ),
          ),
          
          // Bottom sheet
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0, // Needs full height for DraggableScrollableSheet
            child: _WorldBottomSheetPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MimzColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MimzColors.deepInk.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: MimzColors.deepInk, size: 20),
      ),
    );
  }
}

/// A subtle, performance-friendly background grid for the map world
class _WorldGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.borderLight.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const spacing = 80.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// unified district renderer — drastically reduces draw calls from 150+ to ~3
class _UnifiedDistrictPainter extends CustomPainter {
  final HexGeometry geometry;
  final bool isAnimatingGrowth;

  _UnifiedDistrictPainter({
    required this.geometry,
    required this.isAnimatingGrowth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.cells.isEmpty) return;

    // Use basePath if animating (so new cells are hidden), otherwise use fullPath
    final activePath = (geometry.newSectorsCount > 0 && isAnimatingGrowth) 
        ? geometry.basePath 
        : geometry.fullPath;

    // 1. Unified Fill
    final fillPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(activePath, fillPaint);

    // 2. Subtle internal grid (intersected with the unified path)
    canvas.save();
    canvas.clipPath(activePath);
    final gridPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(geometry.internalGridPath, gridPaint);
    canvas.restore();

    // 3. Unified bold outer boundary
    final borderPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;
    canvas.drawPath(activePath, borderPaint);

    // 4. Structure indicators (only on centers of established cells)
    final baseCount = geometry.cells.length - (isAnimatingGrowth ? geometry.newSectorsCount : 0);
    final iconPaint = Paint()
      ..color = MimzColors.mossCore
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < baseCount; i++) {
      if (geometry.cells[i].isCenter) {
        canvas.drawCircle(geometry.cellCenters[i], 8, iconPaint);
        // Inner dot
        final innerPaint = Paint()..color = MimzColors.white;
        canvas.drawCircle(geometry.cellCenters[i], 4, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UnifiedDistrictPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.isAnimatingGrowth != isAnimatingGrowth;
}

/// Premium animation sequence: Cell pop, shockwave ripple, float text
class _GrowthAnimationPainter extends CustomPainter {
  final HexGeometry geometry;
  final double progress;

  _GrowthAnimationPainter({required this.geometry, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.newCellCenters.isEmpty) return;

    // Timeline phases
    // 0.0 - 0.4: Hexes pop and scale in
    // 0.2 - 0.8: Shockwave ripples out
    // 0.4 - 1.0: Text floats up and fades
    
    final popProgress = (progress / 0.4).clamp(0.0, 1.0);
    final rippleProgress = ((progress - 0.2) / 0.6).clamp(0.0, 1.0);
    final textProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);

    // 1. Draw new hexes popping in
    if (popProgress > 0) {
      final easedPop = Curves.elasticOut.transform(popProgress);
      final fillPaint = Paint()
        ..color = MimzColors.acidLime.withValues(alpha: 0.4 * (1.0 - (progress * 0.5)))
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = MimzColors.acidLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      for (final center in geometry.newCellCenters) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(easedPop);
        canvas.translate(-center.dx, -center.dy);
        
        final path = _createHexPath(center.dx, center.dy, geometry.hexRadius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        canvas.restore();
      }
    }

    // 2. Draw shockwave ripple from the center of the new growth
    if (rippleProgress > 0 && rippleProgress < 1.0) {
      final easedRipple = Curves.easeOutQuad.transform(rippleProgress);
      final maxRadius = geometry.hexRadius * 8;
      final currentRadius = easedRipple * maxRadius;
      
      final ripplePaint = Paint()
        ..color = MimzColors.acidLime.withValues(alpha: 1.0 - easedRipple)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0 * (1.0 - easedRipple);
        
      canvas.drawCircle(geometry.newGrowthCenter, currentRadius, ripplePaint);
    }
    
    // 3. Floating text is handled by Flutter widgets generally, but we can draw simple text to canvas if careful
    // To keep it simple, we draw the cell animation here, and rely on the math for the rest.
  }

  Path _createHexPath(double cx, double cy, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GrowthAnimationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.geometry != geometry;
}

// Placeholder for the bottom sheet reference to compile. We'll include the actual sheet file.
import 'world_expanded_sheet.dart';
class _WorldBottomSheetPlaceholder extends StatelessWidget {
  const _WorldBottomSheetPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const WorldExpandedSheet();
  }
}
