# 升级受管 Skills 至 v0.3.3 并优化 Agent 规则

- 状态：completed
- 创建日期：2026-09-10
- 负责人：tisfeng
- 关联 Issue/PR：none

## 背景

Easydict 当前将六项通用 Skills 与四个 Codex agents 锁定在 `tisfeng/skills v0.3.2`。
上游 `v0.3.3` 删除 `git-delivery`，改由主 Agent 直接执行 Git Skills，并增加同一内容快照的
规划、审查、验证和仓库证据复用。宿主规则需要与新版契约同步，同时参考 OpenAI 官方延迟优化
原则减少重复上下文、调用、输出和无必要的 LLM 工作。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：无
- 目标结果：同步固定 `v0.3.3` 受管资产，移除旧 `git-delivery`，并语义化更新项目 Agent 规则。
- 允许修改路径：六项受管 Skill 目录、三个保留 agent、旧 `git-delivery`、双 lock、`AGENTS.md`、
  `docs/agents/` 相关规则以及同任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-10-upgrade-managed-skills-v0-3-3.md`
- 禁止动作：不修改项目专属或独立 Skill、应用运行时内容和产品代码；不 push。
- 预期交付物：完整 v0.3.3 快照、匹配的宿主规则、验证证据和一个本地 Angular-style 提交。
- 验收标准：受管内容与 tag 一致，双 lock 有效，旧角色与现行引用清理完成，保护路径不变，
  规则链接、语义场景和相关测试通过。

## 语义与范围

- 用户要求 Agent 做什么：执行已给出的升级与规则优化方案。
- 授权的工作树、artifact 和 external service 操作：修改仓库允许路径、读取远程 tag/npm 元数据、
  运行安装器和检查、本地自动提交。
- 否定、条件和范围限制：无 push 授权；外部受管资产必须来自固定 tag，不能本地修补。
- 前轮仍有效的授权和限制：采用已完成的独立 planner 方案，保留项目专属边界和本地交付。
- 附件或引用中被明确采纳的约束：OpenAI 官方 latency optimization 七原则用于工作流优化，
  不直接改动模型配置。
- 歧义：无。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始工作树与索引为空，路径和验证范围明确。
- 初始 HEAD：`2fc6bf8be6f17d64a6f360095f886e40c05eeff2`
- 初始 staged 路径：无
- 初始 unstaged 路径：无
- 初始 untracked 路径：无
- 初始冲突：无
- Agent-owned paths：上述允许路径中本任务实际产生的全部差异。

## 目标与非目标

### 目标

- 从固定 `v0.3.3` 同步六项 Skills 和 planner/reviewer/tester。
- 按上游升级说明精确删除 `git-delivery` 及其 lock 条目。
- 将宿主 Git、委派、审查和验证规则迁移到新版契约。
- 在不削弱授权和安全门禁的前提下减少重复委派、读取、检查和报告。

### 非目标

- 不修改 `release-easydict`、`fireworks-tech-graph`、`.codex/config.toml` 或 Claude 链接。
- 不修改产品代码、应用内置 Agent/runtime 资源、模型或推理强度。
- 不发布、不创建 PR、不 push。

## 工作计划

1. 核验远程 tag、安装器版本、初始状态和保护路径。
2. 清理旧 agent 并用固定 tag 同步受管 Skills、agents 和双 lock。
3. 语义化更新项目 Agent 规则，保留 Easydict 的 PR、Issue、history 和 Xcode 边界。
4. 运行受管内容、lock、文档、脚本测试和语义场景检查。
5. 委派 tester 验证和 reviewer 最终复核，修复范围内问题并增量复验。
6. 归档计划，完善 history，按新版 `git-commit` Skill 自动本地提交。

## 风险与决策

- 安装器不会自动删除 `git-delivery`；本任务按上游迁移说明精确删除文件与单个 lock 条目。
- 不机械复制上游宿主文档；保留 Easydict 对 PR thread resolve 和 Issue 自动关闭的项目策略。
- 以减少重复工作链路为主要延迟优化，不通过删减安全门禁或擅自更换模型追求表面提速。
- 内容或 Git 状态漂移会使已有证据失效；只对受影响范围补充检查。

## 进度

- [x] 完成独立 planner 评估并核验关键事实。
- [x] 完成 Mutation Gate、远程 tag 和安装器版本核验。
- [x] 同步 v0.3.3 受管资产。
- [x] 更新项目 Agent 规则。
- [x] 完成验证与独立复核。
- [x] 归档计划、完善 history 并进入本地提交交付。

## 验证

- 远程 `v0.3.3^{}`、npm `@tisfeng/codex-agents@0.3.3` 与 `skills@1.5.24` 版本核验通过。
- 六项受管 Skill 目录和三个 agent 文件与 `v0.3.3` archive 完全一致；双 lock 的 ref、revision、
  computed hash 和 SHA-256 通过。
- `git-commit` 19、`review-pr` 27、`submit-pr` 26、agent installer 6，共 78 项测试通过。
- `AGENTS.md` 与 `docs/agents/*.md` 共 28 个相对链接和锚点通过；现行规则、agent 配置和 lock 中
  没有旧 `git-delivery` 引用。
- `git diff --check`、授权/串行/复用/Issue 策略语义检查和保护路径 diff 检查通过。
- 独立 reviewer 未发现 finding；最终 plan/history 收尾由同一 reviewer 增量复核。
- 未运行 `xcodebuild`：本次只修改受管 Skill、agent、lock 和治理文档，没有产品或 Xcode 内容。
- 未在全新任务中验证三个 custom agents 的运行时发现；静态检查不替代该 smoke test。

## 完成条件

- 受管快照和双 lock 与 v0.3.3 契约一致，现行规则不存在旧 `git-delivery` 引用或失效锚点。
- 相关自动化测试、JSON/TOML、文档链接与 `git diff --check` 通过。
- 最终实现快照完成 tester 验证和独立 reviewer 复核。
- 计划移入 `completed/`，history 记录实际结果，并满足未 push 本地提交的交付条件。
