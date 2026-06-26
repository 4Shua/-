# 打卡规则 v2 设计稿

> 日期：2026-06-24  
> 状态：**已实现**  
> 前置归档：`docs/legacy/check-in-rules-v1.md` · Git tag `check-in-rules-v1`

---

## 1. 目标

重构习惯打卡的核心语义，使表单、规则、统计三者一致：

- 用 **频率（n 次/天）** 取代旧的「周期（天/周）」
- 新增 **目标（z 次/月）** 与月度有效完成统计
- **有效打卡日** 改为 **两大类互斥单选**（周中/周末 类内 toggle）；**不做** 上班/节假
- 文案统一：**频率 / 目标 / 有效打卡日 / 有效打卡时间**
- **补卡**：仅预留扩展点，本次不实现

---

## 2. 核心概念

### 2.1 频率（n 次/天）

- 每个有效打卡日，用户需完成 **n 次** 点击（圆环 n 段）
- 与 v1 的 `completionsPerPeriod` 语义对齐，但**去掉 weekly**

### 2.2 目标（z 次/月）

- 自然月内，累计 **z 次「有效完成日」** 即视为达成当月目标
- **1 次有效完成日** 的定义（已确认）：
  1. 当天是 **有效打卡日**
  2. 用户在 **有效打卡时间** 内操作（若未限制则全天）
  3. 当天结束时 `count >= n`（必须**打满** n 次）
  4. 若只打了部分（如 2 次/天只打 1 次）→ **不计入** 月度有效次数

> 统计方式：**按日终状态回溯计算**，无需后台定时任务。查看月历时用 `count >= n` 判定该日是否有效。

### 2.3 有效打卡日（两大类 · 互斥单选）

| 大类 | UI | 存储语义 |
|------|-----|----------|
| **1. 每天** | 选中即可 | 所有自然日 |
| **2. 周中 / 周末** | 选中大类后，点击切换「周中」「周末」 | 周一至五 **或** 周六日 |

UI 示意：

```
有效打卡日
┌────────┐  ┌──────────────────┐
│  每天  │  │  周中  ⇄  周末   │
└────────┘  └──────────────────┘
   ●              ○
```

- 两类 **互斥**，同时只能选中一个大类
- 大类 2 内部为 **toggle**（点按切换子项）

> **v2 不做**「上班 / 节假」大类（依赖节假日计算，后续单独立项）。旧版 `holidays` 迁移时默认映射为「每天」。

- 与 v1 **时间范围** 逻辑不变：开关 + 开始/结束
- 仅改标签为 **有效打卡时间**

### 2.5 补卡（Future）

本次 **不实现**。预留：

- 设计层：`CheckInRules` / Repository 留 `// TODO: makeup check-in` 扩展点
- UI 层：详情页或设置 **不展示** 入口（避免空按钮）；仅在本文档与 `DECISIONS.md` 记录意向

---

## 3. 数据模型（schema v3 草案）

### 3.1 Habits 表变更

| 变更 | 字段 | 说明 |
|------|------|------|
| **删除** | `frequencyType` | 不再区分天/周 |
| **重命名** | `completionsPerPeriod` → `timesPerDay` | n 次/天（迁移时 copy 值） |
| **新增** | `monthlyTarget` | z 次/月，默认建议 20 或沿用 n×22 等，**表单必填** |
| **替换** | `activeDaysType` → 两字段 | 见下 |

**有效打卡日存储（推荐）：**

```dart
enum EffectiveDayCategory {
  everyDay,        // 每天
  weekdayWeekend,  // 周中/周末
}

enum EffectiveDayVariant {
  weekday,   // 周中（大类2 默认）
  weekend,   // 周末
}
```

- `effectiveDayCategory`：两大类
- `effectiveDayVariant`：仅当 category = weekdayWeekend 时生效

**v1 → v3 迁移映射：**

