## 2026-09-11 | 任务：升级受管 Skills 至 v0.3.8 并移除子代理

**Links:** [`2026-09-11-remove-subagents-upgrade-skills-v0-3-8.md`](../../exec-plans/completed/2026-09-11-remove-subagents-upgrade-skills-v0-3-8.md)

### 用户请求

项目依赖的 skills 已更新，要求同步 Easydict 的 skills 依赖；上游移除了子代理，Easydict 也要
移除子代理并完成相应的同步适配；同时参考上游当天的 Agent 文档更新提交优化项目 Agent 文档规则。
用户明确本对话不使用子代理，并要求保留 `docs/exec-plans/README.md` 与
`docs/histories/README.md`、删除 `.codex/config.toml`。

### 变更

- 将六个受管 Skill 同步到 `tisfeng/skills v0.3.8`（peeled commit
  `d79827eebdb94a7d71240f9b5a07cc0a2260c395`），`skills-lock.json` 记录新的 ref 与内容哈希；
  安装器从 `skills@1.5.24` 提升到 `skills@1.5.25`，lock schema 仍为 `version: 1`。
- 删除 `.codex/agents/{planner,reviewer,tester}.toml`、`.codex/agents-lock.json` 与
  `.codex/config.toml`，项目不再提供 Codex 子代理或项目本地 Agent 配置。
- `docs/agents/request-boundary.md` 移除「Planner 委派决策」与「子代理委派与回退」；
  `review.md` 改为主 Agent 按 Skill 审查，并在规则中明确不把自审写成独立审查；
  `build-and-test.md` 删除 Tester 角色，测试编写与验证由主 Agent 完成。
- `docs/agents/git-workflow.md` 改名为 `git-delivery.md`，并解耦 Skill 内部章节：宿主只提供
  任务、范围与证据，不再引用 `SKILL.md` 内部锚点或步骤名。
- `docs/agents/README.md` 收敛为单一 `skills-lock.json` 资产模型，补入 plan/history 的命名与
  模板入口，并新增 `docs/exec-plans/README.md`、`docs/histories/README.md` 目录索引；
  两个目录 README 保留为目录说明并指向唯一权威来源。
- 更新 `AGENTS.md`、`CONTRIBUTING.md`、`docs/references/tisfeng-skills.md`、
  `docs/references/{README,astra-agent-guidance,easydict-agent-documentation-port}.md`、
  `docs/design-docs/{README,external-agent-assets-management}.md` 中与子代理、双 lock 相关的
  描述。

### 设计意图

受管快照、lock 与宿主规则属于同一版本边界，分开升级会让规则引用不存在的资产。上游已把通用
契约收回 Skill，宿主只保留项目政策，因此同步删除本地子代理能力、把 Skill 内部步骤排除出宿主
规则，并让每项规则只有一个权威来源。

### 验证

- `diff -r` 比对六个 Skill 目录与 `v0.3.8` tracked tree：全部一致。
- 独立重算 `skills-lock.json` 六个 `tisfeng/skills` 条目与 `fireworks-tech-graph` 条目的目录
  哈希（sha256，按相对路径排序拼接路径与内容）：7/7 与 lock 一致。
- `jq -e . skills-lock.json`、`git diff --check`：通过。
- Python 3.12.13 运行受影响 Skill 测试：`git-commit` 19 项、`review` 10 项、`review-pr`
  99 项、`submit-pr` 38 项、`worktree-rebase-merge` 9 项，共 175 项通过。
- 现行 Markdown 相对链接与锚点扫描：53 个文件，仅剩 3 项既有失效锚点位于 `docs/user-docs/`
  （本次未改动，未纳入修复范围）。
- 全仓检索 `planner`、`reviewer`、`tester`、`子代理`、`agents-lock`、`codex-agents`：现行文档
  只保留“已移除”的说明，历史归档与产品内置 Codex CLI 代码不受影响。
- 未运行 `xcodebuild`：本次未修改产品源码、工程文件或运行时资源。

### 受影响文件

- `.agents/skills/{code-simplifier,git-commit,review,review-pr,submit-pr,worktree-rebase-merge}/`
- `skills-lock.json`
- `.codex/agents-lock.json`、`.codex/agents/`、`.codex/config.toml`（删除）
- `AGENTS.md`、`CONTRIBUTING.md`
- `docs/agents/{README,request-boundary,review,build-and-test}.md`
- `docs/agents/git-workflow.md` → `docs/agents/git-delivery.md`
- `docs/exec-plans/README.md`、`docs/histories/README.md`
- `docs/references/{README,tisfeng-skills,astra-agent-guidance,easydict-agent-documentation-port}.md`
- `docs/design-docs/{README,external-agent-assets-management}.md`
- 本任务 plan/history

### 后续事项

- 未 push，也未创建 tag 或 GitHub Release。
- Scoco 与 boss-resume 的同类同步不在本次范围，仍固定各自的受管版本。
- 上游重新引入平台专属资产或改变发布策略时，按 reference 的重新核对条件评估。
