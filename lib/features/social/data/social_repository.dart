import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/social_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';

abstract class SocialRepository {
  /// Search users by username, display name, or email
  Future<List<UserFriendInfo>> searchUsers(String currentUserId, String query);

  /// Stream of user's accepted friends
  Stream<List<UserFriendInfo>> getFriends(String currentUserId);

  /// Stream of incoming pending friend requests for current user
  Stream<List<UserFriendInfo>> getPendingFriendRequests(String currentUserId);

  /// Stream of sent/outgoing pending friend requests from current user
  Stream<List<UserFriendInfo>> getSentFriendRequests(String currentUserId);

  /// Send friend request to target user (status: pending)
  Future<void> sendFriendRequest(String currentUserId, String targetUserId);

  /// Accept friend request (status: accepted)
  Future<void> acceptFriendRequest(String currentUserId, String friendId);

  /// Reject/decline friend request
  Future<void> rejectFriendRequest(String currentUserId, String friendId);

  /// Cancel outgoing friend request
  Future<void> cancelFriendRequest(String currentUserId, String friendId);

  /// Create a new group
  Future<GroupModel> createGroup(GroupModel group);

  /// Stream of groups the current user belongs to
  Stream<List<GroupModel>> getUserGroups(String currentUserId);

  /// Stream of single group details
  Stream<GroupModel?> getGroupById(String groupId);

  /// Add a split bill to a group
  Future<void> addBillToGroup(GroupBillModel bill);

  /// Stream of bills for a given group
  Stream<List<GroupBillModel>> getGroupBills(String groupId);

  /// Settle user share in a group bill. Returns the settled share details if successful.
  Future<GroupBillShare?> settleBillShare({
    required String groupId,
    required String billId,
    required String userId,
  });

  /// Helper to get User Profiles for group members
  Future<List<UserFriendInfo>> getGroupMembers(List<String> userIds);
}

/// Firebase Implementation of [SocialRepository].
class FirebaseSocialRepository implements SocialRepository {
  final FirebaseFirestore _firestore;

  FirebaseSocialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<UserFriendInfo>> searchUsers(String currentUserId, String query) async {
    final cleanQuery = query.trim().toLowerCase().replaceAll('@', '');
    if (cleanQuery.isEmpty) return [];

    debugPrint('[FirebaseSearch] Searching for: "$cleanQuery", currentUserId: "$currentUserId"');

    final List<UserFriendInfo> results = [];
    final Map<String, AppUser> matchedUsersMap = {};

    // 1. Search Firestore collection
    try {
      final snapshot = await _firestore.collection('users').limit(100).get();
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final u = AppUser.fromMap(data, docId: doc.id);
        final uid = u.uid.isNotEmpty ? u.uid : doc.id;

        final uName = u.username.toLowerCase().replaceAll('@', '');
        final dName = u.displayName.toLowerCase();
        final eName = u.email.toLowerCase();

        if (uName.contains(cleanQuery) || dName.contains(cleanQuery) || eName.contains(cleanQuery)) {
          if (uid.isNotEmpty) {
            matchedUsersMap[uid] = u.copyWith(uid: uid);
          }
        }
      }
    } catch (e) {
      debugPrint('[FirebaseSearch] Firestore collection search notice: $e');
    }

    // 2. Only if Firestore returned no matches, fallback to local mock DB
    if (matchedUsersMap.isEmpty) {
      for (final u in LocalMockAuthRepository.sharedMockUsersDb.values) {
        final uName = u.username.toLowerCase().replaceAll('@', '');
        final dName = u.displayName.toLowerCase();
        final eName = u.email.toLowerCase();

        if (uName.contains(cleanQuery) || dName.contains(cleanQuery) || eName.contains(cleanQuery)) {
          matchedUsersMap[u.uid] = u;
        }
      }
    }

