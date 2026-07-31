import 'package:flutter/foundation.dart';

/// Status of a friendship connection.
enum FriendshipStatus {
  pending,
  accepted,
  rejected,
}

/// Friendship model representing a link between two users.
@immutable
class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;

  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FriendshipModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return FriendshipModel(
      id: docId ?? map['id'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FriendshipModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    FriendshipStatus? status,
    DateTime? createdAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents a friend user card data in UI.
@immutable
class UserFriendInfo {
  final String uid;
  final String displayName;
  final String username;
  final String? photoUrl;
  final FriendshipStatus? status; // null if not requested, or current friendship status
  final String? requesterId; // ID of the user who sent the friend request

  const UserFriendInfo({
    required this.uid,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.status,
    this.requesterId,
  });

  String get formattedUsername {
    final clean = username.trim().replaceAll('@', '');
    return clean.isNotEmpty ? '@$clean' : '@user';
  }
}

/// Represents a Group created by users.
@immutable
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return GroupModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Group',
      description: map['description'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      memberIds: (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Individual split share assigned to a user in a group bill.
@immutable
class GroupBillShare {
  final String userId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;

  const GroupBillShare({
    required this.userId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'isSettled': isSettled,
      'settledAt': settledAt?.toIso8601String(),
    };
  }

  factory GroupBillShare.fromMap(Map<String, dynamic> map) {
    return GroupBillShare(
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isSettled: map['isSettled'] as bool? ?? false,
      settledAt: map['settledAt'] != null ? DateTime.tryParse(map['settledAt'] as String) : null,
    );
  }

  GroupBillShare copyWith({
    String? userId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return GroupBillShare(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }
}

/// Group bill model for split expenses.
@immutable
class GroupBillModel {
  final String id;
  final String groupId;
  final String title;
  final double totalAmount;
  final String paidByUserId;
  final List<GroupBillShare> shares;
  final DateTime createdAt;

  const GroupBillModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidByUserId,
    required this.shares,
    required this.createdAt,
  });

  /// Check if a specific user's share is settled
  bool isUserShareSettled(String userId) {
    final share = shares.firstWhere(
      (s) => s.userId == userId,
      orElse: () => const GroupBillShare(userId: '', amount: 0, isSettled: true),
    );
    return share.isSettled;
  }

  /// Get specific user's share amount
  double getUserShareAmount(String userId) {
    final share = shares.firstWhere(
      (s) => s.userId == userId,
      orElse: () => const GroupBillShare(userId: '', amount: 0),
    );
    return share.amount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'totalAmount': totalAmount,
      'paidByUserId': paidByUserId,
      'shares': shares.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupBillModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return GroupBillModel(
      id: docId ?? map['id'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      title: map['title'] as String? ?? 'Bill',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidByUserId: map['paidByUserId'] as String? ?? '',
      shares: (map['shares'] as List<dynamic>?)
              ?.map((s) => GroupBillShare.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  GroupBillModel copyWith({
    String? id,
    String? groupId,
    String? title,
    double? totalAmount,
    String? paidByUserId,
    List<GroupBillShare>? shares,
    DateTime? createdAt,
  }) {
    return GroupBillModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      shares: shares ?? this.shares,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
