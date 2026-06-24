# 架构说明

## 分层

```
Presentation (features/) → State (Riverpod) → Domain (models, rules) → Data (Drift)
```

## 数据模型

### Habit

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

## 核心自研组件

### SegmentedRingButton

- 卡片右上角打卡按钮，圆环按 n 分割，依次点亮
- 满格后再点 → 清空当日 count

### MonthHeatmapRow

- 卡片底部热力图，按月份分组，横向滚动

### CheckInRulesEngine

- 判断今天是否允许打卡：每天 / 工作日 / 周末 / 法定节假日

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

## 明确不做（初版 MVP）

- PRO、HabitKit 品牌、底部三视图导航
- 提醒、Streak Goal、Custom Value、云同步
- 详情页顶部年度热力图