    // 3. Get current friendships to attach status
    final Map<String, FriendshipModel> friendshipMap = {};
    try {
      final friendSnap1 = await _firestore
          .collection('friendships')
          .where('requesterId', isEqualTo: currentUserId)
          .get();
      final friendSnap2 = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      for (final doc in friendSnap1.docs) {
        final f = FriendshipModel.fromMap(doc.data(), docId: doc.id);
        friendshipMap[f.receiverId] = f;
      }
      for (final doc in friendSnap2.docs) {
        final f = FriendshipModel.fromMap(doc.data(), docId: doc.id);
        friendshipMap[f.requesterId] = f;
      }
    } catch (e) {
      debugPrint('[FirebaseSearch] Friendships query notice: $e');
    }

    // 4. Construct results list (excluding self and deduplicating by lowercased username)
    final Set<String> seenUsernames = {};

    for (final user in matchedUsersMap.values) {
      if (user.uid == currentUserId) continue;
      final uKey = user.username.trim().replaceAll('@', '').toLowerCase();
      if (uKey.isNotEmpty && seenUsernames.contains(uKey)) continue;
      if (uKey.isNotEmpty) seenUsernames.add(uKey);

      final existingF = friendshipMap[user.uid];
      final displayUsername = user.username.isNotEmpty
          ? user.username
          : user.formattedUsername.replaceAll('@', '');

      results.add(
        UserFriendInfo(
          uid: user.uid,
          displayName: user.displayName.isNotEmpty ? user.displayName : 'User',
          username: displayUsername,
          photoUrl: user.photoUrl,
          status: existingF?.status,
          requesterId: existingF?.requesterId,
        ),
      );
    }

