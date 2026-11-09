## 2026-11-09 | 任务：收紧 changelog 直接提交收录门槛

**Links:** [发布内容决策](../../../.agents/skills/release-easydict/references/release-workflow.md#内容决策)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

从更新日志筛选规则中排除影响较小的直接提交，以公式复制修补和模型设置间距为例。

### 变更

- 将直接提交的收录条件统一为实质性的用户可见变化，并明确小幅 UI 调整和已收录功能的补充细节如何处理。
- Skill 入口与发布指南统一链接到详细规则。

### 设计意图

让更新日志聚焦影响用户使用的变化，同时允许把必要细节并入主功能条目。

### 验证

- Skill 结构、规则链接及 `git diff --check` 通过。
- 对照两个示例与崩溃修复场景，检查收录与合并口径。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `docs/releases/easydict.md`

### 后续事项

- None
