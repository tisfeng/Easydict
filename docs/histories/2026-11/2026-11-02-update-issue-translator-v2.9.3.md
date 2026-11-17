## 2026-11-02 | 任务：升级 issue-translator 至 v2.9.3

**Links:** [v2.9.3 Release](https://github.com/tisfeng/issues-translate-action/releases/tag/v2.9.3)、[Action 提交](https://github.com/tisfeng/issues-translate-action/commit/c23b39d03d0829323dc719ba0cf34a791675d21a)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

在 Action fork 完成认证移植并发布新版本后，更新 Easydict 使用的版本。

### 变更

- issue-translator 从 tisfeng/issues-translate-action@v2.9.2 更新到已发布的 v2.9.3。
- translate job 显式授予 issues: write 和 pull-requests: write。
- 保留原有三个触发事件、中英双语配置、标题配置与自定义注释，无需增加 Secret 或手动配置 token。

### 设计意图

使用 Action 新默认的工作流 token，以 github-actions[bot] 身份发布译文，避免继续依赖失效的共享凭据。
本次仅更新 GitHub workflow 和治理记录，不修改 macOS 应用依赖、代码、签名或工程配置。

### 验证

- Action v2.9.3 已正式发布并设为 Latest，annotated tag 指向 c23b39d03d0829323dc719ba0cf34a791675d21a。
- 发布源码归档中的 action.yml、认证源码、bundle、source map、license 与本地已验证内容逐字节一致。
- Action 离线验证：58 tests、format-check、build、lint、package、bundle smoke 与旧凭据清除检查通过。
- workflow YAML、事件、权限、输入和依赖版本静态检查通过；git diff --check 通过。
- 未新增 Easydict 测试，未运行 Xcode build/test，未创建真实评论、未触发或重跑真实 workflow。

### 受影响文件

- `.github/workflows/issue-translator.yml`
- `docs/histories/2026-11/2026-11-02-update-issue-translator-v2.9.3.md`

### 后续事项

- 将本次 dev 提交推送到远端后，新的自然事件才能使用新版本；旧任务重跑不作为新配置的验证。
