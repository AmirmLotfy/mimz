import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers.dart';

/// Screen 3 — Sign up / auth screen with Apple, Google, Email
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => context.go('/permissions'),
            child: Text('Skip',
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
              // Apple Sign In
              _SocialButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onTap: () async {
                  await authService.signInWithApple();
                  if (context.mounted) context.go('/permissions');
                },
                isPrimary: true,
              ),
              const SizedBox(height: MimzSpacing.md),
              // Google Sign In
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onTap: () async {
                  await authService.signInWithGoogle();
                  if (context.mounted) context.go('/permissions');
                },
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
                onTap: () async {
                  await authService.signInWithEmail('demo@mimz.app', 'password');
                  if (context.mounted) context.go('/permissions');
                },
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
  final VoidCallback onTap;
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
    );
  }
}
