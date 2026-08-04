import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants/app_sizes.dart';
import '../../app/theme/theme_providers.dart';
import '../providers/app_lock_providers.dart';
import '../services/app_lock_service.dart';
import 'buttons.dart';
import 'finnect_3d_background.dart';

/// Full-screen interactive Security Gate asking for System Phone Lock Credentials (PIN, Pattern, Password, or Biometrics).
class AppLockGateScreen extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGateScreen({super.key, required this.child});

  @override
  ConsumerState<AppLockGateScreen> createState() => _AppLockGateScreenState();
}

class _AppLockGateScreenState extends ConsumerState<AppLockGateScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPhoneLockAuth();
    });
  }

  Future<void> _triggerPhoneLockAuth() async {
    final isLockEnabled = ref.read(isAppLockEnabledProvider);
    final isLocked = ref.read(isAppLockedProvider);

    if (!isLockEnabled || !isLocked || _isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final success = await AppLockService.instance.authenticateWithDeviceLock(
      reason: 'Unlock Finnect using your phone PIN, pattern, or biometrics',
    );

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        HapticFeedback.mediumImpact();
        ref.read(isAppLockedProvider.notifier).unlock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isAppLockedProvider);
    final isLockEnabled = ref.watch(isAppLockEnabledProvider);

    // If app lock is disabled or app is unlocked, render normal child app!
    if (!isLockEnabled || !isLocked) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final preset = ref.watch(themePresetProvider);

    return Scaffold(
      body: Finnect3DBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Glowing Lock Icon Core
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: preset.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: preset.primaryColor.withValues(alpha: 0.45),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: AppSizes.xl),

                Text(
                  'Finnect Locked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Unlock using your phone passcode, pattern, or biometrics',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // Primary Unlock Button
                PrimaryButton(
                  label: _isAuthenticating ? 'Authenticating...' : 'Unlock Finnect',
                  icon: Icons.fingerprint,
                  isLoading: _isAuthenticating,
                  onPressed: _triggerPhoneLockAuth,
                ),

                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
