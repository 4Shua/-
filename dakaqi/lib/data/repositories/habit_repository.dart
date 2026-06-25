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

  /// 点击打卡：未满则 +1，已满则重置为 0。
  /// 返回新的 count；若不允许打卡返回 -1。
  Future<int> tapCheckIn(Habit habit) async {
    if (!CheckInRules.canCheckInOn(habit, AppDateUtils.today())) {
      return -1;
    }

    final date = AppDateUtils.formatDate(AppDateUtils.today());
    final n = habit.completionsPerPeriod;

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

  Future<void> seedIfEmpty() async {
    final count = await _db.select(_db.habits).get().then((r) => r.length);
    if (count > 0) return;

    final pianoTagId = await _db.into(_db.tags).insert(
          TagsCompanion.insert(name: 'piano', colorHex: const Value('#9B59B6')),
        );

    final pianoId = await _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            name: '练琴',
            description: const Value('每天必备练琴'),
            iconKey: 'piano',
            colorHex: '#E74C3C',
            frequencyType: FrequencyType.daily,
            completionsPerPeriod: const Value(1),
            activeDaysType: ActiveDaysType.everyDay,
            tagId: Value(pianoTagId),
            sortOrder: const Value(0),
          ),
        );

    final gegeId = await _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            name: '哥哥',
            description: const Value('我想你了'),
            iconKey: 'favorite',
            colorHex: '#3498DB',
            frequencyType: FrequencyType.daily,
            completionsPerPeriod: const Value(3),
            activeDaysType: ActiveDaysType.everyDay,
            sortOrder: const Value(1),
          ),
        );

    await _seedDemoCheckIns(pianoId, gegeId);
  }

  Future<void> _seedDemoCheckIns(int pianoId, int gegeId) async {
    final today = AppDateUtils.today();
    final records = <CheckInRecordsCompanion>[];

    for (var i = 30; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }
      final key = AppDateUtils.formatDate(date);
      records.add(
        CheckInRecordsCompanion.insert(
          habitId: pianoId,
          date: key,
          count: const Value(1),
        ),
      );
      if (i % 3 == 0) {
        records.add(
          CheckInRecordsCompanion.insert(
            habitId: gegeId,
            date: key,
            count: Value(i % 9 == 0 ? 3 : (i % 3) + 1),
          ),
        );
      }
    }

    for (final record in records) {
      await _db.into(_db.checkInRecords).insert(record);
    }
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
    required FrequencyType frequencyType,
    required int completionsPerPeriod,
    required ActiveDaysType activeDaysType,
    int? tagId,
  }) async {
    final sortOrder = (await maxSortOrder()) + 1;
    return _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            name: name,
            description: Value(description),
            iconKey: iconKey,
            colorHex: colorHex,
            frequencyType: frequencyType,
            completionsPerPeriod: Value(completionsPerPeriod.clamp(1, 20)),
            activeDaysType: activeDaysType,
            tagId: Value(tagId),
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<void> updateHabit({
    required int id,
    required String name,
    String? description,
    required String iconKey,
    required String colorHex,
    required FrequencyType frequencyType,
    required int completionsPerPeriod,
    required ActiveDaysType activeDaysType,
    int? tagId,
    bool clearTag = false,
  }) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
          HabitsCompanion(
            name: Value(name),
            description: Value(description),
            iconKey: Value(iconKey),
            colorHex: Value(colorHex),
            frequencyType: Value(frequencyType),
            completionsPerPeriod: Value(completionsPerPeriod.clamp(1, 20)),
            activeDaysType: Value(activeDaysType),
            tagId: clearTag ? const Value(null) : Value(tagId),
          ),
        );
  }

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

  /// 按名称解析 tagId：空则 null；不存在则新建。
  Future<int?> resolveTagId(String? tagName) async {
    final trimmed = tagName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final existing = await findTagIdByName(trimmed);
    if (existing != null) return existing;
    return createTag(trimmed);
  }
}
