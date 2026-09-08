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
3. 主 Agent 确认授权、允许路径、初始 Git 快照和暂存边界后，串行委派
   [`.codex/agents/git-delivery.toml`](../../.codex/agents/git-delivery.toml)。`commit` 与
   `auto-local-commit` 操作执行 [`.agents/skills/git-commit/SKILL.md`](../../.agents/skills/git-commit/SKILL.md)；
   `integration` 操作执行 [`.agents/skills/worktree-rebase-merge/SKILL.md`](../../.agents/skills/worktree-rebase-merge/SKILL.md)。
4. `implementation` 在验证完成后，只有满足自动本地提交条件时才由 `git-delivery`
   以 `auto-local-commit` 操作执行一次自动提交。

## 本地 Git 交付 Agent

`git-delivery` 是唯一执行本仓库常规本地提交和获授权 worktree 集成的 custom agent；其
模型、推理强度和沙箱以 [`.codex/agents/git-delivery.toml`](../../.codex/agents/git-delivery.toml) 为权威。
它不是一个新的 Skill，也不修改现有 `git-commit` 或 `worktree-rebase-merge` Skill 的
staged-only、提交信息校验、变动统计、目标解析和 no-push 契约。

- 主 Agent 负责在首次写入前记录初始 HEAD、暂存/未暂存/未跟踪路径、冲突和
  `task_allowed_paths`，并在委派前完成交付授权与自动提交资格判断。
- 只有所有其他写入 Agent 已完成，且主 Agent 冻结提交范围后，才能启动一个
  `git-delivery`；不得并发写入共享 Git index 或目标 worktree。
- 主 Agent 仅传递授权类型、operation、允许路径、初始状态摘要和验收标准。`git-delivery`
  必须自行重新读取实际 staged patch、HEAD、源和目标 worktree 状态，并按对应 Skill 的
  完整契约执行。
- 需要创建提交时，`git-delivery` 先以 `prepare` 只读返回精确草稿；主 Agent 在主对话原样
  发送 `提交信息预览` 后，才向同一 Agent 发出 `apply`。确认或仅预览模式在获得用户批准
  前不进入 apply；预览后状态漂移使草稿失效并进入 protected。
- 索引为空但当前操作允许对应 Skill 的唯一一次暂存时，`prepare` 只读冻结候选路径、
  未暂存 raw patch 与未跟踪文件内容摘要，并据此生成草稿。`apply` 必须先重验快照，再按
  `expected_commit_paths` 精确暂存；不能得出完整精确集合时进入 protected，不运行宽泛
  `git add .`。暂存后核对 staged raw patch 未超出候选范围且与草稿依据一致；不一致时
  返回新的 prepare。
- `commit` 与 `auto-local-commit` 只允许执行 `git-commit`。只有明确 `integration` 授权
  才允许 `git-delivery` 按 `worktree-rebase-merge` 在同一 Agent 内创建分支或临时 worktree、
  commit、rebase 和 merge；不得递归委派。
- `git-delivery` 不能安全确认配置、授权、模型、范围、HEAD、索引、目标 worktree 或校验
  结果时，必须进入 protected 并返回主 Agent。custom agent 不可发现或指定模型不可用时同样
  fail closed；主 Agent 不得静默改由自身或其他模型提交或集成。
- 仅当本轮正新增或更新 `git-delivery` 配置、运行时尚不能重新发现该配置时，主 Agent
  可以先解析 TOML，再显式启动拥有完全相同模型、推理强度、写入权限和开发指令的提交
  或集成子智能体。该 bootstrap fallback 必须在交付报告中声明；无法精确复现配置时仍然
  fail closed。
- 完成后，主 Agent 独立核验提交哈希、实际提交信息、分支、最终工作树和未 push 状态，
  再向用户报告结果。

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

当前受管 `submit-pr v0.3.0` 使用 Python 3.10 引入的标准库语法。执行脚本或其测试前先
确认所选 `python3` 版本不低于 3.10；默认解释器较旧时，解析并显式使用当前环境中可用的
兼容解释器。无法确认版本或没有兼容解释器时 fail closed，不在项目内修改受管 Skill。

如果 head 需要推送到其他 fork remote，再显式传入 `--head-remote`。PR review 遵循
`.agents/skills/review-pr/SKILL.md` 的完整流程。
