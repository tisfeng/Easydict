# 收敛 Agent 文档结构

- 状态：completed
- 创建日期：2026-09-08
- 完成日期：2026-09-08
- 负责人：Codex
- 关联 Issue/PR：无

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 目标结果：将根入口与 `docs/agents/` 从 11 份文档收敛为根入口和 5 份专题规则，减少
  重复条款与任务路由负担，并保持现有请求、写入、交付、验证和受管资产边界。
- 允许修改路径：`AGENTS.md`、`CONTRIBUTING.md`、`docs/agents/`、
  `docs/design-docs/agent-documentation-structure.md`、
  `docs/design-docs/external-agent-assets-management.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-08-agent-document-consolidation.md`。
- 禁止动作：修改产品源码、Xcode 工程、公共用户文档内容、受管 Skills、
  `.codex/agents/*.toml`、双 lock 或远程 Git 状态；不批量改写历史计划和历史记录。

## 写入前状态

- 写入前检查：pass；自动提交资格：eligible。
- 初始 HEAD：`f61433859af9a6053a6fe63414e1efff8f4b6e1e`，detached HEAD。
- 初始 staged、unstaged、untracked、冲突：均为空。
- Agent-owned paths：允许路径中本任务实际产生差异的文件。

## 目标与非目标

### 目标

- 保持 `AGENTS.md` 为唯一入口，压缩通用约束和专题路由。
- 将执行安全并入请求边界，将代码质量、Swift/Xcode 与本地化并入开发规则。
- 将外部 Agent 资产治理并入 `docs/agents/README.md`，只要职责内聚且文件少于 500 行
  就不因行数继续拆分。
- 删除被合并的重复文档，更新全部现行链接和结构说明。
- 用代表性任务场景验证重组前后的授权和交付语义一致。

### 非目标

- 不减少或重写 planner、reviewer、tester、git-delivery 运行角色。
- 不改变默认自动本地提交、history、PR review 或受管资产同步政策。
- 不运行产品构建、测试、PR、发布、push、pull、rebase 或 merge。

## 工作计划

1. 建立唯一权威归属，将重复条款迁移到对应专题文件。
2. 更新根路由、贡献指南、设计说明和现行相对链接。
3. 搜索旧路径并执行 Markdown 链接、语义场景和格式验证。
4. 完成独立审查，修复有效问题并覆盖最终快照。
5. 创建 history、将计划归档到 `completed/`，按门禁自动本地提交且不 push。

## 风险与决策

- 以行为等价为第一优先级，不因减少文件数删除授权、安全或交付约束。
- `README.md` 可承载文档和外部资产治理，只要职责仍属于仓库治理且不超过 500 行。
- `git-workflow.md` 只保留项目策略和主 Agent 契约，受管 `git-delivery` 的内部算法不再复制。
- 历史计划和 history 保留原路径作为历史证据，不因当前重组批量改写。

## 进度

- [x] 冻结初始 Git 状态、允许路径和非目标。
- [x] 完成文档合并、删除和路由更新。
- [x] 完成静态验证与语义场景检查。
- [x] 完成独立审查与必要修复。
- [x] 归档计划、补齐 history 并进入本地自动交付。

## 验证

- `git diff --check` 通过；11 个变更 Markdown 的相对文件链接均能解析，两个新锚点存在。
- 现行入口、贡献指南、架构、设计、参考、用户文档和 `.codex` 中没有被删除规则文件的
  活动引用；历史计划与 history 保留原路径作为历史证据。
- planning、禁止提交、自动本地提交、脏索引、显式 staged commit、只读 PR review、
  integration、受管资产同步、验证失败、允许路径超集和精确暂存 11 个场景检查通过。
- 独立 reviewer 首轮发现两项 Git 集合关系问题；修复后确认 `owned = expected`、
  `expected ⊆ allowed`、`staged = expected`，并区分显式 staged 与 integration 复用路径。
  增量复审没有新增 finding。
- 根入口和 5 份专题规则共 511 行，单文件最高 108 行；受管 agent、双 lock 和产品路径无差异。
- 未运行 Xcode：本任务只修改仓库治理 Markdown，静态检查不证明实际 Git 或 GUI 行为。

## 完成条件

- 根入口和 5 份专题规则成为唯一现行结构，旧文件没有活动引用。
- 必须保留的行为边界在新结构中可唯一定位，语义场景回归一致。
- 独立审查和静态验证覆盖最终快照且没有有效阻塞 finding。
- history 已记录结果，计划已移入 `completed/`，变更已进入自动本地交付且不 push。
