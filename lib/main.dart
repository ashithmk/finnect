import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/constants/app_strings.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_providers.dart';
import 'core/providers/app_lock_providers.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/app_lock_gate_screen.dart';
import 'database_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: FinnectApp()));
}

class FinnectApp extends ConsumerStatefulWidget {
  const FinnectApp({super.key});

  @override
  ConsumerState<FinnectApp> createState() => _FinnectAppState();
}

class _FinnectAppState extends ConsumerState<FinnectApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final isLockEnabled = ref.read(isAppLockEnabledProvider);
      if (isLockEnabled) {
        ref.read(isAppLockedProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themePreset = ref.watch(themePresetProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset: themePreset),
      darkTheme: AppTheme.dark(preset: themePreset),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return AppLockGateScreen(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
