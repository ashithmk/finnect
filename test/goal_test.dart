import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finnect/features/goals/domain/goal_model.dart';
import 'package:finnect/features/goals/data/goal_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalModel Unit Tests', () {
    test('GoalModel toMap and fromMap conversion works correctly', () {
      final goal = GoalModel(
        id: 'goal_101',
        title: 'Gaming Console',
        targetPrice: 45000.0,
        description: 'Next gen console',
        createdAt: DateTime(2026, 7, 28),
      );

      final map = goal.toMap();
      expect(map['id'], 'goal_101');
      expect(map['title'], 'Gaming Console');
      expect(map['targetPrice'], 45000.0);

      final restored = GoalModel.fromMap(map);
      expect(restored.id, goal.id);
      expect(restored.title, goal.title);
      expect(restored.targetPrice, goal.targetPrice);
    });
  });

  group('GoalRepository Integration Tests', () {
    late LocalGoalRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalGoalRepository();
    });

    test('addGoal and getGoals persists goal locally', () async {
      final goal = GoalModel(
        id: 'goal_test_1',
        title: 'Smart Watch',
        targetPrice: 15000.0,
        createdAt: DateTime.now(),
      );

      await repository.addGoal(goal);
      final list = await repository.getGoals().first;
      expect(list.any((g) => g.title == 'Smart Watch'), isTrue);
    });

    test('deleteGoal removes goal locally', () async {
      final goal = GoalModel(
        id: 'goal_to_delete',
        title: 'Camera',
        targetPrice: 60000.0,
        createdAt: DateTime.now(),
      );

      await repository.addGoal(goal);
      await repository.deleteGoal('goal_to_delete');
      final list = await repository.getGoals().first;
      expect(list.any((g) => g.id == 'goal_to_delete'), isFalse);
    });
  });
}
