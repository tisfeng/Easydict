---
name: review-pr
description: >
  默认在本地分支准备 GitHub pull request；明确要求时使用隔离 worktree，并可选择
  合并最新 base 分支。复用 review 核心审查准确远程代码，并自动 resolve 有证据的
  已解决或不再适用线程；用户要求只读时禁用远程写入。适用于 GitHub PR review。
---

# PR Review 工作流

先读取通用核心 [`review`](../review/SKILL.md)。本 skill 只补充 GitHub 上下文、准备、
线程维护和 PR 报告；本地工作树、提交、文件或模块 review 直接使用核心，不要求 PR。

默认使用本地 checkout。只有用户明确要求 worktree、并行 review 或并发 review 时，
才使用隔离 Git worktree。如果缺少 PR 引用或引用存在歧义，在改变 Git 状态前先询问。

接受的 PR 引用：

- GitHub URL：`https://github.com/<base-owner>/<base-repo>/pull/<number>`
- 简写：`<base-owner>/<base-repo>#<number>`
- 仅 PR 编号：当前 checkout 属于目标仓库时可用

## 请求与准备权限

明确请求按本 skill review PR，包含下述本地准备流程所需的 remote 添加、fetch、
安全分支创建或 fast-forward、upstream 设置和 checkout。若用户/仓库已启用自动线程
维护（Easydict 默认启用），还包含下述有证据的线程 resolve；未启用的其他仓库须取得
该远程动作授权。此流程不授权产品修复、push、发布评论、approve、删除评论或关闭 PR。
worktree、latest-base 合并与冲突修复仍按下文对应条件单独判断。

仅要求方案或解释时不运行准备命令。用户要求不改变 Git 状态或不切分支时，优先遵守
该限制，使用可访问的准确 PR diff、源码和评论进行只读检查；不要为满足默认流程绕过
限制。只读证据不足时报告缺口，不声称已完成 checkout 验证。以下 checkout 步骤和
禁止直接 review 已 fetch ref 的默认规则，仅适用于获准的本地准备模式。

“只读”“不处理评论”等限制禁用自动 resolve；仅“不切分支”不自动禁用独立获准的
线程维护。只规划本 skill 的改进不授权对真实 PR 执行 mutation。

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
- 对每条评估为 `reasonable` 或 `partially reasonable` 的开放评论，提供可定位的
  修复建议，并以实际 diff、周围代码和项目模式为依据。建议解决问题的最小
  具体变更，相关时包含受影响逻辑、预期行为和针对性验证。即使评论来自 bot 也适用。
  将完整评估和修复放在已有评论的对应条目中；同源线程可引用共用修复，
  不要在独立发现中重复同一问题。
- 每个独立 finding 也提供同样具体的修复建议。只有触发条件、风险和修复方式
  均与所有已有评论不同的问题才能出现在独立发现中。
- 不使用“修复此问题”等含糊建议。存在多种有效方案时，推荐一种并说明重要取舍。
  如果修复取决于产品决策，给出条件选项，并在待确认决策中提出该决策。
- 将修复建议视为 review 指导。除获准的线程维护外，未经授权不要修改 PR；只有短代码示例
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
修复建议、预期行为和针对性验证。对 `unreasonable` 或
`outdated/not applicable` 评论，说明用于否定或取代该担忧的代码证据。对需要产品决策
的评论，推荐一个选项，提供其修复建议，并在待确认决策中通过问题 ID 引用尚未解决
的选择。每个已 review 问题只能分配到一个输出栏目。如果问题由开放 review 评论提出，
其评估和修复只能放在已有评论的对应条目，不要在独立发现中重复。独立发现
仅用于触发条件、风险和修复方式均不同的额外问题。最终报告明确交代开放线程数与
独立新问题数；零项在摘要中说明，不为其创建空栏目。

