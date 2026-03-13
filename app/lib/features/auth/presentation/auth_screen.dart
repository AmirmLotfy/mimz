import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers.dart';

/// Screen 3 — Sign up / auth screen with Apple, Google, Email
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  String? _error;
  bool _loading = false;

  Future<void> _signIn(Future<void> Function() fn) async {
    setState(() { _error = null; _loading = true; });
    try {
      await fn();
      if (mounted) {
        // After auth, wait briefly for providers to settle and check if already onboarded
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final isOnboarded = ref.read(isOnboardedProvider);
        if (isOnboarded) {
          context.go('/world');
        } else {
          context.go('/permissions');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _friendlyError(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('network')) return 'No internet connection. Try again.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Wrong email or password.';
    }
    if (raw.contains('user-not-found')) return 'No account found with that email.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (raw.contains('cancelled') || raw.contains('canceled')) return '';
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
               final isOnboarded = ref.read(isOnboardedProvider);
               context.go(isOnboarded ? '/world' : '/permissions');
            },
            child: const Text('Skip',
                style: TextStyle(color: MimzColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Container(
                  width: i == 0 ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == 0 ? MimzColors.mossCore : MimzColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // Brand icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MimzColors.surfaceLight,
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  border: Border.all(color: MimzColors.borderLight),
                ),
                child: const Icon(Icons.eco, color: MimzColors.mossCore, size: 32),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
              const SizedBox(height: MimzSpacing.xl),
              Text('Join the\nAtlas', style: MimzTypography.displayLarge, textAlign: TextAlign.center)
                  .animate().fadeIn(duration: 500.ms),
              const SizedBox(height: MimzSpacing.sm),
              Text(
                'Create your account and start building your district.',
                style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MimzSpacing.xxl),

              // Error display
              if (_error != null && _error!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: MimzSpacing.md),
                  padding: const EdgeInsets.all(MimzSpacing.base),
                  decoration: BoxDecoration(
                    color: MimzColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                    border: Border.all(color: MimzColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: MimzColors.error, size: 18),
                      const SizedBox(width: MimzSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: MimzTypography.bodySmall.copyWith(
                            color: MimzColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).shake(),

              // Loading overlay
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: MimzSpacing.md),
                  child: LinearProgressIndicator(color: MimzColors.mossCore),
                ),

              // Apple Sign In
              _SocialButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onTap: _loading ? null : () => _signIn(authService.signInWithApple),
                isPrimary: true,
              ),
              const SizedBox(height: MimzSpacing.md),
              // Google Sign In
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onTap: _loading ? null : () => _signIn(authService.signInWithGoogle),
              ),
              const SizedBox(height: MimzSpacing.md),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: MimzColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
                    child: Text('or', style: MimzTypography.bodySmall),
                  ),
                  const Expanded(child: Divider(color: MimzColors.borderLight)),
                ],
              ),
              const SizedBox(height: MimzSpacing.md),
              // Email Sign In
              _SocialButton(
                icon: Icons.mail_outline,
                label: 'Continue with Email',
                onTap: _loading ? null : () => _signIn(
                  () => authService.signInWithEmail('demo@mimz.app', 'password'),
                ),
              ),
              const SizedBox(height: MimzSpacing.xxl),
              // Legal footer
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                style: MimzTypography.bodySmall.copyWith(color: MimzColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
          decoration: BoxDecoration(
            color: isPrimary ? MimzColors.deepInk : MimzColors.white,
            borderRadius: BorderRadius.circular(MimzRadius.md),
            border: isPrimary ? null : Border.all(color: MimzColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? MimzColors.white : MimzColors.deepInk, size: 24),
              const SizedBox(width: MimzSpacing.md),
              Text(
                label,
                style: MimzTypography.buttonText.copyWith(
                  color: isPrimary ? MimzColors.white : MimzColors.deepInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
