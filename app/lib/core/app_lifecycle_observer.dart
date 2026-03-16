import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers.dart';
import '../services/connectivity_service.dart';
import '../design_system/tokens.dart';

/// Wraps the root app to enforce biometric gating when the app resumes.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check on cold start
    _checkAndLockIfNeeded().then((_) {
      if (_isLocked) _authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Lock if we actually backgrounded, unless we are currently showing OS prompt
      if (!_isAuthenticating) {
        _checkAndLockIfNeeded();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _checkAndLockIfNeeded() async {
    if (_isLocked) return;
    final biometricService = ref.read(biometricServiceProvider);
    final shouldGate = await biometricService.shouldGateOnResume();
    if (shouldGate && mounted) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    
    final biometricService = ref.read(biometricServiceProvider);
    final authed = await biometricService.authenticate(
      reason: 'Confirm your identity to access Mimz.',
    );
    
    _isAuthenticating = false;
    if (authed && mounted) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityStatus = ref.watch(connectivityProvider);

    return Stack(
      children: [
        widget.child,
        
        // Connectivity Banner
        if (connectivityStatus != ConnectivityStatus.online)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.md, vertical: MimzSpacing.sm),
                  color: MimzColors.error,
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: MimzColors.white, size: 20),
                      const SizedBox(width: MimzSpacing.sm),
                      Expanded(
                        child: Text(
                          connectivityStatus == ConnectivityStatus.noInternet
                              ? 'No internet connection'
                              : 'Backend unavailable. Reconnecting...',
                          style: MimzTypography.bodySmall.copyWith(color: MimzColors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(connectivityProvider.notifier).retryNow();
                        },
                        child: Text(
                          'RETRY',
                          style: MimzTypography.buttonText.copyWith(color: MimzColors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: -1, duration: 300.ms, curve: Curves.easeOut),

        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: MimzColors.cloudBase,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, size: 64, color: MimzColors.mossCore),
                    const SizedBox(height: MimzSpacing.xl),
                    Text('Mimz is Locked', style: MimzTypography.displayMedium),
                    const SizedBox(height: MimzSpacing.md),
                    Text('Authentication required to continue', style: MimzTypography.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: MimzSpacing.xxl),
                    GestureDetector(
                      onTap: _authenticate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: MimzColors.mossCore,
                          borderRadius: BorderRadius.circular(MimzRadius.md),
                        ),
                        child: Text('Unlock', style: MimzTypography.buttonText.copyWith(color: MimzColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
