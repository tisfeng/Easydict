# 线程检查、回复与关闭

此流程在原 review thread 回复依据后 resolve conversation，不关闭 PR/issue。授权遵循
[入口的模式与授权](../SKILL.md#模式与授权)；只读或禁用评论处理时仅 collect 和报告。必须由 Agent 阅读完整评论、回复以及准确远程代码作语义判断，
helper 不会验证证据文字是否真的成立。

## 收集与判定

普通 PR review 若已经通过 `review_snapshot.py collect` 取得完整 threads、comments、每线程
`fingerprint` 和准确 `headRefOid`，直接复用该快照进行语义判定，不要紧接着重复 collect。
需要生成 apply plan 时使用这些真实字段；apply helper 仍会按下文在每次 mutation 前自行刷新。

```bash
python3 "<review-pr-skill-dir>/scripts/review_threads.py" collect --repo OWNER/REPO --pr NUMBER
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

## 回复内容

回复使用当前请求语言，简短说明原问题如何消除或为何不再适用，附修复提交或准确远程
代码链接，并区分实际执行与尚未执行的验证。不只写“已解决”，不虚构验证结果。
`isOutdated` 只表示原位置过期，不能代替对当前实现的判断。

## Plan 与 apply

用当前 collect 的实际值生成以下 JSON，不能猜测 thread ID、SHA 或 fingerprint：

```json
{
  "version": 2,
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
    "permalink": "评论的实际 URL",
    "reply_body": "已在 <实际提交链接> 修复：<当前逻辑如何消除原问题>。验证：<实际结果或未执行情况>。"
  }]
}
```

根据任务授权执行，不需要每条再问一次。version 2 必须包含非空 `reply_body`，两个开关
分别确认回复与关闭能力；旧 version 1 plan 不再接受，需按当前证据重新生成：

```bash
python3 "<review-pr-skill-dir>/scripts/review_threads.py" apply --plan PLAN.json --allow-reply --allow-resolve
```

helper 每条操作前定向读取请求 PR 与目标 thread，核对该线程确实属于该 PR，并完整分页读取
目标线程全部回复；不为处理一条线程再次扫描其他所有线程。核对 PR 身份、开放状态、远程 head、thread 内容和
`viewerCanResolve`。已解决的线程直接跳过；PR head 变化时停止后续处理，线程内容变化时
跳过该线程。重新阅读变化并重新判定后生成新 plan，不自动改写旧 plan 的 SHA/指纹。

回复使用 GitHub 的 [`addPullRequestReviewThreadReply`](https://docs.github.com/en/graphql/reference/pulls#addpullrequestreviewthreadreply)，
在原线程中发布，不传入 pending review ID。确认回复状态为 `SUBMITTED` 后，
再次定向读取同一线程，确认 head、原评论和状态未变、只新增本次回复，才执行 resolve。
返回回复 ID、URL 和 `reply_status`（`posted`、`reused`、`unknown` 或 `not_attempted`）。
回复失败或无法确认时不关闭；回复成功但关闭失败时保留回复回执，不撤回回复。

再次执行前重新 collect，检查完整讨论和当前代码，重新生成 plan；不得直接修改旧指纹来绕过
复核。helper 在新快照中发现当前登录用户已有完全相同正文且状态为 `SUBMITTED` 的回复时复用，避免重复发布；
Agent 必须确认该回复仍准确且所有实质追问已处理。正文变化时视为新回复，不能凭相似文本去重。
已关闭线程跳过，不新增回复。

resolve 后再次定向读取同一线程，复验身份、head、状态和所有回复；每次分页结束额外核验
线程标志与回复总数。初始/最终全量线程扫描仍由 snapshot helper 完成。异常可能意味着请求已经
生效；保留结果并重新 collect 确认，不盲目重试、不自动 unresolve。输出保留 evidence/permalink、
回复回执及线程处理状态，分别报告已回复、已关闭、保持开放和失败/未知结果。
部分失败返回非零退出码，不能把整个批次写为成功。apply 后仍执行 skill 的最终全量
PR/CI/thread 刷新，并记录本轮发布回复数、resolve 数与最终开放线程。

GitHub [`resolveReviewThread`](https://docs.github.com/en/graphql/reference/pulls#resolvereviewthread)
没有 expected-head CAS。分页读取也不是事务快照；前后校验只能减少竞态，不能保证
原子性。若 head/回复在请求期间变化，明确报告变更后的实际状态，重新审查，不声称
旧证据覆盖新状态。禁止测试时访问真实 PR；使用 fake API 验证守卫及部分失败。