对于旧 PR 或 stale PR，在决定分支是否仍应保留前，检查关联 issue 历史、后续替代 PR
和实时 base tree。当 mergeability 是 review 核心时，使用
`git merge-tree <merge-base> <base-remote>/<base-branch> HEAD` 作为只读的过时或
冲突信号。

使用 `origin` 前确认 base 仓库 remote。fetch 真实 base 分支，再检查 diff 和周围代码：

```bash
git fetch <base-remote> <base-branch>
git diff --stat <base-sha>...<remote-head-sha>
git diff --name-status <base-sha>...<remote-head-sha>
git diff <base-sha>...<remote-head-sha>
```

冻结 fetch 后的 base SHA 与准确 `headRefOid`。latest-base 模式不能用本地 merge HEAD
替代远程 head；集成 diff 另行审查，并明确两种快照的证据归属。

使用 `rg` 搜索周围源码、测试、配置、生成文件和文档。除非用户明确要求本地构建，PR
review 期间不要运行 `xcodebuild`。验证状态重要时检查 PR checks：

```bash
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

相关时运行 `git diff --check` 等轻量本地检查。

### 5. 证据驱动的线程维护

收集或处理线程时读取 [`references/thread-resolution.md`](references/thread-resolution.md)，
使用 `scripts/review_threads.py collect` 完成 thread 与 replies 的双层分页。
对远程当前 head 上确实已修复或不再适用的问题生成证据绑定的 resolve plan；已获准时
直接 apply，无需每条重复确认。`isOutdated`、绿色 CI、本地未推送修复或单纯不同意评论
均不足以 resolve。存在实质未答复问题的线程保持开放。

### 6. 最终输出前刷新实时 PR 状态

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
  内容，结合当前 head 和周围代码验证，更新已有评论的对应条目；只有再次 review
  识别出不同的额外问题时才补充独立发现；已有 F 条目按当前证据复核更新。
  最终输出前更新待确认决策和审查范围与验证。
  对 reply 或 resolution/outdated 状态变化的
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

### 阅读顺序与复杂度

使用用户当前请求的语言；下面的中文标题和字段是语义示例，不是固定英文协议。
保留 P0–P3 优先级和稳定问题 ID：C 表示已有评论、F 表示独立发现、Q 表示待决事项。
编号表示来源而非发现时间；F 条目注明“本轮新增”或“上轮发现，本轮仍成立”。
复审缺少上轮证据时只标明本轮确认，不推断首次发现时间。
复审沿用能对应到同一问题的 ID，不因排序变化重新编号；无旧映射时明确建立本轮编号。

1. **审查结论**：先说明代码审查建议、主要原因及下一步。CI 失败/pending、未完成的
   必要验证或最终刷新缺口若影响判断，在开头明确说明；不能把“没有 finding”写成
   “已验证可合并”。复杂报告增加跨来源按风险排序的行动索引，仅列 ID、短标题和动作，
   不重复证据。需要背景才能理解时，先用一句话说明 PR 目标。
2. **待处理问题**：需要修改或仍有实质争议的已有评论优先，独立发现随后；各组按风险
   排序。两组都有内容时使用独立的二级分区“待处理的已有评论”“独立发现”；只存在
   一组时无需空分区。低优先级旧评论不能在开头行动索引遮蔽更高风险的新问题。
3. **待确认决策**：只放影响正确性/范围且需要用户选择的事项，给出推荐与主要取舍；
   关联已有问题时引用 ID，不重写其证据和修复方案。没有决策就省略。
4. **旧评论与线程处理记录**：无需代码修改的评论逐条简述，保留原问题、当前代码证据、
   判断、permalink 和实际线程状态。已修复或不再适用不等于已 resolve；权限不足、
   只读未操作、失败、未知和未尝试分别说明。有效担忧或未答复的实质问题不能塞进
   此处作为“已处理”。本轮 resolve 成功的记录不能因最终开放清单为空而消失。
5. **审查范围与验证**：保留可复查的范围与证据，按下文记录。背景通常一小段即可，
   不强制三个背景子标题或句数，不再追加重复结论的 Summary。

简单 PR 只保留结论、必要问题和简短验证；不为了满足模板制造空栏目。摘要明确区分
代码问题数、待决事项数和最终开放线程数，不能将“已修复但仍开放”从开放数里扣掉。
多个线程指向同一问题时，每个线程保留链接、状态和独立判断，修复方案引用同一 ID；
问题数去重，线程数不去重。

复审开头突出“已修复、仍存在、新增”。只有具备准确的上轮快照才能作增量比较；
没有旧快照时说明限制。“新增”只计本轮首次发现的问题，沿用 F 编号不代表本轮新增。
“本轮已修复”只计相对上轮从有效问题变为已修复的问题；上轮已修复的线程保留在记录区，
不重复计入本轮修复数。
精简背景不减少当前真实 base diff 和完整线程检查。
所有回复仍需完整阅读；正文重点展示影响判断的实质回复及链接，其他回复可概括，
不能省略未答复的实质问题。读者无需翻回上轮报告才能理解当前有效问题。

### 问题呈现

- 二级标题用于报告分区，三级标题用于具体问题，例如“### [P1] F1 — 回译方向错误”。
  不继续堆叠小标题。问题内使用“**证据：** 正文”等段内标签；多条证据可在短标签下
  分项列出，不让每个字段变成标题。只加粗短标签和关键风险，不将摘要或整段正文加粗。
  复审计数与线程计数分段或分项呈现，不挤入同一长句。
- 每个有效问题包含位置、触发条件、影响、代码证据、具体修复和针对性验证；
  短问题可合并段落，复杂问题充分展开，不用机械字数上限截断关键证据。
- 已有评论以 C 编号及评论 permalink 标明来源，独立问题以 F 编号标明来源。评论判断用
  自然语言表达，如“仍需修复”“部分成立”“已修复”“不再适用”“证据不足”；
  不向读者堆砌 raw GraphQL flags 或 assessment 枚举。
- 路径以短文件名链接呈现，必要时补目录区分同名文件。位置链接对应准确审查快照，
  旧评论行号标记为原位置；不得凭旧行号生成当前 diff 链接。长 SHA 统一留在验证区。
  位置、来源、状态可拆成两行，不把长路径、作者、状态挤成一行。
- 复杂报告在结论与行动项之后、主要二级分区之间使用 `---`，同一分区内相邻长问题
  之间也加一条。相邻边界只用一条，不在问题内部字段或简短线程条目之间加横线。
  简单报告不强制全部分区或分隔线；不在报告开头、结尾添加装饰横线。
- 简短线程记录使用列表，不为每条重复全部字段标题。复现步骤用有序列表，多条代码
  证据用短列表，必要代码/命令才用代码块。避免宽表格、整段引用和密集嵌套。
  问题中的待执行检查标为“建议验证”，与验证区的“已执行验证”区分。
- 不依赖 HTML、折叠块、颜色、特殊卡片或页内锚点。标题、列表、横线前后保留空行，
  使用通用 Markdown；问题 ID 本身就能帮助定位。
- 摘要和行动索引可短引用已有问题，详细评估只能有一个归属；不得把旧评论重新包装
  成新增 finding。展示层调整不改变 checkout、权限、resolve 条件或最终刷新流程。

以下为复审结构示例，替换为实际证据与链接，不照抄示例结论或计数：

```markdown
## 审查结论：建议修复后再合并

