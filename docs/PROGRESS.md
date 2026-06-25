# 开发进度

> 最后更新：2026-06-24 | Phase 5 完成（打卡规则增强）

## 当前阶段

**MVP 增强版 — 可选后续：rules-holiday / polish / 数据导出**

## 已完成

- [x] Phase 0–4（首页、表单、详情、设置）
- [x] Phase 5：打卡时间范围 + 提醒 + 日历视觉
  - **DB schema v2**：`reminderEnabled`、`reminderTime`、`checkInWindowStartMinutes`、`checkInWindowEndMinutes`
  - **`CheckInRules`**：`canCheckInOn`（打卡日）+ `canCheckInNow`（打卡日+时间段）+ 统一拦截文案
  - **`TimeUtils`**：分钟制时间、窗口判断（含结束时刻、支持跨午夜）
  - **`ReminderService`**：Android/iOS 本地通知排程；Windows 开发环境自动跳过
  - **习惯表单**：高级选项（周期、时间范围开关、打卡提醒）；漂浮图标选择器
  - **习惯卡片**：禁用时仍可点击 + `CheckInHint` 单例防重复 SnackBar；副文案区分「今日无需打卡 / 时间范围 / 周期标签」
  - **热力图 + 详情月历**：用 `canCheckInOn` 区分需打卡日（正常灰/色）与休息日（更淡）
  - **Windows 开发**：390×844 窗口；`flutter_local_notifications` 固定 17.2.x 避免 ATL 依赖

## 下一步（可选）

1. `CheckInRulesEngine` + 中国节假日离线数据（`ActiveDaysType.holidays`）
2. Android 真机验收提醒与通知权限
3. UI 对照截图微调
4. 数据导出/导入 JSON

## 环境备注

- Flutter SDK：`D:\Flutter`
- **构建路径**：必须在 ASCII 路径 `dakaqi-workspace/dakaqi/` 下构建（中文路径会导致 Android 问题）
- 国内镜像：`PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL`（见 `scripts/`）
- 远程：https://github.com/4Shua/-.git
- Windows：`flutter run -d windows`（通知不排程，属预期）
- Android：真机为通知与打卡验收标准

## 最近提交

- 05a2f05 — fix(android): 修复真机构建 JVM 目标与 desugaring
- 26bf7ff — feat(check-in): 打卡时间范围、提醒与日历视觉区分
- c698dcb — feat(detail): Phase 4 习惯详情浮层与设置页
- 629d05d — feat(habit-form): Phase 3 新建编辑习惯表单