| v1 activeDaysType | v3 category | v3 variant |
|-------------------|-------------|------------|
| everyDay | everyDay | weekday（忽略） |
| weekdays | weekdayWeekend | weekday |
| weekends | weekdayWeekend | weekend |
| holidays | everyDay | weekday（忽略，待后续节假日功能） |

### 3.2 CheckInRecord

- **不变**：仍按日存 `count`
- **新增计算**（不新表）：`isValidCompletionDay(habit, date)` ⇔ `canCheckInOn && count >= timesPerDay`

### 3.3 月度统计（不新表）

```dart
// 某自然月有效完成天数
int validDaysInMonth(habit, year, month);

// 是否达成目标
bool isMonthGoalMet(habit, year, month) =>
    validDaysInMonth(...) >= habit.monthlyTarget;
```

可选缓存表 **不做**（初版实时算，习惯数量少足够）。

---

## 4. 领域规则（CheckInRules v2）

| 方法 | 行为 |
|------|------|
| `canCheckInOn(habit, date)` | 按 category + variant 判定 |
| `canCheckInNow(habit, moment)` | 打卡日 + 有效打卡时间 |
| `isValidDay(habit, date, count)` | 打卡日 && count >= timesPerDay |
| `validDaysInMonth(habit, year, month)` | 遍历该月有效打卡日，统计 isValidDay |
| `blockedMessage` / `todayStatusHint` | 文案改用新标签 |

**tapCheckIn**：逻辑与 v1 相同（按日 count 递增/满格清零），不改变点击手感。

---

## 5. UI 变更

### 5.1 习惯表单（高级选项）

| 旧标签 | 新标签 | 控件 |
|--------|--------|------|
| 周期 | **频率** | `[−\|n\|+]` + `次 / 天`（无下拉） |
| （无） | **目标** | `[−\|z\|+]` + `次 / 月` |
| 打卡日 | **有效打卡日** | 两大类 Chip + 周中/周末 toggle |
| 时间范围 | **有效打卡时间** | 不变 |
| 打卡提醒 | 打卡提醒 | 不变 |

### 5.2 首页卡片

- 圆环段数 = `timesPerDay`
- 副标题：保留「今日无需打卡 / 时间范围」；非每天大类可显示当前有效日类型
- **可选**：小字月度进度 `本月 8/20` — **首版不做**，仅详情浮层展示

### 5.3 详情浮层

- `_MetaChip` 由「每天」改为 **`n次/天 · z次/月`** 或两行小标签
- 月历：有效完成日（打满 n）用 **实心**习惯色；打了但未满用 **半满/描边**；休息日更淡
- 月历下方：**本月有效 8 / 目标 20**（建议首版展示）

### 5.4 热力图

- 与月历一致：`count >= n` 才用满色，否则区分「应打未满」与「休息」

---

## 6. 实现范围

### 本次做

- [ ] schema v3 + migration
- [ ] enums + CheckInRules v2
- [ ] Repository 月度统计 helper
- [ ] 表单 UI 重构
- [ ] 卡片 / 详情 / 热力图 / 月历视觉
- [ ] 更新 ARCHITECTURE / PROGRESS / DECISIONS
- [ ] 移除 `FrequencyType` 及所有引用

### 本次不做

- [ ] 补卡
- [ ] 上班/节假大类 + 中国节假日数据
- [ ] 首页卡片月度进度（后续再加）

---

## 7. 已确认决策

| 项 | 结论 |
|----|------|
| 月度有效次数 | 仅当当日打满 n 次才计 1 次 |
| 有效打卡日 | 两大类：每天 / 周中⇄周末 |
| 上班/节假 | **v2 不做** |
| 月度进度 UI | 首版仅详情浮层 |
| 补卡 | 预留，不实现 |

## 8. 确认后下一步

1. 你确认全文无异议 → 开始实现  
2. 写入 `docs/DECISIONS.md` ADR  
3. 按 implementation plan 执行：DB migration → rules → form → UI