本轮复审：已修复 0 · 仍存在 1 · 新增 0；另有 1 项范围决策待确认。

线程状态：最终开放 1 条，代码在上轮已修复，但本轮只读未关闭线程。

CI 尚未全部完成，未进行 UI 实测。

**行动项**

- F1：保存实际语言对，修复回译方向。
- Q1：确认是否同时支持 Auto → Auto。

---

## 独立发现

### [P1] F1 — Auto 模式丢失实际回译方向

位置：准确快照中的文件位置链接

来源：上轮发现，本轮复核仍成立

**触发与影响：** 日语经 Auto 翻译为中文后，交换可能得到英语而不是日语。

**证据：**

- 交换入口仍使用 Auto 占位值（准确代码链接）。
- 目标语言解析使用偏好语言（相关调用链链接）。

**建议修复：** 保存原请求的有效语言对，再按原目标到原源发起查询。

**建议验证：** 覆盖 Auto、显式语言、未完成流式与 OCR 场景。

---

## 待确认决策

### Q1 — 是否同时支持 Auto → Auto？

推荐纳入并复用 F1 的有效语言对；否则默认配置仍无法使用此功能。

---

## 旧评论与线程处理记录

- **C1：按钮入口（评论链接）**：按钮与快捷键已共用路径（代码证据链接）；
  代码已修复，线程仍开放（只读未操作）。

