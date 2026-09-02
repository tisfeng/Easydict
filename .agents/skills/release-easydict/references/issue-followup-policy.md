# 发布后 Issue 关联与解决策略

本策略优先识别 PR 模板 `## 关联 Issue / Linked Issues` 区域中的明确关联，同时兼容
现有 PR 中的 closing reference、issue URL、`owner/repo#123` 和裸 `#123`。不要依赖
会在 PR 合并时提前关闭 Issue 的 GitHub closing keyword 或 Development 侧栏关联。

## 候选发现

只从当前 Release Notes 列出的 merged PR 收集同仓库候选：

- PR 正文 `## 关联 Issue / Linked Issues` 区域中的裸 `#123`、完整 issue URL 或
  `owner/repo#123`；这些引用统一标记为 `linked_issue`。
- GitHub `closingIssuesReferences`。
- PR 正文中的完整 issue URL。
- PR 正文或 commit message 中的 `owner/repo#123` 和裸 `#123`。

候选编号必须通过 GitHub issue API 解析。包含 `pull_request` 字段的实体是 PR，直接
排除。同一个 Issue 使用多种格式时只生成一个候选。模板区域外的兼容引用仍需检查
是否只是编号碰撞；候选发现本身不代表关联成立。

## 逐 PR 关联

每个候选 issue 必须为每个引用它的 PR 记录一种关联：

- `fixes`：PR 的目标或实际改动解决该 issue；不要求出现 `Fixes`、`Closes` 或
  `Resolves` 关键字。
- `related`：PR 与 issue 有真实关联，但只把它作为背景、相似问题、回归来源或未实现
  的后续需求。
- `rejected`：编号碰撞、引用的是其他对象，或 PR 与 issue 没有真实关系。

每条关联都必须包含至少一个 GitHub URL 和简短证据说明。不能只根据标题相似度建立
关联。`linked_issue` 表示贡献者已经明确声明 Issue 与 PR 相关，不要求贡献者进一步
区分 `fixes` 或 `related`：

- PR 的目标或实际改动覆盖 Issue 核心请求，且没有明确相反证据时，使用 `fixes`。
- PR 明确只把 Issue 作为背景、相似问题或未实现需求时，使用 `related`。
- 只有编号碰撞或实际不存在关联时才使用 `rejected`。

## 默认解决规则

只要至少一个本次 Release 的 PR 被判为 `fixes`，该 issue 默认是 `resolved`。以下
内容都不能单独推翻默认值：

- issue 当前是 open、closed，或曾在 PR 合并后 reopen。
- PR 使用了“防御性修复”“workaround”“难以定位根因”等措辞。
- reporter 没有再次确认。
- 缺少自动化测试，或 Agent 只有一般性不确定。

只有以下明确反证才允许使用 `not_resolved`：

- 修复合入后，issue 评论或可复现实验明确证明相同问题仍然存在。
- PR 明确说明 issue 的某个验收条件没有实现，且本版本没有其他 PR 补齐。
- 修复在发布前被 revert、禁用或从最终版本移除。
- 实际改动只解决了不同问题，不能覆盖该 issue 的核心请求；这种情况通常还应重新
  检查关联是否应为 `related`。

每条反证必须记录可点击的 GitHub URL 和具体说明。`not_resolved` 没有反证时校验必须
失败。多个 PR 可以共同完成一个 issue；应综合本次 Release 中全部 `fixes` PR。

## 决策结构

每个候选 issue 只生成一条决策，并覆盖全部 source PR：

```json
{
  "issue_number": 1201,
  "source_prs": [1212],
  "associations": [
    {
      "pr_number": 1212,
      "relationship": "fixes",
      "evidence": [
        {
          "url": "https://github.com/tisfeng/Easydict/pull/1212",
          "summary": "The merged PR restores input focus for the reported case."
        }
      ]
    }
  ],
  "resolution": "resolved",
  "outcome": "fixed",
  "language": "zh-Hans",
  "negative_evidence": [],
  "reason": "The released PR fixes the reported focus loss."
}
```

- `resolution`：`resolved`、`not_resolved` 或 `not_applicable`。
- `outcome`：`fixed`、`implemented` 或 `not_applicable`，用于通知文本。
- 含 `fixes` 时必须使用 `resolved` 或 `not_resolved`。
- 只有 `related`/`rejected` 时必须使用 `not_applicable`。
- 全部为 `rejected` 的候选只进入机器审计。

## 动作分类

- `resolved` 且 issue 当前开放：关闭并通知。
- `resolved` 且 issue 当前已关闭：仅通知。
- `not_resolved` 或只有 `related` 关联：保留开放状态，并说明明确原因。
- 全部为 `rejected`：不执行动作，不进入用户可见汇总。

已有版本通知标记只阻止重复评论，不阻止关闭当前开放且已解决的 issue。
