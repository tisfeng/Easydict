# 2026-08-27 | 任务：迁移 Planning 子代理启动入口

**Links:** Scoco reference commit `2b6ff71a1350dd5d731ac360754271a65d5ca1c9`；执行计划：
[`2026-08-27-planning-agent-entry.md`](../../exec-plans/completed/2026-08-27-planning-agent-entry.md)

## 用户请求

将 Scoco 提交 `2b6ff71a1350dd5d731ac360754271a65d5ca1c9` 的 Planning 委派启动契约语义移植
到当前 Easydict 项目，不直接 cherry-pick 来源提交。

## 初始状态

- 仓库：Easydict
- 分支：`dev`
- `initial_head`：`b69e2bfec3a3504ad133a309a17ed32907a3b156`
- 初始暂存区：空
- 初始工作树：干净
- 初始冲突：无

## 变更范围

- 在 `AGENTS.md` 中声明每任务的 Planning 启动契约，拆分 Planning、具体 Skill 和本地
  交付路由。
- 在 `docs/agents/request-boundary.md` 中集中维护只读 planner 的委派、回退和主 Agent
  核验责任。
- 将 `.codex/agents/planner.toml` 的描述从“非简单 planning”泛化为所有 planning 任务，
  保留现有模型、推理强度和只读沙箱。
- 将 `docs/agents/skills.md` 中仍有效的 Easydict Skill、OpenAI 入口和 overlay 说明
  迁移到 `AGENTS.md` 与 `docs/agents/README.md`，再删除职责混杂的 `skills.md`。
- 在 `docs/agents/README.md` 中独立维护应用内置 Agent、运行时资源和后端契约边界。
- 不复制 Scoco 专属产品目录、运行时资源、后端同步脚本或执行事实。

## 适配决策

- Easydict 的 `docs/agents/skills.md` 包含发布、PR、OpenAI 和技术图 overlay 规则，不能
  机械删除；先迁移这些本地规则，再删除文件。
- Easydict 不存在 Scoco 的 `Scoco/Swift/Feature/AIChat/Agent/Docs/`、`agent-home`、
  `ScocoBackend/Docs` 或 `sync-agent-docs` 对应路径，因此不引入这些来源专属引用。
- 已有 completed plan 和 history 中的旧路径属于历史事实，不批量改写；只检查当前活动
  治理文档不残留失效引用。

## 验证

- `git diff --check`：通过。
- 活动 Agent 文档失效引用和来源专属路径扫描：通过。
- 根入口对 Planning、Skill、发布、PR、overlay 和 OpenAI 文档路由扫描：通过。
- planner TOML 解析、只读配置和 Planning 委派关键文本检查：通过。
- completed plan、history 和 Markdown 相对链接：通过。
- 未运行 `xcodebuild`，因为本次仅修改 Agent 文档和 TOML。
