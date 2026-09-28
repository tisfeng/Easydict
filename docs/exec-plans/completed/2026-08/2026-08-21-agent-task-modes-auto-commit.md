# Agent 任务模式与自动本地提交

- 状态：completed
- 创建日期：2026-08-21
- 完成日期：2026-08-21
- 负责人：Easydict 维护者
- 关联 Issue/PR：none

## 背景

仓库需要明确区分计划、方案、讨论与实际实现，避免只要求方案时修改代码。同时，
实现任务需要明确自动本地提交的暂存区保护条件，避免扩大用户已有变更范围。

## 任务契约

- 用户目标：增加 planning 门禁和安全的 implementation 自动提交规则。
- 允许动作：修改仓库 Agent 指南、`git-commit` skill 和执行计划模板。
- 允许修改路径：`docs/agents/repository-guide.md`、`.agents/skills/git-commit/SKILL.md`、
  `docs/exec-plans/templates/execution-plan.md` 及本执行计划和完成历史。
- 预期交付物：任务模式、暂存区保护、一次性自动本地提交和验证规则。
- 验收标准：规则可执行，自动提交不扩大用户暂存范围，文档检查通过。

## 输入来源

- 用户明确请求：补齐 `3d773f69d` 的任务模式和自动提交保护规则。
- 仓库规则：`AGENTS.md`、`docs/agents/` 和现有 `git-commit` skill。
- 附件或引用材料：Scoco 提交 `3d773f69d`，仅提取通用工作流语义。
- 仅作为证据的内容：当前 Easydict 的 Git 状态和现有 skill 文本。

## 目标

- 为 planning、implementation、delivery 和 protected 建立清晰的任务模式。
- 让 planning 默认只读，不修改产品代码或提交。
- 让 implementation 只有在初始暂存区为空、路径可隔离和验证通过时才能自动提交一次。
- 让已有暂存内容、路径重叠、冲突和验证失败进入保护模式。

## 非目标

- 不修改产品代码、测试或 Xcode 工程。
- 不自动 push、pull、rebase、merge 或创建分支。
- 不改变显式 `/git commit` 的既有提交流程。
- 不对纯 Agent 文档、计划或历史变更执行自动提交。

## 工作计划

1. 更新仓库指南中的任务模式和自动本地提交规则。
2. 更新 `git-commit` skill 的自动 implementation delivery 流程。
3. 更新执行计划模板中的任务模式和提交状态字段。
4. 运行文档和 Git 差异检查，归档计划并记录历史。

## 风险与边界

- 自动提交的便利性可能掩盖未完成验证，因此验证失败必须进入 protected 模式。
- 用户已有未暂存变更与 Agent 路径重叠时无法安全拆分，必须跳过自动提交。
- 文档-only 任务不应因新增规则而自动提交。

## 决策记录

- 2026-08-21：将 planning 规则放入每个任务都会读取的 `repository-guide.md`。
- 2026-08-21：自动模式只暂存明确 Agent 路径；显式 `/git commit` 保留既有一次性 fallback。
- 2026-08-21：本次只修改 Agent 文档和 skill，不触发自动本地提交。

## 进度

- [x] 更新任务模式和自动本地提交规则。
- [x] 更新 `git-commit` skill。
- [x] 更新执行计划模板。
- [x] 完成验证并归档计划。

## 验证

- `git diff --check`：通过。
- 新执行计划无尾随空白；规则引用和自动提交边界已复核。
- 未运行 `xcodebuild`，因为没有修改编译源码、测试或 Xcode 工程元数据。
- 未执行自动 commit，本次变更属于 Agent 文档和 skill 规则。

## 完成条件

- 任务模式和自动提交规则位于稳定的 Agent 入口文档和 skill 中。
- 自动模式明确保护初始暂存区、用户既有变更和验证失败。
- 计划已归档，并在 `docs/histories/` 记录结果。
