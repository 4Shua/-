import 'package:dakaqi/domain/models/enums.dart';
import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconKey => text()();
  TextColumn get colorHex => text()();
  IntColumn get frequencyType => intEnum<FrequencyType>()();
  IntColumn get completionsPerPeriod =>
      integer().withDefault(const Constant(1))();
  IntColumn get activeDaysType => intEnum<ActiveDaysType>()();
  IntColumn get tagId => integer().nullable().references(Tags, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CheckInRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id)();
  TextColumn get date => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {habitId, date},
      ];
}
