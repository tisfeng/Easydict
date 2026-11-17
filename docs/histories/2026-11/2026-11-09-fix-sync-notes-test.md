## 2026-11-09 | 任务：修复 sync-notes 路由测试夹具

**Links:** [发布收尾改动](2026-11-09-release-completion.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

查清并修复 sync-notes 失败用例，完整测试通过后提交。

### 变更

- 将入口脚本加载的 `release-auth.sh` 一并复制到临时测试目录。
- 指定不存在的 ASC 配置，验证命令可以分派到日志同步 helper，且不创建 ASC 工作流目录。
- 在测试失败时显示入口脚本的标准错误。

### 设计意图

让夹具具备真实的启动依赖，并隔离本机 ASC 认证配置。

### 验证

- 修复前复现入口脚本报 `release-auth.sh: No such file or directory`。
- 发布工具完整测试 81 项通过，`git diff --check` 通过。

### 受影响文件

- `.agents/skills/release-easydict/tests/test_release_redraft.py`

### 后续事项

- None
