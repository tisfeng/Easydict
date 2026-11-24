## 2026-11-22 | 任务：修复联合 OCR 后续评论

**Links:** [PR #1403](https://github.com/tisfeng/Easydict/pull/1403)、[执行计划](../../exec-plans/completed/2026-11/2026-11-22-fix-ocr-follow-up.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复 PR #1403 的两条新增评论，分别验证并提交。

### 变更

- 原文未识别完时，展开卡片只改变显示状态。完整原文到达后再分发给其他服务，并处理用户已手动展开的空卡片。
- 联合请求失败后，用户编辑输入再展开卡片时恢复正常刷新。没有修改输入时保留错误和重试入口。

### 设计意图

在入口阻止片段查询，避免依赖各服务能否及时取消网络请求。失败状态沿用现有文本比较来决定是否刷新。

### 验证

- `xcodebuild test -testPlan LocalEnvironment`：指定的 DeepSeek/Codex 多服务分发测试通过。
- `xcodebuild test -testPlan Default`：`ReverseTranslationTests` 8 项通过，包含结果卡片折叠及展开。
- 手动检查：已核对同步与延迟展开路径；未实测前台触发 OCR 失败后编辑，或在流式输出时点击另一服务卡片。

### 受影响文件

- `Easydict/Swift/Model/DetectManager.swift`
- `Easydict/Swift/Model/OCRTranslationRequest.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`

### 后续事项

- 两条评论对应的前台交互及截图仍待验收。
