import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';

/// Auth entry screen — Google or Email paths. No guest mode.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  String? _error;
  bool _loading = false;

  /// User-facing message when profile bootstrap fails (after Google sign-in).
  static String _profileLoadErrorMessage(AsyncValue<MimzUser> userState) {
    if (userState.error is BootstrapFailure) {
      return bootstrapFailureMessage(userState.error);
    }
    final err = userState.error;
    if (err is DioException) {
      final code = err.response?.statusCode;
      if (code == 401) {
        return 'Sign-in not recognized. Please try again or use another account.';
      }
      if (code == 403) {
        return 'Signed in, but backend access is restricted by server policy.';
      }
      if (code != null && code >= 500) {
        return 'Server issue. Please try again in a moment.';
      }
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. Check your connection and try again.';
      }
    }
    return 'Could not load your profile. Please check your connection and try again.';
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _error = null; _loading = true; });
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (!mounted) return;

      if (!result.success) {
        // Cancelled is silent; other errors show a message
        if (result.error != AuthErrorType.cancelled) {
          setState(() { _error = result.message ?? 'Sign-in failed. Try again.'; });
        }
        return;
      }

      // Bootstrap user then navigate
      await ref.read(currentUserProvider.notifier).fetchUser();
      if (!mounted) return;
      final userState = ref.read(currentUserProvider);
      if (userState.hasError || userState.valueOrNull == null) {
        setState(() {
          _error = _profileLoadErrorMessage(userState);
        });
        return;
      }

      final isOnboarded = ref.read(isOnboardedProvider).valueOrNull ?? false;
      context.go(isOnboarded ? '/world' : '/permissions');
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        ),
        // NO SKIP BUTTON — guests are not allowed
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

              // Brand logo
              Image.asset(
                'assets/images/logo-dark.png', 
                width: 140, // Let height scale naturally to preserve aspect ratio
                fit: BoxFit.contain
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
                          style: MimzTypography.bodySmall.copyWith(color: MimzColors.error),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).shake(),

              // Loading bar
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: MimzSpacing.md),
                  child: LinearProgressIndicator(color: MimzColors.mossCore),
                ),

              // Google Sign In (primary)
              _AuthButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onTap: _loading ? null : _handleGoogleSignIn,
                isPrimary: true,
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

              // Email (secondary) → opens email form
              _AuthButton(
                icon: Icons.mail_outline,
                label: 'Continue with Email',
                onTap: _loading ? null : () => context.push('/auth/email'),
              ),
              const SizedBox(height: MimzSpacing.xxl),

              // Already have account hint
              GestureDetector(
                onTap: _loading ? null : () => context.push('/auth/email'),
                child: Text(
                  'I already have an account — sign in',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.mossCore,
                    decoration: TextDecoration.underline,
                    decorationColor: MimzColors.mossCore,
                  ),
                ),
              ),

              const SizedBox(height: MimzSpacing.xl),
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

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _AuthButton({
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
