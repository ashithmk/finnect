import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../data/auth_providers.dart';

/// Finnect Login Screen with 3D cosmic background & glowing capsule form.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();

    // Auto-navigate if already authenticated in Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        context.go(RouteNames.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint('Attempting login for: $email');

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );

    if (!mounted) return;

    final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (success || isUserLoggedIn) {
      debugPrint('Login succeeded! Navigating to dashboard.');
      context.go(RouteNames.dashboard);
      return;
    }

    final state = ref.read(authControllerProvider);
    debugPrint('Login failed with error: ${state.error}');
    String errorMessage = AppStrings.genericError;

    if (state.hasError && state.error is FirebaseAuthException) {
      final authEx = state.error as FirebaseAuthException;
      switch (authEx.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          errorMessage =
              'Invalid email/username or password. If you deleted this account from Firebase or haven\'t registered yet, please tap "Sign Up" below to create your account.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many failed login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network connection error. Please check your internet connection.';
          break;
        default:
          errorMessage = authEx.message ?? authEx.code;
      }
    } else if (state.hasError) {
      errorMessage = state.error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('Attempting Google Sign-In...');
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (success) {
      debugPrint('Google Sign-In succeeded! Navigating to dashboard.');
      ref.invalidate(authStateChangesProvider);
      context.go(RouteNames.dashboard);
    }
  }

  Future<void> _handleForgotPassword() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    final String? emailToReset = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = resetEmailController.text.trim();
              if (val.isNotEmpty && val.contains('@')) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (emailToReset != null && emailToReset.isNotEmpty && mounted) {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(emailToReset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $emailToReset'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<dynamic>(currentUserProvider, (previous, next) {
      if (next != null && mounted) {
        debugPrint(
            'currentUserProvider listener triggered navigation to dashboard');
        context.go(RouteNames.dashboard);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg, vertical: AppSizes.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: AppSizes.maxContentWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Finnect App Logo Header
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // Glassmorphism Floating Capsule Form Container
                          Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1C22)
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Email or username',
                                    prefixIcon: const Icon(Icons.person_outline,
                                        color: Colors.blueAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email or @username';
                                    }
                                    return null;
                                  },
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: AppSizes.md),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.password,
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: Colors.blueAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  validator: Validators.password,
                                  enabled: !isLoading,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : _handleForgotPassword,
                                    child: Text(
                                      AppStrings.forgotPassword,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                PrimaryButton(
                                  label: AppStrings.signIn,
                                  isLoading: isLoading,
                                  onPressed: _handleSignIn,
                                ),
                                const SizedBox(height: AppSizes.md),
                                SecondaryButton(
                                  label: AppStrings.signInWithGoogle,
                                  icon: Icons.g_mobiledata,
                                  onPressed:
                                      isLoading ? null : _handleGoogleSignIn,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push(RouteNames.register),
                                child: Text(
                                  AppStrings.signUp,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
