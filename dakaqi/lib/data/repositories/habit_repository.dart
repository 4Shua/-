import 'package:dakaqi/core/notifications/reminder_service.dart';
import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/enums.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:dakaqi/domain/rules/check_in_rules.dart';
import 'package:drift/drift.dart';

class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Stream<List<HabitWithTag>> watchHabitsWithTags() {
    final query = _db.select(_db.habits).join([
      leftOuterJoin(_db.tags, _db.tags.id.equalsExp(_db.habits.tagId)),
    ])..orderBy([OrderingTerm.asc(_db.habits.sortOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return HabitWithTag(
          habit: row.readTable(_db.habits),
          tag: row.readTableOrNull(_db.tags),
        );
      }).toList();
    });
  }

  Stream<List<Tag>> watchTags() {
    return (_db.select(_db.tags)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<int> watchTodayCount(int habitId) {
    final date = AppDateUtils.formatDate(AppDateUtils.today());
    final query = _db.select(_db.checkInRecords)
      ..where(
        (t) => t.habitId.equals(habitId) & t.date.equals(date),
      );

    return query.watchSingleOrNull().map((record) => record?.count ?? 0);
  }

  Stream<Map<String, int>> watchCheckInMap(
    int habitId, {
    int monthsBack = 6,
  }) {
    final today = AppDateUtils.today();
    final start = AppDateUtils.monthsAgo(monthsBack - 1);
    final startKey = AppDateUtils.formatDate(start);
    final endKey = AppDateUtils.formatDate(today);

    final query = _db.select(_db.checkInRecords)
      ..where(
        (t) =>
            t.habitId.equals(habitId) &
            t.date.isBiggerOrEqualValue(startKey) &
            t.date.isSmallerOrEqualValue(endKey),
      );

    return query.watch().map((records) {
      return {for (final r in records) r.date: r.count};
    });
  }

  Stream<Map<String, int>> watchAllCheckIns(int habitId) {
    final query = _db.select(_db.checkInRecords)
      ..where((t) => t.habitId.equals(habitId));

    return query.watch().map((records) {
      return {for (final r in records) r.date: r.count};
    });
  }

  Future<int> tapCheckIn(Habit habit) async {
    final now = DateTime.now();
    if (!CheckInRules.canCheckInOn(habit, now)) {
      return -1;
    }
    if (!CheckInRules.canCheckInNow(habit, now)) {
      return -2;
    }

    final date = AppDateUtils.formatDate(AppDateUtils.today());
    final n = habit.timesPerDay;

    return _db.transaction(() async {
      final existing = await (_db.select(_db.checkInRecords)
            ..where(
              (t) => t.habitId.equals(habit.id) & t.date.equals(date),
            ))
          .getSingleOrNull();

      final current = existing?.count ?? 0;
      final next = current >= n ? 0 : current + 1;

      if (existing == null) {
        await _db.into(_db.checkInRecords).insert(
              CheckInRecordsCompanion.insert(
                habitId: habit.id,
                date: date,
                count: Value(next),
              ),
            );
      } else {
        await (_db.update(_db.checkInRecords)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          CheckInRecordsCompanion(
            count: Value(next),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return next;
    });
  }

  Future<Habit?> getHabit(int id) {
    return (_db.select(_db.habits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> maxSortOrder() async {
    final rows = await _db.select(_db.habits).get();
    if (rows.isEmpty) return 0;
    return rows.map((h) => h.sortOrder).reduce((a, b) => a > b ? a : b);
  }

  Future<int> createHabit({
    required String name,
    String? description,
    required String iconKey,
    required String colorHex,
    required int timesPerDay,
    required int monthlyTarget,
    required EffectiveDayMode effectiveDayMode,
    int? tagId,
    bool reminderEnabled = false,
    String? reminderTime,
    int? checkInWindowStartMinutes,
    int? checkInWindowEndMinutes,
  }) async {
    final sortOrder = (await maxSortOrder()) + 1;
    final id = await _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            name: name,
            description: Value(description),
            iconKey: iconKey,
            colorHex: colorHex,
            timesPerDay: Value(timesPerDay.clamp(1, 20)),
            monthlyTarget: Value(monthlyTarget.clamp(1, 99)),
            effectiveDayMode: effectiveDayMode,
            tagId: Value(tagId),
            sortOrder: Value(sortOrder),
            reminderEnabled: Value(reminderEnabled),
            reminderTime: Value(reminderTime),
            checkInWindowStartMinutes: Value(checkInWindowStartMinutes),
            checkInWindowEndMinutes: Value(checkInWindowEndMinutes),
          ),
        );
    final habit = await getHabit(id);
    if (habit != null) {
      await ReminderService.rescheduleHabit(habit);
    }
    return id;
  }

  Future<void> updateHabit({
    required int id,
    required String name,
    String? description,
    required String iconKey,
    required String colorHex,
    required int timesPerDay,
    required int monthlyTarget,
    required EffectiveDayMode effectiveDayMode,
    int? tagId,
    bool clearTag = false,
    bool reminderEnabled = false,
    String? reminderTime,
    int? checkInWindowStartMinutes,
    int? checkInWindowEndMinutes,
  }) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
          HabitsCompanion(
            name: Value(name),
            description: Value(description),
            iconKey: Value(iconKey),
            colorHex: Value(colorHex),
            timesPerDay: Value(timesPerDay.clamp(1, 20)),
            monthlyTarget: Value(monthlyTarget.clamp(1, 99)),
            effectiveDayMode: Value(effectiveDayMode),
            tagId: clearTag ? const Value(null) : Value(tagId),
            reminderEnabled: Value(reminderEnabled),
            reminderTime: Value(reminderTime),
            checkInWindowStartMinutes: Value(checkInWindowStartMinutes),
            checkInWindowEndMinutes: Value(checkInWindowEndMinutes),
          ),
        );
    final habit = await getHabit(id);
    if (habit != null) {
      await ReminderService.rescheduleHabit(habit);
    }
  }

  Future<void> rescheduleAllReminders() => ReminderService.rescheduleAll(this);

  Future<Tag?> getTag(int id) {
    return (_db.select(_db.tags)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int?> findTagIdByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final tag = await (_db.select(_db.tags)
          ..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
    return tag?.id;
  }

  Future<int> createTag(String name) {
    return _db.into(_db.tags).insert(
          TagsCompanion.insert(name: name.trim()),
        );
  }

  Future<int?> resolveTagId(String? tagName) async {
    final trimmed = tagName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final existing = await findTagIdByName(trimmed);
    if (existing != null) return existing;
    return createTag(trimmed);
  }

  Future<void> deleteHabit(int id) async {
    await ReminderService.cancelHabit(id);
    await (_db.delete(_db.checkInRecords)
          ..where((t) => t.habitId.equals(id)))
        .go();
    await (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
  }
}
