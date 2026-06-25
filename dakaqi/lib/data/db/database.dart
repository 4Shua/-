import 'package:dakaqi/data/db/tables.dart';
import 'package:dakaqi/domain/models/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tags, Habits, CheckInRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(habits, habits.reminderEnabled);
            await m.addColumn(habits, habits.reminderTime);
            await m.addColumn(habits, habits.checkInWindowStartMinutes);
            await m.addColumn(habits, habits.checkInWindowEndMinutes);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dakaqi');
  }
}
