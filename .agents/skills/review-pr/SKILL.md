---
name: review-pr
description: >
  默认在本地分支准备 GitHub pull request；明确要求时使用隔离 worktree，并可选择
  合并最新 base 分支。理解 PR 和关联 issue 的目标，复用 review 核心核对功能与代码正确性，并维护有证据的线程状态；
  用户要求只读时禁用远程写入。适用于 GitHub PR review。
---

# PR Review 工作流

先读取通用核心 `review`。本 skill 只补充 GitHub 上下文、准备、
问题背景、线程维护和 PR 报告；本地工作树、提交、文件或模块 review 直接使用核心，不要求 PR。

下文的 `<review-pr-skill-dir>` 表示当前加载的 `review-pr/SKILL.md` 所在目录。
运行随 skill 分发的脚本时，先解析该实际目录；不要假设 skill 安装在某个固定的
Agent 或项目路径中。

`review` 是完成语义审查的配套依赖：优先从当前环境的 Skill 清单定位，未提供位置时再检查
[同级安装位置](../review/SKILL.md)，不要假设它必须与本 Skill 相邻。开始 Git 准备前确认可读取
该依赖；缺失时报告所缺能力，仍可完成已获准的只读证据收集，但不能宣称完整审查已完成。
运行 helper 前确认 Git、已认证的 `gh` 和兼容的 Python 可用；helper 不可用时使用下文明确
定义的等价回退。项目已有的授权、验证命令和审查要求继续生效，无需新增宿主配置或补救规则。
快照字段、参考文件和重试步骤由本 Skill 内部编排，宿主只需给出 PR、目标和有效限制。

默认使用本地 checkout。只有用户明确要求 worktree、并行 review 或并发 review 时，
才使用隔离 Git worktree。如果缺少 PR 引用或引用存在歧义，在改变 Git 状态前先询问。

接受的 PR 引用：

- GitHub URL：`https://github.com/<base-owner>/<base-repo>/pull/<number>`
- 简写：`<base-owner>/<base-repo>#<number>`
- 仅 PR 编号：当前 checkout 属于目标仓库时可用

## 请求与准备权限

明确请求按本 skill review PR，包含下述本地准备流程所需的 remote 添加、fetch、安全
分支创建或 fast-forward、upstream 设置和 checkout。线程 resolve 需要单独的工作流
授权和远程证据。此流程不授权产品修复、push、发布评论、approve、删除评论或关闭 PR。
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
- 审查真实远程 head、base diff、关联 issue、周围代码与 CI，并收集所有开放线程及回复。
  完整分页、逐条判定、修复建议与最终刷新按下文执行；finding 的通用证据标准以 `review` 为准。

## 快速审查协议

优化正常成功路径的模型往返和重复输出，不减少必要远程证据、diff 审查、线程分页、漂移检查、
权限边界或最终刷新。已经加载且本轮没有变化的本 Skill、`review` 核心和引用文件不重复读取。

- 首次快照使用一个 helper 先冻结 PR 元数据和 head，再并行收集直接关联的 issue 正文、
  完整分页的 threads/replies 与 checks，一次向模型返回证据、覆盖状态及稳定 fingerprint：

  ```bash
  python3 "<review-pr-skill-dir>/scripts/review_snapshot.py" collect \
    --repo <base-owner>/<base-repo> --pr <number>
  ```

  只有 `schema_version: 1`、`mode: collect`、PR/thread/checks 身份与 head 一致且命令明确以
  0 退出时才接受结果。helper 在全部并行采集结束后独立读取并比较 PR 编号、URL、head、base
  名称和 SHA；缺字段、读取失败或漂移均拒绝本轮证据，不返回成功快照或保存新证据文件。
  checks 查询也使用冻结 head 并在查询后复验，不能把其他提交的绿色 CI 绑定到当前快照。
  helper 不可用时按下文 **手动快照回退**执行，不得降低证据范围。
  helper 已检测到 head 或身份不一致时，本轮快照无效；重新采集，不能通过手动回退绕过检查。
  `pr.reviewContext` 保存问题来源，不代表已经理解需求或验证功能；缺失时按下文补齐，不能
  把旧 helper 没有该字段解释为没有关联 issue。`summary.context.coverage` 明示正文覆盖缺口。
