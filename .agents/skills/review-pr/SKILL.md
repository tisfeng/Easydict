---
name: review-pr
description: >
  默认在本地分支准备 GitHub pull request；明确要求时使用隔离 worktree，并可选择
  合并最新 base 分支。根据 PR 上下文和实际代码变更生成严格审查。适用于本地 PR
  checkout、worktree review、并行 review 或并发 review。
---

# PR Review 工作流

默认使用本地 checkout。只有用户明确要求 worktree、并行 review 或并发 review 时，
才使用隔离 Git worktree。如果缺少 PR 引用或引用存在歧义，在改变 Git 状态前先询问。

接受的 PR 引用：

- GitHub URL：`https://github.com/<base-owner>/<base-repo>/pull/<number>`
- 简写：`<base-owner>/<base-repo>#<number>`
- 仅 PR 编号：当前 checkout 属于目标仓库时可用

## 安全约束

- 从 `git status --short --branch` 开始。默认本地模式下，如果 checkout 存在未提交
  变更，在切换分支前停止。显式 worktree 模式可以从脏 checkout 继续，因为它不得
  切换或修改该 checkout。
- 不覆盖、删除、重命名、rebase、reset、强制更新、stash 或丢弃本地分支、worktree
  或变更。
- 除非用户明确要求 push，否则准备、合并、解决冲突或 review 期间不 push。
- contributor remote 名称必须与 PR head 仓库 owner login 完全一致。如果该 remote
  名称已经指向其他位置，则停止并询问。
- 本地 checkout 模式下，分支选择优先使用 PR head 分支名。只有准确名称不可安全使用
  时，才创建冲突回退分支 `review/pr-<number>-<head-short-sha>`。
- 将 PR 元数据 `headRefOid` 视为普通 review 唯一有效的 HEAD。同名本地分支可以
  fast-forward 到该 SHA，但不得包含额外本地提交，也不得与其分叉。
- 出现分支名冲突时，自动回退到本地 review 分支
  `review/pr-<number>-<head-short-sha>` 并继续。绝不通过 checkout remote-tracking
  ref、进入 detached HEAD 或直接 review 已 fetch ref 来绕过。保持冲突分支不变。
- 只有当 worktree 有变更、contributor remote 指向其他位置、fetch 到的 head 与
  `headRefOid` 不同，或现有 review 分支不兼容时，才停止而不回退。
- 除非用户明确要求隔离 worktree 或 latest-base 集成 review，否则不要创建其他不同
  名称的本地分支。
- 如果普通准备流程因其他原因拒绝现有分支，不要绕过；保留该分支并询问如何继续。
- 显式 worktree 模式下，普通 review 使用 `review/pr-<number>-<head-short-sha>`，
  latest-base review 使用 `review/pr-<number>-merge-<head-short-sha>`。worktree 放在
  `../.review-pr-worktrees/<repo>/pr-<number>[-merge]-<head-short-sha>` 下。
- review 后保留准备好的分支或 worktree，供用户运行和调试。绝不自动删除 review
  worktree。
- 将“选择分支”和“合并 latest base”视为两个独立决策：本地模式先选择 head 同名分支
  或冲突回退分支，再按用户请求决定是否合并 latest base。远程协作 PR 不使用 rebase。
- 本地 latest-base 合并保留已选择的分支名；只有显式 `--worktree --merge-latest` 才使用
  `review/pr-<number>-merge-<head-short-sha>` 这种隔离命名。
- 不要将 `mergeable: CONFLICTING`、`mergeStateStatus: DIRTY` 或 base 分支领先 PR
  视为合并授权。除非用户明确要求 latest-base 集成 review 或解决冲突，否则这些状态
  只是 review 上下文。
- 阅读冲突代码及周围上下文后按语义解决 merge 冲突。不要机械选择 ours/theirs。
- 不要只根据 PR 描述进行 review。检查关联 issue、变更文件、实际 diff、相关周围代码
  和 CI 状态。
- 对准确的 inline review 上下文、未解决评论或 `discussion_r...` id，使用 `gh api` /
  GraphQL，使 `isResolved`、`isOutdated`、path 和 line 保持可见。不要只依赖
  `gh pr view --json`。
