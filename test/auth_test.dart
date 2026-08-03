import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finnect/features/auth/domain/user_model.dart';
import 'package:finnect/features/auth/data/auth_repository.dart';

void main() {
  group('AppUser Model Tests', () {
    test('AppUser toMap and fromMap conversion works correctly', () {
      final user = AppUser(
        uid: 'test_uid_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2026, 1, 1),
        currency: 'INR',
      );

      final map = user.toMap();
      expect(map['uid'], 'test_uid_123');
      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'Test User');

      final reconstructedUser = AppUser.fromMap(map);
      expect(reconstructedUser.uid, user.uid);
      expect(reconstructedUser.email, user.email);
      expect(reconstructedUser.displayName, user.displayName);
      expect(reconstructedUser.currency, 'INR');
    });
  });

  group('AuthRepository Integration Tests', () {
    late LocalMockAuthRepository repository;

    setUp(() {
      repository = LocalMockAuthRepository();
    });

    test('sign up creates user account and signs in', () async {
      final user = await repository.signUpWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'securepassword',
        displayName: 'New User',
        username: 'newuser_unique',
      );

      expect(user.email, 'newuser@example.com');
      expect(user.displayName, 'New User');
      expect(repository.currentUser?.email, 'newuser@example.com');
    });

    test('enforces unique usernames on sign up', () async {
      await repository.signUpWithEmailAndPassword(
        email: 'user1@example.com',
        password: 'password123',
        displayName: 'User One',
        username: 'unique_handle',
      );

      expect(
        () async => await repository.signUpWithEmailAndPassword(
          email: 'user2@example.com',
          password: 'password123',
          displayName: 'User Two',
          username: 'UNIQUE_HANDLE', // Same handle case-insensitively
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('updateUserProfile updates details and prevents duplicate username', () async {
      final user = await repository.signUpWithEmailAndPassword(
        email: 'update_test@example.com',
        password: 'password123',
        displayName: 'Original Name',
        username: 'orig_username',
      );

      final updated = await repository.updateUserProfile(
        uid: user.uid,
        displayName: 'New Display Name',
        username: 'new_username_123',
      );

      expect(updated.displayName, 'New Display Name');
      expect(updated.username, 'new_username_123');
      expect(repository.currentUser?.displayName, 'New Display Name');

      // Attempt to update to an existing handle (demo_user)
      expect(
        () async => await repository.updateUserProfile(
          uid: user.uid,
          displayName: 'New Display Name',
          username: 'demo_user',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('sign in succeeds with valid credentials', () async {
      await repository.signUpWithEmailAndPassword(
        email: 'login@example.com',
        password: 'password123',
        displayName: 'Login User',
        username: 'login_user',
      );

      await repository.signOut();
      expect(repository.currentUser, isNull);

      final signedInUser = await repository.signInWithEmailAndPassword(
        email: 'login@example.com',
        password: 'password123',
      );

      expect(signedInUser.email, 'login@example.com');
      expect(repository.currentUser, isNotNull);
    });

    test('sign in succeeds with username handle or email', () async {
      await repository.signUpWithEmailAndPassword(
        email: 'handlelogin@example.com',
        password: 'password123',
        displayName: 'Handle User',
        username: 'my_unique_handle',
      );

      await repository.signOut();

      // Login using username handle '@my_unique_handle'
      final signedInUser = await repository.signInWithEmailAndPassword(
        email: '@my_unique_handle',
        password: 'password123',
      );

      expect(signedInUser.email, 'handlelogin@example.com');
      expect(repository.currentUser, isNotNull);
    });

    test('sign out resets current user to null', () async {
      await repository.signUpWithEmailAndPassword(
        email: 'logout@example.com',
        password: 'password123',
        displayName: 'Logout User',
        username: 'logout_user',
      );

      expect(repository.currentUser, isNotNull);
      await repository.signOut();
      expect(repository.currentUser, isNull);
    });
  });
}
