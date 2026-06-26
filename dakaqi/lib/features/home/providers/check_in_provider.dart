import 'package:dakaqi/core/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todayCheckInProvider = StreamProvider.family<int, int>((ref, habitId) {
  ref.watch(appBootstrapProvider);
  return ref.watch(habitRepositoryProvider).watchTodayCount(habitId);
});

final heatmapDataProvider =
    StreamProvider.family<Map<String, int>, int>((ref, habitId) {
  ref.watch(appBootstrapProvider);
  return ref.watch(habitRepositoryProvider).watchCheckInMap(habitId);
});

final allCheckInsProvider =
    StreamProvider.family<Map<String, int>, int>((ref, habitId) {
  ref.watch(appBootstrapProvider);
  return ref.watch(habitRepositoryProvider).watchAllCheckIns(habitId);
});

final checkInActionProvider = Provider((ref) {
  return CheckInAction(ref);
});

final deleteHabitActionProvider = Provider((ref) {
  return DeleteHabitAction(ref);
});

class CheckInAction {
  CheckInAction(this._ref);

  final Ref _ref;

  Future<int> tap(int habitId) async {
    final repo = _ref.read(habitRepositoryProvider);
    final habits = await repo.watchHabitsWithTags().first;
    final habit = habits.firstWhere((h) => h.habit.id == habitId).habit;
    return repo.tapCheckIn(habit);
  }
}

class DeleteHabitAction {
  DeleteHabitAction(this._ref);

  final Ref _ref;

  Future<void> call(int habitId) async {
    await _ref.read(habitRepositoryProvider).deleteHabit(habitId);
  }
}
