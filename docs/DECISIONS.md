# 决策记录（ADR 简版）

## 2025-06-24 — 技术栈：Flutter + Drift + Riverpod

**决策**：Flutter（Android 优先）+ Drift + Riverpod。

**理由**：关系型数据清晰，Riverpod 适合多页面状态，Flutter 可扩 iOS。

---

## 2025-06-24 — 存储：纯本地

**决策**：SQLite 仅存手机，初版不做云同步。零成本、开发快。

---

## 2025-06-24 — 满格后再点：重置为 0

**决策**：圆环打满后再次点击，清空当日 count。

---

## 2025-06-24 — 图标：Material Icons 精选网格

**决策**：初版 ~40 个 Material Icons。

---

## 2025-06-24 — 跨设备规范

**决策**：AGENTS.md + docs/PROGRESS.md + .cursor/rules/

---

## 2026-06-24 — 打卡时间范围与提醒

**决策**：Habit 表 schema v2 增加 `checkInWindow*` 与 `reminder*` 字段；规则拆为「打卡日」与「打卡时刻」两层。

**理由**：周期（工作日/周末）与每日可打卡时段是独立维度；日历只反映前者，圆环与 SnackBar 反映后者。

---

## 2026-06-24 — 通知：仅 Android/iOS，Windows 跳过

**决策**：`ReminderService` 在 Windows/Web 不初始化排程；`flutter_local_notifications` 固定 **17.2.x**（19.x 在 Windows 需 ATL）。

**理由**：Android 真机为验收标准；Windows 仅用于日常 UI 开发。

---

## 2026-06-24 — 圆环禁用仍可点 + 单条提示

**决策**：`SegmentedRingButton` 禁用时保留点击；`CheckInHint` 保证同一条 SnackBar 不重复弹出；不做防抖。

**理由**：用户需要明确知道「为什么不能打」，且避免连续误触刷屏。

---

## 2026-06-24 — 日历/热力图区分休息日与需打卡日

**决策**：休息日（`!canCheckInOn`）用更淡视觉；需打卡未打用正常灰格；已打用习惯色。

**理由**：极简区分「不必打」与「忘了打」，不增加图例或额外文案。
