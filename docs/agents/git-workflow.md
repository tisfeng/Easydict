# Git 工作流

本文只规定仓库 Git 状态保护、暂存和本地交付；请求语义和变更门禁分别见
[`request-boundary.md`](request-boundary.md) 与 [`execution-safety.md`](execution-safety.md)。

## 基本安全

- 保留用户现有的 staged 和 unstaged 变更，不重写或丢弃无关工作树内容。
- 除非任务明确授权、处于 `delivery` 模式或满足自动本地提交规则，否则不要暂存、提交
  或推送；明确禁止优先。
- 推送前核对目标远程状态及提交关系，按已授权工作流同步。实施默认只本地交付；
  PR 创建、集成或发布请求可包含对应 skill 明示的必要 Git 操作，其他任务不自行执行
  `push`、`pull`、`rebase` 或 `merge`。用户的禁止条件优先，不为同步而重写用户历史。
- 每个提交聚焦于一个连贯的行为或文档变更，并使用 Angular-style 信息。

## Git 交付顺序

1. 第一次写入前记录 `initial_head`、初始 staged、unstaged、untracked、冲突和任务允许路径；
   对任务相关脏内容保留分层 diff/内容快照，不能仅凭路径重建任务归属。
2. 按 `request-boundary.md` 区分普通只读分析与获准的工作流准备；写入和交付保护
   按 `execution-safety.md` 分别判断。不要将自动提交资格用于否决显式 staged 交付。
3. `delivery` 使用
   [`.agents/skills/git-commit/SKILL.md`](../../.agents/skills/git-commit/SKILL.md)。已有 staged
   内容时只提交该范围；显式调用该 skill 且索引为空时，按它的一次暂存规则执行，
   用户指定路径或禁止暂存时优先遵守该限制。
4. `implementation` 在验证完成后，只有满足自动本地提交条件时才执行一次自动提交。

## 自动本地提交条件

以下条件必须同时满足：

- 任务是 `implementation`，且会话中没有仍有效的禁止提交或暂缓交付要求；
- 初始索引为空，任务执行期间也没有出现新的非 Agent staged 内容；
- `HEAD` 未变化，当前索引无冲突，用户变更与 Agent 变更可以清晰分离；
- Agent 产生了仓库文件差异，并已创建或更新同任务 history；
- 允许路径和 Agent-owned paths 已明确，暂存后 staged paths 与预期集合完全一致；
- 按 `build-and-test.md` 完成必要审查与验证，最终结果覆盖最终代码及测试，且没有
  未处理的有效阻塞 finding 或验证失败；
- 当前任务尚未执行过自动提交。

`implementation` 的执行计划如实记录交付默认值及跨轮仍有效的限制。不能因为用户没有
单独提及“提交”，就把自动本地提交降级为未提交；计划作者或 Agent 也不能用计划字段
添加用户未给出的禁止条件。

自动提交只暂存明确的 Agent-owned paths 和同任务 history，不使用 `git add .`。同一
任务分多轮实施时复用同一条 history；仅修改 history 的任务不递归创建第二条。没有
仓库文件差异时不创建空提交。

提交成功后，报告完整提交哈希、实际提交信息、工作树状态、push 状态，以及文本文件的
代码、文档和总变动统计；二进制变动不计入统计。

如果条件不满足，跳过自动提交并报告原因，允许范围内的实施和修复仍可继续。
history 缺失时先补齐；不在允许范围内或无法与用户变更分离时保留未提交结果。
显式交付遵守所选工作流，不反向套用 implementation 的 history 和空索引前提。

## Easydict PR 交付

需要创建 PR 时使用仓库现有的 `submit-pr` skill，并显式传入：

- `--base dev`
- `--base-remote origin`
- `--issue-policy forbid`

如果 head 需要推送到其他 fork remote，再显式传入 `--head-remote`。PR review 遵循
`.agents/skills/review-pr/SKILL.md` 的完整流程。
