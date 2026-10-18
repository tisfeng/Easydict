## 2026-10-18 | 任务：发布流程改用隔离文件认证

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-18-release-file-auth.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

将 ASC 发布认证迁移到仓库外文件，限制权限，仅在发布流程启用；暂不继续 2.25.0 beta Draft。后续要求同步发布维护指南、检查相关文档遗漏并提交到本地。

### 变更

- 发布生命周期及 resume 入口选择专用配置与 profile，绕过 ASC 钥匙串并启用 strict auth。
- 新增认证 helper，校验配置与私钥位于 Git 工作树外、当前用户所有、文件 600 和目录 700。
- 清除进程继承的 ASC API 凭据字段，避免混用；其他 asc 调用和全局 Shell 配置保持原样。
- 将匹配当前 API Key 的已有私钥复制到用户配置目录下的专用发布目录，凭据不进入 Git。
- 中断归档阶段的 `draft-20261018T075631Z-9da8d528`，保留失败状态及恢复材料，未执行公证、上传或后续 Draft 阶段。

- 补充发布维护指南的首次文件配置、权限要求、子 Shell 只读诊断、认证作用范围、helper 索引和停止条件；Skill reference 链接该指南作为统一配置说明。

### 设计意图

使用文件权限保护本机发布凭据，解除对频繁升级的 ad-hoc asc 程序身份的依赖。配置和私钥不满足条件时直接停止，不回退到交互式钥匙串认证。保留原钥匙串条目及原全局配置。

### 验证

- `asc auth status --validate`（在发布认证环境中）：来源为 Config File，`validation: works`。
- `stat`：专用目录 700，配置和私钥 600。
- `bash -n`：入口及认证 helper 通过；缺失配置会失败退出；帮助入口无需加载凭据。
- `test_release_performance.py`：初次遇到临时 Git 仓库后台维护与清理竞态；以进程级配置关闭 `gc.auto`、`maintenance.auto` 后，5 项通过。未新增或修改测试。
- `git diff --check`：通过。
- Review：检查认证来源隔离、权限校验、错误路径和生命周期调用位置，未发现有效 finding；当前实现满足范围，无需增加其他认证层。
- GitHub 只读查询：2.25.0 Release 尚不存在；相关工作流与构建进程已停止。

- 文档补充：已检索现行发布文档并核对 helper 实现；Markdown 相对链接、锚点、Shell 示例语法和差异空白检查通过。未运行或恢复 Draft。

### 受影响文件

- `docs/releases/easydict.md`
- `.agents/skills/release-easydict/scripts/release-auth.sh`
- `.agents/skills/release-easydict/scripts/release-easydict.sh`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `docs/exec-plans/completed/2026-10/2026-10-18-release-file-auth.md`
- `docs/histories/2026-10/2026-10-18-release-file-auth.md`

### 后续事项

- 2.25.0 Draft 按用户要求保持暂停，只有获准后才恢复原 run。
