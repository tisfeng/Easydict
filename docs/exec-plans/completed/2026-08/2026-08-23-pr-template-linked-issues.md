# 新增 PR 模板与关联 Issue 解析

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict maintainers
**Links:** `../../../.github/pull_request_template.md`、`../../../.agents/skills/release-easydict/`

## 任务契约

- 任务模式：`implementation`
- 用户目标：新增简洁的中英双语 GitHub PR 模板，并让发布后的 Issue 跟进可靠识别模板中的单一“关联 Issue”区域。
- 允许动作：新增模板，修改本地 release skill 的解析器、测试和策略，同步中英文贡献指南、计划及历史文档，运行本地验证并自动提交。
- 允许修改路径：`.github/pull_request_template.md`、`.agents/skills/release-easydict/`、`docs/user-docs/en/GUIDE.md`、`docs/user-docs/zh/GUIDE.md`、`docs/agents/skills.md`、本计划及对应历史文档。
- 预期交付物：默认 PR 模板、确定性的关联 Issue 引用类型、兼容旧引用的测试与同步文档。
- 验收标准：模板支持裸 `#123`、完整 Issue URL 和现有仓库编号格式；模板占位符不产生候选；显式区域引用去重且不破坏旧引用；全部 release skill 测试、skill 校验和 `git diff --check` 通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：PR 模板只保留一种“关联 Issue”，支持裸编号和完整 Issue URL，不强制单一书写格式。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 附件或引用材料：无。
- 仅作为证据的内容：现有 `release_issues.py` 弱引用收集行为和 Issue 跟进策略。

## 目标

在默认 PR 模板中提供单一“关联 Issue”区域，并让发布 skill 将该区域中的有效同仓库引用标记为明确关联，同时继续兼容旧 PR 的弱引用。

## 范围

- 包含范围：双语模板、PR 正文区域解析、候选去重、策略说明、中英文贡献文档和单元测试。
- 不包含范围：修改 Issue 模板、GitHub Actions、已有 PR 正文、发布命令接口或真实 GitHub Issue 状态。

## 背景

- 当前行为：仓库没有 PR 模板；helper 会扫描整个 PR 正文和 commit message，但不能区分模板中的明确关联与普通弱引用。
- 相关文件：`.agents/skills/release-easydict/scripts/release_issues.py`、`references/issue-followup-policy.md`、`tests/test_release_issues.py`。
- 约束：避免 GitHub closing keyword；Issue 只在包含相关 PR 的版本发布后统一处理。

## 风险与缓解

- 风险：模板占位符或正文其他章节产生错误候选。
  - 缓解措施：使用非数字占位符，并限制显式区域解析范围到下一个同级标题。
- 风险：同一引用同时被显式区域与通用扫描收集。
  - 缓解措施：显式区域优先占用匹配范围，并补充去重测试。
- 风险：新格式破坏旧 PR。
  - 缓解措施：保留完整 URL、仓库编号、裸编号和 closing reference 的现有兼容路径。

## 里程碑

- [x] 确认范围和约束。
- [x] 实现 PR 模板和关联 Issue 区域解析。
- [x] 同步策略、贡献指南和 Agent 文档。
- [x] 补充并运行测试与静态验证。
- [x] 记录历史并将本计划移到 `completed/`。

## 验证

- 命令：release skill Python 单元测试、Python 编译、`quick_validate.py`、`git diff --check`。
- 手动检查：模板不包含真实 Issue 编号或自动关闭语法；中英文说明一致。
- 观察结果：24 个 release skill 单元测试通过；Python 编译、skill
  `quick_validate.py` 和 `git diff --check` 通过。

## 决策记录

- 2026-08-23：模板只提供一种“关联 Issue”，不要求贡献者区分已解决和仅相关。
- 2026-08-23：支持裸编号、完整 Issue URL 和现有仓库编号格式，模板推荐一行一个但不强制单一格式。

## 进度记录

- 2026-08-23：完成只读现状检查，开始实现模板和解析器。
- 2026-08-23：完成模板、显式区域解析、策略和贡献指南同步；全部本地验证通过。
