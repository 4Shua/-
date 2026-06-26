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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(habits, habits.reminderEnabled);
            await m.addColumn(habits, habits.reminderTime);
            await m.addColumn(habits, habits.checkInWindowStartMinutes);
            await m.addColumn(habits, habits.checkInWindowEndMinutes);
          }
          if (from < 3) {
            await _migrateToV3(m);
          }
          if (from < 4) {
            await _migrateToV4();
          }
        },
      );

  Future<void> _migrateToV3(Migrator m) async {
    await customStatement('''
CREATE TABLE habits_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon_key TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  times_per_day INTEGER NOT NULL DEFAULT 1,
  monthly_target INTEGER NOT NULL DEFAULT 20,
  effective_day_category INTEGER NOT NULL,
  effective_day_variant INTEGER NOT NULL DEFAULT 0,
  tag_id INTEGER REFERENCES tags (id),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
  reminder_enabled INTEGER NOT NULL DEFAULT 0 CHECK (reminder_enabled IN (0, 1)),
  reminder_time TEXT,
  check_in_window_start_minutes INTEGER,
  check_in_window_end_minutes INTEGER
);
''');
    await customStatement('''
INSERT INTO habits_new (
  id, name, description, icon_key, color_hex, times_per_day, monthly_target,
  effective_day_category, effective_day_variant, tag_id, sort_order, created_at,
  reminder_enabled, reminder_time, check_in_window_start_minutes, check_in_window_end_minutes
)
SELECT
  id, name, description, icon_key, color_hex, completions_per_period, 20,
  CASE active_days_type
    WHEN 0 THEN 0
    WHEN 1 THEN 1
    WHEN 2 THEN 1
    ELSE 0
  END,
  CASE active_days_type WHEN 2 THEN 1 ELSE 0 END,
  tag_id, sort_order, created_at,
  reminder_enabled, reminder_time, check_in_window_start_minutes, check_in_window_end_minutes
FROM habits;
''');
    await customStatement('DROP TABLE habits;');
    await customStatement('ALTER TABLE habits_new RENAME TO habits;');
  }

  Future<void> _migrateToV4() async {
    await customStatement('''
CREATE TABLE habits_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon_key TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  times_per_day INTEGER NOT NULL DEFAULT 1,
  monthly_target INTEGER NOT NULL DEFAULT 20,
  effective_day_mode INTEGER NOT NULL DEFAULT 2,
  tag_id INTEGER REFERENCES tags (id),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
  reminder_enabled INTEGER NOT NULL DEFAULT 0 CHECK (reminder_enabled IN (0, 1)),
  reminder_time TEXT,
  check_in_window_start_minutes INTEGER,
  check_in_window_end_minutes INTEGER
);
''');
    await customStatement('''
INSERT INTO habits_new (
  id, name, description, icon_key, color_hex, times_per_day, monthly_target,
  effective_day_mode, tag_id, sort_order, created_at,
  reminder_enabled, reminder_time, check_in_window_start_minutes, check_in_window_end_minutes
)
SELECT
  id, name, description, icon_key, color_hex, times_per_day, monthly_target,
  CASE
    WHEN effective_day_category = 0 THEN 2
    WHEN effective_day_variant = 1 THEN 1
    ELSE 0
  END,
  tag_id, sort_order, created_at,
  reminder_enabled, reminder_time, check_in_window_start_minutes, check_in_window_end_minutes
FROM habits;
''');
    await customStatement('DROP TABLE habits;');
    await customStatement('ALTER TABLE habits_new RENAME TO habits;');
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dakaqi');
  }
}