---

## 审查范围与验证

**范围与快照**

- 范围：PR 目标、关联 issue 与审查边界。
- 远程 Head：完整 SHA。
- Base：冻结的完整 SHA。
- Merge-base：真实差异基线的完整 SHA。

**本地准备**

- 准备模式、分支与 upstream；隔离模式补充 worktree 路径和源 checkout 状态。
- 工作树状态、collision fallback 和 latest-base 是否执行，按实际情况说明。

**已执行验证与限制**

- 已执行：实际检查及各自结果。
- CI：通过、失败或 pending 的实际状态。
- 未运行／受阻：未验证事项及其对结论的影响。

**刷新与操作**

- 最终刷新：Head 是否与上述快照一致、PR updatedAt、线程及回复覆盖和新活动复核。
- 线程计数：初始开放 1 · 本轮确认 resolve 0 · 最终开放 1。
- 实际操作：本轮只读，逐项说明本地准备及 Git／远程操作，不能只写“未 push”。
```

### 验证区的最低信息

根据实际模式简述以下信息，不能因压缩报告而省略失败或范围限制：

复杂报告按“范围与快照／本地准备／已执行验证与限制／刷新与操作”组织短标签和列表，
一项承载一个事实或紧密相关的一组事实，不重新拼成四个大段落。完整 SHA 各自分项，
同一远程 Head 只写一次，刷新处说明是否一致；不同快照分别记录。简单报告可合并组别，
但仍保留适用的最低信息。

- PR 目标、关联 issue、主要变化与重要边界，不只复述 PR 描述。
- 准确完整远程 head SHA、冻结 base/merge-base；latest-base 本地集成快照单列，
  不替代远程证据。普通本地准备记录分支/upstream；worktree 模式记录其路径、
  分支/upstream 或 local-only 状态，以及源 checkout 是否保持不变。
- collision fallback 的分支和原因（如有）；latest-base 是否执行、实际 merge/冲突处理、
  head/base ancestry 验证结果。无法安全解决的冲突明确作为审查限制。
- 实际检查及结果、未运行事项和环境阻塞；CI 通过/失败/pending 与代码判断分开。
- 最终刷新时的 head、PR updatedAt、完整线程及回复的覆盖情况、出现的新活动及复核结果。
  初始开放、本轮 resolve 读回成功、最终开放分别计数；有外部新增/关闭/重开则解释差额。
  刷新失败或状态未知时不宣称清单完整，也不编造最终计数。
- 实际工作树/源码/Git/远程操作，特别是 resolve、提交 review、merge 与 push。
  “未 push”不等于“未修改 GitHub”；成功、失败、跳过和结果不确定分别报告。

Finding 证据和优先级以通用 `review` 核心为准。

交付前核对成稿，而非只核对模板：行动索引按 P0 到 P3 跨来源排序（C/F 前缀不决定
风险顺序），逐线程检查链接与真实状态是否齐全，并把权限/API 枚举转成自然语言。
核对结论和行动项引用的 ID 与正文一致，复审增量计数与上轮状态相符。
没有准确位置链接时保留文本位置并说明缺口，不用 PR 首页链接伪装成代码定位链接。
