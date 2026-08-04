import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/theme_providers.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/providers/app_lock_providers.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../auth/data/auth_providers.dart';



/// Redesigned Profile Screen with top-right Settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _openSettingsSheet(BuildContext context) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      builder: (ctx) => const _SettingsSheet(),
    );
  }

  void _openEditProfileSheet(BuildContext context) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      builder: (ctx) => const _EditProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.navProfile),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => _openSettingsSheet(context),
            ),
            const SizedBox(width: AppSizes.xs),
          ],
        ),
        body: Builder(
          builder: (scaffoldContext) => ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              // User Header Profile Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'U',
                              style: textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: () => _openEditProfileSheet(scaffoldContext),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(Icons.edit, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    user.displayName.isNotEmpty ? user.displayName : 'User',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Profile',
                                  onPressed: () => _openEditProfileSheet(scaffoldContext),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.formattedUsername,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Member since ${DateFormat.yMMMd().format(user.createdAt)}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings Bottom Sheet with functional Profile, Currency, Theme Presets, App Lock & Security, and Direct Log Out.
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  void _openCurrencyPicker(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final currentCurrency = user?.currency ?? 'INR';

    final currencies = [
      {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Currency', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.md),
            for (final c in currencies)
              ListTile(
                leading: Text(c['symbol']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                title: Text(c['name']!),
                subtitle: Text(c['code']!),
                trailing: currentCurrency == c['code'] ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user != null) {
                    await ref.read(authControllerProvider.notifier).updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          username: user.username,
                          currency: c['code'],
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Currency updated to ${c['code']} (${c['symbol']})'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openThemePresetPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final currentPreset = ref.watch(themePresetProvider);
          final currentMode = ref.watch(themeModeProvider);

          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const SizedBox(height: AppSizes.md),

                // 1. Light / Dark / System Mode Control
                Text('Mode', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChipButton(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChipButton(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChipButton(
                        label: 'System',
                        icon: Icons.brightness_auto_outlined,
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                // 2. Dual-Color Theme Combinations
                Text('Color Combinations', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                for (final preset in AppThemePreset.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: preset.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                    ),
                    title: Text(preset.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: currentPreset == preset ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                    onTap: () {
                      ref.read(themePresetProvider.notifier).setPreset(preset);
                    },
                  ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openSecuritySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final isAppLock = ref.watch(isAppLockEnabledProvider);

          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Lock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.xs),
                Text('Protect Finnect using your phone PIN, pattern, password, or biometrics', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSizes.md),
                SwitchListTile(
                  title: const Text('Require Phone Lock Screen'),
                  subtitle: const Text('Unlock app using phone PIN, pattern, or biometrics'),
                  value: isAppLock,
                  onChanged: (val) async {
                    if (val) {
                      final verified = await AppLockService.instance.authenticateWithDeviceLock(
                        reason: 'Verify phone lock credentials to enable App Lock',
                      );
                      if (verified) {
                        await ref.read(isAppLockEnabledProvider.notifier).setEnabled(true);
                        ref.read(isAppLockedProvider.notifier).lock();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone lock verification required to enable App Lock.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } else {
                      await ref.read(isAppLockEnabledProvider.notifier).setEnabled(false);
                      ref.read(isAppLockedProvider.notifier).unlock();
                    }
                  },
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final currentPreset = ref.watch(themePresetProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Settings',
            style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.md),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            subtitle: const Text('Change display name & username'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showAppModalBottomSheet(
                  context: context,
                  ref: ref,
                  builder: (ctx) => const _EditProfileSheet(),
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('Current: ${user?.currency ?? 'INR'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCurrencyPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(currentPreset.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openThemePresetPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('App Lock & Security'),
            subtitle: const Text('PIN & Biometric authentication'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSecuritySheet(context, ref),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                // Instantly navigate straight to login page without home page flash!
                context.go(RouteNames.login);
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Permanently delete your profile & data',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to permanently delete your account? All your transaction history and profile data will be erased.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                context.go(RouteNames.login);
                await ref.read(authControllerProvider.notifier).deleteAccount();
              }
            },
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}

/// Edit Profile Modal Sheet
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.displayName;
      _usernameController.text = user.username.isNotEmpty
          ? user.username
          : user.email.split('@').first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim().replaceAll('@', '');

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          uid: user.uid,
          displayName: newName,
          username: newUsername,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final authState = ref.read(authControllerProvider);
        String msg = 'Failed to update profile. Please try again.';
        if (authState.hasError && authState.error != null) {
          final err = authState.error;
          if (err is Exception) {
            msg = err.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
          } else {
            msg = err.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Profile',
                style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
