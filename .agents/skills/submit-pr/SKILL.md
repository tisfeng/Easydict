---
name: submit-pr
description: >
  根据当前 Git checkout 的已提交变更规划、创建或继续 GitHub Pull Request
  提交流程，安全推送任务分支、复用远程状态并验证最终 PR。不用于
  PR review、merge 或仅本地提交。
---

# 提交 GitHub PR

根据当前 Git checkout 的已提交变更，创建或复用 GitHub Pull Request。

下文的 `<submit-pr-skill-dir>` 表示当前加载的 `submit-pr/SKILL.md` 所在目录。
运行随 skill 分发的脚本时，先解析该实际目录；不要假设 skill 安装在某个固定的
Agent 或项目路径中。

## 模式

- `plan`：只读发现仓库拓扑，预览提交范围、标题、正文、base、head 和 push remote；
  不 fetch、不创建分支、不写仓库文件、不 push、不创建 PR。
- 默认：使用 helper 的 `apply`，fetch base、推送任务分支、创建或复用正式 PR 并验证。
- `draft`：与默认相同，但创建 Draft PR。

用户没有指定模式时使用默认模式。

## 必需流程

1. 先确定用户模式和限制，阅读 [工作流契约](references/workflow.md)。用户语言、正文标准、模板、
   Issue 策略、拓扑、身份验证和恢复规则以该文档为准。
2. 运行 `git status --short --branch`，记录 HEAD 与 staged、unstaged、untracked 边界。
3. **纯 plan**：只检查现有提交与缓存，按工作流契约起草内容并运行 helper `plan`，展示完整
   PR 预览后停止。无新增提交或缺少 cached base 时，报告已有证据和预览缺口；不为使预览
   成功而提交、fetch 或创建分支。
4. **默认或 draft**：先准备可交付内容，再生成最终预览。
   - unstaged 或 untracked 非空时停止，不运行 `git add`。
   - 仅 staged 非空时，按目标仓库交付规则用可用的 `git-commit` 提交既有索引；工作树干净时
     复用已有提交。helper 本身不暂存或提交。
   - 按工作流契约确认 base repository、remote 和 branch，在干净工作树中 fetch 精确 base ref：

     ```bash
     git fetch --no-tags <base-remote> refs/heads/<base>:refs/remotes/<base-remote>/<base>
     ```

   - 检查完整 `<base-remote>/<base>..HEAD` 提交和文件范围；无关、为空、来源不明或 HEAD
     未包含 base 时停止，不自动 rebase、merge 或修正历史。
5. 按工作流契约解析用户首选语言及来源，再起草内容。运行 helper `plan` 渲染并展示首选语言、
   语言来源和完整 PR 预览；语言与正文不一致时先修正，不把自然语言判断交给 helper。默认模式
   继续，用户要求确认或暂缓时遵守限制。禁止使用可能 push 的 `gh pr create --dry-run`。
6. 使用 helper `apply` 重新核对状态、fetch base、精确推送并创建或复用 PR；draft 追加 `--draft`。
   最终报告 PR URL、base/head repository 与 branch、head SHA、Draft 状态、分支/push/PR 动作
   及截图提醒。本轮创建过提交时，一并保留 `git-commit` 的完整回执，Push 字段反映实际结果。
   helper 成功结果已包含最终 PR 校验摘要，正常路径不再额外读取完整 PR 正文。

## 快速执行协议

保持完整预览、写前重新发现、精确 fetch、提交范围审核、现有 PR 防覆盖、精确 push 和写后验证；
优化正常成功路径的模型与工具往返，不删除远程状态检查或权限边界。

- 首次调用 helper 前选择一个 Python 3.10+ 解释器，优先使用项目已规定的版本；同一任务的
  `plan` 和 `apply` 复用该解释器。helper 会在任何 Git 或 GitHub 调用前拒绝不兼容版本。
- 展示最终 PR 预览后，如果用户没有确认、暂缓或其他持续限制，在一次程序化工具调用中依次等待
  独立的 `apply` 命令和必要的本地回执命令。每个工具调用仍须明确完成且命令 `exit_code === 0`
  才能继续；运行中 session、审批未完成、非零退出码或工具错误都立即停止后续动作并返回模型。
- `apply` 成功时直接使用其 `pr_verification` 和其他 JSON 字段交付，不再调用 `gh pr view` 重复
  获取正文。需要检查 CI 时只查询 checks，不重新读取完整 PR。
- 默认不等待 CI。只报告调用时已经获得的状态；仅当用户或目标仓库规则明确要求等待时，才执行
  `gh pr checks --watch` 或等价等待。
- 需要显式更新已有 PR 的 title/body 时，继续冻结旧值和仓库身份，在已获远程编辑授权后单独更新，
  再运行 `apply` 完成写前及写后验证。正常新建或内容一致的复用路径不进入该迁移分支。
- 语言、正文、范围、身份或远程状态变化，现有 PR 不匹配，授权拒绝或验证失败时立即返回模型；
  不自动覆盖维护者编辑、不跳过 apply 的重新发现，也不跨 `plan` 与 `apply` 缓存可变远程状态。

## Helper 调用

最小调用示例：

```bash
python3.12 "<submit-pr-skill-dir>/scripts/submit_pr.py" plan \
  --title '<type(scope): subject>' \
  --summary '<summary>' \
  --verification '<verification>' \
  --head-branch '<type/kebab-case-summary>' \
  [--issue '#123'] \
  [--issue 'https://github.com/owner/repo/issues/123'] \
  [--issue 'owner/repo#123'] \
  [--ui-change]
```

示例使用 Python 3.12；项目明确使用其他 Python 3.10+ 解释器时，以解析后的同一可执行文件替换，
不要在 `plan` 与 `apply` 之间重新选择。创建时把 `plan` 改为 `apply`。字符串必须作为独立参数传递，不能通过 `eval` 或拼接
可执行 shell。只有当前分支已经是合规任务分支时才可省略 `--head-branch`。

存在拓扑歧义或项目专属规则时使用：

```bash
  [--repo owner/repo] \
  [--base main] \
  [--base-remote upstream] \
  [--head-remote fork] \
  [--protected-branch production] \
  [--template .github/PULL_REQUEST_TEMPLATE/feature.md] \
  [--extra-body-file /path/to/project-sections.md] \
  [--issue-policy neutral|allow|forbid]
```

## 安全边界

- 明确提交 PR 才允许上述默认/draft 写入；纯 plan 保持只读。
- 只支持 GitHub remote；拓扑有歧义时要求显式参数，不创建 fork。
- 不 force push，不执行 rebase、merge、reset、stash、删除分支或 remote；不切换当前 checkout
  或推送保护分支。
- 不自动添加 reviewer、label、milestone、project，不 merge PR、评论或关闭 Issue。
- 远程状态不匹配时保留现场，不覆盖已有 PR。恢复时按工作流契约复用已完成动作，不重复创建。
