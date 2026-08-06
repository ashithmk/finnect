import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/providers/app_lock_providers.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../../auth/data/auth_providers.dart';
import '../../../auth/domain/user_model.dart';
import '../../../goals/data/goal_providers.dart';

/// Profile Screen — clean hero card + settings sheet via top-right icon
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _avatarFile;

  // ─── Settings sheet (contains all menu items) ─────────────────────────────

  void _openSettingsSheet(BuildContext context) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      builder: (ctx) => _FullSettingsSheet(avatarFile: _avatarFile),
    );
  }

  // ─── Avatar picker ────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rawUser = ref.watch(currentUserProvider);
    final user = rawUser ??
        AppUser(
          uid: 'user_default',
          email: 'user@finnect.app',
          displayName: 'Finnect User',
          username: 'user',
          createdAt: DateTime.now(),
          currency: 'INR',
        );

    final goalsAsync = ref.watch(goalsStreamProvider);
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
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tappable Avatar ──
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _avatarFile != null
                              ? Image.file(
                                  _avatarFile!,
                                  fit: BoxFit.cover,
                                  width: 96,
                                  height: 96,
                                )
                              : Center(
                                  child: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Name & username ──
              Center(
                child: Column(
                  children: [
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : 'User',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.formattedUsername,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Shopping Goals Banner ──
              FinnectGlassCard(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.track_changes_rounded,
                          size: 20,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goals',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$goalCount active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push(RouteNames.goals),
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Set Goals',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Full Settings Sheet — opened via top-right settings icon
// Contains: Account Info, Currency, App Lock, Settings & Prefs, Log Out
// ─────────────────────────────────────────────────────────────────────────────

class _FullSettingsSheet extends ConsumerWidget {
  final File? avatarFile;
  const _FullSettingsSheet({this.avatarFile});

  void _openEditProfile(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).pop();
    final rootContext = rootNavigatorKey.currentContext!;
    showAppModalBottomSheet(
      context: rootContext,
      ref: ref,
      builder: (ctx) => const _EditProfileSheet(),
    );
  }

  void _openCurrency(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).pop();
    final rootContext = rootNavigatorKey.currentContext!;
    showAppModalBottomSheet(
      context: rootContext,
      ref: ref,
      builder: (ctx) => _CurrencySheet(widgetRef: ref),
    );
  }

  void _openAppLock(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).pop();
    final rootContext = rootNavigatorKey.currentContext!;
    showAppModalBottomSheet(
      context: rootContext,
      ref: ref,
      builder: (ctx) => const _AppLockSheet(),
    );
  }

  void _openPreferences(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).pop();
    final rootContext = rootNavigatorKey.currentContext!;
    showAppModalBottomSheet(
      context: rootContext,
      ref: ref,
      builder: (ctx) => const _PreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassSubtleFill,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Menu items
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Account Info',
              subtitle: user?.displayName ?? '',
              onTap: () => _openEditProfile(context, ref),
            ),
            const Divider(height: 1, indent: 72, endIndent: 24),
            _SettingsTile(
              icon: Icons.currency_exchange_rounded,
              title: 'Currency & Format',
              subtitle: user?.currency ?? 'INR',
              onTap: () => _openCurrency(context, ref),
            ),
            const Divider(height: 1, indent: 72, endIndent: 24),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'App Lock & Security',
              onTap: () => _openAppLock(context, ref),
            ),
            const Divider(height: 1, indent: 72, endIndent: 24),
            _SettingsTile(
              icon: Icons.tune_rounded,
              title: 'Settings & Preferences',
              onTap: () => _openPreferences(context, ref),
            ),
            const Divider(height: 1, indent: 72, endIndent: 24),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              titleColor: Colors.redAccent,
              onTap: () async {
                // Show dialog BEFORE popping the sheet so context stays valid
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
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
                  Navigator.pop(context); // close the settings sheet
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut(); // sign out first; router will redirect automatically
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Single settings list row
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.glassSubtleFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18, color: titleColor ?? AppColors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-sheets
// ─────────────────────────────────────────────────────────────────────────────

/// Shared sheet scaffold
class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassSubtleFill,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Currency sheet
class _CurrencySheet extends StatelessWidget {
  final WidgetRef widgetRef;
  const _CurrencySheet({required this.widgetRef});

  static const _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = widgetRef.watch(currentUserProvider);
    final currentCurrency = user?.currency ?? 'INR';

    return _SheetScaffold(
      title: 'Currency & Format',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in _currencies)
            ListTile(
              leading: Text(c['symbol'] ?? '',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              title: Text(c['name'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle:
                  Text(c['code'] ?? '', style: GoogleFonts.inter(fontSize: 12)),
              trailing: currentCurrency == c['code']
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                if (user != null) {
                  await widgetRef
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
    );
  }
}

/// App Lock sheet
class _AppLockSheet extends ConsumerWidget {
  const _AppLockSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLockEnabled = ref.watch(isAppLockEnabledProvider);

    return _SheetScaffold(
      title: 'App Lock & Security',
      child: SwitchListTile(
        activeThumbColor: AppColors.primary,
        title: Text('Device App Lock',
            style:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Require Phone Lock PIN or Biometrics to open Finnect',
            style: GoogleFonts.inter(fontSize: 12)),
        value: isLockEnabled,
        onChanged: (val) async {
          await ref.read(isAppLockEnabledProvider.notifier).setEnabled(val);
        },
      ),
    );
  }
}

/// Settings & Preferences sheet
class _PreferencesSheet extends StatelessWidget {
  const _PreferencesSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Settings & Preferences',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: Text('Notifications',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text('Manage reminders & alerts',
                style: GoogleFonts.inter(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text('Appearance',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text('Theme & display',
                style: GoogleFonts.inter(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text('About Finnect',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text('Version & licenses',
                style: GoogleFonts.inter(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(
              uid: user.uid,
              displayName: _nameController.text.trim(),
              username: _usernameController.text.trim(),
            );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Username may be taken.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Account Info',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.glassSubtleFill,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username Handle',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (val.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Save Changes',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