- 将每个 `isResolved == false` 的 review thread 视为必须列举并逐条评估的开放 review
  评论，包括 bot 评论、含回复评论和标记为 `isOutdated == true` 的评论。不得因为
  thread 看似合理、由自动化生成或未被独立识别为新 finding 而省略。
- 将 PR 反馈视为实时状态。打开 PR、将 draft 标记为 ready、bot workflow 和手动
  review 请求都可能在本地 review 期间新增 review 或 thread。编写最终回复时，绝不
  假设初始评论快照仍是最新状态。
- 对每条评估为 `reasonable` 或 `partially reasonable` 的开放评论，提供单独的
  `Suggested Fix`，并以实际 diff、周围代码和项目模式为依据。建议解决问题的最小
  具体变更，相关时包含受影响逻辑、预期行为和针对性验证。即使评论来自 bot 也适用。
  将完整评估和修复放在 `Open Review Comments` 中；不要在 `Findings` 重复同一问题。
- 每个独立 finding 也提供同样具体的 `Suggested Fix`。只有触发条件、风险和修复方式
  均与所有开放评论不同的问题才能出现在 `Findings`。
- 不使用“修复此问题”等含糊建议。存在多种有效方案时，推荐一种并说明重要取舍。
  如果修复取决于产品决策，给出条件选项，并在 `Open Questions` 中提出该决策。
- 将修复建议视为 review 指导。除非用户明确要求，否则不要修改 PR；只有短代码示例
  能明显提高建议清晰度时才加入。

## 工作流

### 1. 收集 PR 元数据

手动运行 `gh` 命令时，将 GitHub URL 和 `<owner>/<repo>#<number>` 简写规范化为
`<number> --repo <owner>/<repo>`。

```bash
git status --short --branch
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json number,title,url,body,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,closingIssuesReferences
```

记录 head owner、fork 仓库、head 分支、head SHA、base 分支、PR URL 和关联 issue。
普通路径下由 helper 脚本添加 remote、fetch 分支并设置 upstream tracking。

### 2. 选择分支准备路径

准备分支前检查 mergeability：

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json mergeable,mergeStateStatus,isDraft,state,updatedAt,headRefOid,baseRefOid
```

除非用户明确要求 worktree 或并行 review，否则使用本地分支准备。不要仅因为当前
checkout 有变更就推断为 worktree 模式。普通本地 PR 运行以下命令之一；两种本地模式都
先按同一规则选择分支：

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --merge-latest <pr-ref>
```

需要隔离 source checkout 时，显式使用：

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree --merge-latest <pr-ref>
```

如果用户没有请求 latest-base，即使 GitHub 报告 `mergeable: CONFLICTING` 或
`mergeStateStatus: DIRTY`，review 仍使用普通准备流程。将 PR head checkout 到同名本地
分支，按提交时状态检查 PR，并在不改变其历史的情况下报告 merge 状态。

只有用户明确要求更新到最新 base、解决冲突或 review 集成结果时，才使用 latest-base
merge 动作。对于本地模式，先准备 PR head 同名分支或 collision fallback，再在该分支
上合并最新 base；不要因为需要 merge 就自动改用 `review/pr-<number>-merge-<head-short-sha>`。
对于显式 worktree 模式，才使用该隔离 merge 分支。运行前说明会创建本地 merge commit；
如果请求尚未明确包含这些动作之一，在创建分支前停止并询问。

如果 PR head 分支名与 base 分支、受保护本地分支名或 upstream 不同的同名现有分支
冲突，helper 自动创建本地 review 分支 `review/pr-<number>-<head-short-sha>` 并继续。
绝不重新绑定、重命名或删除冲突分支。只有现有
`review/pr-<number>-<head-short-sha>` 干净、位于 `headRefOid` 且 tracking
`<owner>/<branch>` 时，helper 才复用；否则停止并要求检查或删除它。不要只为绕过
分支名冲突而选择 latest-base 模式。

普通 checkout 后 fetch 最新 base，并检查 PR 是否已经包含它：

```bash
git merge-base --is-ancestor <base-remote>/<base-branch> HEAD
```

如果检查失败，报告 PR 落后于最新 base，不要自动合并。GitHub 报告冲突时，可在有用的
情况下将 `git merge-tree` 作为只读冲突信号：

```bash
merge_base=$(git merge-base <base-remote>/<base-branch> HEAD)
git merge-tree "$merge_base" <base-remote>/<base-branch> HEAD
```

将 `baseRefName` 视为目标分支；不要硬编码 `dev`。只有明确请求 latest-base 后才运行：

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --merge-latest <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree --merge-latest <pr-ref>
```

