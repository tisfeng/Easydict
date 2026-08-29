# 发布后 Issue 跟进

当用户调用 `issue-followup plan|apply|resume <version>`，或主发布流程在远程验证成功后
进入 Issue 阶段时，读取本文档。关联和解决判断同时遵循
[issue-followup-policy.md](issue-followup-policy.md)。

## 动作与授权

- `issue-followup plan <version>`：重新收集 GitHub 证据并生成计划和固定汇总；允许写入
  `.tmp` 下被忽略的本地状态，不评论或关闭 Issue。
- `issue-followup apply <version>`：先完整执行一次最新 `plan`，冻结本批次后再评论和
  关闭 Issue。用户不需要提前调用独立 `plan`，旧的未执行计划也不能直接作为执行源。
- `issue-followup resume <version>`：复用中断 `apply` 的冻结候选和决策，刷新当前
  Issue 状态，只重试尚未完成的远程动作。

`apply` 和 `resume` 只有在用户明确请求具体版本，或同一用户请求已经授权
`publish`/`release` 且版本通过远程发布验证后，才允许修改 GitHub。Issue 阶段不得
发布、编辑、删除 GitHub Release，也不得修改 prerelease 状态。

要求目标版本已经公开发布。频道由 GitHub Release 的实际状态确定：prerelease 为
`beta`，否则为 `stable`；调用方指定的频道如果不一致，必须停止。

## `plan`

1. 捕获精确版本的已发布 GitHub Release 及其 PR 条目。
2. 收集每个 merged PR 在模板区域声明的关联 Issue 和兼容弱引用，解析 GitHub 实体并
   排除 PR 编号碰撞。
3. 逐个检查候选 Issue 与全部 source PR，按照
   [issue-followup-policy.md](issue-followup-policy.md) 生成且只生成一条 schema-v2 决策。
4. 验证候选来源哈希和全部决策，再生成 `plan.json` 与 `summary.md`。
5. 输出固定三类汇总后停止，不执行任何 GitHub 写入。

## `apply`

1. 重新执行完整 `plan` 流程，替换更早但尚未执行的计划。
2. 将候选、决策和计划冻结为同一个执行批次。
3. 先运行不带 `--execute` 的本地预览；通过后再以相同输入追加 `--execute`。
4. 每个版本最多发布一次带隐藏标记的通知；所有当前开放且被判为已解决的 Issue 都应
   关闭，包括曾经关闭后重新打开的 Issue。
5. 刷新并核对最终 Issue 状态，返回 helper 生成的固定 Markdown 汇总。

## `resume`

1. 要求状态目录中存在 schema-v2 冻结批次；不得导入或覆盖直接存放在 `state/` 下的
   schema-v1 旧状态。
2. 验证冻结的候选、决策和来源哈希，然后重新运行 `apply --execute`。
3. 版本通知标记用于防止重复评论；是否关闭只取决于当前 Issue 是否开放以及冻结决策
   是否已解决，不取决于 reopen 历史或旧的本地关闭标记。

## 状态目录

只使用 `.tmp/release/<version>/state/issue-followup/`：

- `release-content.json`：已发布 Release 和精确 PR 条目。
- `candidates.json`：PR、引用、Issue 和评论快照。
- `decisions.json`：逐 Issue 的关联和解决决策。
- `plan.json`：确定性执行批次。
- `summary.md`：固定三类 Markdown 汇总。
- `actions.json`：逐 Issue 的远程动作进度。

schema-v1 文件是审计数据，不自动复用、迁移或删除。

## 固定汇总

始终按以下顺序输出标题；空分组也必须包含 `- 无`：

1. `关闭 issue 并已通知`
2. `仅发通知`
3. `未关闭的相关 issue`

每个可见 Issue 和 PR 都必须使用 Markdown 链接。第三组必须提供来自已验证决策的具体
原因。编号碰撞和无关引用只保留在 `plan.json` 的机器审计中，不新增用户可见分类。

## Helper 命令

以下命令均从仓库根目录执行。

先创建状态目录并捕获 Release：

```bash
mkdir -p .tmp/release/<version>/state/issue-followup

.agents/skills/release-easydict/scripts/release_content.py capture \
  --repo tisfeng/Easydict \
  --version <version> \
  --output .tmp/release/<version>/state/issue-followup/release-content.json
```

收集候选：

```bash
.agents/skills/release-easydict/scripts/release_issues.py collect \
  --repo tisfeng/Easydict \
  --version <version> \
  --content .tmp/release/<version>/state/issue-followup/release-content.json \
  --output .tmp/release/<version>/state/issue-followup/candidates.json
```

按照决策策略生成 `decisions.json`，外层格式为：

```json
{
  "schema_version": 2,
  "source_sha256": "copy from candidates.json",
  "decisions": []
}
```

验证决策：

```bash
.agents/skills/release-easydict/scripts/release_issues.py validate \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json
```

生成计划和汇总：

```bash
.agents/skills/release-easydict/scripts/release_issues.py plan \
  --repo tisfeng/Easydict \
  --version <version> \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json \
  --plan .tmp/release/<version>/state/issue-followup/plan.json \
  --summary .tmp/release/<version>/state/issue-followup/summary.md
```

预览和执行使用相同参数；只有第二次追加 `--execute`：

```bash
.agents/skills/release-easydict/scripts/release_issues.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --candidates .tmp/release/<version>/state/issue-followup/candidates.json \
  --decisions .tmp/release/<version>/state/issue-followup/decisions.json \
  --plan .tmp/release/<version>/state/issue-followup/plan.json \
  --summary .tmp/release/<version>/state/issue-followup/summary.md \
  --state .tmp/release/<version>/state/issue-followup/actions.json
```

`resume` 保留冻结输入并重新运行上述 `apply --execute`。helper 会跳过已有版本通知，但
仍会关闭当前开放且已解决的 Issue。

## 失败处理

- 收集、决策或计划失败时不执行任何 GitHub 写入。
- `apply` 部分失败时保留已发布 Release 和全部已完成动作，不做回滚。
- 主发布流程应报告“发布成功，但 issue 后续处理未完成”，并提供：

  ```text
  $release-easydict issue-followup resume <version>
  ```
