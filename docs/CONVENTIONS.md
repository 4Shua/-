# 编码与协作规范

## 目录约定

- **feature-first**：每个功能在 `lib/features/<name>/` 下
- **共享组件**：`lib/widgets/`
- **主题常量**：`lib/core/theme/`
- **数据层**：`lib/data/`，UI 不直接访问 Drift

## Dart 命名

| 类型 | 风格 | 示例 |
|------|------|------|
| 文件 | snake_case | `habit_card.dart` |
| 类 | PascalCase | `HabitCard` |
| Provider | 功能 + Provider | `habitListProvider` |

## Riverpod

- 优先 `@riverpod` 代码生成
- Repository 通过 Provider 注入

## Git

- **主分支**：`main`
- **功能分支**：`feat/<简述>`
- 每次会话结束前 push

## Commit Message

格式：`type(scope): 中文简述`

示例：`feat(home): 习惯卡片列表`

## 会话结束 checklist

1. 更新 `docs/PROGRESS.md`
2. 架构变更时同步 `docs/ARCHITECTURE.md`
3. `flutter analyze` 无 error
4. commit + push
