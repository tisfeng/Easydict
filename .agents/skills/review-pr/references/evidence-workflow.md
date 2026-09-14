# PR 证据收集与刷新

执行 GitHub PR 审查时读取。该协议建立可复核的远程身份、需求、CI、线程和代码范围；
不授权 Git 或 GitHub mutation。

## PR 身份与前置

接受：

- `https://github.com/<base-owner>/<base-repo>/pull/<number>`
- `<base-owner>/<base-repo>#<number>`
- 仅 PR 编号，但当前 checkout 必须属于目标仓库

引用缺失或有歧义时，在改变 Git 状态前请用户明确。运行 helper 前确认 Git、
已认证 `gh` 和兼容 Python 可用。

## 初始快照

优先运行：

```bash
python3 "<review-pr-skill-dir>/scripts/review_snapshot.py" collect \
  --repo <base-owner>/<base-repo> --pr <number>
```

接受 `schema_version: 1`、`mode: collect` 且身份校验完整的成功回执。helper 并发收集 PR、
直接问题正文、全部 threads/replies 和 checks，然后单独复验 PR 编号、URL、head、base
名称与 SHA。缺字段、读取失败或漂移时，本轮混合证据无效。checks 必须绑定冻结 head；
空 checks 集合不是绿色 CI 证据。

`context` 只保存需求来源，不表示已理解或已验证功能。按
[问题背景与功能核对](problem-review.md) 提炼原问题、触发场景、期望结果、关键验收条件、
承诺范围和未确定边界。`summary.context.coverage` 中的缺口必须保留；需要问题讨论或另一
明确 issue 时，使用该 reference 定义的 `--issue` / `--issue-comments`。

大 PR、工具输出会截断或需要复用完整快照时，按
[快照传输协议](snapshot-protocol.md) 使用 `--snapshot-out` 和分页。

## 手动快照回退

仅当 snapshot helper 不可用时使用。helper 已检测到身份或 head/base 漂移时，不用手动路径
绕过它；重新收集一次，再次漂移时报告快照限制。

1. 将引用规范化为 `<number> --repo <base-owner>/<base-repo>`，读取完整元数据：

   ```bash
   gh pr view <number> --repo <base-owner>/<base-repo> \
     --json number,title,url,body,baseRefName,baseRefOid,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,mergeable,mergeStateStatus,updatedAt,files,commits,closingIssuesReferences,comments,reviews
   ```

   冻结 `number`、`url`、`headRefOid`、`baseRefName` 和 `baseRefOid`，验证编号与仓库身份。
   按问题背景协议收集直接目标 issue 及已采用讨论的完整内容与身份。
2. 收集完整分页 threads/replies 和 checks：

   ```bash
   python3 "<review-pr-skill-dir>/scripts/review_threads.py" collect \
     --repo <base-owner>/<base-repo> --pr <number>
   gh pr checks <number> --repo <base-owner>/<base-repo> \
     --json bucket,link,name,state,workflow
   ```

   thread helper 不可用时使用 GraphQL `reviewThreads`，对 thread 和 comments 分别翻页到
   `pageInfo.hasNextPage == false`。保留 thread id、`isResolved`、`isOutdated`、path、line，
   以及所有回复的 id、URL、body、author、timestamp 和 commit OID。`gh pr checks` 的
   失败/pending 状态码在它仍返回有效 checks JSON 时是审查事实，不是读取失败。
3. 所有采集结束后再读取身份：

   ```bash
   gh pr view <number> --repo <base-owner>/<base-repo> \
     --json number,url,headRefOid,baseRefName,baseRefOid
   ```

   五个字段必须与步骤 1 完全一致，threads 的编号、URL 和 head 也必须匹配。然后才将
   checks 与该 head 绑定并接受本轮证据。

手动回退得到的是多次 GitHub 读取的一致观测，不是原子快照。失败或缺字段时不复用当前
checks，不伪造 helper fingerprint。

## 代码范围与语义审查

本地准备 helper 已冻结 base remote、base SHA、remote head 和 merge-base。使用配套 `review`：

```bash
python3 "<review-skill-dir>/scripts/collect_review_snapshot.py" \
  --repo <prepared-checkout> --range '<frozen-base-sha>...<remote-head-sha>'
```

核对返回 merge-base 与准备回执一致，完整读取 raw patch。review helper 不可用时，用相同冻结端点的
`git diff --name-status` 和完整 `git diff` 收集。不用本地 latest-base merge HEAD 替代 remote head；
集成结果另行取证并标明归属。

根据仓库规则、变更风险和用户授权执行针对性验证。准确同一 `headRefOid` 的已完成且
全部通过 checks 可作为证据，不默认重跑同范围的本地全量 CI；真实 finding、用户要求、
仓库强制检查或远程未覆盖的变更仍需验证。checks 失败或 pending 是审查状态；除非
用户要求，不 `--watch`。空白错误使用
`git diff --check <frozen-merge-base> <remote-head-sha>` 检查历史 patch。

对每个开放 thread 结合当前 head、diff、调用链和周边代码，判断为成立、部分成立、不成立、
已过时/不适用，或需要产品决策。成立和部分成立项给出风险、具体修复和验证；否定项给出取代
该担忧的当前证据；产品决策项给出推荐与取舍。

## 最终刷新

结论前立即运行：

```bash
python3 "<review-pr-skill-dir>/scripts/review_snapshot.py" refresh \
  --repo <base-owner>/<base-repo> --pr <number> \
  --expected-head <head-sha> \
  --expected-base-name <base-branch> --expected-base-sha <frozen-base-sha> \
  --expected-pr-fingerprint <sha256> \
  --expected-context-fingerprint <sha256> \
  --expected-threads-fingerprint <sha256> \
  --expected-checks-fingerprint <sha256>
```

`unchanged: true` 表示本轮重新查询后可复用冻结证据。大快照按传输协议使用 previous
snapshot 和 delta；`context_delta` 或 `threads_delta` 中的变化来源需要重新读取和判断。

- head 变化：更新准备 checkout，使用真实 base 重新审查 diff，复核旧 finding 与新变更。
- base 名称或 SHA 变化：重新冻结 base 和 merge-base；范围变化时检查增量并复核结论。
- 标题、描述、issue 关联或已采用讨论变化：重新核对受影响的目标和验收判断。
- 新的 review、thread、reply、resolve/reopen/outdated 变化：阅读准确内容，更新对应评论条目。

处理刷新中的新活动后再刷新一次。当最新取得的完整快照没有未检查项时交付，注明时间和 head。
状态持续变化或读取失败时，报告已审查 SHA 和未覆盖活动，不声称已检查所有当前线程。