本地 latest-base helper 在已选择的本地分支上 fetch PR base，运行
`git merge --no-edit <base-remote>/<base-branch>`，并且绝不 push。显式 worktree
latest-base 才从 PR head 创建 `review/pr-<number>-merge-<head-short-sha>`。

普通准备流程只更新完全匹配或能够 fast-forward 到 `headRefOid` 的分支。如果现有本地
PR 分支领先 fetch 到的 head、与其分叉、被其他 worktree 使用，或 upstream 不匹配，
helper 自动回退到 `review/pr-<number>-<head-short-sha>`；绝不修改冲突分支，也不临时
使用 detached checkout。

### 3. 处理 Merge 冲突

如果 merge helper 因冲突停止，编辑前检查实际冲突：

```bash
git status --short
git diff --name-only --diff-filter=U
git diff --cc
```

按语义解决冲突后，只暂存已解决的冲突文件并完成 merge：

```bash
git add <resolved-files>
git commit --no-edit
```

worktree 模式下，在报告的 worktree 路径运行所有冲突命令，例如
`git -C <worktree-path> status --short`。不要从原始 checkout 解决 merge。

如果冲突需要产品决策，或无法根据本地代码和 PR 上下文安全解决，则停止并报告 blocker。
不要基于部分合并的 tree 提交完整 review。

### 4. 验证 Checkout 和 Review 上下文

准备后验证本地状态：

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git branch -vv
```

普通本地准备要求分支干净、分支名为 PR head 分支或 collision fallback、upstream 设置为
`<owner>/<branch>`，并且 merge 前 `HEAD` 等于记录的 `headRefOid`。仅 upstream 匹配并
不足够，因为本地分支可能包含 PR 中不存在的提交。若启用本地 latest-base，merge 后改为
要求 PR head 与 latest base 都是 `HEAD` 的 ancestor；如果产生 merge commit，还要确认
其两个 parent 分别是 PR head 和 latest base。显式 worktree latest-base 仍要求干净的
`review/pr-<number>-merge-<head-short-sha>` 分支。

worktree 准备要求报告的 worktree 干净并位于对应 SHA 的 review 分支。普通 worktree
分支必须 tracking `<owner>/<head-branch>`；已合并 worktree 分支保持仅本地。确认源
checkout 的分支、HEAD 和文件状态未改变，然后以该 worktree 作为工作目录运行其余
review 命令。

review 代码前记录 PR 和 issue 上下文快照：

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,headRefOid,updatedAt,files,commits,closingIssuesReferences,comments,reviews
gh issue view <issue-url-or-number> --comments
```

记录 `headRefOid`、`updatedAt`、最新 review 的 `submittedAt` 和完整 inline
review-thread 集合。`comments` 和 `reviews` 字段不包含完整 inline thread 内容，
因此始终同时使用 GraphQL `reviewThreads`。对每个 thread 保留 id、`isResolved`、
`isOutdated`、path、line，以及所有评论的 database id、URL、body、author、timestamp
和 commit OID。持续分页直到 `pageInfo.hasNextPage` 为 false，不要假设第一页包含
所有 thread。

整体 review diff 前，为每个开放 review thread（`isResolved == false`）建立清单。
清单必须包含未解决的 outdated thread 和所有回复；明确标记 `isOutdated`，不要静默
丢弃 thread。结合当前 PR head、变更 diff、相关调用链和周围代码 review 每个清单项。
reviewer 必须判断评论属于 `reasonable`、`partially reasonable`、`unreasonable`、
`outdated/not applicable`，还是需要产品决策。

