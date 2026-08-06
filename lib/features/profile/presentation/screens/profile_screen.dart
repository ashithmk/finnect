import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/theme_providers.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/providers/app_lock_providers.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/stitch_glass_card.dart';
import '../../../auth/data/auth_providers.dart';
import '../../../goals/data/goal_providers.dart';
import '../../../transactions/data/transaction_providers.dart';

/// 1:1 Profile Screen strictly matching the "Profil" reference mockup image:
/// - Avatar with soft white ring halo centered at top
/// - Crisp White Liquid Glass Profile Hero Card with Name, Handle, Premium Pill Badge,
///   3 Soft Stat Boxes (Expenses, Goals, Streak), and Dark Metallic "Kredin Tükendi!" Banner
/// - Unified Glass Menu Container with rounded action rows
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
    final isDark = theme.brightness == Brightness.dark;

    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    final int txCount = transactionsAsync.maybeWhen(
      data: (txs) => txs.length,
      orElse: () => 0,
    );
    final int goalCount = goalsAsync.maybeWhen(
      data: (gs) => gs.length,
      orElse: () => 0,
    );

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
            children: [
              // Header matching mockup lines 177-186
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1C23),
                      letterSpacing: -0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () => _openSettingsSheet(context),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF1A1C23),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Centered Avatar Ring Halo
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF252830)
                        : Colors.white.withValues(alpha: 0.90),
                    border: Border.all(
                      color: Colors.white,
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1C23),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Main Hero Card matching mockup right screen
              StitchGlassCard(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Name & Handle Header Row with Premium Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName
                                  : 'User',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1C23),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.formattedUsername,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF757885),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C23),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.amberAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3 Stat Pills Row (Gönderi, Takipçi, Takip)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatPill(
                            context,
                            count: '$txCount',
                            label: 'Entries',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatPill(
                            context,
                            count: '$goalCount',
                            label: 'Goals',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatPill(
                            context,
                            count: '15',
                            label: 'Streak',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dark Metallic Banner ("Kredin Tükendi!")
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252830),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro Features Unlocked',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Unlimited AI budget insights active.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _openSettingsSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A1C23),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Settings Group Menu Container matching mockup
              StitchGlassCard(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Account Info',
                      onTap: () => _openEditProfileSheet(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      context,
                      icon: Icons.currency_exchange_rounded,
                      title: 'Currency & Format',
                      subtitle: user.currency,
                      onTap: () => _openSettingsSheet(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'App Lock & Security',
                      onTap: () => _openSettingsSheet(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings & Preferences',
                      onTap: () => _openSettingsSheet(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      titleColor: Colors.redAccent,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out'),
                            content:
                                const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.redAccent),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          context.go(RouteNames.login);
                          ref.read(authControllerProvider.notifier).signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(BuildContext context,
      {required String count, required String label}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1C23),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF757885),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: titleColor ??
                    (isDark ? Colors.white : const Color(0xFF1A1C23)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor ??
                        (isDark ? Colors.white : const Color(0xFF1A1C23)),
                  ),
                ),
              ),
              if (subtitle != null) ...[
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF757885),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : const Color(0xFFA0A3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings Bottom Sheet
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
            Text('Select Currency',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.md),
            for (final c in currencies)
              ListTile(
                leading: Text(c['symbol']!,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                title: Text(c['name']!),
                subtitle: Text(c['code']!),
                trailing: currentCurrency == c['code']
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user != null) {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          username: user.username,
                          currency: c['code'],
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Currency updated to ${c['code']} (${c['symbol']})'),
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
          final currentMode = ref.watch(themeModeProvider);

          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const SizedBox(height: AppSizes.md),

                Text('Mode',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChipButton(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChipButton(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChipButton(
                        label: 'System',
                        icon: Icons.brightness_auto_outlined,
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
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
                Text('App Lock',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.xs),
                Text(
                    'Protect Finnect using your phone PIN, pattern, password, or biometrics',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSizes.md),
                SwitchListTile(
                  title: const Text('Require Phone Lock Screen'),
                  subtitle: const Text(
                      'Unlock app using phone PIN, pattern, or biometrics'),
                  value: isAppLock,
                  onChanged: (val) async {
                    if (val) {
                      final verified = await AppLockService.instance
                          .authenticateWithDeviceLock(
                        reason:
                            'Verify phone lock credentials to enable App Lock',
                      );
                      if (verified) {
                        await ref
                            .read(isAppLockEnabledProvider.notifier)
                            .setEnabled(true);
                        ref.read(isAppLockedProvider.notifier).lock();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Phone lock verification required to enable App Lock.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } else {
                      await ref
                          .read(isAppLockEnabledProvider.notifier)
                          .setEnabled(false);
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg)),
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
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Settings',
            style: context.textStyles.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.md),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('Current: ${user?.currency ?? 'INR'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCurrencyPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme Mode'),
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
        ],
      ),
    );
  }
}

/// Edit Profile Sheet
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

    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile.'),
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
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg)),
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
                style: context.textStyles.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
