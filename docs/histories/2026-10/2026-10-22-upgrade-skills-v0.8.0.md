## 2026-10-22 | 任务：同步 Skills v0.8.0 并接入共享命名工具

**Links:** [计划](../../exec-plans/completed/2026-10/2026-10-22-upgrade-skills-v0.8.0.md)、
[上游发布](https://github.com/tisfeng/skills/releases/tag/v0.8.0)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

同步已发布 v0.8.0，并将项目发布脚本接入共享命名工具。
按用户要求整理提交，AGENTS.md 和 CONTRIBUTING.md 的改进归入前置文档提交。
不创建或切换分支，验证后本地提交，不 push。

### 变更

- 使用 skills@1.5.25 安装器从远程固定 tag 同步六个完整受管技能并生成 lock。
- 项目专属 release-easydict 调用共享命名工具，删除重复命名拼接与文档定义，补充命名验证。
- 更新来源基线，记录同级技能依赖；保留第三方技能及 Claude 符号链接。

### 设计意图

只从已发布固定版本获取受管快照，不恢复旧提交中的未发布技能内容，也不手工修改快照或哈希。
命名规则、生成和校验集中于 git-commit，项目入口与消费端只引用或调用。

### 验证

- 远程 v0.8.0 annotated tag 与 peeled commit 均与来源基线一致。
- 六个技能共 56 个文件与 tag 内容逐字节一致；六个 lock 哈希重算通过。
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s <skill>/tests`：
  git-commit 25、submit-pr 30、review-pr 64、worktree-rebase-merge 6 项通过。
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .agents/skills/release-easydict/tests -p test_release_git_flow.py`：
  2 项通过，覆盖共享命名、非法版本拒绝与隔离发布 Git 流程。
- 临时目录验证：发布命名依赖缺失时返回失败，没有新增文件。
- frontmatter、agents/openai.yaml、相对链接、`jq -e . skills-lock.json`、变更 Shell 的
  `bash -n`、`git diff --check` 均通过。
- 原升级任务已完成 Review：检查技能升级、发布接入及新增文件，
  快照复验一致，无有效 finding；现有统一工具已足够，无需额外抽象。
- 受管目录没有新增 bytecode 缓存；独立第三方快照和 lock、符号链接、上游仓库未改变。
- 不涉及应用构建图，未运行 Xcode 构建或真实发布。

- 提交整理验证：两份入口文档归入前置提交，本提交不再修改它们；技能、lock、脚本与测试
  保持原升级提交内容，复用此前 127 项测试结果；核对链接、差异和提交父子关系。

### 受影响文件

- `.agents/skills/{git-commit,review-pr,submit-pr,worktree-rebase-merge}/`
- `.agents/skills/release-easydict/`
- `skills-lock.json`
- `docs/agents/skills.md`
- 本任务 plan 与 history。

### 后续事项

- None
