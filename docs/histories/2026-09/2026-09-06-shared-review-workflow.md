## 2026-09-06 | 任务：通用 Review 与并行任务收尾

**Links:** [执行计划](../../exec-plans/completed/2026-09-06-shared-review-workflow.md)

### 用户请求

拆分通用 review，支持任务、本地工作树、提交/range、文件与模块；新增独立 reviewer，
与 gpt-5.6-terra tester 并行完成审查和验证。PR review 自动 resolve 有远程证据的
已修复或不再适用线程，主 Agent 及时修复任务内有效问题。

### 变更

- 新增只读 review 核心及 reviewer 配置，明确快照、归属、证据与修复责任。
- 更新任务收尾及提交门禁，最终代码和测试需完成增量复核与相关验证。
- 保留 PR checkout helper，新增双层分页、证据 plan、前后状态守卫和读回结果。
- 新增离线测试；独立审查发现分页末尾 head 漂移窗口，补充最终身份检查与回归测试。

### 设计意图

通用审查与 GitHub 编排分离；reviewer 只读，tester 只写获准测试，主 Agent 修复和交付。
outdated 标记及本地未推送修复不能证明远程问题已消失。GitHub API 无 expected-head CAS，
前后刷新减少但不能消除竞态，不把状态不确定报告为成功。

首轮 reviewer 文件不硬编码模型，调用时保持主任务配置；配置优先级依据
[OpenAI 官方子代理文档](https://learn.chatgpt.com/docs/agent-configuration/subagents)。
本次未热加载 custom reviewer，使用传入相同只读指令的独立子任务回退；tester 显式
使用 gpt-5.6-terra/high。未访问真实 PR 执行 mutation。

### 验证

- 独立 reviewer：完成第一轮审查及 merge-parent/outdated 两个只读场景检查。
- `quick_validate.py`：review 和 review-pr 均通过。
- reviewer TOML 解析与 `git diff --check`：通过。
- `python3 .agents/skills/review-pr/tests/test_review_threads.py -v`：18/18 通过。
- `python3 .agents/skills/review-pr/tests/test_prepare_pr_branch.py -v`：6/6 通过。
- 独立 reviewer 增量复核：分页竞态已修复，最终实现和测试无新增 finding。
- 最终 helper SHA256：`6f32fc2d2fbcc08b8e6a4eb6780c4f5d1fd2fb7fc5e7d8b5bf5f510da6ece0b8`；
  测试 SHA256：`1b42c9345ca8215f70fc5ad3aee511f0e4ed8fe2fb9f3c32b87063461082c66e`。
- 本任务不涉及应用源码，未运行 Xcode 构建。

### 受影响文件

- `.agents/skills/review/SKILL.md`
- `.agents/skills/review-pr/` 的 skill、线程 helper、reference 和测试
- `.codex/agents/reviewer.toml`
- `AGENTS.md`、`docs/agents/` 的请求、执行、测试和 Git 规则
- 本任务计划与 history

### 后续事项

- 真实 GitHub 线程处理尚未进行线上验证；按 skill 在后续获准 PR review 中使用。

### 后续调整：固定 reviewer 模型

用户确认将 reviewer 改为 `gpt-6-astra` / `high`，避免审查配置随主任务变化。
同步 reviewer 指令、任务收尾与显式回退说明；planner 的 Astra/high 和 tester 的
Terra/high 保持不变，只读权限及任务边界不变。

本轮初始 HEAD 为 `e37cf95b28066bb4908d43ca08f1185cbb2d718d`，staged、unstaged、
untracked 均为空。允许及实际修改路径仅 reviewer TOML、`docs/agents/build-and-test.md`
与本 history；实施授权包含自动本地提交，不推送。

验证：三个子代理 TOML 解析及配置断言、planner/tester 无差异检查、当前规则一致性
复核和 `git diff --check` 通过。未运行 Xcode，也未验证宿主热加载后的实际调用参数。
