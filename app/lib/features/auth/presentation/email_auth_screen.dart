import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers.dart';

/// Email/password sign-in and sign-up with real validation.
/// Accessed via Continue with Email on the main auth screen.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Shared
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {
          _error = null;
          _success = null;
        }));
    _checkPendingLink();
  }

  Future<void> _checkPendingLink() async {
    const storage = FlutterSecureStorage();
    final email = await storage.read(key: 'pending_link_email');
    if (email != null && mounted) {
      setState(() {
        _emailCtrl.text = email;
        _error = 'This email is already registered. Sign in with your password to link your Google account.';
      });
      _tab.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ──────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters required';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ─── Auth Actions ─────────────────────────────────
  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; _success = null; });

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithEmail(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() { _loading = false; _error = result.message ?? 'Sign-in failed.'; });
      return;
    }

    await ref.read(currentUserProvider.notifier).fetchUser();
    if (!mounted) return;
    final userState = ref.read(currentUserProvider);
    if (userState.hasError || userState.valueOrNull == null) {
      setState(() {
        _loading = false;
        _error = 'Signed in, but failed to load your profile. Please retry.';
      });
      return;
    }

    setState(() => _loading = false);
    final isOnboarded = ref.read(isOnboardedProvider).valueOrNull ?? false;
    context.go(isOnboarded ? '/world' : '/permissions');
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; _success = null; });

    final authService = ref.read(authServiceProvider);
    final result = await authService.createAccountWithEmail(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() { _loading = false; _error = result.message ?? 'Account creation failed.'; });
      return;
    }

    await ref.read(currentUserProvider.notifier).fetchUser();
    if (!mounted) return;
    final userState = ref.read(currentUserProvider);
    if (userState.hasError || userState.valueOrNull == null) {
      setState(() {
        _loading = false;
        _error = 'Account created, but profile bootstrap failed. Please retry.';
      });
      return;
    }

    setState(() => _loading = false);
    // New user → always goes to permissions/onboarding
    context.go('/permissions');
  }

  Future<void> _showForgotPassword() async {
    final email = _emailCtrl.text.trim();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(initialEmail: email),
    );
  }

  // ─── UI ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Account'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: MimzColors.mossCore,
          labelColor: MimzColors.mossCore,
          unselectedLabelColor: MimzColors.textSecondary,
          tabs: const [
            Tab(text: 'SIGN IN'),
            Tab(text: 'CREATE ACCOUNT'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tab,
          children: [
            _buildSignInTab(),
            _buildSignUpTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_error != null && _error!.isNotEmpty) {
      return Container(
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
      ).animate().fadeIn(duration: 300.ms).shake();
    }
    if (_success != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: MimzSpacing.md),
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: MimzColors.mossCore.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: MimzColors.mossCore.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: MimzColors.mossCore, size: 18),
            const SizedBox(width: MimzSpacing.sm),
            Expanded(
              child: Text(
                _success!,
                style: MimzTypography.bodySmall.copyWith(color: MimzColors.mossCore),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MimzSpacing.xl),
      child: Form(
        key: _tab.index == 0 ? _formKey : GlobalKey<FormState>(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: MimzSpacing.md),
            _buildStatusBanner(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: MimzSpacing.md),
                child: LinearProgressIndicator(color: MimzColors.mossCore),
              ),
            Text('Welcome back', style: MimzTypography.displayMedium)
                .animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Sign in with your email and password.',
              style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            _buildEmailField(),
            const SizedBox(height: MimzSpacing.md),
            _buildPasswordField(_passwordCtrl, 'Password', _showPassword, () {
              setState(() => _showPassword = !_showPassword);
            }),
            const SizedBox(height: MimzSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _showForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.mossCore,
                    decoration: TextDecoration.underline,
                    decorationColor: MimzColors.mossCore,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: _loading ? 'Signing in…' : 'SIGN IN →',
              onPressed: _loading ? null : _signIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MimzSpacing.xl),
      child: Form(
        key: _tab.index == 1 ? _formKey : GlobalKey<FormState>(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: MimzSpacing.md),
            _buildStatusBanner(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: MimzSpacing.md),
                child: LinearProgressIndicator(color: MimzColors.mossCore),
              ),
            Text('Create your account', style: MimzTypography.displayMedium)
                .animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Join the atlas and claim your district.',
              style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            _buildEmailField(),
            const SizedBox(height: MimzSpacing.md),
            _buildPasswordField(_passwordCtrl, 'Password (8+ chars)', _showPassword, () {
              setState(() => _showPassword = !_showPassword);
            }, validator: _validatePassword),
            const SizedBox(height: MimzSpacing.md),
            _buildPasswordField(
              _confirmPasswordCtrl,
              'Confirm Password',
              _showConfirm,
              () => setState(() => _showConfirm = !_showConfirm),
              validator: _validateConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: _loading ? 'Creating account…' : 'CREATE ACCOUNT →',
              onPressed: _loading ? null : _signUp,
            ),
            const SizedBox(height: MimzSpacing.md),
            Center(
              child: Text(
                'By creating an account you agree to our Terms and Privacy Policy.',
                style: MimzTypography.bodySmall.copyWith(color: MimzColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      validator: _validateEmail,
      decoration: _inputDecoration('Email address', Icons.mail_outline),
    );
  }

  Widget _buildPasswordField(
    TextEditingController ctrl,
    String hint,
    bool visible,
    VoidCallback onToggle, {
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      textInputAction: textInputAction,
      validator: validator ?? _validatePassword,
      onFieldSubmitted: onSubmitted,
      decoration: _inputDecoration(hint, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              color: MimzColors.textSecondary),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: MimzColors.textSecondary, size: 20),
      hintStyle: MimzTypography.bodyMedium.copyWith(color: MimzColors.textTertiary),
      filled: true,
      fillColor: MimzColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.base,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MimzRadius.md),
        borderSide: const BorderSide(color: MimzColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MimzRadius.md),
        borderSide: const BorderSide(color: MimzColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MimzRadius.md),
        borderSide: const BorderSide(color: MimzColors.mossCore, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MimzRadius.md),
        borderSide: const BorderSide(color: MimzColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MimzRadius.md),
        borderSide: const BorderSide(color: MimzColors.error, width: 1.5),
      ),
    );
  }
}

