## 2026-10-23 | 任务：移植 Scoco 应用验证实例保护规则

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-23-scoco-validation-safety.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

每周增量筛选 Scoco 适合 Easydict 的改动，实际移植并验证后本地提交；不 push、不创建 PR、不自动合并开发分支。

### 变更

- 从 Scoco `9d1dacad5968acac52d62b0b1f37b21870c346ac` 检查至 `276fa5d1efa211da75763025fa3190ee2f8522a9`，共 8 个新增提交；来源本地 dev 和远端 dev 均为该结束 SHA。
- 目标基线为已核实的 Easydict origin/dev `8d80bfa219dde99c9c1f2760b59b2df72ad4adef`。用户主 checkout 仍是本地 dev `b4eced749d492d283f451f88e5504413e4533f44`，本任务不更新它。
- 适配 Scoco `18bdb49cf62d9ce13c5d9aceef22dbe21f4d06fd` 的单实例验证规则，以及 `6e863b0292374185ca14171eb6966f02b0fc3fef` 中沿用项目 bundle ID 的文档约束。
- 新增启动前后按 bundle ID、产物路径核对 PID 和实例数、默认复用已有实例、自动化失败后先查询进程、仅清理任务自建实例与恢复检查规则。
- 保留目标全部既有测试授权、工程组织和命令；未移植 Scoco 专属源码，未新增测试。

### 设计意图

将实际适用的应用实例保护集中在 build-and-test.md，避免同一 bundle ID 的测试宿主与用户调试实例冲突。编译缓存继续由独立 DerivedData 隔离，不以改应用身份或重复启动规避运行时限制。

### 验证

- `git diff --check`：通过。
- 静态检查：Bash 命令块、测试授权与工程组织章节相对基线逐字未变；新实例管理章节唯一，Easydict 路径保持正确；相对链接检查通过。
- 文档语义核对：来源行为与目标一致，未授权时保留用户实例，明确多实例例外、禁止按应用名批量终止、退出和失败检查不重新启动应用。
- 本次仅治理文档，按 AGENTS.md 豁免生产代码 review；未运行 Xcode 构建、行为测试或真实 UI。
- 未修改 Scoco 源工作树和用户主 checkout。远端核对遇到 SSH 签名延迟后通过 HTTPS fetch 与 GitHub API 完成，未更改远程配置。

### 受影响文件

- `docs/agents/build-and-test.md`
- `docs/exec-plans/completed/2026-10/2026-10-23-scoco-validation-safety.md`
- `docs/histories/2026-10/2026-10-23-scoco-validation-safety.md`

### 后续事项

候选台账与下次检查点：

| Scoco 源提交 | 状态 | 理由 |
| --- | --- | --- |
| `6e863b0292374185ca14171eb6966f02b0fc3fef` | 部分适配 | 仅采用 bundle ID 文档约束；引导、云端语音认证和 AI 会话初始化为 Scoco 专属功能，排除源码变更。 |
| `3de91f7e0d77a5b7eda6e5bd3bcdb021eb0319b6` | 排除 | Scoco README 本地资源目录修复；目标 README 使用不同图标来源。 |
| `18bdb49cf62d9ce13c5d9aceef22dbe21f4d06fd` | 已适配 | 单实例应用验证规则适用于目标。 |
| `acce33d0f695d20c5ad5cfb35ad57f04ae6538ba` | 排除 | 仅精简来源规则措辞；保留目标自身的新增服务验证等约束，不整体覆盖文档。 |
| `d56db34e6f1912a5145fb55e7a515e3a645042e2` | 排除 | Scoco 0.5.71 版本元数据。 |
| `ceb6bdfbc523096756d1595fe6e9a28f0852ab2f` | 排除 | Scoco 0.5.71 发布产物元数据。 |
| `bd01b8dc5617415d40d8fc2a2ca3d49761645b65` | 暂缓，未移植 | 目标已有 perform 返回后完成的边界；utility/enforceQoS 会改变前台请求调度，来源后续记录仍提示警告未解决。需先在目标获取等待栈、验证取消语义与负载延迟，再决定是否降低优先级，不能视为已修复或已同步。 |
| `276fa5d1efa211da75763025fa3190ee2f8522a9` | 排除 | 主要消除来源的截图/OCR 包装层；目标没有相同重复结构，不照搬文件重组。 |

- 下次从 `276fa5d1efa211da75763025fa3190ee2f8522a9` 增量检查，同时重新评估上述暂缓的 `bd01b8dc5617415d40d8fc2a2ca3d49761645b65`；暂缓不等于已移植。
- 上轮 CSS 修复以目标 `b4eced749` 收录；与旧任务提交 `8673a94d3` 内容等价，未重复移植。`b03e9ac38` 仍由目标空词条提前返回保护覆盖，无需补丁。
- 本任务分支 `codex/scoco-validation-safety` 尚未合入 dev，不 push。