- 支持一次模型调用内编排多个工具时，先并行执行初始远程快照与本地 status。确认本地模式和
  权限后，在一次程序化调用中依次等待准备 helper 的结构化回执和本地 range 取证；准备 helper
  已完成本轮 head/base fetch 与 checkout 校验，不再紧接着重复 fetch 或打印全量分支列表。
  每条命令仍是独立工具调用，只有明确完成且 `exit_code === 0` 才进入下一步。返回运行中会话
  时继续等待同一会话，禁止重新启动相同命令。
- 首次语义审查后冻结 remote head、base SHA、merge-base、changed paths、raw diff 和三类远程
  fingerprint。每个 changed hunk 与所需周围代码只读取一次；完整 diff、完整文件和扩大上下文
  不能无条件重复读取同一内容。只有证据不足、实际漂移或验证结果要求追踪调用链时才增量读取。
- 对准确同一 `headRefOid`，初始快照中已经完成且全部通过的远程 checks 是可复用证据；默认不再
  重跑覆盖相同范围的本地全量 CI。真实 finding、用户要求、仓库强制验证或远程 checks 未覆盖的
  变更仍运行针对性检查。checks 失败或 pending 是审查状态，不是等待授权；除非用户明确要求，
  不使用 `--watch`，也不等待 CI 完成。
- 最终刷新仍重新读取 PR、选定 issue 证据、完整 threads/replies 和 checks，但以 fingerprint 压缩未变化输出：

  ```bash
  python3 "<review-pr-skill-dir>/scripts/review_snapshot.py" refresh \
    --repo <base-owner>/<base-repo> --pr <number> \
    --expected-head <head-sha> \
    --expected-base-name <base-branch> --expected-base-sha <frozen-base-sha> \
    --expected-pr-fingerprint <sha256> \
    --expected-threads-fingerprint <sha256> \
    --expected-checks-fingerprint <sha256>
  ```

  `unchanged: true` 只省略重复传回模型的全量内容，不跳过远程刷新或末尾的完整身份复验。
  默认完整返回变化的 section；head 变化时返回全部当前证据。base 参数成对提供，不能把 `base_comparison: not_provided`
  当作 base 未变；旧 helper 路径需手动比较 base 名称和 SHA，按下文重新确定审查范围。

大 PR 或需要复用准备元数据时，读取 [快照传输协议](references/snapshot-protocol.md)，使用可选
`--snapshot-out` 把完整证据存到获准的任务临时文件并分页读取。刷新可以按已验证的前次快照输出
完整变化线程和全量索引；缺页、旧证据丢失或不匹配时回退完整读取。小 PR 可继续直接 JSON 输出，
不强制增加文件操作。checks 集合与线程列表的返回顺序不影响指纹，评论本身的顺序仍保留。

### 手动快照回退

初始采集和最终刷新使用同一协议。将 PR 引用规范化为明确的 `<number> --repo <base-owner>/<base-repo>`，
本轮所有查询固定使用该身份；只有完成最后的完整身份复验，才能接受本轮证据。

1. 读取完整 PR 元数据，冻结 `number`、`url`、`headRefOid`、`baseRefName` 和 `baseRefOid`；
   编号必须匹配请求，URL 必须对应请求仓库和 PR，其余字段必须是非空字符串：

   ```bash
   gh pr view <number> --repo <base-owner>/<base-repo> \
     --json number,title,url,body,baseRefName,baseRefOid,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,mergeable,mergeStateStatus,updatedAt,files,commits,closingIssuesReferences,comments,reviews
   ```

   按 [问题背景与功能核对](references/problem-review.md) 读取直接目标 issue 的正文及已采用的
   讨论，保留来源身份、覆盖范围和原始内容；初始与最终都比较这些证据，不只比较 PR updatedAt。

2. 再收集完整分页的 threads/replies 与 checks；这两项可并行，但都必须完成后才进入下一步：

   ```bash
   python3 "<review-pr-skill-dir>/scripts/review_threads.py" collect \
     --repo <base-owner>/<base-repo> --pr <number>
   gh pr checks <number> --repo <base-owner>/<base-repo> --json bucket,link,name,state,workflow
   ```

   thread helper 不可用时，按 **验证 Checkout 和 Review 上下文**的 thread/reply 字段及分页要求
   执行 GraphQL 查询，保留 PR 编号、URL 与 head。普通命令必须明确以 0 退出并返回有效数据；
   `gh pr checks` 的 0、1、8 退出码只有在返回有效 checks JSON 数组时才可作为观测状态接受。
   失败或 pending checks 不是读取失败，也不是等待指令；空数组不能作为绿色 CI 证据。

