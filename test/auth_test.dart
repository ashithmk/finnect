import 'package:flutter_test/flutter_test.dart';
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
        username: 'newuser',
      );

      expect(user.email, 'newuser@example.com');
      expect(user.displayName, 'New User');
      expect(repository.currentUser?.email, 'newuser@example.com');
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
