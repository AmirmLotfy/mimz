import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../design_system/components/permission_card.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/providers.dart';

/// Screen 4 — Permission overview with trust framework
class PermissionOverviewScreen extends ConsumerStatefulWidget {
  const PermissionOverviewScreen({super.key});

  @override
  ConsumerState<PermissionOverviewScreen> createState() => _PermissionOverviewScreenState();
}

class _PermissionOverviewScreenState extends ConsumerState<PermissionOverviewScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndAdvance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsProvider.notifier).refresh();
    }
  }

  void _checkAndAdvance() {
    // Small delay to allow providers to settle
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final permissions = ref.read(permissionsProvider);
      if (permissions.allGranted) {
        context.go('/onboarding/live');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsProvider);
    final locationService = ref.read(locationServiceProvider);

    // Auto-advance if all granted while on the screen
    ref.listen(permissionsProvider, (prev, next) {
      if (next.allGranted) {
        context.go('/onboarding/live');
      }
    });

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/onboarding/summary'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Permissions'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trust badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.base,
                  vertical: MimzSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.mossCore.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user,
                        color: MimzColors.mossCore, size: 16),
                    const SizedBox(width: MimzSpacing.sm),
                    Text(
                      'TRUST FRAMEWORK',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.mossCore,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.xl),
              Text(
                'Your privacy\npowers the\nexperience',
                style: MimzTypography.displayMedium,
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05),
              const SizedBox(height: MimzSpacing.md),
              Text(
                'We need a few permissions to deliver the full Mimz experience. Here\'s exactly why.',
                style: MimzTypography.bodyMedium.copyWith(
                  color: MimzColors.textSecondary,
                ),
              ),
              const SizedBox(height: MimzSpacing.xxl),
              // Permission cards
              PermissionCard(
                icon: Icons.location_on,
                title: 'Location',
                description: 'Spawn your district on the real map and discover nearby events.',
                isGranted: permissions.location,
                onEnable: () async {
                  final granted = await locationService.requestPermission();
                  if (granted) {
                    ref.read(permissionsProvider.notifier).grantLocation();
                  } else {
                    if (context.mounted) context.go('/permissions/location');
                  }
                },
                onDismiss: () => context.go('/permissions/location'),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.md),
              PermissionCard(
                icon: Icons.mic,
                title: 'Microphone',
                description: 'Talk to Mimz AI and answer quiz questions by voice.',
                isGranted: permissions.microphone,
                onEnable: () => context.go('/permissions/microphone'),
                onDismiss: () => context.go('/permissions/microphone'),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.md),
              PermissionCard(
                icon: Icons.camera_alt,
                title: 'Camera',
                description: 'Unlock Vision Quest and identify real-world objects.',
                isGranted: permissions.camera,
                onEnable: () => context.go('/permissions/camera'),
                onDismiss: () => context.go('/permissions/camera'),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: permissions.allGranted
                    ? 'ALL SET — CONTINUE  →'
                    : 'CONTINUE  →',
                onPressed: () => context.go('/onboarding/live'),
              ),
              const SizedBox(height: MimzSpacing.md),
              Center(
                child: Text(
                  '${permissions.grantedCount}/3 permissions granted',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.mossCore,
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