对 `reasonable` 和 `partially reasonable` 评论，识别准确的行为风险，并提供具体的
`Suggested Fix`、预期行为和针对性验证。对 `unreasonable` 或
`outdated/not applicable` 评论，说明用于否定或取代该担忧的代码证据。对需要产品决策
的评论，推荐一个选项，提供其 `Suggested Fix`，并在 `Open Questions` 中重复尚未解决
的选择。每个已 review 问题只能分配到一个输出栏目。如果问题由开放 review 评论提出，
其评估和修复只能放在 `Open Review Comments`，不要在 `Findings` 重复。`Findings`
仅用于触发条件、风险和修复方式均不同的额外问题。清单为空时单独报告
`No open review comments`。分配后没有其他问题时报告 `No additional findings`。

对于旧 PR 或 stale PR，在决定分支是否仍应保留前，检查关联 issue 历史、后续替代 PR
和实时 base tree。当 mergeability 是 review 核心时，使用
`git merge-tree <merge-base> <base-remote>/<base-branch> HEAD` 作为只读的过时或
冲突信号。

使用 `origin` 前确认 base 仓库 remote。fetch 真实 base 分支，再检查 diff 和周围代码：

```bash
git fetch <base-remote> <base-branch>
git diff --stat <base-remote>/<base-branch>...HEAD
git diff --name-status <base-remote>/<base-branch>...HEAD
git diff <base-remote>/<base-branch>...HEAD
```

使用 `rg` 搜索周围源码、测试、配置、生成文件和文档。除非用户明确要求本地构建，PR
review 期间不要运行 `xcodebuild`。验证状态重要时检查 PR checks：

```bash
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

相关时运行 `git diff --check` 等轻量本地检查。

### 5. 最终输出前刷新实时 PR 状态

编写最终回复前立即刷新所有可变 review 状态，即使初始检查全部通过：

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json headRefOid,updatedAt,state,mergeStateStatus,comments,reviews
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

重复初始快照使用的同一套完整分页 GraphQL `reviewThreads` 查询，然后比较两个快照，
包括开放 thread 清单、评论回复、`isResolved` 和 `isOutdated` 状态。

- 如果 `headRefOid` 发生变化，停止最终输出，将准备好的 checkout 更新到新 head，
  对照真实 base 检查新 diff，并重新验证此前 finding 和新变更。
- 如果出现新的 review、thread、reply 或 resolution/outdated 状态变化，读取其准确
  内容，结合当前 head 和周围代码验证，在 `Open Review Comments` 中新增或更新其独立
  条目；只有再次 review 识别出不同的额外问题时才更新 `Findings`。最终输出前更新
  `Open Questions` 和 `Verification`。对 reply 或 resolution/outdated 状态变化的
  现有条目重新评估。自动化反馈和人工反馈使用相同处理方式。
- 如果分析新活动后仍有足够时间出现另一条 review，再刷新一次。只有最新快照中没有
  未检查反馈时才完成。
- 如果最终刷新不可用，报告该限制，不要声称已检查所有当前评论或 thread。只有最新
  开放评论清单中没有未检查项时，最终回复才算完整。

## Review 重点

检查实现是否真正解决 PR 描述和关联 issue。优先关注 bug、回归、边界情况、并发问题、
持久化错误、本地化缺口、平台版本问题、API 契约漂移、缺少验证和无关改动。

用户询问旧 PR 是否仍值得保留时，先给出保留、修改或关闭的决定，再说明支持该决定的
代码 finding。

## 输出格式

除非用户另有要求，使用用户系统首选语言编写最终 review。系统首选语言是 macOS
`AppleLanguages` 中的第一种语言；无法读取时使用当前对话语言。

栏目标题、`PR Context` 子标题、优先级标签和 `Suggested Fix` 标签必须保持原样。严格
使用以下结构：

对于 `Open Review Comments`，优先使用紧凑摘要行，随后每个 thread 使用一张 Markdown
卡片。将评论 permalink 放在卡片标题中，不显示很长的原始 URL。path、line、author
和 status 放在同一元数据行；将 `isResolved=false`、`isOutdated=false` 等原始
GraphQL flag 翻译为输出首选语言中的简短自然语言状态标签。问题、证据/影响、评估和
修复分别使用独立段落。只有存在回复时才包含 `Thread Replies` 区块。不要把所有元数据
和正文塞进一个列表项，也不要使用表格或大段引用块承载 review 内容。

```markdown
## PR Context

