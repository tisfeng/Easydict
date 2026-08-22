# Issue 决策策略

本策略用于兼容现有 PR 中的弱 issue 引用，不要求 PR 模板或新的正文约定。

## 候选来源

只从当前 Release Notes 中列出的 PR 收集同仓库候选：

- GitHub `closingIssuesReferences`。
- PR 正文中的完整 issue URL，可带 `#issuecomment-...`。
- PR 正文或 commit message 中的 `owner/repo#123` 和裸 `#123`。

候选发现不是关闭授权。编号必须经 GitHub issue API 解析；如果实体包含
`pull_request` 字段，则它是 PR 而不是 issue，必须排除。

## 两道判断门

### 1. Relationship

- `target`：PR 的实际目标是解决该 issue。
- `related`：issue 只是背景、相似问题、回归来源、讨论或后续工作。
- `uncertain`：证据不足以确定。

判断时阅读 issue 标题、正文、全部评论，以及 PR 标题、正文、commit 摘要、变更路径
和引用上下文。不能因为出现 closing keyword、issue URL 或相同关键词就直接判为
`target`。

### 2. Completion

- `resolved`：报告的缺陷及其验收条件已经完整修复。
- `implemented`：请求的功能已经完整实现。
- `partial`：仅缓解、只覆盖部分场景、仍需后续工作或明确属于 workaround。
- `unverified`：无法从实际改动与上下文确认结果。

只有 `target + resolved` 或 `target + implemented` 可以得到
`notify_on_release`。其他组合必须是 `skip`。

## 多 PR 聚合

同一个 issue 可能由本次版本中的多个 PR 联合完成。以 issue 为单位综合全部相关 PR：

- 只有部分 PR 完成，但组合后满足全部验收条件，可以判为完整解决。
- 仍有一个未覆盖条件，必须判为 `partial`。
- 不在本次 Release Notes 中的 PR 不计入完成证据。

## 反证优先

以下信息阻止自动关闭：

- “部分修复”“防御性补丁”“很难根治”“workaround”“follow-up”等表述。
- Issue 在关联 PR 合并后被重新打开。
- 最新评论确认问题仍可复现或功能仍不完整。
- Issue 是 tracking/meta 任务，仍有未完成子项。
- 实际改动只处理了 issue 中的次要场景。

例如 PR #1212 虽然写了 `Close #1201`，正文同时说明它是防御性补丁且难以根治，
因此必须判为 `partial`。

## 决策文件

为候选文件中的每个 issue 生成且只生成一条决策：

```json
{
  "issue_number": 1254,
  "source_prs": [1255],
  "relationship": "target",
  "completion": "resolved",
  "decision": "notify_on_release",
  "language": "zh-Hans",
  "positive_evidence": [
    "PR prevents automatic selection in the reported mirror applications"
  ],
  "counter_evidence": [],
  "reason": "The released change covers the reported behavior"
}
```

证据必须对应原始 GitHub 数据。低置信度不是请求用户选择的理由；自动降级为 `skip`，
并在最终报告中说明原因。

## 发布后刷新

发布成功后，只刷新冻结清单中的 issue。允许将 `notify_on_release` 降级为 `skip`，
禁止增加新 issue 或把 `skip` 升级为通知。若 issue 已关闭，仍可发布一次版本说明评论；
若 issue 在既有版本评论后重新打开，则不得再次关闭。
