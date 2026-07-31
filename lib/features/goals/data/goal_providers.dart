import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/goal_model.dart';
import 'goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return LocalGoalRepository();
});

final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoals();
});

class GoalController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> addGoal(GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.addGoal(goal);
    });
    return !state.hasError;
  }

  Future<bool> updateGoal(GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateGoal(goal);
    });
    return !state.hasError;
  }

  Future<bool> deleteGoal(String id) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.deleteGoal(id);
    });
    return !state.hasError;
  }
}

final goalControllerProvider =
    NotifierProvider<GoalController, AsyncValue<void>>(GoalController.new);