3. 全部读取结束后，再单独查询：

   ```bash
   gh pr view <number> --repo <base-owner>/<base-repo> \
     --json number,url,headRefOid,baseRefName,baseRefOid
   ```

   验证字段完整，并逐项与步骤 1 的五个字段比较。只有全部相等，且 threads 的编号、URL 和
   head 与初始 PR 一致时才接受完整快照；checks 随该 head 保存。只检查 head 不能证明 base
   没有变化，checks 或 thread 分页内部的检查也不能替代所有采集完成后的这次复验。
   最终刷新还须与此前已审查的 head 和完整上下文比较，不能仅凭本轮内部一致宣称审查已覆盖新 head。

查询失败、缺少必要字段或无法证明一致性时，不复用本轮 checks，也不据此跳过本地验证。
检测到漂移时丢弃本轮混合证据并重新采集完整快照；再次漂移或读取仍失败时，报告已审查的 SHA
和未覆盖状态，结束本轮尝试，不无限重试。新 head 的准备和审查遵循 **最终输出前刷新实时 PR 状态**。
helper 检测到漂移时同样适用这一停止条件。支持程序化编排时，上述依赖步骤可在一次调用中完成，
不增加模型往返；正常 helper 路径无需额外查询。
该复验证明本轮观测到的身份一致，不构成远程原子快照，也不保证之后没有新活动；需求、评论和
checks 的内容仍按最终刷新协议比较，报告保留实际已检查的快照边界。

## 工作流

### 1. 收集 PR 元数据与问题背景

先按 **快速审查协议**运行 `review_snapshot.py collect`，并冻结输出的 head、updatedAt 和
fingerprints。helper 不可用时先完成 **手动快照回退**，再使用其中的元数据和已绑定 head 的 checks；
手动路径没有 helper fingerprint 时直接比较完整证据，不伪造 fingerprint。

记录 head owner、fork 仓库、head 分支、head SHA、base 分支、PR URL、关联 issue、mergeability、
checks 和完整 thread 快照。
普通路径下由 helper 脚本添加 remote、fetch 分支并设置 upstream tracking。

语义审查前读取 [问题背景与功能核对](references/problem-review.md)。先理解标题、完整描述和
实际要解决的 issue，明确原问题、触发场景、期望结果、本 PR 承诺的范围及尚不确定的边界。
记录来源，区分明确要求、作者声明、已确认决策与推断；不能根据 diff 反推需求并当作验收标准。
没有 issue 是合法情况；缺少证据只限制相应功能结论，其余安全的代码审查继续。

将目标和关键验收条件连同来源交给 `review`，在同一次审查中核对“验收条件 → 实现/调用路径 →
验证证据 → 判断”。简单 PR 用短段落即可，复杂 PR 使用短表；脚本不能替代目标提炼和语义判断。

### 2. 选择分支准备路径

准备分支前使用初始快照中的 mergeability；**手动快照回退**也已收集这些字段，无需重复查询。

除非用户明确要求 worktree 或并行 review，否则使用本地分支准备。不要仅因为当前
checkout 有变更就推断为 worktree 模式。普通本地 PR 运行以下命令之一；两种本地模式都
先按同一规则选择分支：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" --expected-head <head-sha> --json <pr-ref>
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" --merge-latest --expected-head <head-sha> --json <pr-ref>
```

需要隔离 source checkout 时，显式使用：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" --worktree --expected-head <head-sha> --json <pr-ref>
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" --worktree --merge-latest --expected-head <head-sha> --json <pr-ref>
```

`--expected-head` 必须来自已接受的初始快照。仅接受退出码 0、`schema_version: 1`、
`status: prepared` 的回执，核对请求 repo/number、head、base、merge-base、checkout/upstream、
collision 和 integration 模式。日志在 stderr；`failed` 回执说明停止阶段，不能自动清理或重启写入。
旧 CLI 仍可用，但调用方需收集等价证据。已有完整任务快照时可按快照传输协议传给准备 helper，
省去重复 `gh pr view`；存储哈希和身份校验不替代真实 fetch/head 校验。

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

准备回执已冻结最新 base；普通 review 使用回执中的远程 head 检查 PR 是否已经包含它：

```bash
git merge-base --is-ancestor <frozen-base-sha> <remote-head-sha>
```

