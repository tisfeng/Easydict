## 2026-09-13 | 任务：继续精简 Astra Agent 文档

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-13-astra-agent-docs-follow-up.md)

### 用户请求

在通用 Skills 升级到 v0.4.0 后，继续参考 GPT-6 Astra 官方建议精简 Agent 文档和项目专属
Skill；删除 Claude 本地权限文件，不修改 History 规则，并完整保留构建测试命令。

### 变更

- 将计划模式、执行模式、自动本地提交和外部写入边界合并到根 `AGENTS.md`，删除所有任务都要
  额外读取的 `docs/agents/task-modes.md`。
- 合并 `build-and-test.md` 中重复的 Xcode 验证、测试范围和 DerivedData 说明，完整保留原有
  build、test、focused test 和 fallback 命令。
- 将 `release-easydict` 的详细 Release 生命周期、状态、内容选择和恢复流程集中到按需读取的
  `references/release-workflow.md`；根 Skill 只保留动作路由、授权边界和完成条件。
- 按用户要求删除 `.claude/settings.local.json`，不迁移其中的本地权限。

### 设计意图

根 Agent 入口直接提供每个任务都需要的最小决策边界，专题文档和 Skill reference 只在相关任务
中加载。高风险发布授权继续留在 Skill 入口，具体步骤保持自我完备但采用渐进披露。

### 验证

- 构建测试命令区块与初始 HEAD 比较：完全一致。
- `python3 /Users/tisfeng/.codex/skills/.system/skill-creator/scripts/quick_validate.py
  .agents/skills/release-easydict`：通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：
  23 个测试通过。
- 现行文档旧路径检索和 Release reference 目标检查：通过。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改治理 Markdown、Skill 指令和 Claude 本地配置。

### 受影响文件

- `AGENTS.md`
- `docs/agents/build-and-test.md`
- `docs/agents/task-modes.md`
- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/commands.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `.claude/settings.local.json`
- `docs/exec-plans/completed/2026-09/2026-09-13-astra-agent-docs-follow-up.md`
- `docs/histories/2026-09/2026-09-13-astra-agent-docs-follow-up.md`

### 后续事项

- None
