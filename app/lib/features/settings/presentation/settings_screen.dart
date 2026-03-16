import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';

/// Settings screen — account, preferences, privacy, support.
/// All toggles are persisted via SettingsService. No fake state.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notifications;
  bool? _haptic;
  bool? _sound;
  bool? _locationSharing;
  bool _loading = true;

  String _normalizeDifficulty(String value) {
    switch (value) {
      case 'casual':
        return 'easy';
      case 'hardcore':
        return 'hard';
      default:
        return const ['easy', 'dynamic', 'hard'].contains(value)
            ? value
            : 'dynamic';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final svc = ref.read(settingsServiceProvider);
      final n = await svc.getNotifications();
      final h = await svc.getHaptic();
      final s = await svc.getSound();
      final l = await svc.getLocationSharing();
      if (mounted) {
        setState(() {
          _notifications = n;
          _haptic = h;
          _sound = s;
          _locationSharing = l;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  Future<void> _toggle(
    String _name,
    bool value,
    void Function(bool) setter,
    Future<void> Function(bool) persist,
  ) async {
    ref.read(hapticsServiceProvider).selection();
    setState(() => setter(value));
    await persist(value);
  }

  Future<void> _showEmailActions(String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email is linked to this account yet.')),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy email'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset password'),
              onTap: () => Navigator.pop(context, 'reset'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: email));
      ref.read(hapticsServiceProvider).success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email copied to clipboard.')),
        );
      }
    } else if (action == 'reset') {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset sent to $email')),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    ref.read(hapticsServiceProvider).heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all notifications, haptics, and sound settings to their defaults. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset', style: TextStyle(color: MimzColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(settingsServiceProvider).resetAll();
      await _loadPreferences();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings restored to defaults')),
        );
      }
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Mimz',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Mimz. All rights reserved.',
      children: [
        const SizedBox(height: 8),
        const Text('Learn live. Build your district.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (_loading) {
      return const Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: Center(child: CircularProgressIndicator(color: MimzColors.mossCore)),
      );
    }

    final difficulty = _normalizeDifficulty(user?.difficultyPreference ?? 'dynamic');
    final squad = user?.squadPreference ?? 'social';

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MimzSpacing.base,
            MimzSpacing.base,
            MimzSpacing.base,
            MimzSpacing.xxl,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCOUNT
            _sectionLabel('ACCOUNT'),
            const SizedBox(height: MimzSpacing.md),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: user?.displayName ?? 'Explorer',
              onTap: () => context.push('/settings/profile-edit'),
            ),
            _SettingsTile(
              icon: Icons.interests,
              title: 'My Interests',
              subtitle: user?.interests.isEmpty ?? true
                  ? 'Set your interests'
                  : '${user!.interests.length} topics selected',
              onTap: () => context.push('/settings/profile-edit'),
            ),
            _SettingsTile(
              icon: Icons.mail_outline,
              title: 'Email',
              subtitle: user?.email ?? 'Not set',
              onTap: () => _showEmailActions(user?.email),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Security',
              subtitle: 'Password, biometrics, linked accounts',
              onTap: () => context.push('/settings/security'),
            ),

            const SizedBox(height: MimzSpacing.xl),
            _sectionLabel('GAMEPLAY'),
            const SizedBox(height: MimzSpacing.md),

            // Difficulty picker
            Container(
              padding: const EdgeInsets.all(MimzSpacing.base),
              margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.md),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: MimzColors.mossCore.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MimzRadius.sm),
                      ),
                      child: const Icon(Icons.speed, color: MimzColors.mossCore, size: 20),
                    ),
                    const SizedBox(width: MimzSpacing.md),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Challenge Level', style: MimzTypography.headlineSmall),
                        Text('How hard should questions be?', style: MimzTypography.bodySmall),
                      ],
                    )),
                  ]),
                  const SizedBox(height: MimzSpacing.md),
                  Row(children: [
                    for (final opt in [('easy', 'Casual'), ('dynamic', 'Dynamic'), ('hard', 'Challenger')])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _setDifficulty(opt.$1, user),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: MimzSpacing.sm),
                            decoration: BoxDecoration(
                              color: difficulty == opt.$1
                                  ? MimzColors.mossCore
                                  : MimzColors.cloudBase,
                              borderRadius: BorderRadius.circular(MimzRadius.sm),
                              border: Border.all(
                                color: difficulty == opt.$1
                                    ? MimzColors.mossCore
                                    : MimzColors.borderLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                opt.$2,
                                style: MimzTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  color: difficulty == opt.$1
                                      ? MimzColors.white
                                      : MimzColors.deepInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),

            // Squad mode toggle
            Container(
              padding: const EdgeInsets.all(MimzSpacing.base),
              margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.md),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: MimzColors.mossCore.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(MimzRadius.sm),
                    ),
                    child: const Icon(Icons.group, color: MimzColors.mossCore, size: 20),
                  ),
                  const SizedBox(width: MimzSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Squad Mode', style: MimzTypography.headlineSmall),
                      Text(
                        squad == 'social' ? 'Playing with a squad' : 'Playing solo',
                        style: MimzTypography.bodySmall,
                      ),
                    ],
                  )),
                  Switch.adaptive(
                    value: squad == 'social',
                    onChanged: (v) => _setSquad(v ? 'social' : 'solo', user),
                    activeTrackColor: MimzColors.mossCore,
                  ),
                ],
              ),
            ),

            const SizedBox(height: MimzSpacing.xl),
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: MimzSpacing.md),
            _SettingsToggle(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Live events, squad updates',
              value: _notifications!,
              onChanged: (v) => _toggle(
                'notifications', v, (x) => _notifications = x,
                ref.read(settingsServiceProvider).setNotifications,
              ),
            ),
            _SettingsToggle(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              subtitle: 'Vibrations on actions',
              value: _haptic!,
              onChanged: (v) => _toggle(
                'haptic', v, (x) => _haptic = x,
                ref.read(settingsServiceProvider).setHaptic,
              ),
            ),
            _SettingsToggle(
              icon: Icons.volume_up_outlined,
              title: 'Sound Effects',
              subtitle: 'In-app audio cues',
              value: _sound!,
              onChanged: (v) => _toggle(
                'sound', v, (x) => _sound = x,
                ref.read(settingsServiceProvider).setSound,
              ),
            ),

            const SizedBox(height: MimzSpacing.xl),
            _sectionLabel('PRIVACY'),
            const SizedBox(height: MimzSpacing.md),
            _SettingsToggle(
              icon: Icons.location_on_outlined,
              title: 'Location Sharing',
              subtitle: 'Share district location with squad',
              value: _locationSharing!,
              onChanged: (v) => _toggle(
                'location', v, (x) => _locationSharing = x,
                ref.read(settingsServiceProvider).setLocationSharing,
              ),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacy Policy',
              subtitle: 'How we protect your data',
              onTap: () => context.push('/settings/privacy'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Usage agreement',
              onTap: () => context.push('/settings/terms'),
            ),

            const SizedBox(height: MimzSpacing.xl),
            _sectionLabel('SUPPORT'),
            const SizedBox(height: MimzSpacing.md),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Common questions answered',
              onTap: () => context.push('/settings/help'),
            ),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve Mimz',
              onTap: () => context.push('/settings/feedback'),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Mimz',
              subtitle: 'Version 1.0.0',
              onTap: _showAbout,
            ),

            const SizedBox(height: MimzSpacing.xxl),
            GestureDetector(
              onTap: _resetSettings,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
                decoration: BoxDecoration(
                  color: MimzColors.cloudBase,
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  border: Border.all(color: MimzColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    'Reset Settings to Default',
                    style: MimzTypography.buttonText.copyWith(color: MimzColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.md),
            GestureDetector(
              onTap: () async {
                ref.read(hapticsServiceProvider).heavyImpact();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Sign Out', style: TextStyle(color: MimzColors.error)),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && mounted) {
                  final authService = ref.read(authServiceProvider);
                  await ref.read(isOnboardedProvider.notifier).resetOnboarding();
                  await authService.signOut();
                  if (mounted) context.go('/welcome');
                }
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
                    style: MimzTypography.buttonText.copyWith(color: MimzColors.error),
                  ),
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

  Widget _sectionLabel(String label) => Text(
    label,
    style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700),
  );

  Future<void> _setDifficulty(String level, dynamic user) async {
    ref.read(hapticsServiceProvider).selection();
    if (user == null) return;
    final previous = user.difficultyPreference;
    ref.read(currentUserProvider.notifier).updateUser(
      user.copyWith(difficultyPreference: level),
    );
    try {
      await ref.read(apiClientProvider).patch('/profile', {'difficultyPreference': level});
    } catch (e) {
      ref.read(currentUserProvider.notifier).updateUser(
        user.copyWith(difficultyPreference: previous),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update challenge level: $e')),
        );
      }
    }
  }

  Future<void> _setSquad(String mode, dynamic user) async {
    ref.read(hapticsServiceProvider).selection();
    if (user == null) return;
    final previous = user.squadPreference;
    ref.read(currentUserProvider.notifier).updateUser(
      user.copyWith(squadPreference: mode),
    );
    try {
      await ref.read(apiClientProvider).patch('/profile', {'squadPreference': mode});
    } catch (e) {
      ref.read(currentUserProvider.notifier).updateUser(
        user.copyWith(squadPreference: previous),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update squad mode: $e')),
        );
      }
    }
  }
}


class _SettingsTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () { ref.read(hapticsServiceProvider).selection(); onTap(); },
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: Icon(icon, color: MimzColors.mossCore, size: 20),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MimzTypography.headlineSmall),
                Text(subtitle, style: MimzTypography.bodySmall),
              ],
            )),
            const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: MimzColors.mossCore.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.sm),
            ),
            child: Icon(icon, color: MimzColors.mossCore, size: 20),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MimzTypography.headlineSmall),
              Text(subtitle, style: MimzTypography.bodySmall),
            ],
          )),
          Switch.adaptive(
            value: value,
            onChanged: (v) { ref.read(hapticsServiceProvider).selection(); onChanged(v); },
            activeTrackColor: MimzColors.mossCore,
          ),
        ],
      ),
    );
  }
}
