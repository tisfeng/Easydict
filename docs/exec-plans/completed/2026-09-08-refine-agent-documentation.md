# 优化 Agent 文档表达与规则边界

- 状态：completed
- 创建日期：2026-09-08
- 完成日期：2026-09-08
- 负责人：Codex
- 关联 Issue/PR：无

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 目标结果：简化现行 Agent 文档中的重复描述，消除授权、Git 交付和验证规则的歧义，保持
  既有行为不变。
- 允许修改路径：`AGENTS.md`、`docs/agents/`、
  `docs/design-docs/agent-documentation-structure.md`、
  `docs/design-docs/external-agent-assets-management.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-08-refine-agent-documentation.md`。
- 禁止动作：修改产品源码、受管 Skills、`.codex/agents/*.toml`、双 lock 或远程 Git 状态。

## 写入前状态

- 写入前检查：pass；自动提交资格：eligible。
- 初始 HEAD：`12f05421dc3edb29f4d7f68c257b293b11ab0be7`，detached HEAD。
- 初始 staged、unstaged、untracked、冲突：均为空。
- Agent-owned paths：允许路径中本任务实际产生差异的文件。

## 目标与非目标

### 目标

- 解决请求来源、交付授权、PR push、验证触发条件和子代理回退之间的语义冲突。
- 将 Git 路径范围规则改写为可直接执行的自然语言。
- 删除跨文件重复条款，修正不自然或过度抽象的表达。
- 保留 `Plan`、`History` 术语及当前根入口加五份专题规则的结构。

### 非目标

- 不改变自动本地提交、history、PR review、Xcode 阈值或外部资产治理政策。
- 不拆分或合并现行 Agent 规则文件，不批量改写历史记录。

## 工作计划

1. 调整请求边界、Git 交付和验证规则中的冲突与歧义。
2. 精简根入口、仓库治理和开发规则中的重复描述。
3. 修正两份设计文档中过度承诺或重复现行阈值的表达。
4. 执行格式、链接、旧表达和代表性语义场景检查。
5. 完成独立审查，记录 history，归档计划并按门禁本地提交。

## 风险与决策

- 以行为保持不变为首要约束；不通过缩短文字放宽授权或交付门禁。
- 保留 `Plan` 与 `History`，使术语继续对应现有目录名称。
- 路径交付规则使用“逐一列入、不得遗漏、不得混入”的动作描述，不使用抽象集合等式。

## 进度

- [x] 冻结初始 Git 状态、允许路径和非目标。
- [x] 完成文档精简与冲突修复。
- [x] 完成静态验证和独立审查。
- [x] 补齐 history、归档计划并进入本地交付。

## 验证

- `git diff --check` 通过；10 个本任务 Markdown 的 18 个相对文件链接均可解析，所引用锚点
  存在。
- planning、implementation、脏索引、显式 staged 交付、创建 PR、PR review、Xcode 明确要求、
  tester Git 边界和外部 lock 9 个代表性场景检查通过。
- 已确认 `Plan 与 History` 保持不变，旧的集合等式和其他目标歧义表达没有活动残留。
- 独立 reviewer 未发现阻塞问题；收尾措辞调整后完成增量复审。
- 根入口和 5 份专题规则共 516 行，单文件最高 108 行，没有新增或拆分规则文件。
- 未运行 Xcode：本任务只修改仓库治理 Markdown；静态检查不证明真实 Git、运行时或远程行为。

## 完成条件

- 现行文档没有已知冲突、重复权威条款或难以执行的路径范围表达。
- 相对链接、格式和代表性授权场景检查通过。
- 独立审查覆盖最终快照且没有尚未解决的阻塞问题。
- history 已记录结果，计划已归档并进入本地交付，不 push。
