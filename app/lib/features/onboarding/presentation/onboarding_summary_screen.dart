import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../design_system/components/mimz_chip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers.dart';
import '../providers/onboarding_provider.dart';

/// Screen — Onboarding profile summary before district setup.
/// Shows condensed view of all collected data and saves to backend.
class OnboardingSummaryScreen extends ConsumerStatefulWidget {
  const OnboardingSummaryScreen({super.key});

  @override
  ConsumerState<OnboardingSummaryScreen> createState() =>
      _OnboardingSummaryScreenState();
}

class _OnboardingSummaryScreenState
    extends ConsumerState<OnboardingSummaryScreen> {
  bool _isSaving = false;

  Future<void> _complete() async {
    setState(() => _isSaving = true);

    final onboardingData = ref.read(onboardingDataProvider);
    final interests = ref.read(interestsProvider);
    final user = ref.read(currentUserProvider).valueOrNull;

    // Build payload
    final payload = <String, dynamic>{
      if (onboardingData.preferredName != null)
        'preferredName': onboardingData.preferredName,
      if (onboardingData.ageBand != null) 'ageBand': onboardingData.ageBand,
      if (onboardingData.studyWorkStatus != null)
        'studyWorkStatus': onboardingData.studyWorkStatus,
      if (onboardingData.majorOrProfession != null)
        'majorOrProfession': onboardingData.majorOrProfession,
      'difficultyPreference': onboardingData.difficultyPreference,
      'squadPreference': onboardingData.squadPreference,
      if (interests.isNotEmpty) 'interests': interests,
      // Also update displayName if preferredName captured
      if (onboardingData.preferredName != null &&
          onboardingData.preferredName!.isNotEmpty)
        'displayName': onboardingData.preferredName,
    };

    // Update local user state immediately for snappy UI
    if (user != null) {
      ref.read(currentUserProvider.notifier).updateUser(user.copyWith(
            preferredName: onboardingData.preferredName,
            ageBand: onboardingData.ageBand,
            studyWorkStatus: onboardingData.studyWorkStatus,
            majorOrProfession: onboardingData.majorOrProfession,
            difficultyPreference: onboardingData.difficultyPreference,
            squadPreference: onboardingData.squadPreference,
            interests: interests,
          ));
    }

    // Persist to backend
    try {
      await ref.read(apiClientProvider).dio.patch(
            '/profile',
            data: payload,
            options: Options(
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
    } catch (_) {
      // Non-fatal — local state already updated
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final onboardingData = ref.watch(onboardingDataProvider);
    final interests = ref.watch(interestsProvider);

    final displayName =
        onboardingData.preferredName ?? user?.displayName ?? 'Explorer';

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'PROFILE SUMMARY',
          style: MimzTypography.caption.copyWith(
            fontSize: 13,
            color: MimzColors.deepInk,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: MimzSpacing.xl),
            // Avatar + Name
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor:
                            MimzColors.mossCore.withValues(alpha: 0.2),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'M',
                          style: MimzTypography.displayMedium.copyWith(
                            color: MimzColors.mossCore,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: MimzColors.mossCore,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: MimzColors.cloudBase, width: 3),
                          ),
                          child: const Icon(Icons.edit,
                              color: MimzColors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MimzSpacing.base),
                  Text(displayName, style: MimzTypography.headlineLarge),
                  Text(
                    user?.email ?? '',
                    style: MimzTypography.bodyMedium
                        .copyWith(color: MimzColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),

            // About section
            _sectionHeader('About You'),
            const SizedBox(height: MimzSpacing.md),
            _InfoRow(
                icon: Icons.cake_outlined,
                label: 'AGE',
                value: onboardingData.ageBand ?? 'Not set'),
            const SizedBox(height: MimzSpacing.sm),
            _InfoRow(
                icon: Icons.work_outline,
                label: 'STATUS',
                value: onboardingData.studyWorkStatus ?? 'Not set'),
            if (onboardingData.majorOrProfession != null) ...[
              const SizedBox(height: MimzSpacing.sm),
              _InfoRow(
                icon: Icons.school_outlined,
                label: 'FIELD',
                value: onboardingData.majorOrProfession!,
              ),
            ],
            const SizedBox(height: MimzSpacing.xxl),

            // Interests
            _sectionHeader('Your Interests'),
            const SizedBox(height: MimzSpacing.md),
            if (interests.isNotEmpty)
              Wrap(
                spacing: MimzSpacing.sm,
                runSpacing: MimzSpacing.sm,
                children: interests
                    .map((i) => MimzChip(
                          label: i,
                          isSelected: true,
                          onDelete: null,
                        ))
                    .toList(),
              )
            else
              Text(
                'No interests selected.',
                style: MimzTypography.bodySmall
                    .copyWith(color: MimzColors.textSecondary),
              ),
            const SizedBox(height: MimzSpacing.xxl),

            // Play Style
            _sectionHeader('Play Style'),
            const SizedBox(height: MimzSpacing.md),
            _InfoRow(
              icon: Icons.speed,
              label: 'DIFFICULTY',
              value: _difficultyLabel(onboardingData.difficultyPreference),
            ),
            const SizedBox(height: MimzSpacing.sm),
            _InfoRow(
              icon: Icons.group,
              label: 'MODE',
              value: onboardingData.squadPreference == 'social'
                  ? 'Squad Player'
                  : 'Solo Explorer',
            ),
            const SizedBox(height: MimzSpacing.xxl),

            // Account
            _sectionHeader('Account'),
            const SizedBox(height: MimzSpacing.md),
            _InfoRow(
              icon: Icons.mail_outline,
              label: 'EMAIL',
              value: (user?.email != null && user!.email!.isNotEmpty)
                  ? user.email!
                  : 'Not provided',
            ),
            const SizedBox(height: MimzSpacing.xxl),

            MimzButton(
              label: _isSaving ? 'Saving...' : 'COMPLETE SETUP  →',
              onPressed: _isSaving ? null : _complete,
            ),
            const SizedBox(height: MimzSpacing.md),
            Center(
              child: Text(
                'By clicking continue, you agree to our Terms of Service',
                style: MimzTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: MimzTypography.headlineMedium,
      );

  String _difficultyLabel(String pref) {
    switch (pref) {
      case 'easy':
        return 'Casual';
      case 'hard':
        return 'Challenger';
      default:
        return 'Dynamic (adapts to you)';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: MimzColors.mistBlue, size: 24),
          const SizedBox(width: MimzSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: MimzTypography.caption
                      .copyWith(color: MimzColors.mistBlue)),
              Text(value, style: MimzTypography.bodyMedium),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
        ],
      ),
    );
  }
}
