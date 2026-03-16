import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';

/// Security screen — biometrics, password reset, linked providers.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _biometricsAvailable = false;
  bool _biometricsEnrolled = false;
  bool _biometricsEnabled = false;
  bool _loadingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final svc = ref.read(biometricServiceProvider);
    final available = await svc.isAvailable();
    final enrolled = await svc.isEnrolled();
    final enabled = await svc.isEnabled();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsEnrolled = enrolled;
        _biometricsEnabled = enabled;
        _loadingBiometrics = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    ref.read(hapticsServiceProvider).selection();
    final svc = ref.read(biometricServiceProvider);

    if (value) {
      // Verify they can actually auth before enabling
      final authed = await svc.authenticate(
        reason: 'Confirm your identity to enable biometric lock.',
      );
      if (!authed) return;
      await svc.enable();
      ref.read(hapticsServiceProvider).success();
    } else {
      await svc.disable();
    }

    if (mounted) setState(() => _biometricsEnabled = value);
  }

  Future<void> _showPasswordReset() async {
    final authService = ref.read(authServiceProvider);
    final email = authService.userEmail;
    if (email == null) return;

    bool loading = false;
    bool sent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MimzRadius.lg)),
          title: Text(sent ? 'Email sent!' : 'Reset Password', style: MimzTypography.headlineMedium),
          content: sent
              ? Text('Check your inbox at $email.', style: MimzTypography.bodyMedium)
              : Text(
                  'Send a password reset link to:\n$email',
                  style: MimzTypography.bodyMedium,
                ),
          actions: sent
              ? [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('DONE'))]
              : [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setDialogState(() => loading = true);
                            final result = await authService.sendPasswordReset(email);
                            if (result.success) {
                              setDialogState(() { loading = false; sent = true; });
                            } else {
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('SEND RESET LINK',
                            style: TextStyle(color: MimzColors.mossCore)),
                  ),
                ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final hasEmailProvider = authService.linkedProviders.contains('password');
    final hasGoogleProvider = authService.linkedProviders.contains('google.com');
    final userEmail = authService.userEmail ?? '';

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MimzSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account info
            Text('ACCOUNT', style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: MimzSpacing.md),
            if (userEmail.isNotEmpty)
              _InfoTile(
                icon: Icons.mail_outline,
                title: 'Email',
                subtitle: userEmail,
              ),
            const SizedBox(height: MimzSpacing.xl),

            // Linked providers
            Text('LINKED ACCOUNTS', style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: MimzSpacing.md),
            _ProviderTile(
              icon: Icons.g_mobiledata,
              label: 'Google',
              isLinked: hasGoogleProvider,
            ),
            _ProviderTile(
              icon: Icons.mail_outline,
              label: 'Email / Password',
              isLinked: hasEmailProvider,
            ),
            const SizedBox(height: MimzSpacing.xl),

            // Password reset (only for email users)
            if (hasEmailProvider) ...[
              Text('PASSWORD', style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: MimzSpacing.md),
              _ActionTile(
                icon: Icons.lock_reset,
                title: 'Reset Password',
                subtitle: 'Send a reset link to your email',
                onTap: _showPasswordReset,
              ),
              const SizedBox(height: MimzSpacing.xl),
            ],

            // Biometrics
            Text('BIOMETRICS', style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: MimzSpacing.md),

            if (_loadingBiometrics)
              const Center(child: Padding(
                padding: EdgeInsets.all(MimzSpacing.xl),
                child: CircularProgressIndicator(color: MimzColors.mossCore),
              ))
            else if (!_biometricsAvailable)
              const _StatusCard(
                icon: Icons.fingerprint,
                title: 'Not Supported',
                message: 'Your device does not support biometric authentication.',
                color: MimzColors.textSecondary,
              )
            else if (!_biometricsEnrolled)
              _StatusCard(
                icon: Icons.fingerprint,
                title: 'No Biometrics Enrolled',
                message: 'Go to device Settings to enroll a fingerprint or face.',
                color: MimzColors.textSecondary,
                actionLabel: 'Open Settings',
                onAction: () async {
                  ref.read(hapticsServiceProvider).selection();
                  await openAppSettings();
                },
              )
            else
              Container(
                width: double.infinity,
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
                      child: const Icon(Icons.fingerprint, color: MimzColors.mossCore, size: 20),
                    ),
                    const SizedBox(width: MimzSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biometric Lock', style: MimzTypography.headlineSmall),
                          Text(
                            'Require biometrics when reopening the app',
                            style: MimzTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _biometricsEnabled,
                      onChanged: _toggleBiometrics,
                      activeTrackColor: MimzColors.mossCore,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

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
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLinked;

  const _ProviderTile({required this.icon, required this.label, required this.isLinked});

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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isLinked ? MimzColors.mossCore : MimzColors.textSecondary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.sm),
            ),
            child: Icon(icon, color: isLinked ? MimzColors.mossCore : MimzColors.textSecondary, size: 20),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(child: Text(label, style: MimzTypography.headlineSmall)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: (isLinked ? MimzColors.mossCore : MimzColors.borderLight).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(MimzRadius.pill),
            ),
            child: Text(
              isLinked ? 'LINKED' : 'NOT LINKED',
              style: MimzTypography.caption.copyWith(
                color: isLinked ? MimzColors.mossCore : MimzColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(hapticsServiceProvider).selection();
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

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: MimzSpacing.md),
          Text(title, style: MimzTypography.headlineSmall.copyWith(color: color)),
          const SizedBox(height: MimzSpacing.sm),
          Text(message, style: MimzTypography.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: MimzSpacing.md),
            MimzButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
