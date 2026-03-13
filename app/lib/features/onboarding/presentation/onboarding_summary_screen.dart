import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../design_system/components/mimz_chip.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Screen 9 — Onboarding summary / profile summary
class OnboardingSummaryScreen extends ConsumerWidget {
  const OnboardingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
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
          children: [
            const SizedBox(height: MimzSpacing.xl),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: MimzColors.mossCore.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    size: 56,
                    color: MimzColors.mossCore,
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
                      border: Border.all(color: MimzColors.cloudBase, width: 3),
                    ),
                    child: const Icon(Icons.edit, color: MimzColors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.base),
            Text(user?.displayName ?? 'Explorer', style: MimzTypography.headlineLarge),
            Text(
              user?.email ?? 'mimz_explorer',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
            ),
            Text(
              'Just joined',
              style: MimzTypography.bodySmall,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Interests section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Interests', style: MimzTypography.headlineMedium),
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: MimzColors.mossCore, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Add New',
                      style: MimzTypography.labelLarge.copyWith(
                        color: MimzColors.mossCore,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.md),
            const Wrap(
              spacing: MimzSpacing.sm,
              runSpacing: MimzSpacing.sm,
              children: [
                MimzChip(
                  label: 'Technology',
                  icon: Icons.computer,
                  isSelected: true,
                  onDelete: null,
                ),
                MimzChip(
                  label: 'Science',
                  icon: Icons.science,
                  isSelected: true,
                ),
                MimzChip(
                  label: 'History',
                  icon: Icons.history_edu,
                  isSelected: true,
                ),
                MimzChip(
                  label: 'Architecture',
                  icon: Icons.apartment,
                  isSelected: true,
                ),
                MimzChip(
                  label: 'Music',
                  icon: Icons.music_note,
                  isSelected: true,
                ),
                MimzChip(
                  label: 'Design',
                  icon: Icons.palette,
                  isSelected: true,
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Account details
            Text('Account Details',
                style: MimzTypography.headlineMedium),
            const SizedBox(height: MimzSpacing.md),
            _DetailRow(
              icon: Icons.mail_outline,
              label: 'EMAIL',
              value: user?.email ?? 'user@mimz.app',
            ),
            const SizedBox(height: MimzSpacing.md),
            const _DetailRow(
              icon: Icons.lock_outline,
              label: 'SECURITY',
              value: 'Set up later',
            ),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: 'COMPLETE SETUP  →',
              onPressed: () => context.go('/district/name'),
            ),
            const SizedBox(height: MimzSpacing.md),
            Text(
              'By clicking continue, you agree to our Terms of Service',
              style: MimzTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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
              Text(label, style: MimzTypography.caption.copyWith(
                color: MimzColors.mistBlue,
              )),
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
