import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../data/auth_providers.dart';

/// Liquid Minimalist Redesigned Login Screen strictly matching `finnect_design/login/code.html` and `DESIGN.md`.
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
  bool _obscurePassword = true;

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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();

    // Auto-navigate if already authenticated
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

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );

    if (!mounted) return;

    final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (success || isUserLoggedIn) {
      context.go(RouteNames.dashboard);
      return;
    }

    final state = ref.read(authControllerProvider);
    String errorMessage = AppStrings.genericError;

    if (state.hasError && state.error is FirebaseAuthException) {
      final authEx = state.error as FirebaseAuthException;
      switch (authEx.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          errorMessage =
              'Invalid email or password. Please check your credentials or tap "Create New Account".';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many failed attempts. Please try again later.';
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (success) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4C4546)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email or Username',
                prefixIcon: const Icon(Icons.mail_outline, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF4C4546)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4648D4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = resetEmailController.text.trim();
              if (val.isNotEmpty && val.contains('@')) {
                Navigator.pop(ctx, val);
              }
            },
            child: Text(
              'Send Link',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
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
        context.go(RouteNames.dashboard);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient Liquid Background Orbs
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6063EE).withValues(alpha: 0.20),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4EDEA3).withValues(alpha: 0.18),
                  ),
                ),
              ),

              // Main Scrollable Content
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Header / Logo ──
                              Center(
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.65),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 15,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.account_balance_wallet_rounded,
                                              size: 32,
                                              color: Color(0xFF191C1D),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'FINNECT',
                                      style: GoogleFonts.inter(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: const Color(0xFF191C1D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Liquid Glass Form Card ──
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.38),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1F2687).withValues(alpha: 0.08),
                                          blurRadius: 32,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Email Address Field
                                        Text(
                                          'EMAIL ADDRESS',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                            color: const Color(0xFF4C4546),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                            child: TextFormField(
                                              controller: _emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              enabled: !isLoading,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                color: const Color(0xFF191C1D),
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'username or email',
                                                hintStyle: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color: const Color(0xFF4C4546).withValues(alpha: 0.50),
                                                ),
                                                prefixIcon: const Icon(
                                                  Icons.mail_outline_rounded,
                                                  size: 20,
                                                  color: Color(0xFF4C4546),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white.withValues(alpha: 0.35),
                                                contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 14),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFF6063EE),
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                              validator: (val) {
                                                if (val == null || val.trim().isEmpty) {
                                                  return 'Please enter your email address';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Password Field
                                        Text(
                                          'PASSWORD',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                            color: const Color(0xFF4C4546),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                            child: TextFormField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              enabled: !isLoading,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                color: const Color(0xFF191C1D),
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '',
                                                hintStyle: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color: const Color(0xFF4C4546).withValues(alpha: 0.50),
                                                ),
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 20,
                                                  color: Color(0xFF4C4546),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_outlined
                                                        : Icons.visibility_off_outlined,
                                                    size: 20,
                                                    color: const Color(0xFF4C4546),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword = !_obscurePassword;
                                                    });
                                                  },
                                                ),
                                                filled: true,
                                                fillColor: Colors.white.withValues(alpha: 0.35),
                                                contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 14),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFF6063EE),
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                              validator: Validators.password,
                                            ),
                                          ),
                                        ),

                                        // Forgot Password Link
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: isLoading ? null : _handleForgotPassword,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Forgot Password?',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF4648D4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // ── Primary Login Button ──
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isLoading ? null : _handleSignIn,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Ink(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF000000).withValues(alpha: 0.88),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.25),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (isLoading)
                                                    const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  else ...[
                                                    Text(
                                                      'Login',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons.arrow_forward_rounded,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // ── Secondary Google Login Button ──
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isLoading ? null : _handleGoogleSignIn,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Ink(
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.55),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.04),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 22,
                                                    height: 22,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'G',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF4285F4),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Login with Google',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF191C1D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Footer ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF4C4546),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => context.push(RouteNames.register),
                                    child: Text(
                                      'Create New Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4648D4),
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
            ],
          ),
        ),
      ),
    );
  }
}