    debugPrint('[FirebaseSearch] Matching search results count: ${results.length}');
    return results;
  }

  @override
  Stream<List<UserFriendInfo>> getFriends(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value([]);

    final controller = StreamController<List<UserFriendInfo>>.broadcast();

    _firestore
        .collection('friendships')
        .where('status', isEqualTo: FriendshipStatus.accepted.name)
        .snapshots()
        .listen((snapshot) async {
      final List<String> friendUids = [];

      for (final doc in snapshot.docs) {
        final f = FriendshipModel.fromMap(doc.data(), docId: doc.id);
        if (f.requesterId == currentUserId) {
          friendUids.add(f.receiverId);
        } else if (f.receiverId == currentUserId) {
          friendUids.add(f.requesterId);
        }
      }

      if (friendUids.isEmpty) {
        controller.add([]);
        return;
      }

      final friendInfos = await getGroupMembers(friendUids);
      controller.add(friendInfos.map((f) => UserFriendInfo(
        uid: f.uid,
        displayName: f.displayName,
        username: f.username,
        photoUrl: f.photoUrl,
        status: FriendshipStatus.accepted,
      )).toList());
    });

    return controller.stream;
  }

  @override
  Stream<List<UserFriendInfo>> getPendingFriendRequests(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('friendships')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<String> requesterUids = [];
      for (final doc in snapshot.docs) {
        final f = FriendshipModel.fromMap(doc.data(), docId: doc.id);
        requesterUids.add(f.requesterId);
      }
      if (requesterUids.isEmpty) return [];

      final memberInfos = await getGroupMembers(requesterUids);
      return memberInfos
          .map((m) => UserFriendInfo(
                uid: m.uid,
                displayName: m.displayName,
                username: m.username,
                photoUrl: m.photoUrl,
                status: FriendshipStatus.pending,
                requesterId: m.uid,
              ))
          .toList();
    });
  }

  @override
  Stream<List<UserFriendInfo>> getSentFriendRequests(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: currentUserId)
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<String> receiverUids = [];
      for (final doc in snapshot.docs) {
        final f = FriendshipModel.fromMap(doc.data(), docId: doc.id);
        receiverUids.add(f.receiverId);
      }
      if (receiverUids.isEmpty) return [];

      final memberInfos = await getGroupMembers(receiverUids);
      return memberInfos
          .map((m) => UserFriendInfo(
                uid: m.uid,
                displayName: m.displayName,
                username: m.username,
                photoUrl: m.photoUrl,
                status: FriendshipStatus.pending,
                requesterId: currentUserId,
              ))
          .toList();
    });
  }

  @override
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    final docId = '${currentUserId}_$targetUserId';
    await _firestore.collection('friendships').doc(docId).set({
      'id': docId,
      'requesterId': currentUserId,
      'receiverId': targetUserId,
      'status': FriendshipStatus.pending.name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> acceptFriendRequest(String currentUserId, String friendId) async {
    final docId1 = '${friendId}_$currentUserId';
    final docId2 = '${currentUserId}_$friendId';

    final doc1 = await _firestore.collection('friendships').doc(docId1).get();
    if (doc1.exists) {
      await doc1.reference.update({'status': FriendshipStatus.accepted.name});
      return;
    }

    final doc2 = await _firestore.collection('friendships').doc(docId2).get();
    if (doc2.exists) {
      await doc2.reference.update({'status': FriendshipStatus.accepted.name});
      return;
    }

    await _firestore.collection('friendships').doc(docId1).set({
      'id': docId1,
      'requesterId': friendId,
      'receiverId': currentUserId,
      'status': FriendshipStatus.accepted.name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> rejectFriendRequest(String currentUserId, String friendId) async {
    final docId1 = '${friendId}_$currentUserId';
    final docId2 = '${currentUserId}_$friendId';
    try {
      await _firestore.collection('friendships').doc(docId1).delete();
    } catch (_) {}
    try {
      await _firestore.collection('friendships').doc(docId2).delete();
    } catch (_) {}
  }

  @override
  Future<void> cancelFriendRequest(String currentUserId, String friendId) async {
    await rejectFriendRequest(currentUserId, friendId);
  }

  @override
  Future<GroupModel> createGroup(GroupModel group) async {
    final ref = _firestore.collection('groups').doc();
    final newGroup = group.copyWith(id: ref.id);
    await ref.set(newGroup.toMap());
    return newGroup;
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    });
  }

  @override
  Stream<GroupModel?> getGroupById(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return GroupModel.fromMap(data, docId: doc.id);
    });
  }

  @override
  Future<void> addBillToGroup(GroupBillModel bill) async {
    final ref = _firestore.collection('groups').doc(bill.groupId).collection('bills').doc();
    final newBill = bill.copyWith(id: ref.id);
    await ref.set(newBill.toMap());
  }

  @override
  Stream<List<GroupBillModel>> getGroupBills(String groupId) {
    if (groupId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('bills')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupBillModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    });
  }

  @override
  Future<GroupBillShare?> settleBillShare({
    required String groupId,
    required String billId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('bills').doc(billId);
    final doc = await docRef.get();
    final docData = doc.data();
    if (docData == null) return null;

    final bill = GroupBillModel.fromMap(docData, docId: doc.id);
    GroupBillShare? targetShare;

    final updatedShares = bill.shares.map((share) {
      if (share.userId == userId) {
        final updated = share.copyWith(
          isSettled: true,
          settledAt: DateTime.now(),
        );
        targetShare = updated;
        return updated;
      }
      return share;
    }).toList();

    await docRef.update({
      'shares': updatedShares.map((s) => s.toMap()).toList(),
    });

    return targetShare;
  }

  @override
  Future<List<UserFriendInfo>> getGroupMembers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final List<UserFriendInfo> members = [];

    for (final uid in userIds) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final user = AppUser.fromMap(doc.data()!);
          members.add(
            UserFriendInfo(
              uid: user.uid,
              displayName: user.displayName,
              username: user.username,
              photoUrl: user.photoUrl,
            ),
          );
        } else {
          members.add(
            UserFriendInfo(
              uid: uid,
              displayName: 'User',
              username: 'user_${uid.substring(0, uid.length > 5 ? 5 : uid.length)}',
            ),
          );
        }
      } catch (e) {
        members.add(
          UserFriendInfo(
            uid: uid,
            displayName: 'Friend',
            username: 'friend',
          ),
        );
      }
    }
    return members;
  }
}

