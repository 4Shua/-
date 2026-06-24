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
