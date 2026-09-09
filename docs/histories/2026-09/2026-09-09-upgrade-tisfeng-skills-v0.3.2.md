## 2026-09-09 | 任务：升级受管 `tisfeng/skills` 快照至 v0.3.2

**Links:** [`v0.3.2 release`](https://github.com/tisfeng/skills/releases/tag/v0.3.2)、
[`执行计划`](../../exec-plans/completed/2026-09-09-upgrade-tisfeng-skills-v0.3.2.md)

### 用户请求

将 Easydict 项目依赖的通用 Skill 与 Codex 子代理更新至 `tisfeng/skills v0.3.2`。

### 结果

- 同步六个通用 Skill 与四个 Codex 子代理至 `v0.3.2`，由双 lock 固定 tag、peeled commit
  和内容哈希。
- 同步 `git-commit`、`worktree-rebase-merge`、`submit-pr` 与 `git-delivery` 的累计交付安全
  更新；其他同基线快照保持内容不变。
- 更新宿主基线、安装命令与 `staging_strategy` 委派契约；保持项目专属与独立来源内容不变。

### 验证

- 六个 Skill 目录与上游 `v0.3.2` tracked tree 逐文件一致；四个 agent 文件与上游一致，
  `agents-lock.json` 的 revision 与 SHA-256 均匹配。
- `git-commit` 19 项、`submit-pr` 23 项与 `review-pr` 27 项已安装快照测试通过；新增的
  `worktree-rebase-merge` staging-contract 2 项测试在冻结上游 checkout 通过。该测试依赖
  上游目录布局，不在安装后的项目路径中运行。
- 上游 `@tisfeng/codex-agents@0.3.2` 安装器 6 项测试通过；JSON/TOML 解析、文档链接、
  受保护路径比对与 `git diff --check` 通过。
- 未运行 Xcode；静态快照验证不证明当前或全新 Codex 任务已发现新 agent 配置。
