import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('乱七八糟打卡器 · 版本 $appVersion'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('数据存储'),
            subtitle: Text('纯本地 SQLite，数据仅保存在本机'),
          ),
        ],
      ),
    );
  }
}
