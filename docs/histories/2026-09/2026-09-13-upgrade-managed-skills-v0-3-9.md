## 2026-09-13 | 任务：升级受管 Skills 至 v0.3.9

**Links:** [`tisfeng/skills v0.3.9`](https://github.com/tisfeng/skills/tree/v0.3.9)

### 用户请求

项目依赖的 Skills 已更新，要求同步 Easydict 的 Skills 依赖。

### 变更

- 将六项通用 Skills 固定同步到 `tisfeng/skills v0.3.9`（peeled commit
  `f1636df32afad927723ea269e5d4b2544d7f26c9`），并由安装器更新 `skills-lock.json`。
- `review` 与 `review-pr` 增加实现方式评估；`review-pr` 将需求上下文拆成独立 fingerprint，
  并支持需求来源的差量刷新。其余四项 Skill 内容未变化，只统一更新 lock ref。
- 独立的 `fireworks-tech-graph` 上游 main 未变化，但既有快照缺少被 `.gitignore` 的 `Icon?`
  规则误匹配的 `assets/icons/cloud/manifest-v1.json`；单独重装该来源，并为受管 icons 路径
  增加精确 ignore 例外，使快照恢复完整。
- 更新两个外部来源参考；项目专属 `release-easydict` 与 `.claude/skills` 链接保持不变。

### 设计意图

通过已核验的安装器从固定 tag 同步完整快照，不在 Easydict 内修补上游 Skill；不同来源继续
独立管理。精确放行受管 icons 路径，避免 macOS Finder `Icon?` 忽略规则继续吞掉合法上游资产。
宿主规则只引用稳定入口，因此本次无需同步修改项目 Agent 规则。

### 验证

- 六个通用 Skill 与 `v0.3.9` tracked tree、`fireworks-tech-graph` 与 commit
  `31fea364eda5f1852b1175f3d9e29ea31d22dcb4` tracked tree：递归比对完全一致。
- 按安装器算法独立重算七个目录 hash：7/7 与 `skills-lock.json` 一致；`jq -e` 验证 lock
  schema、来源、数量与 ref：通过。
- Python 3.12.3 运行 `git-commit` 19 项、`review` 10 项、`review-pr` 101 项、`submit-pr`
  38 项、`worktree-rebase-merge` 9 项测试，共 177 项通过。
- Python 3.12.3 运行 `fireworks-tech-graph` 单测：141 项通过，5 项需 Chromium/ImageMagick 的
  可选渲染回归按上游条件跳过。
- `py_compile` 检查变更的 `review-pr` Python 脚本、`git diff --check`：通过。
- 未运行 `xcodebuild`：本次未修改产品源码、工程文件或运行时资源。

### 受影响文件

- `.agents/skills/review/`
- `.agents/skills/review-pr/`
- `.agents/skills/fireworks-tech-graph/assets/icons/cloud/manifest-v1.json`
- `.gitignore`
- `skills-lock.json`
- `docs/references/tisfeng-skills.md`
- `docs/references/fireworks-tech-graph.md`
- `docs/histories/2026-09/2026-09-13-upgrade-managed-skills-v0-3-9.md`

### 后续事项

- 未 push。
