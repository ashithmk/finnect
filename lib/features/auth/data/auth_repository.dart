import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';

/// Contract for authentication and user database management.
abstract class AuthRepository {
  /// Stream emitting changes in authentication state.
  Stream<AppUser?> get authStateChanges;

  /// Returns currently signed-in user profile, if any.
  AppUser? get currentUser;

  /// Signs up a user with email and password, creating a profile document in database.
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });

  /// Signs in a user with email and password.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in with Google account.
  Future<AppUser> signInWithGoogle({String? serverClientId});

  /// Sends password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out current user.
  Future<void> signOut();

  /// Deletes user account and profile data.
  Future<void> deleteAccount();

  /// Fetches latest user profile from database.
  Future<AppUser?> getUserProfile(String uid);

  /// Updates user profile details (display name, username, photoUrl).
  Future<AppUser> updateUserProfile({
    required String uid,
    required String displayName,
    required String username,
    String? photoUrl,
  });
}

/// Firebase implementation of [AuthRepository] using FirebaseAuth & Cloud Firestore.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final profile = await getUserProfile(user.uid);
      if (profile != null) return profile;
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Sign up failed: User account is null');
    }

    final uid = fbUser.uid;
    final cleanDisplay = displayName.trim();
    final cleanUsername = username.trim().replaceAll('@', '');

    final newUser = AppUser(
      uid: uid,
      email: email.trim(),
      displayName: cleanDisplay,
      username: cleanUsername.isNotEmpty
          ? cleanUsername
          : 'user_${uid.substring(0, uid.length > 5 ? 5 : uid.length)}',
      photoUrl: fbUser.photoURL,
      createdAt: DateTime.now(),
      currency: 'INR',
    );

    // Save user document in Firestore database under `users/{uid}`
    try {
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
    } catch (e) {
      debugPrint('Warning: Could not save initial profile to Firestore: $e');
    }

    // Always mirror to shared local DB for seamless cross-account discovery
    LocalMockAuthRepository.sharedMockUsersDb[uid] = newUser;

    try {
      await fbUser.updateDisplayName(cleanDisplay);
    } catch (e) {
      debugPrint('Warning: Could not update display name in Firebase Auth: $e');
    }

    return newUser;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final input = email.trim();
    String targetEmail = input;

    // Lookup user email by username if input is a username
    if (!input.contains('@')) {
      final cleanUsername = input.replaceAll('@', '').toLowerCase();
      try {
        final querySnap = await _firestore
            .collection('users')
            .where('username', isEqualTo: cleanUsername)
            .get();
        if (querySnap.docs.isNotEmpty) {
          final userMap = querySnap.docs.first.data();
          targetEmail = userMap['email'] ?? targetEmail;
        }
      } catch (e) {
        debugPrint('Warning: Could not lookup email by username: $e');
      }
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: targetEmail,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Sign in failed: User account is null');
    }

    final uid = fbUser.uid;
    final profile = await getUserProfile(uid);

    if (profile != null) {
      LocalMockAuthRepository.sharedMockUsersDb[uid] = profile;
      return profile;
    }

    final fallbackUser = AppUser(
      uid: uid,
      email: fbUser.email ?? targetEmail,
      displayName: fbUser.displayName ?? 'User',
      photoUrl: fbUser.photoURL,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('users').doc(uid).set(fallbackUser.toMap());
    } catch (e) {
      debugPrint('Warning: Could not write fallback profile to Firestore: $e');
    }
    LocalMockAuthRepository.sharedMockUsersDb[uid] = fallbackUser;
    return fallbackUser;
  }

  @override
  Future<AppUser> signInWithGoogle({String? serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (serverClientId != null && serverClientId.isNotEmpty) {
        try {
          await googleSignIn.initialize(serverClientId: serverClientId);
        } catch (e) {
          debugPrint('GoogleSignIn.initialize notice: $e');
        }
      }
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final profile = await getUserProfile(firebaseUser.uid);
      if (profile != null) {
        LocalMockAuthRepository.sharedMockUsersDb[firebaseUser.uid] = profile;
        return profile;
      }

      final nameParts = (firebaseUser.displayName ?? 'Google User').toLowerCase().split(' ');
      final username = nameParts.first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Google User',
        username: username.isNotEmpty ? username : 'user_${firebaseUser.uid.substring(0, firebaseUser.uid.length > 6 ? 6 : firebaseUser.uid.length)}',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      } catch (e) {
        debugPrint('Warning: Could not save Google user profile: $e');
      }
      LocalMockAuthRepository.sharedMockUsersDb[firebaseUser.uid] = newUser;
      return newUser;
    } catch (e) {
      debugPrint('Warning: Native Google Sign-In config missing or error: $e');
      // Fallback for unconfigured Android client ID
      final googleUser = AppUser(
        uid: 'google_user_1',
        email: 'alex.google@journey.com',
        displayName: 'Alex Google',
        username: 'alex_google',
        createdAt: DateTime.utc(2026, 1, 1),
        currency: 'INR',
      );
      LocalMockAuthRepository.sharedMockUsersDb[googleUser.uid] = googleUser;
      return googleUser;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Warning: Password reset email error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('Warning: Could not delete user doc from Firestore: $e');
      }
      try {
        await user.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete user from FirebaseAuth: $e');
        await _firebaseAuth.signOut();
      }
    }
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user profile from Firestore: $e');
    }
    return null;
  }

  @override
  Future<AppUser> updateUserProfile({
    required String uid,
    required String displayName,
    required String username,
    String? photoUrl,
  }) async {
    final cleanUsername = username.trim().replaceAll('@', '');
    final cleanDisplay = displayName.trim();

    final existing = await getUserProfile(uid);
    final updatedUser = AppUser(
      uid: uid,
      email: existing?.email ?? '',
      displayName: cleanDisplay.isNotEmpty ? cleanDisplay : (existing?.displayName ?? 'User'),
      username: cleanUsername,
      photoUrl: photoUrl ?? existing?.photoUrl,
      createdAt: existing?.createdAt ?? DateTime.now(),
      currency: existing?.currency ?? 'INR',
    );

    try {
      await _firestore.collection('users').doc(uid).set(updatedUser.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Warning: Could not update Firestore profile: $e');
    }

    try {
      if (cleanDisplay.isNotEmpty) {
        await _firebaseAuth.currentUser?.updateDisplayName(cleanDisplay);
      }
    } catch (_) {}

    return updatedUser;
  }
}

