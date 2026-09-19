## 2026-09-17 | 任务：修正 Apple Dictionary 测试文件作者信息

**Links:** https://github.com/tisfeng/Easydict/pull/1320

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`

### 用户请求

修复 PR #1320 审查中发现的测试文件使用 Agent 名称作为作者的问题。

### 变更

- 将 `AppleDictionaryTests.swift` 文件头中的 Agent 名称替换为 PR 作者名称。
- 未修改测试逻辑或生产代码。

### 设计意图

遵循仓库新文件作者信息规则，并与相邻测试文件的文件头格式保持一致。

### 验证

- `rg -n "Created by Codex" EasydictTests/Service/AppleDictionaryTests.swift`：无匹配。
- `git diff --check`：通过。

### 受影响文件

- `EasydictTests/Service/AppleDictionaryTests.swift`
- `docs/histories/2026-09/2026-09-17-fix-apple-dictionary-test-author.md`

### 后续事项

- PR #1320 中关于 `AppleDictionaryTests` 触发真实词典目录清理的开放评论仍需单独处理。
