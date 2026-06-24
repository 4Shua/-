import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/enums.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
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
    return (_db.select(_db.tags)..orderBy([OrderingTerm.asc(_db.tags.name)]))
        .watch();
  }

  Future<void> seedIfEmpty() async {
    final count = await _db.select(_db.habits).get().then((r) => r.length);
    if (count > 0) return;

    final pianoTagId = await _db.into(_db.tags).insert(
          TagsCompanion.insert(name: 'piano', colorHex: const Value('#9B59B6')),
        );

    await _db.into(_db.habits).insert(
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

    await _db.into(_db.habits).insert(
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
  }
}
