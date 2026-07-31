import 'package:flutter/foundation.dart';

/// Representation of an authenticated user profile in Finnect.
@immutable
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final DateTime createdAt;
  final String currency;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username = '',
    this.photoUrl,
    required this.createdAt,
    this.currency = 'INR',
  });

  /// Returns formatted username with @ prefix
  String get formattedUsername {
    final clean = username.trim().replaceAll('@', '');
    if (clean.isNotEmpty) return '@$clean';
    if (email.isNotEmpty) {
      final namePart = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      if (namePart.isNotEmpty) return '@$namePart';
    }
    return '@user_${uid.substring(0, uid.length > 6 ? 6 : uid.length)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username.isNotEmpty ? username : formattedUsername.substring(1),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'currency': currency,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    final emailVal = (map['email'] as String? ??
            map['emailAddress'] as String? ??
            map['email_address'] as String? ??
            '')
        .trim();

    final uidVal = (map['uid'] as String? ??
            map['userId'] as String? ??
            map['user_id'] as String? ??
            docId ??
            '')
        .trim();

    final rawUsername = (map['username'] as String? ??
            map['userName'] as String? ??
            map['user_name'] as String? ??
            map['handle'] as String? ??
            '')
        .trim();

    final rawDisplay = (map['displayName'] as String? ??
            map['display_name'] as String? ??
            map['name'] as String? ??
            map['fullName'] as String? ??
            '')
        .trim();

    String derivedUsername = rawUsername.replaceAll('@', '');
    if (derivedUsername.isEmpty && emailVal.isNotEmpty) {
      derivedUsername = emailVal.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    }
    if (derivedUsername.isEmpty && uidVal.isNotEmpty) {
      derivedUsername = 'user_${uidVal.substring(0, uidVal.length > 6 ? 6 : uidVal.length)}';
    }

    final displayNameVal = rawDisplay.isNotEmpty
        ? rawDisplay
        : (derivedUsername.isNotEmpty ? derivedUsername : 'User');

    return AppUser(
      uid: uidVal,
      email: emailVal,
      displayName: displayNameVal,
      username: derivedUsername,
      photoUrl: map['photoUrl'] as String? ??
          map['photoURL'] as String? ??
          map['avatar'] as String? ??
          map['avatarUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      currency: map['currency'] as String? ?? 'INR',
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    DateTime? createdAt,
    String? currency,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.username == username &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return Object.hash(uid, email, displayName, username, photoUrl, createdAt, currency);
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, username: $username, currency: $currency)';
  }
}
