# 强制校验 Git 提交信息结构

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict maintainers
**Links:** `../../../.agents/skills/git-commit/`

## 任务契约

- 任务模式：`implementation`
- 用户目标：修复不符合双语三段式契约的本地提交，并让 `git-commit` skill 在提交前后自动校验实际提交信息。
- 允许动作：仅改写当前未推送提交的信息；新增确定性校验脚本、隔离测试、计划和历史文档；更新目标 skill；按仓库规则自动本地提交。
- 允许修改路径：`.agents/skills/git-commit/`、本计划及对应历史文档。
- 预期交付物：可独立调用的提交信息校验器、完整测试和接入校验器的 skill 流程。
- 验收标准：旧错误信息被拒绝；修正后的双语信息通过；提交前失败不创建提交；提交后验证实际 Git 信息并核对消息文件；全部本地验证通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：执行已确认的提交信息门禁改进方案。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 附件或引用材料：当前 `git-commit` skill 和不合规提交 `0b0beac0fc618cc93a2aab2a1803eaf946547c07`。
- 仅作为证据的内容：当前提交的 parent、tree、远程 refs 和 GitHub commit 查询结果。

## 目标

将“每个语言区块恰好三个正文段落”的自然语言要求变成提交前后都会执行的确定性门禁，并保证失败时保留提交信息文件供修复。

## 范围

- 包含范围：Angular 标题、正文段落、双语分隔线、可选 breaking footer、文件输入、Git commit 输入和预期文件一致性校验。
- 不包含范围：语义翻译质量判断、全仓库 Git hook、CI 门禁、历史远程提交重写或自动修复提交信息。

## 背景

- 当前行为：skill 文档已要求每种语言三个正文段落，但执行流程直接调用 `git commit`，没有机器校验。
- 相关文件：`.agents/skills/git-commit/SKILL.md`、`.agents/skills/git-commit/scripts/`、`.agents/skills/git-commit/tests/`。
- 约束：不能改变用户暂存边界；不能 push；消息改写必须保持原提交 parent 和 tree 不变。

## 风险与缓解

- 风险：校验器误把多行正文当成多个段落。
  - 缓解措施：按空行分段，允许单个正文段落包含多行。
- 风险：提交后实际消息与预览文件不同。
  - 缓解措施：提交后读取 Git commit，并与规范化后的预期文件逐字比较。
- 风险：消息改写意外改变提交内容。
  - 缓解措施：改写前后比较完整 parent 和 tree object ID。
- 风险：本机通用 `python3` 指向 macOS 系统 Python 3.9。
  - 缓解措施：校验器不使用 Python 3.10 才支持的 `zip(strict=True)`，并直接用系统 Python 3.9 运行完整测试。
- 风险：其他 Conventional footer 或畸形 breaking footer 冒充第三个正文段落。
  - 缓解措施：只接受最终且包含非空说明的 `BREAKING CHANGE: ` footer，拒绝所有 footer-like 正文，并要求双语两侧 footer 状态一致。

## 里程碑

- [x] 确认范围、Git 安全条件和错误根因。
- [x] 仅改写不合规本地提交的信息并验证 parent/tree 不变。
- [x] 实现提交信息校验器和隔离测试。
- [x] 将校验器接入 skill 提交前后流程。
- [x] 完成全部验证、历史记录和自动本地提交。
- [x] 将本计划移到 `completed/`。

## 验证

- 命令：Python 单元测试与编译、macOS 系统 Python 3.9 测试、skill `quick_validate.py`、`git diff --check`。
- 手动检查：旧消息失败且指出两个语言区块都只有两个正文段落；修正消息和最终实现提交均通过提交前后校验。
- 观察结果：19 个测试在项目 Python 下通过；13 个校验器测试及修正后的实际 commit 在系统 Python 3.9 下通过；历史错误消息按预期失败；独立前向测试发现的 Python 3.9 和伪 footer 缺口均已修复。

## 决策记录

- 2026-08-23：校验器要求调用方显式指定 `english` 或 `bilingual`，避免中文单区块误通过英语模式。
- 2026-08-23：footer 只支持最终、非空的 `BREAKING CHANGE: ` 段落，不接受无法确定性分类的“特殊说明”或其他 footer。
- 2026-08-23：双语区块必须同时存在或同时不存在 breaking footer，避免两种语言表达不同的兼容性信息。
- 2026-08-23：提交后校验失败时不自动 amend，并保留消息文件供诊断。

## 进度记录

- 2026-08-23：确认错误提交仅存在于本地，安全改写为 `cd8fe06d8e49b4cebf4132618822b34f4df76476`；parent 和 tree 均保持不变。
- 2026-08-23：完成校验器、skill 接入和 19 个单元与临时仓库测试。
- 2026-08-23：独立前向测试发现系统 Python 3.9 与伪 footer 缺口；修复后使用项目 Python 和系统 Python 重新验证通过。
