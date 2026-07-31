/// Keys used with `shared_preferences` and other local key-value stores.
///
/// Kept in one place so renames don't silently orphan stored data.
abstract class AppKeys {
  AppKeys._();

  static const String prefThemeMode = 'pref_theme_mode'; // 'light'|'dark'|'system'
  static const String prefLocale = 'pref_locale';
  static const String prefCurrencyCode = 'pref_currency_code';
  static const String prefCurrencySymbol = 'pref_currency_symbol';
  static const String prefOnboardingComplete = 'pref_onboarding_complete';
  static const String prefLastSyncedAt = 'pref_last_synced_at';
  static const String prefAppLockEnabled = 'pref_app_lock_enabled';
  static const String prefBiometricEnabled = 'pref_biometric_enabled';

  // Firestore top-level collection
  static const String usersCollection = 'users';

  // Firestore subcollections (relative to users/{uid})
  static const String accountsSubcollection = 'accounts';
  static const String categoriesSubcollection = 'categories';
  static const String transactionsSubcollection = 'transactions';
  static const String budgetsSubcollection = 'budgets';
  static const String goalsSubcollection = 'goals';
  static const String recurringSubcollection = 'recurring';

  // Firebase Storage paths
  static String receiptStoragePath(String uid, String transactionId) =>
      'users/$uid/receipts/$transactionId.jpg';
  static String avatarStoragePath(String uid) => 'users/$uid/avatar.jpg';
}
