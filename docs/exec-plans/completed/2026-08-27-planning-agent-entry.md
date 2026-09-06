# Planning 子代理启动入口迁移

**Status:** completed
**Created:** 2026-08-27
**Updated:** 2026-08-27
**Owner:** Codex
**Source:** Scoco `2b6ff71a1350dd5d731ac360754271a65d5ca1c9`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将 Scoco 的 Planning 委派启动契约适配到 Easydict 的 Agent 文档结构。
- 允许修改路径：`AGENTS.md`、`docs/agents/README.md`、
  `docs/agents/request-boundary.md`、`docs/agents/skills.md`、
  `.codex/agents/planner.toml`、本计划、同任务 history。
- 禁止动作：不直接 cherry-pick；不修改产品源码、测试、Xcode 工程、运行时资源或远程
  Git 状态；不 fetch、pull、rebase、merge 或 push。

## 初始 Git 快照

- 仓库：Easydict 当前 checkout
- 初始分支：`dev`
- `initial_head`：`b69e2bfec3a3504ad133a309a17ed32907a3b156`
- 初始暂存区：空
- 初始工作树：干净
- 初始冲突：无

## 目标与验收标准

- `request-boundary.md` 成为每个任务的 Planning 启动契约，统一规定只读 planner 委派、
  回退和主 Agent 责任。
- `AGENTS.md` 直接区分 Planning 子代理、具体 Skill 和 Easydict 专属路由。
- `planner.toml` 适用于所有 planning 任务，不再使用“非简单 planning”表述，同时保留
  现有模型、推理强度和只读沙箱。
- 删除职责混杂的 `docs/agents/skills.md` 前，迁移其仍有效的 Easydict Skill、OpenAI
  入口和 overlay 路由；不丢失 `release-easydict`、`submit-pr` 或技术图规则。
- `docs/agents/README.md` 独立维护应用内置 Agent、运行时资源和后端契约边界，不复制
  Scoco 专属目录或同步脚本。
- 创建同任务 history，完成后将本计划归档到 `docs/exec-plans/completed/`。

## 实施步骤

1. 将 Planning 委派、回退和只读约束从 `docs/agents/skills.md` 移到
   `docs/agents/request-boundary.md`。
2. 更新 `AGENTS.md` 的启动契约和直接路由，并把仍需发现的 Easydict Skill 入口补齐。
3. 将应用内置 Agent 边界整理到 `docs/agents/README.md`，更新 `planner.toml`，删除旧的
   `docs/agents/skills.md`。
4. 创建 history，运行文档、TOML、链接、范围和格式验证，归档本计划。
5. 在验证通过且 Git 门禁仍满足时，只暂存本任务路径并创建一个本地 Angular-style
   双语提交；不 push。

## Easydict 适配决策

- 来源的 `Scoco/Swift/Feature/AIChat/Agent/Docs/`、`agent-home`、`ScocoBackend/Docs`
  和 `sync-agent-docs` 在 Easydict 中不存在，不移植。
- Easydict 的 `docs/agents/skills.md` 比来源版本包含发布、PR、OpenAI 入口和本地
  overlay 说明；这些语义会迁移到目标仓库现有入口，不机械删除后丢失。
- 已有 history 和 completed plan 中对旧 `docs/agents/skills.md` 的引用属于历史事实，
  不批量改写；活动治理文档不得残留失效引用。

## 风险与验证

- 删除 `skills.md` 可能造成路由遗漏；通过逐条迁移盘点、根入口扫描和关键路径存在性检查
  缓解。
- 静态规则正确不等于宿主运行时一定启动 planner；本任务只验证文件和配置，不伪装成
  runtime smoke test。
- 已验证：`git diff --check`、planner TOML `tomllib` 解析、活动文档失效引用扫描、
  Easydict 专属路由扫描、Markdown 相对链接检查和精确变更范围复核。
- 本任务仅修改 Agent 文档和 TOML，不运行 `xcodebuild`。

## 完成记录

- 已完成 Planning 委派规则迁移、Easydict 路由保留和 `docs/agents/skills.md` 删除。
- 已创建同任务 history，并将本计划归档到 `docs/exec-plans/completed/`。
- 已通过提交前所需静态验证，未执行远程 Git 操作。
