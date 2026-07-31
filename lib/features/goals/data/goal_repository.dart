import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/goal_model.dart';

abstract class GoalRepository {
  Stream<List<GoalModel>> getGoals();
  Future<void> addGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
}

class LocalGoalRepository implements GoalRepository {
  static const String _storageKey = 'user_goals_v1';
  final StreamController<List<GoalModel>> _controller =
      StreamController<List<GoalModel>>.broadcast();
  final List<GoalModel> _goals = [];
  bool _initialized = false;

  LocalGoalRepository() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _goals.clear();
        for (final item in decoded) {
          _goals.add(GoalModel.fromMap(item as Map<String, dynamic>));
        }
      } catch (_) {
        _seedInitialGoals();
      }
    } else {
      _seedInitialGoals();
    }

    _initialized = true;
    _emit();
  }

  void _seedInitialGoals() {
    final now = DateTime.now();
    _goals.addAll([
      GoalModel(
        id: 'goal_seed_1',
        title: 'New Smartphone',
        targetPrice: 25000.0,
        description: 'Next gen flagship camera smartphone',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      GoalModel(
        id: 'goal_seed_2',
        title: 'Noise Cancelling Headphones',
        targetPrice: 8000.0,
        description: 'Wireless premium audio headset',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_goals.map((g) => g.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_goals));
  }

  @override
  Stream<List<GoalModel>> getGoals() {
    _init();
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    await _init();
    final newId = goal.id.isNotEmpty
        ? goal.id
        : 'goal_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = goal.copyWith(id: newId);
    _goals.insert(0, toSave);
    await _saveToPrefs();
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    await _init();
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await _saveToPrefs();
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _init();
    _goals.removeWhere((g) => g.id == id);
    await _saveToPrefs();
  }
}