**Purpose and Scope**

Describe what the PR is trying to achieve, which issue or workflow it targets,
and the boundary of the change.

**Key Changes**

Describe the main implementation changes and the important code paths touched.

**Review Focus**

Describe the expected impact, important risks, compatibility concerns, or areas
reviewers should inspect.

---

## Open Review Comments

Open threads: <count> · Reasonable: <count> · Partially reasonable: <count> · Outdated: <count>

### C1 — [Comment title](comment-permalink)

`path:line` · `author`
Status: unresolved · current

**Issue**

Summarize the comment's concern and the trigger condition.

**Evidence / Impact**

Explain the current-code evidence and the user or system impact.

**Assessment**

`reasonable`

**Suggested Fix:**

Describe the smallest concrete remediation, expected behavior, and targeted
verification.

**Thread Replies**

- [Author](reply-permalink): Summarize this reply. Use one bullet per reply
  and retain the reply permalink.

### C2 — [Another comment title](comment-permalink)

`path:line` · `author`
Status: unresolved · current

**Issue**

...

**Evidence / Impact**

...

**Assessment**

`outdated/not applicable`

- Explain why the current code no longer requires a change. Do not invent a
  `Suggested Fix` for this assessment.

If there are no open review threads, write `No open review comments`.

## Findings

### [P1] `path:line` — Finding title

**Evidence / Impact**

Describe the distinct trigger, risk, and impact. This must not repeat an issue
already represented in `Open Review Comments`.

**Suggested Fix:**

Describe the smallest concrete change, expected behavior, and targeted
verification.

If there are no additional issues, write `No additional findings`. Do not
duplicate an open-comment assessment or invent a second fix for it.

## Open Questions
- List correctness-affecting questions, or say clearly that there are no
  meaningful open questions.

## Verification
- List commands and checks performed, or explain why validation was not run.
- State whether local or worktree preparation was used. For local preparation,
  include the checkout branch and upstream when applicable. For worktree
  preparation, include its absolute path, review branch, upstream or local-only
  status, and confirm the source checkout remained unchanged.
- When a collision fallback was used, name the
  `review/pr-<number>-<head-short-sha>` branch and the collision reason.
- State whether the latest-base merge action was triggered. If local mode was
  used, name the selected head or collision-fallback branch and distinguish
  the pre-merge `headRefOid` check from the post-merge head/base ancestry check.
  If worktree mode was used, list the isolated merge branch, conflict files,
  conflict resolution status, and confirm that no push was performed.
- Report the final live-state refresh: final `headRefOid`, PR `updatedAt`, and
  whether new reviews, threads, replies, or thread-state changes appeared after
  the initial snapshot. Report the final open-comment inventory, whether any
  additional findings remain, and state that every new or changed item was
  individually assessed, or describe the remaining limitation.
- Confirm that no push was performed unless the user explicitly asked for one.
- If merge conflicts could not be resolved safely, report that blocker here and
  do not claim that a full review was completed.

## Summary
Short neutral summary of the overall review result without repeating the PR
context.
```

根据检查过的 PR 标题和正文、关联 issue、实际 diff 及相关周围代码构建
`PR Context`。不要只是复述 PR 描述。每个子标题下写一个包含 2–4 句的自然段落。

优先级含义：

- `P0`：数据丢失、崩溃、安全缺陷或核心工作流损坏。
- `P1`：很可能造成用户可见回归或错误行为。
- `P2`：边界情况 bug、兼容性缺失或 issue 覆盖不完整。
- `P3`：值得修复的可维护性、清晰度或测试/文档缺口。
