import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/data/repositories/habit_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  return HabitRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
Future<void> appBootstrap(Ref ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  await repo.rescheduleAllReminders();
}