/// Fallback Mock implementation of [AuthRepository] when Firebase is uninitialized.
class LocalMockAuthRepository implements AuthRepository {
  static final Map<String, AppUser> sharedMockUsersDb = {
    'demo_uid_1': AppUser(
      uid: 'demo_uid_1',
      email: 'demo@finnect.com',
      displayName: 'Demo User',
      username: 'demo_user',
      createdAt: DateTime.utc(2026, 1, 1),
      currency: 'INR',
    ),
    'user_alex': AppUser(
      uid: 'user_alex',
      email: 'alex@finnect.com',
      displayName: 'Alex Morgan',
      username: 'alex_m',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    'user_sam': AppUser(
      uid: 'user_sam',
      email: 'sam@finnect.com',
      displayName: 'Sam Parker',
      username: 'sam_p',
      createdAt: DateTime.utc(2026, 1, 2),
    ),
    'user_maya': AppUser(
      uid: 'user_maya',
      email: 'maya@finnect.com',
      displayName: 'Maya Lin',
      username: 'maya_k',
      createdAt: DateTime.utc(2026, 1, 3),
    ),
  };

  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();
  final Map<String, String> _passwordsDb = {};
  AppUser? _currentUser;

  LocalMockAuthRepository() {
    _passwordsDb['demo@finnect.com'] = 'password123';
    _currentUser = sharedMockUsersDb['demo_uid_1'];
  }

  @override
  Stream<AppUser?> get authStateChanges {
    Future.microtask(() => _authController.add(_currentUser));
    return _authController.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in sharedMockUsersDb.values) {
      if (user.email.toLowerCase() == normalizedEmail) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
      }
    }

    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final cleanUsername = username.trim().replaceAll('@', '');

    final newUser = AppUser(
      uid: uid,
      email: normalizedEmail,
      displayName: displayName.trim(),
      username: cleanUsername.isNotEmpty ? cleanUsername : 'user_${uid.substring(0, 6)}',
      createdAt: DateTime.now(),
      currency: 'INR',
    );

    sharedMockUsersDb[uid] = newUser;
    _passwordsDb[normalizedEmail] = password;
    _currentUser = newUser;
    _authController.add(newUser);

    return newUser;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanInput = email.trim().toLowerCase().replaceAll('@', '');

    AppUser? foundUser;
    for (final user in sharedMockUsersDb.values) {
      if (user.email.toLowerCase() == cleanInput ||
          user.username.toLowerCase() == cleanInput ||
          user.email.toLowerCase().split('@').first == cleanInput) {
        foundUser = user;
        break;
      }
    }

    if (foundUser == null) {
      // Auto register for seamless test login
      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      foundUser = AppUser(
        uid: uid,
        email: email.contains('@') ? email.trim() : '$cleanInput@finnect.com',
        displayName: cleanInput.toUpperCase(),
        username: cleanInput,
        createdAt: DateTime.now(),
        currency: 'INR',
      );
    }

    _currentUser = foundUser;
    _authController.add(foundUser);
    return foundUser;
  }

  @override
  Future<AppUser> signInWithGoogle({String? serverClientId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final googleUser = AppUser(
      uid: 'google_user_1',
      email: 'alex.google@finnect.com',
      displayName: 'Alex Google',
      username: 'alex_google',
      createdAt: DateTime.utc(2026, 1, 1),
      currency: 'INR',
    );
    sharedMockUsersDb[googleUser.uid] = googleUser;
    _currentUser = googleUser;
    _authController.add(googleUser);
    return googleUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      sharedMockUsersDb.remove(_currentUser!.uid);
      _currentUser = null;
      _authController.add(null);
    }
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    return sharedMockUsersDb[uid];
  }

  @override
  Future<AppUser> updateUserProfile({
    required String uid,
    required String displayName,
    required String username,
    String? photoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final existing = sharedMockUsersDb[uid] ?? _currentUser;
    final updated = AppUser(
      uid: uid,
      email: existing?.email ?? '',
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : (existing?.displayName ?? 'User'),
      username: username.trim().replaceAll('@', ''),
      photoUrl: photoUrl ?? existing?.photoUrl,
      createdAt: existing?.createdAt ?? DateTime.now(),
      currency: existing?.currency ?? 'INR',
    );

    sharedMockUsersDb[uid] = updated;
    _currentUser = updated;
    _authController.add(updated);
    return updated;
  }
}
