import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../design_system/components/waveform_visualizer.dart';
import '../../../services/haptics_service.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/providers.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen 6 — Microphone permission
class MicrophonePermissionScreen extends ConsumerStatefulWidget {
  const MicrophonePermissionScreen({super.key});

  @override
  ConsumerState<MicrophonePermissionScreen> createState() => _MicrophonePermissionScreenState();
}

class _MicrophonePermissionScreenState extends ConsumerState<MicrophonePermissionScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndPop();
  }

  void _checkAndPop() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      if (ref.read(permissionsProvider).microphone) {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null) {
          ref.read(currentUserProvider.notifier).updateUser(
            user.copyWith(onboardingStage: 'emblem'),
          );
        }
        try {
          await ref.read(apiClientProvider).updateProfile({
            'onboardingStage': 'emblem',
          });
        } catch (_) {}
        if (!context.mounted) return;
        context.go('/district/emblem');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes and pop if granted
    ref.listen(permissionsProvider, (prev, next) {
      if (next.microphone) {
        Future<void>(() async {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user != null) {
            ref.read(currentUserProvider.notifier).updateUser(
              user.copyWith(onboardingStage: 'emblem'),
            );
          }
          try {
            await ref.read(apiClientProvider).updateProfile({
              'onboardingStage': 'emblem',
            });
          } catch (_) {}
          if (!context.mounted) return;
          context.go('/district/emblem');
        });
      }
    });

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          'LIVE EXPERIENCE',
          style: MimzTypography.caption.copyWith(
            color: MimzColors.persimmonHit,
            fontSize: 13,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Column(
          children: [
            const Spacer(),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Experience ',
                    style: MimzTypography.displayLarge,
                  ),
                  TextSpan(
                    text: 'Mimz',
                    style: MimzTypography.displayLarge.copyWith(
                      color: MimzColors.persimmonHit,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(
                    text: '\nLive',
                    style: MimzTypography.displayLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Text(
              'Speak naturally. Our live AI uses advanced voice recognition to guide your play in real-time.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Waveform preview card
            Container(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              decoration: BoxDecoration(
                color: MimzColors.surfaceLight,
                borderRadius: BorderRadius.circular(MimzRadius.lg),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Column(
                children: [
                  const WaveformVisualizer(
                    isActive: true,
                    color: MimzColors.persimmonHit,
                    height: 60,
                  ),
                  const SizedBox(height: MimzSpacing.base),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MimzColors.persimmonHit.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: MimzColors.persimmonHit,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Privacy info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MimzColors.persimmonHit.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MimzRadius.sm),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: MimzColors.persimmonHit, size: 20),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy First', style: MimzTypography.headlineSmall),
                      Text(
                        'Audio is processed in real-time and never stored.',
                        style: MimzTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.base),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MimzColors.persimmonHit.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MimzRadius.sm),
                  ),
                  child: const Icon(Icons.bolt,
                      color: MimzColors.persimmonHit, size: 20),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Real-time Feedback', style: MimzTypography.headlineSmall),
                      Text(
                        'Instant voice interaction for live challenges.',
                        style: MimzTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            MimzButton(
              label: 'Enable Microphone',
              variant: MimzButtonVariant.accent,
              onPressed: () async {
                ref.read(hapticsServiceProvider).mediumImpact();
                final status = await Permission.microphone.request();
                if (status.isPermanentlyDenied) {
                  ref.read(hapticsServiceProvider).error();
                  await openAppSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Microphone is permanently denied. Enable it in Settings.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                if (status.isGranted || status.isLimited) {
                  ref.read(hapticsServiceProvider).success();
                  await ref.read(permissionsProvider.notifier).grantMicrophone();
                  final user = ref.read(currentUserProvider).valueOrNull;
                  if (user != null) {
                    ref.read(currentUserProvider.notifier).updateUser(
                      user.copyWith(onboardingStage: 'emblem'),
                    );
                  }
                  try {
                    await ref.read(apiClientProvider).updateProfile({
                      'onboardingStage': 'emblem',
                    });
                  } catch (_) {}
                } else if (mounted) {
                  ref.read(hapticsServiceProvider).error();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Microphone permission denied. Live mode needs mic access.',
                      ),
                    ),
                  );
                }
                if (!context.mounted) return;
                context.go('/district/emblem');
              },
            ),
            const SizedBox(height: MimzSpacing.md),
            MimzButton(
              label: 'Maybe Later',
              variant: MimzButtonVariant.ghost,
              onPressed: () async {
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user != null) {
                  ref.read(currentUserProvider.notifier).updateUser(
                    user.copyWith(onboardingStage: 'emblem'),
                  );
                }
                try {
                  await ref.read(apiClientProvider).updateProfile({
                    'onboardingStage': 'emblem',
                  });
                } catch (_) {}
                if (!context.mounted) return;
                context.go('/district/emblem');
              },
            ),
            const SizedBox(height: MimzSpacing.base),
          ],
          ),
        ),
      ),
    );
  }
}
