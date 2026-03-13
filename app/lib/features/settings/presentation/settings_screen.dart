import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers.dart';

/// Settings screen — account, privacy, notifications, support
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharing = true;
  bool _hapticFeedback = true;
  bool _soundEffects = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MimzSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            Text('ACCOUNT', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: user?.displayName ?? 'Explorer',
              onTap: () => context.go('/profile'),
            ),
            _SettingsTile(
              icon: Icons.mail_outline,
              title: 'Email',
              subtitle: user?.email ?? 'user@mimz.app',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Security',
              subtitle: 'Password, biometrics',
              onTap: () {},
            ),

            const SizedBox(height: MimzSpacing.xl),
            Text('PREFERENCES', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            _SettingsToggle(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Live events, squad updates',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            _SettingsToggle(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              subtitle: 'Vibrations on actions',
              value: _hapticFeedback,
              onChanged: (v) => setState(() => _hapticFeedback = v),
            ),
            _SettingsToggle(
              icon: Icons.volume_up_outlined,
              title: 'Sound Effects',
              subtitle: 'In-app audio cues',
              value: _soundEffects,
              onChanged: (v) => setState(() => _soundEffects = v),
            ),

            const SizedBox(height: MimzSpacing.xl),
            Text('PRIVACY', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            _SettingsToggle(
              icon: Icons.location_on_outlined,
              title: 'Location Sharing',
              subtitle: 'Share district location with squad',
              value: _locationSharing,
              onChanged: (v) => setState(() => _locationSharing = v),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacy Policy',
              subtitle: 'How we protect your data',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Usage agreement',
              onTap: () {},
            ),

            const SizedBox(height: MimzSpacing.xl),
            Text('SUPPORT', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Common questions answered',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve Mimz',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Mimz',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),

            const SizedBox(height: MimzSpacing.xxl),
            // Sign out
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final authService = ref.read(authServiceProvider);
                await ref.read(isOnboardedProvider.notifier).resetOnboarding();
                await authService.signOut();
                if (context.mounted) context.go('/welcome');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
                decoration: BoxDecoration(
                  color: MimzColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  border: Border.all(color: MimzColors.error.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    'Sign Out',
                    style: MimzTypography.buttonText.copyWith(
                      color: MimzColors.error,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: MimzColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: Icon(icon, color: MimzColors.mossCore, size: 20),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MimzTypography.headlineSmall),
                  Text(subtitle, style: MimzTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MimzColors.mossCore.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.sm),
            ),
            child: Icon(icon, color: MimzColors.mossCore, size: 20),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MimzTypography.headlineSmall),
                Text(subtitle, style: MimzTypography.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeTrackColor: MimzColors.mossCore,
          ),
        ],
      ),
    );
  }
}