如果检查失败，报告 PR 落后于最新 base，不要自动合并。GitHub 报告冲突时，可在有用的
情况下将 `git merge-tree` 作为只读冲突信号：

```bash
git merge-tree <frozen-merge-base> <frozen-base-sha> <remote-head-sha>
```

将 `baseRefName` 视为目标分支；不要硬编码 `dev`。只有明确请求 latest-base 后，才使用
上方与所选准备模式对应的 `--merge-latest` 命令。

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

结构化准备回执已校验本地状态，事实未变时直接复用。旧 helper 或后续状态漂移时针对当前分支
补充等价检查，不打印全量 `git branch -vv`：

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git for-each-ref --format='%(upstream:short)' refs/heads/<selected-branch>
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

初始 helper 或 **手动快照回退**已记录 PR 上下文、comments、reviews 和完整分页的
review threads，不要紧接着重复查询相同内容。复用 `pr.reviewContext` 的 issue 正文；存在需求
争议、复现修订、讨论未覆盖或特定回复引用时，按问题背景协议补读讨论，并把所有采用的来源
纳入后续 refresh。只读回退查询必须使用准确 issue URL 或显式 repo，不借用当前 fork 猜测身份。

从初始快照记录 `headRefOid`、`updatedAt`、最新 review 的 `submittedAt` 和完整 inline
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

准备 helper 已确认 base remote 并 fetch，使用回执中的准确端点调用 `review` 的本地快照能力：

```bash
python3 "<review-skill-dir>/scripts/collect_review_snapshot.py" \
  --repo <prepared-checkout> --range '<frozen-base-sha>...<remote-head-sha>'
```

核对返回 merge-base 与准备回执一致，按 `review` 的分页覆盖与最终复验规则完整读取 raw patch。
helper 不可用时，使用相同冻结端点的 `git diff --name-status` 与完整 `git diff` 收集；没有已验证
base 的只读/旧 helper 路径才在授权范围内补齐 base 获取。不能用无关 origin 或未确认 ref 替代。
latest-base 模式不能用本地 merge HEAD 替代远程 head；集成 diff 另行审查并标记证据归属。

使用 `rg` 搜索周围源码、测试、配置、生成文件和文档。根据仓库验证要求、变更风险和
用户授权选择适当的本地检查。初始 helper 或手动快照已经包含 PR checks；需要单独诊断
具体 check 时可运行：

```bash
gh pr checks <number> [--repo <base-owner>/<base-repo>] --json bucket,link,name,state,workflow
```

单独诊断结果不自动替换已验证的快照。若要将其用于审查结论或免跑本地全量 CI，须按
**手动快照回退**完成查询前后 head 复验及其他快照读取，或重新运行 snapshot helper。

相关时运行 `git diff --check <frozen-merge-base> <remote-head-sha>` 等轻量本地检查。裸
`git diff --check` 不能验证干净 checkout 的已提交 PR 差异。远程 checks 对当前准确 head 已全部完成且通过时，
不默认重复运行本地全量 CI；按照 **快速审查协议**补充必要的针对性验证。

### 5. 证据驱动的线程维护

收集或处理线程时读取 [`references/thread-resolution.md`](references/thread-resolution.md)，
优先复用初始 `review_snapshot.py collect` 中的完整 thread 数据；它已经通过
`review_threads.py` 完成 thread 与 replies 的双层分页，不要立即重复 collect。
对远程当前 head 上确实已修复或不再适用的问题生成证据绑定的 resolve plan；已获准时
直接 apply，无需每条重复确认。`isOutdated`、绿色 CI、本地未推送修复或单纯不同意评论
均不足以 resolve。存在实质未答复问题的线程保持开放。

### 6. 最终输出前刷新实时 PR 状态

编写最终回复前立即按 **快速审查协议**运行 `review_snapshot.py refresh`。它会再次完整读取所有
可变 review 状态；fingerprint 未变化时只返回紧凑结果。helper 不可用或初始手动快照没有
fingerprint 时，按 **手动快照回退**重新完整采集；通过最后的完整身份复验后，才与初始快照比较，
包括 PR 上下文、checks、开放 thread 清单、评论回复、`isResolved` 和 `isOutdated` 状态。

- 如果 `headRefOid` 发生变化，停止最终输出，将准备好的 checkout 更新到新 head，
  对照真实 base 检查新 diff，并重新验证此前 finding 和新变更。
