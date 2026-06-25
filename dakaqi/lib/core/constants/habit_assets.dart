import 'package:dakaqi/domain/models/enums.dart';
import 'package:flutter/material.dart';

/// 习惯可选 Material Icon（iconKey -> IconData）
abstract final class HabitIcons {
  static const defaultKey = 'circle';

  static const entries = <String, IconData>{
    'circle': Icons.circle_outlined,
    'favorite': Icons.favorite_border,
    'piano': Icons.piano,
    'fitness': Icons.fitness_center,
    'run': Icons.directions_run,
    'book': Icons.menu_book_outlined,
    'water': Icons.water_drop_outlined,
    'sleep': Icons.bedtime_outlined,
    'coffee': Icons.coffee_outlined,
    'food': Icons.restaurant_outlined,
    'fruit': Icons.apple,
    'meditate': Icons.self_improvement,
    'walk': Icons.directions_walk,
    'bike': Icons.directions_bike,
    'swim': Icons.pool,
    'music': Icons.music_note,
    'paint': Icons.palette_outlined,
    'code': Icons.code,
    'work': Icons.work_outline,
    'study': Icons.school_outlined,
    'language': Icons.translate,
    'write': Icons.edit_note,
    'read': Icons.auto_stories_outlined,
    'game': Icons.sports_esports_outlined,
    'phone': Icons.phone_android_outlined,
    'clean': Icons.cleaning_services_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'plant': Icons.local_florist_outlined,
    'pet': Icons.pets,
    'money': Icons.savings_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'travel': Icons.flight_takeoff,
    'photo': Icons.photo_camera_outlined,
    'sun': Icons.wb_sunny_outlined,
    'moon': Icons.nightlight_outlined,
    'heart': Icons.monitor_heart_outlined,
    'pill': Icons.medication_outlined,
    'tooth': Icons.health_and_safety_outlined,
    'stretch': Icons.accessibility_new,
    'yoga': Icons.spa_outlined,
    'smoke_free': Icons.smoke_free,
    'alarm': Icons.alarm,
    'check': Icons.check_circle_outline,
  };

  static IconData resolve(String key) =>
      entries[key] ?? entries[defaultKey]!;
}

abstract final class HabitColors {
  static const defaultHex = '#E74C3C';

  static const palette = [
    '#E74C3C',
    '#E67E22',
    '#F1C40F',
    '#2ECC71',
    '#1ABC9C',
    '#3498DB',
    '#9B59B6',
    '#E91E63',
    '#FF5722',
    '#795548',
    '#607D8B',
    '#34495E',
    '#95A5A6',
    '#BDC3C7',
  ];

  static Color parse(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

extension FrequencyTypeLabel on FrequencyType {
  String get label => switch (this) {
        FrequencyType.daily => '每天',
        FrequencyType.weekly => '每周',
      };
}

extension ActiveDaysTypeLabel on ActiveDaysType {
  String get label => switch (this) {
        ActiveDaysType.everyDay => '每天',
        ActiveDaysType.weekdays => '工作日',
        ActiveDaysType.weekends => '周末',
        ActiveDaysType.holidays => '法定节假日',
      };
}
