# 外部 Agent 资产治理

本文规定项目内外部 Skills 与 Codex 子代理的权威来源、lock 所有权和同步边界。文档分层
见 [`README.md`](README.md)，工作树写入门禁见
[`execution-safety.md`](execution-safety.md)。

## 资产分类

### `tisfeng/skills` 统一资产

以下 Skills 由 `skills-lock.json` 管理，当前统一基线为 `tisfeng/skills v0.3.0`：

- `code-simplifier`
- `git-commit`
- `review`
- `review-pr`
- `submit-pr`
- `worktree-rebase-merge`

以下 Codex 子代理由 `.codex/agents-lock.json` 管理，使用同一 tag 与 revision：

- `planner`
- `reviewer`
- `tester`
- `git-delivery`

这些目录和 TOML 是外部权威内容的项目可运行快照。Easydict 不直接修改、删减、重命名或
重新格式化其中内容，也不删除当前任务不适用的 reference。项目差异写入 `AGENTS.md` 或
`docs/agents/`；需要改变通用行为时，先修改并发布上游，再通过安装器同步新版本。

### 独立第三方 Skill

`fireworks-tech-graph` 由 `yizhiyanhua-ai/fireworks-tech-graph` 单独维护，通过
`skills-lock.json` 记录来源与内容哈希。它不属于 `tisfeng/skills`，只允许从自己的
`skills/fireworks-tech-graph` 上游路径同步；禁止在 Easydict 中本地修补。

### 项目专属 Skill

`release-easydict` 是 Easydict 专属发布 Skill，不登记到外部 lock，由本仓库维护。同步任何
外部来源时必须保持其完整目录不变。

## Lock 所有权

- `skills-lock.json` 是外部 Skill 快照的控制面，记录来源、ref、入口路径和安装器计算的
  内容哈希。不得手工改 hash 来接受本地漂移。
- `.codex/agents-lock.json` 是 Codex 子代理快照的控制面，记录来源、ref、精确 Git revision、
  目标相对路径和文件哈希。
- lock 文件不替代已安装内容；仓库同时提交可离线读取和运行的完整快照。
- `.codex/config.toml` 是 Easydict 的本地 Codex 配置，不受 agents lock 管理。
- `.claude/skills` 继续指向 `.agents/skills`，不是另一份可独立修改的副本。

## 写入和同步规则

1. 修改 `.agents/skills/` 或 `.codex/agents/` 前，先读取两个 lock 并确定资产分类。
2. 普通实现、修复、review 和文档任务不得编辑外部受管路径；发现问题时报告上游来源和
   当前 lock 证据。
3. 只有用户明确授权同步或升级时，才使用对应安装器写入受管快照和 lock。两个来源分步
   执行并分别检查 diff，不使用会不加区分地更新所有来源的宽泛命令。
4. 首次为已有子代理建立 lock 时，只有在冻结并核对精确 TOML 后才可使用一次 `--force`；
   后续更新依靠已记录哈希检测本地漂移，不默认强制覆盖。
5. 不直接递归复制上游工作目录；安装内容必须来自已核验的 tag、commit 或安装器克隆，
   避免带入被 Git 忽略的缓存与构建产物。
6. 同步后验证目标集合、lock、来源内容和项目专属保护路径，再按本仓库 Git 门禁交付。

## 验证要求

- `tisfeng/skills` 的六个 Skill 目录与所选 tag 的 tracked tree 完全一致。
- 四个 agent 文件的 SHA-256 与 agents lock 一致，并使用同一 revision。
- `fireworks-tech-graph` 与记录的独立上游 commit 一致，且 lock source 不指向
  `tisfeng/skills`。
- `release-easydict`、`.codex/config.toml` 和 `.claude/skills` 前后不变。
- TOML、JSON、Skill 自带测试、Shell/Python 静态检查和文档相对链接按变更风险执行。

静态验证只能证明仓库快照和配置一致；新的自定义子代理能否被 Codex 运行时发现，需要在
全新任务中另行 smoke 验证。
