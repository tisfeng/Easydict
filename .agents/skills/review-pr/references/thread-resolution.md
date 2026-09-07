# 线程收集与安全 resolve

此流程 resolve review conversation，不关闭 PR/issue，也不发布回复。只读或禁用评论
处理时仅 collect 和报告。必须由 Agent 阅读完整评论、回复以及准确远程代码作语义判断，
helper 不会验证证据文字是否真的成立。

## 收集与判定

```bash
python3 .agents/skills/review-pr/scripts/review_threads.py collect --repo OWNER/REPO --pr NUMBER
```

输出 PR 的 `id`、`headRefOid`、状态及完整 threads/comments，每个 thread 有内容
`fingerprint`。输出不自动保存文件；如需重用，通过已授权文件工具保存到任务临时目录。
所有 `isResolved == false` 都必须评估，包括 outdated、bot 及有回复线程。

只有以下两类可以列入 apply plan：

- `fixed`：当前远程代码已消除原问题，证据注明路径、逻辑/行号和验证情况。
- `not_applicable`：代码/需求的实质变化让原问题不再存在，且没有未答复的实质问题。

不能仅凭 `isOutdated`、CI 绿色、评论声称修好、作者身份、主观不同意或本地未推送修复
关闭线程。latest-base 本地合并内容也不能证明远程已修复。合理、部分合理、需产品决策
或证据不足的评论保持开放，并提供修复建议/问题。刷新失败时不继续 mutation。

## Plan 与 apply

用当前 collect 的实际值生成以下 JSON，不能猜测 thread ID、SHA 或 fingerprint：

```json
{
  "version": 1,
  "repo": "OWNER/REPO",
  "number": 123,
  "id": "PR_ID",
  "headRefOid": "REMOTE_HEAD_SHA",
  "decisions": [{
    "thread_id": "THREAD_ID",
    "fingerprint": "COLLECTED_FINGERPRINT",
    "assessment": "fixed",
    "evidence_head": "REMOTE_HEAD_SHA",
    "evidence": "path:line 的实际远程代码如何消除原问题；相关验证结果",
    "permalink": "评论的实际 URL"
  }]
}
```

获准后执行，不需要每条再问一次：

```bash
python3 .agents/skills/review-pr/scripts/review_threads.py apply --plan PLAN.json --allow-resolve
```

helper 每条操作前重新 collect，核对 PR 身份、开放状态、远程 head、thread 内容和
`viewerCanResolve`，已 resolved 则幂等跳过；head 漂移停止后续处理，thread 漂移跳过
该项。重新阅读变化并重新判定后生成新 plan，不自动改写旧 plan 的 SHA/指纹。

mutation 后再次 collect 读回状态。异常可能意味着请求已经生效；保留结果并重新
collect 确认，不盲目重试、不自动 unresolve。输出保留 evidence/permalink，报告
resolved、already_resolved、stale、cannot_resolve、error、unknown 或 not_attempted。
部分失败返回非零退出码，不能把整个批次写为成功。apply 后仍执行 skill 的最终全量
PR/CI/thread 刷新，并记录本轮 resolve 与最终开放线程。

GitHub [`resolveReviewThread`](https://docs.github.com/en/graphql/reference/pulls#resolvereviewthread)
没有 expected-head CAS。分页读取也不是事务快照；前后校验只能减少竞态，不能保证
原子性。若 head/回复在请求期间变化，明确报告变更后的实际状态，重新审查，不声称
旧证据覆盖新状态。禁止测试时访问真实 PR；使用 fake API 验证守卫及部分失败。
