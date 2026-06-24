import 'package:dakaqi/core/providers/database_provider.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final habitListProvider = StreamProvider<List<HabitWithTag>>((ref) {
  ref.watch(appBootstrapProvider);
  return ref.watch(habitRepositoryProvider).watchHabitsWithTags();
});

final tagListProvider = StreamProvider<List<Tag>>((ref) {
  ref.watch(appBootstrapProvider);
  return ref.watch(habitRepositoryProvider).watchTags();
});

final selectedTagIdProvider =
    NotifierProvider<SelectedTagIdNotifier, int?>(SelectedTagIdNotifier.new);

class SelectedTagIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? tagId) => state = tagId;
}
