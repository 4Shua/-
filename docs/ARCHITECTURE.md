# 架构说明

## 分层

```
Presentation (features/) → State (Riverpod) → Domain (models, rules) → Data (Drift)
```

## 数据模型

### Habit（schema v2）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| name | String | 名称 |
| description | String? | 描述 |
| iconKey | String | Material Icon 名 |
| colorHex | String | 主题色 |
| frequencyType | enum | daily / weekly |
| completionsPerPeriod | int | 每周期 n 次 |
| activeDaysType | enum | everyDay / weekdays / weekends / holidays |
| tagId | int? | 关联类型 |
| sortOrder | int | 排序 |
| createdAt | DateTime | 创建时间 |
| reminderEnabled | bool | 是否开启打卡提醒 |
| reminderTime | String? | 提醒时刻 HH:mm |
| checkInWindowStartMinutes | int? | 打卡窗口开始（分钟，null=不限） |
| checkInWindowEndMinutes | int? | 打卡窗口结束（分钟，null=不限） |

### Tag（类型）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| name | String | 类型名 |
| colorHex | String? | 可选颜色 |

### CheckInRecord

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| habitId | int | 习惯 ID |
| date | String | yyyy-MM-dd |
| count | int | 当日进度（0~n） |
| updatedAt | DateTime | 更新时间 |

## 打卡规则（CheckInRules）

| 方法 | 用途 |
|------|------|
| `canCheckInOn(habit, date)` | 该日是否为打卡日（周期规则） |
| `canCheckInNow(habit, moment)` | 打卡日 + 是否在时间窗口内 |
| `hasCheckInWindow(habit)` | 是否设置了时间范围 |
| `blockedMessage(habit, moment)` | 点击圆环被拦截时的 SnackBar 文案 |
| `todayStatusHint(habit, moment)` | 卡片副标题（今日无需打卡 / 时间范围） |

**约定**：时间范围只影响「此刻能否打卡」；日历/热力图用 `canCheckInOn` 区分需打卡日与休息日。

## 核心自研组件

### SegmentedRingButton

- 卡片右上角打卡按钮，圆环按 n 分割，依次点亮
- 满格后再点 → 清空当日 count
- `enabled=false` 时仍可点击，由外层展示提示

### MonthHeatmapRow

- 卡片底部热力图，按月份分组，横向滚动
- 传入 `Habit`，休息日格子更淡，需打卡日正常灰/习惯色

### ReadOnlyMonthCalendar

- 详情浮层只读月历；休息日数字变淡、无灰底圆

### CheckInHint

- 全局单例，同一时刻只显示一条 SnackBar

### ReminderService

- `lib/core/notifications/reminder_service.dart`
- 仅 Android/iOS 排程 `flutter_local_notifications`
- 习惯保存/删除后 debounce 重排；Windows/Web 静默跳过

## 页面

| 页面 | 路径 |
|------|------|
| 首页 | features/home/ |
| 新建/编辑 | features/habit_form/ |
| 详情浮层 | features/habit_detail/ |
| 设置 | features/settings/ |

## UI 风格

- 背景：`#F2F2F7`
- 卡片：白底、圆角 16–20、轻阴影
- 极简：高级选项可折叠；时间/提醒用统一 `_TimeBox` 样式

## 平台差异

| 能力 | Android | iOS | Windows |
|------|---------|-----|---------|
| 本地提醒 | ✅ | ✅ | 跳过 |
| 打卡时间窗口 | ✅ | ✅ | ✅ |
| 日常 UI 开发 | ✅ | — | ✅（390×844） |

## 明确不做（初版 MVP）

- PRO、HabitKit 品牌、底部三视图导航
- Streak Goal、Custom Value、云同步
- 详情页顶部年度热力图
- 中国节假日表（`holidays` 枚举已预留，逻辑待接）
