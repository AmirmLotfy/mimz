import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/providers.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen 5 — Location permission dedicated screen
class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndPop();
  }

  void _checkAndPop() async {
    await ref.read(permissionsProvider.notifier).refresh();
    if (mounted && ref.read(permissionsProvider).location) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        ref.read(currentUserProvider.notifier).updateUser(
              user.copyWith(onboardingStage: 'permissions_microphone'),
            );
      }
      try {
        await ref.read(apiClientProvider).updateProfile({
          'onboardingStage': 'permissions_microphone',
        });
      } catch (_) {}
      if (!context.mounted) return;
      context.go('/permissions/microphone');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes and pop if granted
    ref.listen(permissionsProvider, (prev, next) {
      if (next.location) {
        Future<void>(() async {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user != null) {
            ref.read(currentUserProvider.notifier).updateUser(
                  user.copyWith(onboardingStage: 'permissions_microphone'),
                );
          }
          try {
            await ref.read(apiClientProvider).updateProfile({
              'onboardingStage': 'permissions_microphone',
            });
          } catch (_) {}
          if (!context.mounted) return;
          context.go('/permissions/microphone');
        });
      }
    });

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Location Access'),
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Map preview
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MimzColors.mistBlue.withValues(alpha: 0.3),
                  MimzColors.mossCore.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: MimzColors.white,
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: MimzColors.deepInk.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: MimzColors.mossCore,
                  size: 48,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                children: [
                  Text(
                    'Discover Your District',
                    style: MimzTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.base),
                  Text(
                    'To begin your journey in Mimz, we need your coordinates. This allows us to spawn your unique local district and connect you with nearby players.',
                    style: MimzTypography.bodyMedium.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.xxl),
                  // Feature chips
                  const Row(
                    children: [
                      Expanded(
                        child: _FeatureChip(
                          icon: Icons.map_outlined,
                          label: 'SPAWN',
                          sublabel: 'Local Realm',
                        ),
                      ),
                      SizedBox(width: MimzSpacing.base),
                      Expanded(
                        child: _FeatureChip(
                          icon: Icons.people_outline,
                          label: 'CONNECT',
                          sublabel: 'Nearby Players',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  MimzButton(
                    label: 'Allow Location Access',
                    icon: Icons.navigation,
                    onPressed: () async {
                      ref.read(hapticsServiceProvider).mediumImpact();
                      final status = await Permission.location.request();
                      if (status.isPermanentlyDenied) {
                        ref.read(hapticsServiceProvider).error();
                        await openAppSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location is permanently denied. Enable it in Settings to continue.',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      if (status.isGranted || status.isLimited) {
                        ref.read(hapticsServiceProvider).success();
                        await ref.read(permissionsProvider.notifier).grantLocation();
                        final user = ref.read(currentUserProvider).valueOrNull;
                        if (user != null) {
                          ref.read(currentUserProvider.notifier).updateUser(
                                user.copyWith(
                                  onboardingStage: 'permissions_microphone',
                                ),
                              );
                        }
                        try {
                          await ref.read(apiClientProvider).updateProfile({
                            'onboardingStage': 'permissions_microphone',
                          });
                        } catch (_) {}
                      } else if (mounted) {
                        ref.read(hapticsServiceProvider).error();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location permission denied. You can grant it later in app settings.',
                            ),
                          ),
                        );
                      }
                      if (!context.mounted) return;
                      context.go('/permissions/microphone');
                    },
                  ),
                  const SizedBox(height: MimzSpacing.base),
                  MimzButton(
                    label: 'Maybe Later',
                    variant: MimzButtonVariant.ghost,
                    onPressed: () async {
                      final user = ref.read(currentUserProvider).valueOrNull;
                      if (user != null) {
                        ref.read(currentUserProvider.notifier).updateUser(
                              user.copyWith(
                                onboardingStage: 'permissions_microphone',
                              ),
                            );
                      }
                      try {
                        await ref.read(apiClientProvider).updateProfile({
                          'onboardingStage': 'permissions_microphone',
                        });
                      } catch (_) {}
                      if (!context.mounted) return;
                      context.go('/permissions/microphone');
                    },
                  ),
                  const SizedBox(height: MimzSpacing.base),
                  Text(
                    'YOUR PRIVACY IS PROTECTED BY MIMZ PROTOCOLS',
                    style: MimzTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MimzColors.mossCore.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MimzColors.mossCore, size: 24),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text(label, style: MimzTypography.caption),
          Text(sublabel, style: MimzTypography.labelLarge.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
