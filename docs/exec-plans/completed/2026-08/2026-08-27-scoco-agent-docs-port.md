# Scoco Agent 文档提交分阶段移植

**Status:** completed
**Created:** 2026-08-27
**Updated:** 2026-08-27
**Owner:** Codex
**Links:** Scoco `b9adbae19`、`896f49435`、`247621028`、`51189a4c9`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将 Scoco 2026-08-27 的四个 Agent 文档提交按相同提交粒度移植到 Easydict。
- 允许修改路径：`.agents/skills/git-commit/`、`.agents/skills/code-simplifier/`、`.codex/agents/planner.toml`、`docs/histories/`、本计划及其完成归档。
- 禁止动作：不直接 cherry-pick；不修改产品代码、测试目标、Xcode 工程、运行时资源或外部服务；不 push、pull、rebase、merge 或 squash。
- 预期交付物：四个独立的 Easydict 本地提交，每个提交对应一个来源提交及其适配 history。
- 验收标准：来源语义按顺序保留，Easydict 既有规则不被覆盖，四个提交可分别验证，最终计划归档且工作树干净。

## 写入前状态

- 写入前检查：`PASS`
- 初始 HEAD：`9856f7d43420b36daa71b0e0c354166efc99ee29`
- 初始分支：`dev`
- 初始 staged：空
- 初始 unstaged：空
- 初始 untracked：空
- 初始冲突：无
- Agent-owned paths：本计划契约中列出的 skill、planner、history 和计划路径。

## 来源提交与适配策略

1. `b9adbae199ac48704dc2f48723e2482faaf8a488`：Easydict 已有一次性空索引 fallback，因此不重复修改 skill；用适配 history 记录核对结果，避免空提交。
2. `896f494358832f54c0d84cd3186d0cc2b89b556c`：泛化 `git-commit` 的项目文案、示例、校验器说明和测试用户名；Easydict 没有 `.agents/openai.yaml`，不执行不存在文件的删除。
3. `24762102854d8b509fd01eb04686c80ee74b0e04`：拆分 `code-simplifier` 通用核心和 Swift/Xcode 专项 reference，保留当前任务授权边界。
4. `51189a4c93d99e578984e120ed5c3409de7643eb`：泛化只读 planner 的角色和仓库读取方式，保留只读与禁止递归委派约束，并归档本计划。

## 实施结果

- [x] 创建 active plan 和 4 个独立 history，未覆盖用户已有变更。
- [x] 完成第 1 个本地提交：`4928be28b75f13321efa37f863f37fa1493d5f75`。
- [x] 完成第 2 个本地提交：`a2c5d61533af3aa48fb10f120cd684572ab33c1b`。
- [x] 完成第 3 个本地提交：`3a9cb73f783e12540fa9183fc73afe7d518e975a`。
- [x] 完成第 4 个本地提交并归档本计划。
- [x] 未修改产品代码、测试目标、Xcode 工程、运行时资源或远程状态。

## 非目标

- 不复制 Scoco 的项目专属 `.agents/openai.yaml`。
- 不复制 Scoco 的目录结构、产品资源、发布规则或其他项目的执行事实。
- 不改变 Easydict 的产品代码、构建配置、测试目标或现有 PR/发布流程。
- 不把四个来源提交合并成一个提交。

## 风险与决策

- 来源第一提交的功能在 Easydict 已存在，采用记录性提交而不是伪造无变化提交。
- 每个来源提交单独适配并单独提交，避免把多个来源提交 squash 成一个提交；整体计划统一记录本次任务范围。
- 所有提交只暂存对应 Agent-owned paths，active plan 和后续 history 不进入不相关的前序提交。

## 验证

- [x] 每个提交前执行 `git diff --check`、精确 staged names 和 staged raw patch 复核。
- [x] 每个提交使用 `validate-commit-message.py` 进行双语提交信息校验，并在提交后用完整 hash 复核。
- [x] `git-commit` 两个测试文件共 19 个 Python 测试通过，相关 Python 文件语法检查通过。
- [x] `code-simplifier` 专项 reference 的链接、格式、generic scope 和授权语义检查通过。
- [x] planner TOML 解析、计划归档、history 链接和最终规则范围检查完成。
- [x] 未运行 `xcodebuild`；本任务只涉及 Agent skill、planner 和治理文档。

## 完成记录

- 2026-08-27：按用户要求以 4 个独立本地提交完成 Scoco 文档提交的 Easydict 语义移植；未执行 push。