/// Fallback Mock Implementation of [SocialRepository].
class LocalMockSocialRepository implements SocialRepository {
  final List<FriendshipModel> _friendships = [
    FriendshipModel(
      id: 'f1',
      requesterId: 'demo_uid_1',
      receiverId: 'user_alex',
      status: FriendshipStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    FriendshipModel(
      id: 'f2',
      requesterId: 'demo_uid_1',
      receiverId: 'user_sam',
      status: FriendshipStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final List<GroupModel> _groups = [
    GroupModel(
      id: 'group_goa',
      name: 'Goa Trip 🏖️',
      description: 'Expenses for summer vacation in Goa',
      createdBy: 'demo_uid_1',
      memberIds: ['demo_uid_1', 'user_alex', 'user_sam'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final Map<String, List<GroupBillModel>> _groupBills = {};

  final StreamController<List<GroupModel>> _groupsController =
      StreamController<List<GroupModel>>.broadcast();
  final StreamController<List<UserFriendInfo>> _friendsController =
      StreamController<List<UserFriendInfo>>.broadcast();
  final StreamController<List<UserFriendInfo>> _pendingRequestsController =
      StreamController<List<UserFriendInfo>>.broadcast();
  final StreamController<List<UserFriendInfo>> _sentRequestsController =
      StreamController<List<UserFriendInfo>>.broadcast();
  final Map<String, StreamController<List<GroupBillModel>>> _billControllers = {};

  LocalMockSocialRepository() {
    _notifyFriends('demo_uid_1');
    _notifyGroups('demo_uid_1');
    _notifyPendingRequests('demo_uid_1');
    _notifySentRequests('demo_uid_1');
  }

  void _notifyFriends(String userId) {
    final currentFriends = _friendships
        .where((f) =>
            (f.requesterId == userId || f.receiverId == userId) &&
            f.status == FriendshipStatus.accepted)
        .map((f) {
      final friendId = f.requesterId == userId ? f.receiverId : f.requesterId;
      final user = LocalMockAuthRepository.sharedMockUsersDb[friendId] ??
          AppUser(
            uid: friendId,
            email: '$friendId@finnect.com',
            displayName: friendId,
            username: friendId,
            createdAt: DateTime.now(),
          );
      return UserFriendInfo(
        uid: user.uid,
        displayName: user.displayName,
        username: user.username,
        photoUrl: user.photoUrl,
        status: FriendshipStatus.accepted,
      );
    }).toList();

    _friendsController.add(currentFriends);
  }

  void _notifyPendingRequests(String userId) {
    final pending = _friendships
        .where((f) => f.receiverId == userId && f.status == FriendshipStatus.pending)
        .map((f) {
      final requester = LocalMockAuthRepository.sharedMockUsersDb[f.requesterId] ??
          AppUser(
            uid: f.requesterId,
            email: '${f.requesterId}@finnect.com',
            displayName: f.requesterId,
            username: f.requesterId,
            createdAt: DateTime.now(),
          );
      return UserFriendInfo(
        uid: requester.uid,
        displayName: requester.displayName,
        username: requester.username,
        photoUrl: requester.photoUrl,
        status: FriendshipStatus.pending,
        requesterId: requester.uid,
      );
    }).toList();

    _pendingRequestsController.add(pending);
  }

  void _notifySentRequests(String userId) {
    final sent = _friendships
        .where((f) => f.requesterId == userId && f.status == FriendshipStatus.pending)
        .map((f) {
      final receiver = LocalMockAuthRepository.sharedMockUsersDb[f.receiverId] ??
          AppUser(
            uid: f.receiverId,
            email: '${f.receiverId}@finnect.com',
            displayName: f.receiverId,
            username: f.receiverId,
            createdAt: DateTime.now(),
          );
      return UserFriendInfo(
        uid: receiver.uid,
        displayName: receiver.displayName,
        username: receiver.username,
        photoUrl: receiver.photoUrl,
        status: FriendshipStatus.pending,
        requesterId: userId,
      );
    }).toList();

    _sentRequestsController.add(sent);
  }

  void _notifyGroups(String userId) {
    final userGroups = _groups.where((g) => g.memberIds.contains(userId)).toList();
    _groupsController.add(List.unmodifiable(userGroups));
  }

  @override
  Future<List<UserFriendInfo>> searchUsers(String currentUserId, String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final cleanQuery = query.trim().toLowerCase().replaceAll('@', '');

    final List<UserFriendInfo> results = [];

    final Set<String> seenUsernames = {};

    for (final user in LocalMockAuthRepository.sharedMockUsersDb.values) {
      if (user.uid == currentUserId) continue;

      final uName = user.username.toLowerCase().replaceAll('@', '');
      final dName = user.displayName.toLowerCase();
      final eName = user.email.toLowerCase();

      if (cleanQuery.isEmpty ||
          uName.contains(cleanQuery) ||
          dName.contains(cleanQuery) ||
          eName.contains(cleanQuery)) {
        if (uName.isNotEmpty && seenUsernames.contains(uName)) continue;
        if (uName.isNotEmpty) seenUsernames.add(uName);

        FriendshipStatus? status;
        String? requesterId;
        for (final f in _friendships) {
          if ((f.requesterId == currentUserId && f.receiverId == user.uid) ||
              (f.receiverId == currentUserId && f.requesterId == user.uid)) {
            status = f.status;
            requesterId = f.requesterId;
            break;
          }
        }

        results.add(
          UserFriendInfo(
            uid: user.uid,
            displayName: user.displayName,
            username: user.username,
            photoUrl: user.photoUrl,
            status: status,
            requesterId: requesterId,
          ),
        );
      }
    }
    return results;
  }

  @override
  Stream<List<UserFriendInfo>> getFriends(String currentUserId) {
    Future.microtask(() => _notifyFriends(currentUserId));
    return _friendsController.stream;
  }

  @override
  Stream<List<UserFriendInfo>> getPendingFriendRequests(String currentUserId) {
    Future.microtask(() => _notifyPendingRequests(currentUserId));
    return _pendingRequestsController.stream;
  }

  @override
  Stream<List<UserFriendInfo>> getSentFriendRequests(String currentUserId) {
    Future.microtask(() => _notifySentRequests(currentUserId));
    return _sentRequestsController.stream;
  }

  @override
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _friendships.removeWhere((f) =>
        (f.requesterId == currentUserId && f.receiverId == targetUserId) ||
        (f.requesterId == targetUserId && f.receiverId == currentUserId));

    _friendships.add(
      FriendshipModel(
        id: 'f_${DateTime.now().millisecondsSinceEpoch}',
        requesterId: currentUserId,
        receiverId: targetUserId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    _notifyFriends(currentUserId);
    _notifyPendingRequests(targetUserId);
    _notifySentRequests(currentUserId);
  }

  @override
  Future<void> acceptFriendRequest(String currentUserId, String friendId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _friendships.indexWhere((f) =>
        (f.requesterId == friendId && f.receiverId == currentUserId) ||
        (f.requesterId == currentUserId && f.receiverId == friendId));

    if (index != -1) {
      _friendships[index] = _friendships[index].copyWith(status: FriendshipStatus.accepted);
    } else {
      _friendships.add(
        FriendshipModel(
          id: 'f_${DateTime.now().millisecondsSinceEpoch}',
          requesterId: friendId,
          receiverId: currentUserId,
          status: FriendshipStatus.accepted,
          createdAt: DateTime.now(),
        ),
      );
    }
    _notifyFriends(currentUserId);
    _notifyFriends(friendId);
    _notifyPendingRequests(currentUserId);
    _notifySentRequests(currentUserId);
  }

  @override
  Future<void> rejectFriendRequest(String currentUserId, String friendId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _friendships.removeWhere((f) =>
        (f.requesterId == friendId && f.receiverId == currentUserId) ||
        (f.requesterId == currentUserId && f.receiverId == friendId));
    _notifyFriends(currentUserId);
    _notifyPendingRequests(currentUserId);
    _notifySentRequests(currentUserId);
  }

  @override
  Future<void> cancelFriendRequest(String currentUserId, String friendId) async {
    await rejectFriendRequest(currentUserId, friendId);
  }

  @override
  Future<GroupModel> createGroup(GroupModel group) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = group.id.isNotEmpty
        ? group.id
        : 'group_${DateTime.now().millisecondsSinceEpoch}';
    final created = group.copyWith(id: newId);
    _groups.insert(0, created);
    _notifyGroups(group.createdBy);
    return created;
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String currentUserId) {
    Future.microtask(() => _notifyGroups(currentUserId));
    return _groupsController.stream;
  }

  @override
  Stream<GroupModel?> getGroupById(String groupId) {
    return _groupsController.stream.map((groups) {
      final index = groups.indexWhere((g) => g.id == groupId);
      if (index != -1) return groups[index];
      return _groups.firstWhere((g) => g.id == groupId, orElse: () => _groups.first);
    });
  }

  @override
  Future<void> addBillToGroup(GroupBillModel bill) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = bill.id.isNotEmpty
        ? bill.id
        : 'bill_${DateTime.now().millisecondsSinceEpoch}';
    final newBill = bill.copyWith(id: newId);

    _groupBills.putIfAbsent(bill.groupId, () => []);
    _groupBills[bill.groupId]?.insert(0, newBill);

    if (_billControllers.containsKey(bill.groupId)) {
      _billControllers[bill.groupId]?.add(List.unmodifiable(_groupBills[bill.groupId] ?? []));
    }
  }

  @override
  Stream<List<GroupBillModel>> getGroupBills(String groupId) {
    if (!_billControllers.containsKey(groupId)) {
      _billControllers[groupId] = StreamController<List<GroupBillModel>>.broadcast();
    }

    final list = _groupBills[groupId] ?? [];
    Future.microtask(() => _billControllers[groupId]?.add(List.unmodifiable(list)));
    return _billControllers[groupId]?.stream ?? Stream.value([]);
  }

  @override
  Future<GroupBillShare?> settleBillShare({
    required String groupId,
    required String billId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final bills = _groupBills[groupId];
    if (bills == null) return null;

    final index = bills.indexWhere((b) => b.id == billId);
    if (index == -1) return null;

    final bill = bills[index];
    GroupBillShare? targetShare;

    final updatedShares = bill.shares.map((share) {
      if (share.userId == userId) {
        targetShare = share.copyWith(
          isSettled: true,
          settledAt: DateTime.now(),
        );
        return targetShare!;
      }
      return share;
    }).toList();

    final updatedBill = bill.copyWith(shares: updatedShares);
    bills[index] = updatedBill;

    if (_billControllers.containsKey(groupId)) {
      _billControllers[groupId]?.add(List.unmodifiable(bills));
    }

    return targetShare;
  }

  @override
  Future<List<UserFriendInfo>> getGroupMembers(List<String> userIds) async {
    final List<UserFriendInfo> members = [];
    for (final uid in userIds) {
      if (LocalMockAuthRepository.sharedMockUsersDb.containsKey(uid)) {
        final u = LocalMockAuthRepository.sharedMockUsersDb[uid]!;
        members.add(
          UserFriendInfo(
            uid: u.uid,
            displayName: u.displayName,
            username: u.username,
            photoUrl: u.photoUrl,
          ),
        );
      } else {
        members.add(
          UserFriendInfo(
            uid: uid,
            displayName: 'User',
            username: 'user_${uid.substring(0, uid.length > 5 ? 5 : uid.length)}',
          ),
        );
      }
    }
    return members;
  }
}
