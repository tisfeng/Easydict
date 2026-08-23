# Helper 命令

以下命令从仓库根目录执行。将 `<version>` 替换为目标版本；状态目录固定为
`.tmp/release/<version>/state/issue-followup/`。

## 捕获与收集

```bash
mkdir -p .tmp/release/<version>/state/issue-followup

.agents/skills/release-easydict/scripts/release_content.py capture \
  --repo tisfeng/Easydict \
  --version <version> \
  --output .tmp/release/<version>/state/issue-followup/release-content.json

.agents/skills/release-easydict-issue-followup/scripts/release_issues.py collect \
  --repo tisfeng/Easydict \
  --version <version> \
  --content .tmp/release/<version>/state/issue-followup/release-content.json \
  --output .tmp/release/<version>/state/issue-followup/candidates.json
```

根据 `decision-policy.md` 生成 `decisions.json`。文件外层格式为：

```json
{
  "schema_version": 2,
  "source_sha256": "copy from candidates.json",
  "decisions": []
}
```

然后验证：

```bash
.agents/skills/release-easydict-issue-followup/scripts/release_issues.py validate \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json
```

## `plan`

`plan` 只读取 GitHub 并生成本地 JSON/Markdown：

```bash
.agents/skills/release-easydict-issue-followup/scripts/release_issues.py plan \
  --repo tisfeng/Easydict \
  --version <version> \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json \
  --plan .tmp/release/<version>/state/issue-followup/plan.json \
  --summary .tmp/release/<version>/state/issue-followup/summary.md
```

频道由 GitHub Release 的 `isPrerelease` 自动确定。

## `apply`

skill 必须先重新执行“捕获与收集”，生成当前 decisions，然后运行本地预览：

```bash
.agents/skills/release-easydict-issue-followup/scripts/release_issues.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json \
  --plan .tmp/release/<version>/state/issue-followup/plan.json \
  --summary .tmp/release/<version>/state/issue-followup/summary.md \
  --state .tmp/release/<version>/state/issue-followup/actions.json
```

验证预览成功后，使用相同命令追加 `--execute`。这一步会再次读取当前 issue 状态和
已有版本标记，因此不要求用户提前调用独立的 `plan`。

## `resume`

保留已冻结的 `candidates.json` 和 `decisions.json`，再次运行上述 `apply --execute`。
helper 会跳过已有版本通知，但只要已解决的 issue 当前开放，仍会将其关闭。
