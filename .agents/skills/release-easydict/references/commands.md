# Helper 命令映射

以下命令从仓库根目录执行。将 `<version>` 替换为目标版本；默认仓库固定为
`tisfeng/Easydict`。

## Draft 内容

```bash
.agents/skills/release-easydict/scripts/release_content.py capture \
  --repo tisfeng/Easydict \
  --version <version> \
  --output .tmp/release/<version>/state/release-content-source.json
```

根据捕获文件生成完整的 curated JSON，不得遗漏或增加 PR：

```json
{
  "schema_version": 1,
  "source_sha256": "copy from release-content-source.json",
  "release_title": "2.22.0 ✨ feat: add a global translation toggle",
  "highlight_pr": 1203,
  "entries": [
    {
      "pr_number": 1203,
      "title": "feat(shortcut): add a global translation toggle shortcut"
    }
  ]
}
```

然后渲染并预览应用计划：

```bash
.agents/skills/release-easydict/scripts/release_content.py render \
  --source .tmp/release/<version>/state/release-content-source.json \
  --curated .tmp/release/<version>/state/release-content-curated.json \
  --output .tmp/release/<version>/state/release-notes-en.md

.agents/skills/release-easydict/scripts/release_content.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --source .tmp/release/<version>/state/release-content-source.json \
  --curated .tmp/release/<version>/state/release-content-curated.json \
  --notes .tmp/release/<version>/state/release-notes-en.md
```

先检查不带 `--execute` 的 JSON 计划，再使用相同命令追加 `--execute`。只有目标
Release 仍为相同 Draft 且正文没有在 capture 后变化，helper 才允许写入。

## 发布前冻结 issue 决策

```bash
.agents/skills/release-easydict/scripts/release_issues.py collect \
  --repo tisfeng/Easydict \
  --version <version> \
  --content .tmp/release/<version>/state/release-content-source.json \
  --output .tmp/release/<version>/state/issue-candidates.json

.agents/skills/release-easydict/scripts/release_issues.py validate \
  --candidates .tmp/release/<version>/state/issue-candidates.json \
  --decisions .tmp/release/<version>/state/issue-decisions.json
```

`issue-decisions.json` 由 Agent 根据 `issue-decision-policy.md` 和候选快照生成。决策
必须覆盖全部候选，且 `source_sha256` 必须与候选文件完全一致。文件外层格式为：

```json
{
  "schema_version": 1,
  "source_sha256": "copy from issue-candidates.json",
  "decisions": [
    {
      "issue_number": 1254,
      "source_prs": [1255],
      "relationship": "target",
      "completion": "resolved",
      "decision": "notify_on_release",
      "language": "zh-Hans",
      "positive_evidence": ["The released change covers the report."],
      "counter_evidence": [],
      "reason": "The two release gates pass."
    }
  ]
}
```

## 发布后刷新与执行

```bash
.agents/skills/release-easydict/scripts/release_issues.py refresh \
  --repo tisfeng/Easydict \
  --version <version> \
  --candidates .tmp/release/<version>/state/issue-candidates.json \
  --output .tmp/release/<version>/state/issue-candidates-refreshed.json

.agents/skills/release-easydict/scripts/release_issues.py validate \
  --candidates .tmp/release/<version>/state/issue-candidates-refreshed.json \
  --decisions .tmp/release/<version>/state/issue-decisions-refreshed.json \
  --previous-decisions .tmp/release/<version>/state/issue-decisions.json

.agents/skills/release-easydict/scripts/release_issues.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --channel beta \
  --candidates .tmp/release/<version>/state/issue-candidates-refreshed.json \
  --decisions .tmp/release/<version>/state/issue-decisions-refreshed.json \
  --previous-decisions .tmp/release/<version>/state/issue-decisions.json \
  --state .tmp/release/<version>/state/issue-actions.json
```

稳定版本将 `--channel beta` 改为 `--channel stable`。先检查不带 `--execute` 的计划，
确认 Release 已发布且频道匹配后，再使用相同命令追加 `--execute`。
