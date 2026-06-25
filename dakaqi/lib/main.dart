import 'package:dakaqi/app.dart';
import 'package:dakaqi/core/notifications/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.initialize();
  runApp(
    const ProviderScope(
      child: DakaqiApp(),
    ),
  );
}