// ─── Forgot Password Bottom Sheet ──────────────────────────────

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; });

    final authService = ref.read(authServiceProvider);
    final result = await authService.sendPasswordReset(email);

    if (!mounted) return;
    if (result.success) {
      setState(() { _loading = false; _sent = true; });
    } else {
      setState(() {
        _loading = false;
        _error = result.message ?? 'Could not send reset email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(MimzSpacing.base),
      padding: EdgeInsets.only(
        left: MimzSpacing.xl,
        right: MimzSpacing.xl,
        top: MimzSpacing.xl,
        bottom: MimzSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: MimzColors.cloudBase,
        borderRadius: BorderRadius.circular(MimzRadius.xl),
      ),
      child: _sent ? _buildSentState() : _buildForm(),
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: MimzColors.mossCore, size: 48),
        const SizedBox(height: MimzSpacing.md),
        Text('Check your inbox', style: MimzTypography.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: MimzSpacing.sm),
        Text(
          'We sent a password reset link to ${_emailCtrl.text.trim()}.',
          style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MimzSpacing.xl),
        MimzButton(label: 'DONE', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reset Password', style: MimzTypography.headlineMedium),
        const SizedBox(height: MimzSpacing.sm),
        Text(
          'Enter the email address for your Mimz account.',
          style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
        ),
        if (_error != null) ...[
          const SizedBox(height: MimzSpacing.md),
          Text(_error!, style: MimzTypography.bodySmall.copyWith(color: MimzColors.error)),
        ],
        const SizedBox(height: MimzSpacing.xl),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            filled: true,
            fillColor: MimzColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
              borderSide: const BorderSide(color: MimzColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
              borderSide: const BorderSide(color: MimzColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MimzRadius.md),
              borderSide: const BorderSide(color: MimzColors.mossCore, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: MimzSpacing.xl),
        MimzButton(
          label: _loading ? 'Sending…' : 'SEND RESET LINK →',
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }
}
