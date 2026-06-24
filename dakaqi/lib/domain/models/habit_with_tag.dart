import 'package:dakaqi/data/db/database.dart';

class HabitWithTag {
  const HabitWithTag({
    required this.habit,
    this.tag,
  });

  final Habit habit;
  final Tag? tag;
}
