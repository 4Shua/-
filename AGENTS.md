# 乱七八糟打卡器 — AI 续开发指南

## 续开发流程（换设备后）

1. 读 [`docs/PROGRESS.md`](docs/PROGRESS.md)（进度与下一步）
2. 读 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)（架构与数据模型）
3. 运行 `flutter pub get && flutter analyze`
4. 从 PROGRESS 的「下一步」继续，完成后更新 PROGRESS

## 技术栈

- **Flutter** + **Drift**（SQLite）+ **Riverpod**
- 纯本地存储，Android 优先，零后端成本
- 本地通知：`flutter_local_notifications` 17.2.x + `timezone`（仅 Android/iOS 排程）

## 关键目录

App 工程在 **`dakaqi/`** 子目录（**须 ASCII 路径**，勿在中文目录下构建 Android）：

```
dakaqi/lib/
  main.dart / app.dart
  core/theme/              # 颜色、间距、主题
  core/providers/          # 数据库 Provider
  core/notifications/      # ReminderService
  core/utils/              # date_utils, time_utils
  data/db/                 # Drift 表与迁移
  data/repositories/       # 数据访问
  domain/models/           # 领域模型
  domain/rules/            # CheckInRules
  features/home/           # 首页
  features/habit_form/     # 新建/编辑
  features/habit_detail/   # 详情浮层
  widgets/                 # SegmentedRingButton, MonthHeatmapRow, CheckInHint
```

## Flutter 命令

在 `dakaqi/` 目录下执行：

```bash
flutter pub get
flutter analyze
flutter run                    # 默认设备
flutter run -d windows         # Windows UI 开发（390×844）
flutter run -d <android-id>    # 真机验收通知与打卡
```

国内镜像（可选）见 `dakaqi/scripts/`。

## MVP 边界

见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) 中「明确不做」一节。

## 用户偏好（续开发请遵守）

- **Android 真机**为通知、打卡等行为验收标准；Windows 上通知跳过属正常
- **极简 UI**：样式从简；有歧义时先确认是否采用更简方案
- **打卡按钮**：不禁用点击；SnackBar 提示且不重复弹出

## 参考素材

- [`开发文档/乱七八糟打卡器初步开发文档.md`](开发文档/乱七八糟打卡器初步开发文档.md)
- `开发文档/` 下截图（UI 对照用，只读勿删）

## 禁止事项

- 不要删除或覆盖 `开发文档/` 中的需求原文与截图
- 初版不做：云同步、PRO、底部三栏导航、年度热力图
- 不要将 `flutter_local_notifications` 升到 19.x（Windows 需 ATL）
- 颜色/间距走 `core/theme/`，避免魔法数字散落

## 标准续开发指令

> 阅读 AGENTS.md 和 docs/PROGRESS.md，继续乱七八糟打卡器的开发。
