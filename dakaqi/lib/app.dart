import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/features/home/pages/home_page.dart';
import 'package:flutter/material.dart';

class DakaqiApp extends StatelessWidget {
  const DakaqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乱七八糟打卡器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}