- 如果 base 分支名或 SHA 变化（包括 PR retarget），重新冻结该真实 base 并计算 merge-base 和
  diff 内容。head 未变且 merge-base、raw patch 与相关上下文未变时复用代码审查；范围变化时
  检查增量并复核已有 finding，不能用旧 base 的结论覆盖新范围。获取新 base 仍受只读/不改变 Git
  限制约束；证据不足时报告限制。latest-base 集成结果保留旧快照身份，不自动 reset 或重做 merge。
- 即使 head 未变，标题、描述、issue 关联集合、正文或已采用的讨论变化，也须重新核对受影响
  的目标、验收条件与实现/测试证据。需求未变且 patch 未变时复用既有判断；不能因为代码未变就
  宣称功能结论仍成立。来源读取失败、旧快照缺失或讨论未覆盖时保留明确限制。
- 如果出现新的 review、thread、reply 或 resolution/outdated 状态变化，读取其准确
  内容，结合当前 head 和周围代码验证，更新已有评论的对应条目；只有再次 review
  识别出不同的额外问题时才补充独立发现；已有 F 条目按当前证据复核更新。
  最终输出前更新待确认决策和审查范围与验证。
- 若刷新出现新活动，处理后再次刷新；最新取得的完整快照没有未检查项时即可交付，注明该
  快照的时间与 head，不等待假设中可能出现的下一条 review。反馈持续变化或读取失败时，报告
  已检查的快照和仍未覆盖的活动，不声称覆盖了尚未取得的最新状态。
- 如果最终刷新不可用，报告该限制，不要声称已检查所有当前评论或 thread。只有最新
  开放评论清单中没有未检查项时，最终回复才算完整。

## Review 重点

依据已经建立的目标记录，检查实现是否真正解决 PR 描述和关联 issue：从需求检查漏实现、
原始复现场景与端到端路径，从实现检查无关行为变化和承诺保留的行为。测试断言应对应验收条件，
绿色 CI、静态推理或仅修复 UI 表象均不等于原问题已解决。优先关注 bug、回归、边界情况、并发问题、
持久化错误、本地化缺口、平台版本问题、API 契约漂移、缺少验证和无关改动。

用户询问旧 PR 是否仍值得保留时，先给出保留、修改或关闭的建议，再说明代码证据；
建议关闭不等于获准执行关闭操作。

## 输出格式

### 阅读顺序与复杂度

报告标题和字段使用当前请求的语言。需要编写复杂复审报告时，读取
[复审报告示例](references/report-example.md)；示例只说明结构，不照抄结论、计数或证据。
保留 P0–P3 优先级和稳定问题 ID：C 表示已有评论、F 表示独立发现、Q 表示待决事项。
C/F/Q 前缀区分问题来源或类型；数字用于稳定标识问题，不表示发现时间。F 条目注明
“本轮新增”或“上轮发现，本轮仍成立”。
复审缺少上轮证据时只标明本轮确认，不推断首次发现时间。
复审沿用能对应到同一问题的 ID，不因排序变化重新编号；无旧映射时明确建立本轮编号。

1. **审查结论**：先分别说明功能目标的满足程度与代码审查建议、主要原因及下一步。功能目标
   区分已满足、部分满足、明确缺口或证据不足，并说明是静态证据还是实际运行验证。CI 失败/pending、未完成的
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

- 二级标题用于报告分区，三级标题用于具体问题，例如“### [P1] F1 — 简洁问题标题”。
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
- 摘要和行动索引可短引用已有问题，每个问题只在对应条目中详细说明；不得把旧评论重新包装
  成新增 finding。展示层调整不改变 checkout、权限、resolve 条件或最终刷新流程。

### 验证区的最低信息

根据实际模式简述以下信息，不能因压缩报告而省略失败或范围限制：

复杂报告按“范围与快照／本地准备／已执行验证与限制／刷新与操作”组织短标签和列表，
每项写一个结果或一组紧密相关的信息，不重新拼成四个大段落。完整 SHA 各自分项，
同一远程 Head 只写一次，刷新处说明是否一致；不同快照分别记录。简单报告可合并组别，
但仍保留适用的最低信息。

- PR 目标、关联 issue、主要变化与重要边界，以及关键验收条件与证据的对应，不只复述 PR 描述。
  保留需求来源和覆盖限制；推断、用户决策、静态判断和实际验证不得混写。
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
