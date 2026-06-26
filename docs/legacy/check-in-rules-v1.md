# 打卡规则 v1（重构前快照）

> 归档日期：2026-06-24  
> 对应 Git 标签：`check-in-rules-v1`（commit `e110b59`）  
> **本文档只描述旧逻辑，重构后勿再按此实现。**

---

## 1. 数据模型（Habits 表 schema v2）

| 字段 | 类型 | 说明 |
|------|------|------|
| `frequencyType` | enum | `daily` / `weekly`（周期单位） |
| `completionsPerPeriod` | int | 每个周期要打几次（默认 1） |
| `activeDaysType` | enum | `everyDay` / `weekdays` / `weekends` / `holidays` |
| `checkInWindowStartMinutes` | int? | 有效打卡时间起（null=不限） |
| `checkInWindowEndMinutes` | int? | 有效打卡时间止 |
| `reminderEnabled` | bool | 是否提醒 |
| `reminderTime` | String? | 提醒时刻 HH:mm |

### CheckInRecord

- 按自然日 `yyyy-MM-dd` 存 `count`（0 ~ n）
- 同一天多次点击圆环：`count` 递增，满 n 后再点重置为 0

---

## 2. 表单 UI（高级选项）

| 区块 | 标签 | 控件 |
|------|------|------|
| 周期 | 「周期」 | `[−|数字|+]` + `次 /` + 下拉 `天`/`周` |
| 打卡日 | 「打卡日」 | 四选一 Chip：每天 / 工作日 / 周末 / 法定节假日 |
| 时间 | 「时间范围」 | 开关 + 开始/结束 TimeBox |
| 提醒 | 「打卡提醒」 | 开关 + TimeBox |

---

## 3. 领域规则（CheckInRules）

### canCheckInOn(habit, date) — 是否打卡日

| activeDaysType | 规则 |
|----------------|------|
| everyDay | 始终 true |
| weekdays | 周一至周五 |
| weekends | 周六、周日 |
| holidays | **恒 false**（节假日表未接） |

### canCheckInNow(habit, moment) — 此刻能否点圆环

1. 先过 `canCheckInOn`
2. 若设置了时间窗口，再检查 `TimeUtils.isWithinWindow`（结束时刻含边界，支持跨午夜）

### 文案

- `blockedMessage`：非打卡日 / 非时间范围
- `todayStatusHint`：卡片副标题「今日无需打卡」或时间范围

---

## 4. 打卡动作（HabitRepository.tapCheckIn）

1. 校验 `canCheckInOn` → 返回 `-1`
2. 校验 `canCheckInNow` → 返回 `-2`
3. 取**当天**记录，`count`：`current >= n ? 0 : current + 1`
4. **注意**：`frequencyType.weekly` 已入库，但**未实现按周累计**，实际始终按**自然日**计次

---

## 5. UI 展示

| 位置 | 展示内容 |
|------|----------|
| 详情浮层 `_MetaChip` | `frequencyType.label` →「每天」/「每周」（不含次数） |
| 首页卡片副标题 | `todayStatusHint` 或 `activeDaysType.label` |
| 圆环 `SegmentedRingButton` | 段数 = `completionsPerPeriod`；`enabled = canCheckInNow` |
| 热力图 / 月历 | `canCheckInOn` 区分休息日（更淡）与需打卡日 |

---

## 6. 已知局限（v1）

- `weekly` 周期无实际周统计
- `holidays` 打卡日无效（占位）
- 详情「每天」易与「打卡日·每天」混淆
- 无月度目标 / 月度完成度统计
- 「有效完成」= 打满 n 次，但不单独标记「当日有效」字段

---

## 7. 相关文件

```
lib/domain/models/enums.dart          # FrequencyType, ActiveDaysType
lib/domain/rules/check_in_rules.dart
lib/data/db/tables.dart
lib/data/repositories/habit_repository.dart
lib/features/habit_form/pages/habit_form_screen.dart
lib/features/home/widgets/habit_card.dart
lib/features/habit_detail/widgets/habit_detail_sheet.dart
lib/widgets/month_heatmap_row.dart
lib/features/habit_detail/widgets/read_only_month_calendar.dart
lib/core/notifications/reminder_service.dart
```
