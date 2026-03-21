import 'dart:async';
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
import '../../../data/models/district.dart';
import '../../../data/models/game_state.dart';
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
  bool _showTutorial = false;
  bool _trackedFirstWorldRender = false;
  bool _feedbackClearScheduled = false;

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

  Offset _eventZoneTarget(
    HexGeometry geometry,
    int index,
    int total,
  ) {
    final count = total <= 0 ? 1 : total;
    final radius =
        max(geometry.bounds.width, geometry.bounds.height) * 0.45 + 180;
    final angle = (-pi / 3) + ((2 * pi) / count) * index;
    final raw = Offset(
      geometry.bounds.center.dx + cos(angle) * radius,
      geometry.bounds.center.dy + sin(angle) * radius,
    );
    return Offset(
      raw.dx.clamp(120.0, _mapSize - 120.0),
      raw.dy.clamp(120.0, _mapSize - 120.0),
    );
  }

  Offset _conflictTarget(
    HexGeometry geometry,
    int index,
    int total,
  ) {
    final count = total <= 0 ? 1 : total;
    final radius =
        max(geometry.bounds.width, geometry.bounds.height) * 0.28 + 96;
    final angle = (pi / 5) + ((2 * pi) / count) * index;
    final raw = Offset(
      geometry.bounds.center.dx + cos(angle) * radius,
      geometry.bounds.center.dy + sin(angle) * radius,
    );
    return Offset(
      raw.dx.clamp(140.0, _mapSize - 140.0),
      raw.dy.clamp(140.0, _mapSize - 140.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districtAsync = ref.watch(districtProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final activeEvent = ref.watch(canonicalActiveEventProvider);
    final eventZones = ref.watch(eventZonesProvider);
    final activeConflicts = ref.watch(activeConflictsProvider);
    final structureProgress = ref.watch(structureProgressProvider);
    final showMeetMimzPrompt = ref.watch(showMeetMimzPromptProvider);
    final heroBanner = ref.watch(worldHeroBannerProvider);
    final primaryAction = ref.watch(recommendedPrimaryActionProvider);
    final secondaryAction = ref.watch(recommendedSecondaryActionProvider);
    final districtHealth = ref.watch(districtHealthSummaryProvider);
    final growthEvent = ref.watch(districtGrowthEventProvider);
    final worldArrivalFeedback = ref.watch(worldArrivalFeedbackProvider);
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
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: MimzColors.error,
                  ),
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
                  const Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: MimzColors.textSecondary,
                  ),
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
    if (worldArrivalFeedback != null && !_feedbackClearScheduled) {
      _feedbackClearScheduled = true;
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        ref.read(worldArrivalFeedbackProvider.notifier).state = null;
        _feedbackClearScheduled = false;
      });
    } else if (worldArrivalFeedback == null) {
      _feedbackClearScheduled = false;
    }
    if (!_trackedFirstWorldRender) {
      _trackedFirstWorldRender = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(telemetryServiceProvider).track(
                'world_first_render',
                route: '/world',
                metadata: {
                  'sectorCount': district.sectors,
                  'eventZoneCount': eventZones.length,
                  'conflictCount': activeConflicts.length,
                  'healthState': districtHealth?.state ?? district.decayState,
                  'hasPrimaryAction': primaryAction != null,
                },
                dedupeKey: 'world-first-render',
              ),
        );
      });
    }
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
    final eventMarkerData =
        eventZones.take(3).toList().asMap().entries.map((entry) {
      return (
        zone: entry.value,
        center: _eventZoneTarget(
          geom,
          entry.key,
          min(eventZones.length, 3),
        ),
      );
    }).toList();
    final conflictMarkerData =
        activeConflicts.take(2).toList().asMap().entries.map((entry) {
      return (
        conflict: entry.value,
        center: _conflictTarget(
          geom,
          entry.key,
          min(activeConflicts.length, 2),
        ),
      );
    }).toList();
    final hiddenEventZoneCount = max(0, eventZones.length - eventMarkerData.length);
    final hiddenConflictCount =
        max(0, activeConflicts.length - conflictMarkerData.length);
    final extraEventClusterCenter = hiddenEventZoneCount > 0
        ? _eventZoneTarget(
            geom,
            eventMarkerData.length,
            min(eventZones.length, eventMarkerData.length + 1),
          )
        : null;
    final extraConflictClusterCenter = hiddenConflictCount > 0
        ? _conflictTarget(
            geom,
            conflictMarkerData.length,
            min(activeConflicts.length, conflictMarkerData.length + 1),
          )
        : null;
    final buildReadyTarget = structureProgress?.readyToBuild == true
        ? Offset(
            geom.bounds.topCenter.dx.clamp(140.0, _mapSize - 140.0),
            (geom.bounds.topCenter.dy - 120).clamp(140.0, _mapSize - 140.0),
          )
        : null;

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
                    CustomPaint(
                      size: Size(_mapSize, _mapSize),
                      painter: _WorldZoneFieldPainter(
                        fields: [
                          ...eventMarkerData.map(
                            (entry) => _WorldZoneField(
                              center: entry.center,
                              baseColor: entry.zone.status == 'live'
                                  ? MimzColors.dustyGold
                                  : MimzColors.mistBlue,
                              radius: entry.zone.status == 'live' ? 210 : 168,
                              emphasis: entry.zone.status == 'live' ? 1 : 0.66,
                            ),
                          ),
                          ...conflictMarkerData.map(
                            (entry) => _WorldZoneField(
                              center: entry.center,
                              baseColor: MimzColors.persimmonHit,
                              radius: 148 +
                                  min(entry.conflict.cellsAtStake, 6) * 8,
                              emphasis: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomPaint(
                      size: Size(_mapSize, _mapSize),
                      painter: _WorldLinkPainter(
                        districtCenter: geom.bounds.center,
                        eventTargets: eventMarkerData
                            .map((entry) => entry.center)
                            .toList(),
                        conflictTargets: conflictMarkerData
                            .map((entry) => entry.center)
                            .toList(),
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
                    if (_isAnimatingGrowth && growthEvent != null)
                      Positioned(
                        left: geom.newGrowthCenter.dx - 86,
                        top: geom.newGrowthCenter.dy - 122,
                        child: _WorldGrowthCallout(
                          sectorsGained: growthEvent.newSectors,
                          score: growthEvent.scoreEarned,
                        ),
                      ),
                    ...eventMarkerData.map((entry) {
                      final markerCenter = entry.center;
                      final zone = entry.zone;
                      return Positioned(
                        left: markerCenter.dx - 34,
                        top: markerCenter.dy - 34,
                        child: _EventZoneMarker(
                          zone: zone,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(animated: true, target: markerCenter);
                            context.go('/events');
                          },
                        ),
                      );
                    }),
                    ...conflictMarkerData.map((entry) {
                      final markerCenter = entry.center;
                      final conflict = entry.conflict;
                      return Positioned(
                        left: markerCenter.dx - 30,
                        top: markerCenter.dy - 30,
                        child: _ConflictMarker(
                          conflict: conflict,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(animated: true, target: markerCenter);
                            context.go('/district/detail');
                          },
                        ),
                      );
                    }),
                    if (extraEventClusterCenter != null)
                      Positioned(
                        left: extraEventClusterCenter.dx - 28,
                        top: extraEventClusterCenter.dy - 28,
                        child: _WorldClusterMarker(
                          icon: Icons.public,
                          label: '+$hiddenEventZoneCount',
                          color: MimzColors.mistBlue,
                          subtitle: 'zones',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(
                              animated: true,
                              target: extraEventClusterCenter,
                            );
                            context.go('/events');
                          },
                        ),
                      ),
                    if (extraConflictClusterCenter != null)
                      Positioned(
                        left: extraConflictClusterCenter.dx - 28,
                        top: extraConflictClusterCenter.dy - 28,
                        child: _WorldClusterMarker(
                          icon: Icons.warning_amber_rounded,
                          label: '+$hiddenConflictCount',
                          color: MimzColors.persimmonHit,
                          subtitle: 'risks',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(
                              animated: true,
                              target: extraConflictClusterCenter,
                            );
                            context.go('/district/detail');
                          },
                        ),
                      ),
                    if (buildReadyTarget != null)
                      Positioned(
                        left: buildReadyTarget.dx - 42,
                        top: buildReadyTarget.dy - 42,
                        child: _StructureReadyBeacon(
                          structureName:
                              structureProgress?.nextStructureName ??
                              'Structure',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(animated: true, target: buildReadyTarget);
                            context.go('/district/detail');
                          },
                        ),
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

          if (heroBanner != null ||
              showMeetMimzPrompt ||
              activeEvent != null ||
              activeConflicts.isNotEmpty ||
              district.decayState != 'stable')
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: MimzSpacing.base,
              right: MimzSpacing.base + 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (heroBanner != null)
                    _WorldHeroCard(
                      eyebrow: heroBanner.eyebrow,
                      title: heroBanner.title,
                      body: heroBanner.body,
                      primaryAction: primaryAction,
                      secondaryAction: secondaryAction,
                      districtHealth: districtHealth,
                      activeConflictCount: activeConflicts.length,
                      highlightedZone:
                          eventZones.isNotEmpty ? eventZones.first : null,
                      structureProgress: structureProgress,
                    ),
                  if (showMeetMimzPrompt) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    GestureDetector(
                      onTap: () => context.go('/onboarding/live'),
                      child: const _WorldStateChip(
                        icon: Icons.record_voice_over,
                        label: 'Hear your district welcome',
                        color: MimzColors.mossCore,
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
                  if (eventZones.isNotEmpty) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    _MapControlButton(
                      icon: Icons.wifi_tethering,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _centerMap(
                          animated: true,
                          target: _eventZoneTarget(
                            geom,
                            0,
                            min(eventZones.length, 3),
                          ),
                        );
                      },
                    ),
                  ],
                  if (activeConflicts.isNotEmpty) ...[
                    const SizedBox(height: MimzSpacing.sm),
                    _MapControlButton(
                      icon: Icons.warning_amber_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _centerMap(
                          animated: true,
                          target: _conflictTarget(
                            geom,
                            0,
                            min(activeConflicts.length, 2),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideX(begin: 0.5),
            ),
          ),

          Positioned(
            left: MimzSpacing.base,
            right: MimzSpacing.base + 56,
            bottom: worldArrivalFeedback != null ? 272 : 128,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _WorldFocusPill(
                      icon: Icons.hexagon_outlined,
                      label: districtName,
                      accent: MimzColors.mossCore,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _centerMap(animated: true, target: geom.bounds.center);
                      },
                    ),
                    ...eventMarkerData.map((entry) {
                      final zone = entry.zone;
                      return Padding(
                        padding: const EdgeInsets.only(left: MimzSpacing.sm),
                        child: _WorldFocusPill(
                          icon: zone.status == 'live'
                              ? Icons.wifi_tethering
                              : Icons.public,
                          label: zone.title,
                          accent: zone.status == 'live'
                              ? MimzColors.dustyGold
                              : MimzColors.mistBlue,
                          badge: zone.status == 'live' ? 'LIVE' : 'ZONE',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(animated: true, target: entry.center);
                          },
                        ),
                      );
                    }),
                    if (hiddenEventZoneCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: MimzSpacing.sm),
                        child: _WorldFocusPill(
                          icon: Icons.add_circle_outline,
                          label: '$hiddenEventZoneCount more zone${hiddenEventZoneCount == 1 ? '' : 's'}',
                          accent: MimzColors.mistBlue,
                          badge: 'MAP',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go('/events');
                          },
                        ),
                      ),
                    ...conflictMarkerData.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: MimzSpacing.sm),
                        child: _WorldFocusPill(
                          icon: Icons.warning_amber_rounded,
                          label: entry.conflict.headline ?? 'Frontier conflict',
                          accent: MimzColors.persimmonHit,
                          badge: 'RISK',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _centerMap(animated: true, target: entry.center);
                          },
                        ),
                      );
                    }),
                    if (hiddenConflictCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: MimzSpacing.sm),
                        child: _WorldFocusPill(
                          icon: Icons.layers_clear,
                          label:
                              '$hiddenConflictCount more frontier risk${hiddenConflictCount == 1 ? '' : 's'}',
                          accent: MimzColors.persimmonHit,
                          badge: 'RISK',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go('/district/detail');
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: MimzSpacing.base,
            bottom: worldArrivalFeedback != null ? 348 : 204,
            child: SafeArea(
              top: false,
              child: _WorldMiniLegend(
                visibleZoneCount: eventMarkerData.length,
                totalZoneCount: eventZones.length,
                visibleConflictCount: conflictMarkerData.length,
                totalConflictCount: activeConflicts.length,
              ),
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

          if (worldArrivalFeedback != null)
            Positioned(
              left: MimzSpacing.base,
              right: MimzSpacing.base,
              bottom: 180,
              child: _WorldArrivalFeedbackCard(
                feedback: worldArrivalFeedback,
                onDismiss: () {
                  ref.read(worldArrivalFeedbackProvider.notifier).state = null;
                  _feedbackClearScheduled = false;
                },
              ),
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

class _WorldFocusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  const _WorldFocusPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.base,
          vertical: MimzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: MimzColors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(MimzRadius.pill),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: MimzSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.deepInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: MimzSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  badge!,
                  style: MimzTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorldMiniLegend extends StatelessWidget {
  final int visibleZoneCount;
  final int totalZoneCount;
  final int visibleConflictCount;
  final int totalConflictCount;

  const _WorldMiniLegend({
    required this.visibleZoneCount,
    required this.totalZoneCount,
    required this.visibleConflictCount,
    required this.totalConflictCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: MimzColors.deepInk.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WORLD LEGEND',
            style: MimzTypography.caption.copyWith(
              color: MimzColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          const _LegendRow(
            color: MimzColors.mossCore,
            label: 'District core',
            icon: Icons.hexagon,
          ),
          const SizedBox(height: MimzSpacing.xs),
          const _LegendRow(
            color: MimzColors.dustyGold,
            label: 'Live event zone',
            icon: Icons.wifi_tethering,
          ),
          const SizedBox(height: MimzSpacing.xs),
          const _LegendRow(
            color: MimzColors.persimmonHit,
            label: 'Frontier risk',
            icon: Icons.warning_amber_rounded,
          ),
          if (totalZoneCount > visibleZoneCount ||
              totalConflictCount > visibleConflictCount) ...[
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Showing $visibleZoneCount of $totalZoneCount zones • $visibleConflictCount of $totalConflictCount risks',
              style: MimzTypography.caption.copyWith(
                color: MimzColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.12);
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(MimzRadius.md),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: MimzSpacing.sm),
        Text(
          label,
          style: MimzTypography.caption.copyWith(
            color: MimzColors.deepInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WorldHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final RecommendedActionModel? primaryAction;
  final RecommendedActionModel? secondaryAction;
  final DistrictHealthSummaryModel? districtHealth;
  final int activeConflictCount;
  final EventZoneModel? highlightedZone;
  final StructureProgressModel? structureProgress;

  const _WorldHeroCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
    this.districtHealth,
    this.activeConflictCount = 0,
    this.highlightedZone,
    this.structureProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(MimzRadius.xl),
        border: Border.all(color: MimzColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: MimzColors.deepInk.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: MimzTypography.caption.copyWith(
              color: MimzColors.mossCore,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MimzSpacing.xs),
          Text(title, style: MimzTypography.headlineMedium),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            body,
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          if (highlightedZone != null ||
              activeConflictCount > 0 ||
              districtHealth?.state != 'stable' ||
              structureProgress?.readyToBuild == true) ...[
            const SizedBox(height: MimzSpacing.base),
            Wrap(
              spacing: MimzSpacing.sm,
              runSpacing: MimzSpacing.sm,
              children: [
                if (highlightedZone != null)
                  _HeroPulsePill(
                    icon: highlightedZone!.status == 'live'
                        ? Icons.wifi_tethering
                        : Icons.public,
                    label:
                        '${highlightedZone!.title} • x${highlightedZone!.rewardMultiplier.toStringAsFixed(1)}',
                    color: highlightedZone!.status == 'live'
                        ? MimzColors.dustyGold
                        : MimzColors.mistBlue,
                  ),
                if (districtHealth != null && districtHealth!.reclaimableCells > 0)
                  _HeroPulsePill(
                    icon: Icons.restore,
                    label:
                        'Reclaim ${districtHealth!.reclaimableCells} frontier cell${districtHealth!.reclaimableCells == 1 ? '' : 's'}',
                    color: MimzColors.persimmonHit,
                  )
                else if (districtHealth != null && districtHealth!.state != 'stable')
                  _HeroPulsePill(
                    icon: Icons.thermostat,
                    label: districtHealth!.headline,
                    color: MimzColors.persimmonHit,
                  ),
                if (activeConflictCount > 0)
                  _HeroPulsePill(
                    icon: Icons.warning_amber_rounded,
                    label:
                        '$activeConflictCount frontier conflict${activeConflictCount == 1 ? '' : 's'}',
                    color: MimzColors.persimmonHit,
                  ),
                if (structureProgress?.readyToBuild == true)
                  _HeroPulsePill(
                    icon: Icons.account_balance,
                    label:
                        '${structureProgress?.nextStructureName ?? 'Structure'} ready',
                    color: MimzColors.mossCore,
                  ),
              ],
            ),
          ],
          if (primaryAction != null) ...[
            const SizedBox(height: MimzSpacing.base),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MimzSpacing.sm),
              decoration: BoxDecoration(
                color: MimzColors.surfaceLight,
                borderRadius: BorderRadius.circular(MimzRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${primaryAction!.impactLabel} • ${primaryAction!.estimatedMinutes} min',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.mossCore,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    primaryAction!.rewardPreview,
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push(primaryAction!.route),
                    style: FilledButton.styleFrom(
                      backgroundColor: MimzColors.mossCore,
                      foregroundColor: MimzColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: MimzSpacing.base,
                      ),
                    ),
                    child: Text(primaryAction!.ctaLabel),
                  ),
                ),
                if (secondaryAction != null) ...[
                  const SizedBox(width: MimzSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.push(secondaryAction!.route),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MimzColors.deepInk,
                      side: const BorderSide(color: MimzColors.borderLight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: MimzSpacing.base,
                        vertical: MimzSpacing.base,
                      ),
                    ),
                    child: Text('${secondaryAction!.estimatedMinutes} min'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }
}

class _HeroPulsePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroPulsePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.md,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: MimzSpacing.xs),
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

class _EventZoneMarker extends StatelessWidget {
  final EventZoneModel zone;
  final VoidCallback onTap;

  const _EventZoneMarker({
    required this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = zone.status == 'live';
    final markerColor = isLive ? MimzColors.dustyGold : MimzColors.mistBlue;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: markerColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isLive ? Icons.wifi_tethering : Icons.public,
              color: markerColor,
              size: 28,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.96, end: 1.04, duration: 1200.ms),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: MimzColors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(MimzRadius.md),
              border: Border.all(color: markerColor.withValues(alpha: 0.18)),
            ),
            child: Text(
              zone.title,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.deepInk,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldZoneField {
  final Offset center;
  final Color baseColor;
  final double radius;
  final double emphasis;

  const _WorldZoneField({
    required this.center,
    required this.baseColor,
    required this.radius,
    this.emphasis = 1,
  });
}

class _WorldZoneFieldPainter extends CustomPainter {
  final List<_WorldZoneField> fields;

  const _WorldZoneFieldPainter({
    this.fields = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final field in fields) {
      final outerFill = Paint()
        ..shader = RadialGradient(
          colors: [
            field.baseColor.withValues(alpha: 0.0),
            field.baseColor.withValues(alpha: 0.035 * field.emphasis),
            field.baseColor.withValues(alpha: 0.12 * field.emphasis),
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(
          Rect.fromCircle(center: field.center, radius: field.radius),
        )
        ..style = PaintingStyle.fill;
      final outerStroke = Paint()
        ..color = field.baseColor.withValues(alpha: 0.12 * field.emphasis)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      final innerStroke = Paint()
        ..color = field.baseColor.withValues(alpha: 0.18 * field.emphasis)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(field.center, field.radius, outerFill);
      canvas.drawCircle(field.center, field.radius * 0.62, innerStroke);
      canvas.drawCircle(field.center, field.radius * 0.94, outerStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldZoneFieldPainter oldDelegate) {
    return oldDelegate.fields != fields;
  }
}

class _WorldLinkPainter extends CustomPainter {
  final Offset districtCenter;
  final List<Offset> eventTargets;
  final List<Offset> conflictTargets;

  const _WorldLinkPainter({
    required this.districtCenter,
    this.eventTargets = const [],
    this.conflictTargets = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eventPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          MimzColors.dustyGold.withValues(alpha: 0.0),
          MimzColors.dustyGold.withValues(alpha: 0.28),
        ],
      ).createShader(Rect.fromPoints(districtCenter, Offset(size.width, size.height)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final conflictPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          MimzColors.persimmonHit.withValues(alpha: 0.0),
          MimzColors.persimmonHit.withValues(alpha: 0.22),
        ],
      ).createShader(Rect.fromPoints(districtCenter, Offset(size.width, size.height)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final target in eventTargets) {
      final path = Path()
        ..moveTo(districtCenter.dx, districtCenter.dy)
        ..quadraticBezierTo(
          (districtCenter.dx + target.dx) / 2,
          min(districtCenter.dy, target.dy) - 60,
          target.dx,
          target.dy,
        );
      canvas.drawPath(path, eventPaint);
    }

    for (final target in conflictTargets) {
      final path = Path()
        ..moveTo(districtCenter.dx, districtCenter.dy)
        ..quadraticBezierTo(
          (districtCenter.dx + target.dx) / 2,
          max(districtCenter.dy, target.dy) + 36,
          target.dx,
          target.dy,
        );
      canvas.drawPath(path, conflictPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldLinkPainter oldDelegate) {
    return oldDelegate.districtCenter != districtCenter ||
        oldDelegate.eventTargets != eventTargets ||
        oldDelegate.conflictTargets != conflictTargets;
  }
}

class _ConflictMarker extends StatelessWidget {
  final ConflictStateModel conflict;
  final VoidCallback onTap;

  const _ConflictMarker({
    required this.conflict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTakeover = conflict.type == 'inactivity_takeover';
    final markerColor =
        isTakeover ? MimzColors.persimmonHit : MimzColors.dustyGold;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: markerColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isTakeover ? Icons.restore : Icons.warning_amber_rounded,
              color: markerColor,
              size: 26,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.96, end: 1.05, duration: 1000.ms),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 124),
            padding: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: MimzColors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(MimzRadius.md),
              border: Border.all(color: markerColor.withValues(alpha: 0.18)),
            ),
            child: Text(
              conflict.headline ??
                  (isTakeover ? 'Frontier reclaim' : 'Frontier conflict'),
              style: MimzTypography.caption.copyWith(
                color: MimzColors.deepInk,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldClusterMarker extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WorldClusterMarker({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: MimzColors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              label,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.deepInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle.toUpperCase(),
              style: MimzTypography.caption.copyWith(
                color: MimzColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 240.ms).scaleXY(begin: 0.92, end: 1.0),
    );
  }
}

class _StructureReadyBeacon extends StatelessWidget {
  final String structureName;
  final VoidCallback onTap;

  const _StructureReadyBeacon({
    required this.structureName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: MimzColors.mossCore.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: MimzColors.mossCore.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: MimzColors.mossCore.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance,
              color: MimzColors.mossCore,
              size: 28,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.96, end: 1.05, duration: 1200.ms),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 132),
            padding: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: MimzColors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(MimzRadius.md),
              border: Border.all(
                color: MimzColors.mossCore.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              '$structureName ready',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.deepInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldGrowthCallout extends StatelessWidget {
  final int sectorsGained;
  final int score;

  const _WorldGrowthCallout({
    required this.sectorsGained,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.base,
          vertical: MimzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: MimzColors.deepInk.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(MimzRadius.lg),
          border: Border.all(
            color: MimzColors.acidLime.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: MimzColors.deepInk.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FRONTIER SURGE',
              style: MimzTypography.caption.copyWith(
                color: MimzColors.acidLime,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+$sectorsGained sector${sectorsGained == 1 ? '' : 's'}',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (score > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Score +$score',
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 1000.ms)
          .fadeIn(duration: 180.ms),
    );
  }
}

class _WorldArrivalFeedbackCard extends StatelessWidget {
  final WorldArrivalFeedback feedback;
  final VoidCallback onDismiss;

  const _WorldArrivalFeedbackCard({
    required this.feedback,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final materialParts = <String>[
      if (feedback.materials.stone > 0) '+${feedback.materials.stone} stone',
      if (feedback.materials.glass > 0) '+${feedback.materials.glass} glass',
      if (feedback.materials.wood > 0) '+${feedback.materials.wood} wood',
    ];
    final impactChips = <({IconData icon, String label, Color color})>[
      if (feedback.structureReadyName != null &&
          feedback.structureReadyName!.isNotEmpty)
        (
          icon: Icons.account_balance,
          label: '${feedback.structureReadyName} ready',
          color: MimzColors.acidLime,
        ),
      if (feedback.reclaimableCells > 0)
        (
          icon: Icons.restore,
          label:
              '${feedback.reclaimableCells} reclaimable cell${feedback.reclaimableCells == 1 ? '' : 's'}',
          color: MimzColors.dustyGold,
        ),
      if (feedback.vulnerableCells > 0)
        (
          icon: Icons.warning_amber_rounded,
          label:
              '${feedback.vulnerableCells} vulnerable cell${feedback.vulnerableCells == 1 ? '' : 's'}',
          color: MimzColors.persimmonHit,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.deepInk.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(MimzRadius.xl),
        border: Border.all(
          color: MimzColors.acidLime.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: MimzColors.deepInk.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MimzColors.acidLime.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: MimzColors.acidLime,
              size: 22,
            ),
          ),
          const SizedBox(width: MimzSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISTRICT UPDATED',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.acidLime,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: MimzSpacing.xs),
                Text(
                  feedback.sectorsGained > 0
                      ? '${feedback.districtName} expanded by +${feedback.sectorsGained} sector${feedback.sectorsGained == 1 ? '' : 's'}.'
                      : '${feedback.districtName} absorbed your latest progress.',
                  style: MimzTypography.bodyMedium.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MimzSpacing.xs),
                Text(
                  [
                    'Score ${feedback.score}',
                    'now ${feedback.newTotalSectors} sectors',
                    if (materialParts.isNotEmpty) materialParts.join(' • '),
                  ].join(' • '),
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.white.withValues(alpha: 0.72),
                  ),
                ),
                if ((feedback.healthHeadline?.isNotEmpty ?? false) ||
                    (feedback.healthSummary?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    feedback.healthHeadline ?? 'District status updated',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.acidLime.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (feedback.healthSummary?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      feedback.healthSummary!,
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ],
                if (impactChips.isNotEmpty) ...[
                  const SizedBox(height: MimzSpacing.sm),
                  Wrap(
                    spacing: MimzSpacing.xs,
                    runSpacing: MimzSpacing.xs,
                    children: impactChips
                        .map(
                          (chip) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MimzSpacing.sm,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: chip.color.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(MimzRadius.pill),
                              border: Border.all(
                                color: chip.color.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(chip.icon, size: 12, color: chip.color),
                                const SizedBox(width: 4),
                                Text(
                                  chip.label,
                                  style: MimzTypography.caption.copyWith(
                                    color: MimzColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (feedback.nextActionTitle?.isNotEmpty ?? false) ...[
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    'Next up: ${feedback.nextActionTitle}',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: MimzColors.white.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
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
    const w = hexRadius * 2;
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
        const miniR = s * 0.5;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * pi / 180;
          final x = center.dx + miniR * cos(angle);
          final y = center.dy + miniR * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
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
