import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/world_provider.dart';
import '../providers/game_state_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/events/providers/events_provider.dart';
import '../../../data/models/district.dart';
import '../../../core/providers.dart';
import '../utils/hex_geometry.dart';
import 'world_expanded_sheet.dart';

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
  bool _showTutorial = true; // Shows once per app session

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
      ..setTranslationRaw(dx, dy, 0.0); // Default zoom

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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final activeEvent = ref.watch(activeEventProvider);
    final eventZones = ref.watch(eventZonesProvider);
    final activeConflicts = ref.watch(activeConflictsProvider);
    final structureProgress = ref.watch(structureProgressProvider);
    final growthEvent = ref.watch(districtGrowthEventProvider);
    final districtErr = districtAsync.error?.toString() ?? '';
    final districtErrorDetail = districtErr
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '');

    if (districtAsync.isLoading) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: MimzSpacing.md),
                Text(
                  'Loading your district…',
                  style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (districtAsync.hasError) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: MimzColors.error),
                  const SizedBox(height: MimzSpacing.md),
                  Text(
                    'Could not load your district.',
                    style: MimzTypography.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (districtErrorDetail.isNotEmpty) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    Text(
                      districtErrorDetail,
                      style: MimzTypography.bodyMedium.copyWith(
                        color: MimzColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: MimzSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => ref.read(districtProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  if (districtErr.contains('Session expired')) ...[
                    const SizedBox(height: MimzSpacing.md),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(isOnboardedProvider.notifier).resetOnboarding();
                        await ref.read(authServiceProvider).signOut();
                        if (!context.mounted) return;
                        context.go('/welcome');
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Sign out'),
                      style: TextButton.styleFrom(
                        foregroundColor: MimzColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (districtAsync.valueOrNull == null) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: MimzColors.textSecondary),
                  const SizedBox(height: MimzSpacing.md),
                  Text(
                    'No district data yet.',
                    style: MimzTypography.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => ref.read(districtProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final district = districtAsync.valueOrNull!;
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
            ref.read(districtProvider.notifier).updateLocal(district.copyWith(newSectors: 0));
          });
        });
      });
    }

    final districtName = district.name.isNotEmpty ? district.name : user?.districtName ?? 'My District';
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
                        structures: district.structures,
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
                    Positioned(
                      left: _mapCenter.dx - 8,
                      top: _mapCenter.dy - 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: MimzColors.mossCore,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MimzColors.mossCore.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: 1500.ms,
                          )
                          .fadeIn(),
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
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go('/district/detail');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                districtName,
                                style: MimzTypography.displayMedium.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: MimzColors.deepInk,
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 12, color: MimzColors.textTertiary),
                            ],
                          ),
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

          // World state chips
          if (activeEvent != null || activeConflicts.isNotEmpty || district.decayState != 'stable')
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: MimzSpacing.base,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeEvent != null)
                    GestureDetector(
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
                  if (eventZones.isNotEmpty) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    GestureDetector(
                      onTap: () => context.go('/events'),
                      child: _WorldStateChip(
                        icon: Icons.public,
                        label: '${eventZones.first.regionLabel} • x${eventZones.first.rewardMultiplier.toStringAsFixed(1)} rewards',
                        color: MimzColors.mistBlue,
                      ),
                    ),
                  ],
                  if (activeConflicts.isNotEmpty || district.decayState != 'stable') ...[
                    const SizedBox(height: MimzSpacing.sm),
                    GestureDetector(
                      onTap: () => context.go('/district/detail'),
                      child: _WorldStateChip(
                        icon: activeConflicts.isNotEmpty ? Icons.warning_amber_rounded : Icons.thermostat,
                        label: activeConflicts.isNotEmpty
                            ? '${activeConflicts.length} frontier conflict${activeConflicts.length > 1 ? 's' : ''}'
                            : 'Frontier is ${district.decayState}',
                        color: MimzColors.persimmonHit,
                      ),
                    ),
                  ],
                  if (structureProgress?.readyToBuild == true) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    GestureDetector(
                      onTap: () => context.go('/district/detail'),
                      child: _WorldStateChip(
                        icon: Icons.account_balance,
                        label: '${structureProgress?.nextStructureName ?? 'New structure'} ready to build',
                        color: MimzColors.dustyGold,
                      ),
                    ),
                  ],
                ],
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

          // ── First-time tutorial overlay (UX-06) ─────────────
          if (_showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showTutorial = false),
                child: Container(
                  color: MimzColors.nightSurface.withValues(alpha: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pulsing hex ring
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MimzColors.acidLime,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.hexagon_outlined,
                          color: MimzColors.acidLime,
                          size: 52,
                        ),
                      )
                          .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                          .scaleXY(begin: 0.9, end: 1.05, duration: 1000.ms, curve: Curves.easeInOut)
                          .then()
                          .fadeIn(duration: 200.ms),
                      const SizedBox(height: MimzSpacing.xl),
                      Text(
                        'Your District Awaits',
                        style: MimzTypography.displayMedium.copyWith(
                          color: MimzColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: MimzSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                        child: Text(
                          'Play live voice rounds to earn sectors.\nYour district grows with every win.',
                          style: MimzTypography.bodyMedium.copyWith(
                            color: MimzColors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: MimzSpacing.xxl),
                      // Start Playing CTA
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showTutorial = false);
                          context.go('/play');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MimzSpacing.xxl,
                            vertical: MimzSpacing.base,
                          ),
                          decoration: BoxDecoration(
                            color: MimzColors.acidLime,
                            borderRadius: BorderRadius.circular(MimzRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: MimzColors.acidLime.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            '▶  Start Playing',
                            style: MimzTypography.headlineMedium.copyWith(
                              color: MimzColors.deepInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),
                      const SizedBox(height: MimzSpacing.xl),
                      Text(
                        'Tap anywhere to dismiss',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.white.withValues(alpha: 0.4),
                        ),
                      ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),
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

class _WorldStateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _WorldStateChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: MimzSpacing.sm),
          Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: MimzColors.deepInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hex-based background grid for the map world
class _WorldGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.borderLight.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexRadius = 40.0;
    final w = hexRadius * 2;
    final h = hexRadius * sqrt(3);

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      final yOff = row * h * 0.75;
      final xShift = (row.toInt() % 2 == 0) ? 0.0 : w * 0.75;
      for (double col = -1; col * w * 1.5 < size.width + w; col++) {
        final cx = col * w * 1.5 + xShift;
        final cy = yOff;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * pi / 180;
          final px = cx + hexRadius * cos(angle);
          final py = cy + hexRadius * sin(angle);
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// unified district renderer with territory layer coloring
class _UnifiedDistrictPainter extends CustomPainter {
  final HexGeometry geometry;
  final bool isAnimatingGrowth;
  final List<Structure> structures;

  static const _coreFill = Color(0xFF2D6A4F);
  static const _innerFill = Color(0xFF40916C);
  static const _frontierFill = Color(0xFF74C69D);

  _UnifiedDistrictPainter({
    required this.geometry,
    required this.isAnimatingGrowth,
    this.structures = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.cells.isEmpty) return;

    final activePath = (geometry.newSectorsCount > 0 && isAnimatingGrowth)
        ? geometry.basePath
        : geometry.fullPath;

    // 1. Base fill
    final fillPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(activePath, fillPaint);

    // 2. Per-cell layer coloring
    final baseCount = geometry.cells.length - (isAnimatingGrowth ? geometry.newSectorsCount : 0);
    for (int i = 0; i < baseCount && i < geometry.cellCenters.length; i++) {
      final cell = geometry.cells[i];
      Color layerColor;
      double alpha;
      switch (cell.layer) {
        case CellLayer.core:
          layerColor = _coreFill;
          alpha = 0.25;
        case CellLayer.inner:
          layerColor = _innerFill;
          alpha = 0.18;
        case CellLayer.frontier:
          layerColor = _frontierFill;
          alpha = 0.12 + (cell.stability / 100) * 0.08;
      }

      final cellPath = _hexPath(geometry.cellCenters[i], geometry.hexRadius);
      canvas.drawPath(cellPath, Paint()
        ..color = layerColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill);
    }

    // 3. Internal grid
    canvas.save();
    canvas.clipPath(activePath);
    final gridPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(geometry.internalGridPath, gridPaint);
    canvas.restore();

    // 4. Outer boundary
    final borderPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;
    canvas.drawPath(activePath, borderPaint);

    // 5. Center dot
    for (int i = 0; i < baseCount; i++) {
      if (geometry.cells[i].isCenter) {
        canvas.drawCircle(geometry.cellCenters[i], 8, Paint()..color = MimzColors.mossCore);
        canvas.drawCircle(geometry.cellCenters[i], 4, Paint()..color = MimzColors.white);
      }
    }

    // 6. Structure icons on specific cells
    final structPaint = Paint()
      ..color = MimzColors.dustyGold
      ..style = PaintingStyle.fill;
    final structStroke = Paint()
      ..color = MimzColors.dustyGold.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int si = 0; si < structures.length && si < baseCount; si++) {
      final cellIdx = _structureCellIndex(si, baseCount);
      if (cellIdx >= baseCount || cellIdx >= geometry.cellCenters.length) continue;
      final center = geometry.cellCenters[cellIdx];
      _drawStructureIcon(canvas, center, structures[si].id, structPaint, structStroke);
    }
  }

  int _structureCellIndex(int structureIndex, int totalCells) {
    // Place structures at evenly spaced cells, skipping center (0)
    if (totalCells <= 1) return 0;
    final step = (totalCells - 1) ~/ (structures.length.clamp(1, totalCells - 1));
    return 1 + structureIndex * step.clamp(1, totalCells - 1);
  }

  void _drawStructureIcon(Canvas canvas, Offset center, String structureId, Paint fill, Paint stroke) {
    const s = 10.0;
    switch (structureId) {
      case 'library':
        canvas.drawRect(Rect.fromCenter(center: center, width: s, height: s * 1.2), fill);
        canvas.drawRect(Rect.fromCenter(center: center, width: s, height: s * 1.2), stroke);
      case 'observatory':
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), stroke);
        canvas.restore();
      case 'archive':
        final path = Path()
          ..moveTo(center.dx, center.dy - s * 0.7)
          ..lineTo(center.dx + s * 0.6, center.dy + s * 0.5)
          ..lineTo(center.dx - s * 0.6, center.dy + s * 0.5)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case 'park_pavilion':
        canvas.drawCircle(center.translate(0, -s * 0.3), s * 0.45, fill);
        canvas.drawLine(center.translate(0, -s * 0.3), center.translate(0, s * 0.6), stroke);
      case 'maker_hub':
        final miniR = s * 0.5;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * pi / 180;
          final x = center.dx + miniR * cos(angle);
          final y = center.dy + miniR * sin(angle);
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      default:
        canvas.drawCircle(center, s * 0.4, fill);
    }
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _UnifiedDistrictPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.isAnimatingGrowth != isAnimatingGrowth ||
      oldDelegate.structures.length != structures.length;
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
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GrowthAnimationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.geometry != geometry;
}

// Placeholder for the bottom sheet reference to compile. We'll include the actual sheet file.
// Placeholder for the bottom sheet reference to compile. We'll include the actual sheet file.
class _WorldBottomSheetPlaceholder extends StatelessWidget {
  const _WorldBottomSheetPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const WorldExpandedSheet();
  }
}
