# submit-pr 工作流契约

本文件说明 `submit_pr.py` 与调用 Agent 的职责，以及各阶段的检查和执行规则。执行
`plan`、默认或 `draft` 模式时都要完整阅读。

首次运行 helper 前选择一个可用的 Python 3.10+ 解释器；同一任务的 `plan` 和 `apply`
使用同一解释器。这是 helper 的运行时要求，不是产品依赖；不要为此修改项目的 Python 配置。
找不到兼容解释器时报告缺口，不声称 helper 已运行。

## Repository 拓扑发现

helper 只接受指向 `github.com` 的 SSH 或 HTTPS remote，并按以下顺序解析：

1. base repository：显式 `--repo`、`GH_REPO`、所有 GitHub remote 所属 fork 网络的
   唯一根仓库；多个根仓库时停止。
2. base remote：显式 `--base-remote`，否则唯一指向 base repository 的 remote；不能
   仅因名称是 `origin` 就信任它。
3. base branch：显式 `--base`、attached 当前分支的 `branch.<name>.gh-merge-base`、GitHub
   repository 的 default branch；detached checkout 跳过 branch-scoped 配置。
4. head remote：显式 `--head-remote`、attached 当前分支的 `branch.<name>.pushRemote`、
   `remote.pushDefault`、唯一 fork remote、attached 当前 upstream、base remote。detached checkout
   跳过 branch-scoped 配置；任一步产生多个有效候选时停止。
5. head repository 必须与 base repository 位于同一 fork 网络；跨 fork PR 使用
   `<owner>:<branch>` 作为 `gh` 的 head 参数。

显式参数只解决歧义，不能绕过 remote URL、fork 网络和 GitHub 返回身份的校验。
同次拓扑发现中，显式 repository 与已查询的 remote repository 相同时复用元数据；每次
`preflight`、`plan` 或 `apply` 调用重新发现，不跨调用缓存，也不省略写入前后的状态校验。
同一 `apply` 调用内已经验证的 repository 元数据、remote push URL 和冻结 SHA 可以复用，避免
为相同事实重复启动本地进程；复用范围不得跨越新的 helper 调用。

## 分支决策

任务名与显式名称校验统一使用 [`git-commit` 的命名工具](../../git-commit/references/branch-naming.md)。
显式 `--head-branch` 可提供用户指定的其他合法字面名称；普通本地提交不受下面的 PR 来源分支限制。

base branch、GitHub default branch 和重复传入的 `--protected-branch` 都属于保护分支。

- `preflight` 是只读分支预检：解析仓库拓扑后，比较当前分支名与 base branch、GitHub default
  branch，并校验显式 `--head-branch`。它不 fetch、不创建 ref、不切换 checkout、不写仓库文件或
  push；成功时返回已解析的 repository、base/default、head remote 和 branch 信息。
- 当前分支名与 base branch 或 GitHub default branch 相同时，`preflight`、`plan` 和 `apply` 都拒绝
  继续，即使传入了不同的 `--head-branch`。错误提示用户自行创建并切换到新的任务分支后重试；已有
  提交可由新分支继承，无需重复创建相同提交。`apply` 在 fetch base 前重复此检查。
- 显式 head 名称不得与 base branch、GitHub default branch 或额外配置的保护分支同名。head 位于
  fork remote 时仍按名称比较，不因 repository 不同而绕过检查。
- 当前分支是其他保护分支或不符合 Conventional 格式：必须提供
  `--head-branch <task-branch>`。helper 从冻结 HEAD 创建或复用该本地 ref，但不切换 checkout、不
  移动当前分支。
- 显式名称等于当前非保护分支时直接复用，不因其格式与默认值不同而另建分支。
- 当前已经是默认 Conventional 非保护任务分支：直接使用；如果同时提供 `--head-branch`，名称必须相同。
- 显式名称不得是保护分支；名称冲突时尝试的后缀候选同样跳过保护分支。
- Detached HEAD：调用 Agent 根据用户明确名称、项目既有命名或任务与只读 diff 生成分支名，并向
  `preflight`、`plan` 和 `apply` 显式传入相同的 `--head-branch`。helper 自身不从 PR 标题猜测名称；
  缺少参数时在写入前停止。
  `plan` 以 `current_branch: null` 和 `would-create`、`would-update` 或 `would-reuse` 预览动作且不创建
  ref；`apply` 从冻结 HEAD 创建、更新或复用本地 ref，不切换 checkout。

调用 Agent 在提交 staged 内容、fetch 或调用 `apply` 前运行 `preflight`；`plan` 和 `apply` 内部也
重复分支检查，不能依赖调用方一定执行预检。`apply` 先解析拓扑并完成保护分支检查，再 fetch
精确 base ref，之后要求 `<base-remote>/<base>` 是 HEAD 的祖先且范围至少包含一个提交。该拓扑检查
不替代调用 Agent 对提交范围和任务边界的语义审查。

## 工作树与提交

- `preflight` 与 `plan` 使用 `GIT_OPTIONAL_LOCKS=0` 执行 Git 读取；二者都不 fetch、不创建 ref、
  不写临时文件。`plan` 可以报告 staged、unstaged 和 untracked 状态。
- `apply` 要求工作树完全干净。
- `apply` 在本地 ref 写入前重新检查 checkout 的 attached/detached 状态与 HEAD；与冻结计划不一致时
  停止，并重新读取目标 ref。分支更新继续使用 Git 的 worktree 检出保护，不移动其他 worktree
  正在使用的分支。
- helper 不运行 `git add` 或 `git commit`。已有 staged 内容由调用 Agent 根据目标
  仓库交付规则处理；有 unstaged 或 untracked 内容时停止。
- 默认/draft 的调用方先运行 `preflight`，再完成允许的 staged 提交和精确 base fetch，解决首次提交或
  缺少 cached base 的准备问题。纯 plan 不执行这些动作，缺少前提时只报告限制。
- helper 不修改提交历史，也不把无关提交从范围中自动剔除。

## 固定 PR 正文契约

`plan`、默认和 `draft` 均依据用户请求、目标仓库规则、真实提交范围与 diff 起草正文。
PR 标题使用 Angular-style `type(scope): subject`，subject 统一使用英文说明主要行为，不随正文或
对话语言变化。

正文只使用 Skill 自带的 [固定模板](../assets/pull_request_template.md)，依次包含：

1. `背景 / Context`：说明为什么需要本 PR、目标和必要约束。
2. `变更内容 / Changes`：说明实际改变的行为或实现，不重复验证结果。
3. `关联 Issue / Linked Issues`：列出有证据的关联 Issue 和 PR，并简述各自与本次改动的关系。
4. `验证 / Verification`：只列实际执行的检查及结果；未执行时写明原因。
5. `截图 / Screenshots`：内嵌已有验证图片，有截图缺口时保留补图提示。非 UI 修改既无图片也无缺口时使用 `N/A`。

调用 Agent 不发现或读取目标仓库根目录、`docs/`、`.github/` 或其他位置的 GitHub PR 模板，
也不把其中的标题、说明或 checklist 合并进正文。目标仓库的明确规则仍可约束语言、证据和 Issue
策略；规则要求与固定结构不兼容时停止并说明冲突，不恢复模板合并。

helper 要求 `--title`、`--context`、`--changes` 和 `--verification`；不接受 `--summary`、
`--template`、`--extra-body-file` 或任意正文文件。Context、Changes 和 Verification 均不能为空。

### 正文与报告语言

调用 Agent 在起草前按顺序从第一个可用来源解析 `{USR_PREFERRED_LANGUAGE}`：

1. 当前请求或对话中明确的语言偏好。
2. 当前对话的主要交流语言。
3. 可读取的用户系统首选语言，例如 macOS `AppleLanguages`、POSIX `LC_ALL`、
   `LC_MESSAGES`、`LANG`、`locale` 或 Windows PowerShell culture 输出。
4. 以上均无法确定时使用英语。

目标仓库明确要求特定正文语言时，将其作为独立硬约束并在预览中说明；若它与用户明确偏好冲突，
停止并请求用户决定。固定模板标题、提交信息、分支名或单独的英文终端 locale 不能覆盖已经确定的
对话语言，也不能单独视为仓库语言要求。

PR 正文默认使用一种首选语言。Context、Changes、Verification、调用 Agent 自拟的 Issue 或
截图说明，以及用户可见的最终报告都使用该语言；只有用户或仓库明确要求时才生成双语正文。
引用 PR 标题时保留其英文原文；Angular `type(scope)`、Issue 关键字、命令、路径、branch、SHA、
API、产品名和检查名等技术标识保留原文。

固定模板的双语标题、`N/A` 和 helper 固定截图提示属于稳定结构，不参与语言推断。调用 Agent
在运行 helper 前负责检查标题使用英文、正文与首选语言一致，并在 PR 预览中分别显示标题语言
和正文语言及来源；helper 只校验格式并原样渲染传入内容，不检测语言或翻译。

### 关联证据

在正文预览前，结合任务上下文、提交信息和真实 diff 核对解释改动来由的 Issue 和 PR。沿相关文件、
删除路径或关键字符串查看 Git 历史，例如使用 `git log <base-ref> -- <paths>`、
`git log -S <literal> <base-ref> -- <paths>` 或 `git log --follow <base-ref> -- <path>`。
用历史提交的 PR 编号或 GitHub 的提交关联查询定位引入、替代或临时修复该行为的 PR。
需要时用只读 `gh issue view`、`gh pr view`、`gh pr diff` 或 GitHub 搜索核对正文与改动，
确认每条引用和当前 diff 的直接关系。相同文件的例行更新以及只匹配关键词的结果应剔除。
证据不足时省略该引用，整段没有证据时留空。

- 对每个 Issue 传入 `--issue 'REF 关系说明'`。REF 接受 `#123`、完整 Issue URL 或
  `owner/repo#123`，旧的纯 REF 输入仍有效。
- 对每个 PR 传入 `--related-pr URL '关系说明'`，使用明确的 GitHub `/pull/<number>` URL。
  这类引用作为中性条目渲染。两个选项均可重复，说明使用正文语言，每条一行。
- 例如，恢复官方图表并删除自建流程时，应核对上游故障、仓库曾采用的临时替代方案，以及引入
  被删除流程的 PR。例行生成图表的更新 PR 无需列入。

## Issue 策略

`--issue-policy` 决定 GitHub 自动关闭引用的约束：

- `neutral`（默认）：调用 Agent 不主动生成 `Fixes`、`Closes`、`Resolves` 等自动关闭语法；
  允许用户明确要求的正文包含该语法。helper 不生成 closing keyword，也不对正文和提交历史
  施加额外限制。
- `allow`：显式表明目标工作流允许 closing keyword。
- `forbid`：扫描正文和 base..HEAD 的完整提交信息，并在创建后要求
  `closingIssuesReferences == []`。

关联条目只渲染引用和说明。已有 Issue 自动关闭策略照常应用。

## 截图交付

1. 生成 PR 预览前，主动检查本对话中的图片、附件、链接和工具产物，包括调用 Skill 之前已有的材料。
   核对截图是否来自本次 PR 的实际验证，并确认所展示的页面、主题或状态。找到匹配且可访问的
   截图就直接复用，无需用户再次提供。若图片只在聊天中可见，且无法取得原图或可用 URL，
   报告该截图及访问缺口。
   UI 修改传 `--ui-change`。每张已有可用 HTTPS URL 的验证图片都传 `--screenshot '描述' URL`。
   全部齐备时截图区域只含图片，仍有待交付的截图时追加 `--screenshots-incomplete` 保留补图提示。
   无 URL 的 UI 修改自动显示提示，无需因此改成 Draft。
2. 纯 `plan` 仅嵌入已有 URL，预览中列出已有但待上传的截图及其用途。获准交付时，主动上传
   可访问的验证截图文件，包括对话附件和工具产物。
   若能访问 GitHub 的 PR 创建编辑器并上传本地文件，使用
   [GitHub 网页附件](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files)
   取得图片 URL，将其交给 helper 渲染，创建仍由 helper 执行。
   浏览器不可用时，将待上传图片逐张传给 `apply --screenshot-file '描述' PATH`，每张使用不同描述。
   此时仅当还有未列入本次上传的缺图时传 `--screenshots-incomplete`。
   helper 只在需要新建 PR 时使用 [GitHub CLI 的 `gh pr create --attach`](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli)，
   并验证 GitHub 在截图区域写入的图片链接。已有 PR 保持原正文，缺图继续按下一步处理。
3. 需要在创建后补传时，先用 helper 创建或复用并验证 PR。将原始 apply JSON 保存到仓库外的任务文件，
   并保留已验证正文的参数。读回该 PR 后，在正文编辑器中上传附件，取得 URL 并保留在任务上下文中。
   此时保持编辑器未保存。补传要求上传与正文保存分开执行。`gh pr edit --attach` 会在上传后自动写回
   上传前读取的正文，不能用于此步骤。无法分开执行时报告上传缺口，保留现有正文。
4. 使用最终截图 URL 运行 `plan --apply-receipt <file>` 生成预期正文，沿用原始标题、Draft、Issue 策略及
   非截图内容。helper 用原始回执的摘要拒绝非截图正文变化。准备好截图区域的改动，再用最近一次已验证正文的参数运行
   `plan --apply-receipt <file> --verify-pr <number>` 立即读回并核对。发现正文或 PR 身份有漂移时停止保存。
   核对通过后立即保存，或使用只更新正文的 `gh pr edit <number> --repo <repo> --body-file <file>`。
   若仍有截图缺口，保留补图提示并报告原因。
   远程读取和保存是两次操作，期间发现并发编辑时停止。
5. 用最终正文参数运行同一个 `plan --apply-receipt <file> --verify-pr <number>` 命令，只读核对完整
   正文、PR 身份、原始 head SHA、标题、Draft 和 Issue 策略。再检查 GitHub 渲染页上的图片是否加载，
   使用目标读者有权访问的会话核对私有附件。图片加载失败时继续处理，必要时保留补图提示并复验。
   无法检查实际渲染时如实说明。

附件重试先读取同一个 PR 和已取得的 URL。正文已与最终版本一致时直接复验。正文仍是上次验证版本时，
复用已取得的 URL，只上传仍缺失的文件。上次上传或保存结果不明时，先核对编辑器和远程正文。
无法核实时报告缺口，保留原 PR。

CLI 新建部分成功时，即使命令返回非零，helper 也会读回返回 URL 对应的 PR。只有已验证的身份、正文和
已上传图片才进入回执。以 `uploaded_screenshots` 中的标签和 URL 重建已验证正文，按
`missing_screenshots` 继续补图。若原始正文没有显式补图提示，重建旧正文时省略
`--screenshots-incomplete`，在生成仍有缺口的目标正文时再加上。使用同一组本地文件重试可识别和复用
尚未编辑的 CLI 创建结果。发生后续正文编辑后，使用原始回执复验。

## GitHub 写入

push 始终使用计划冻结的 SHA、唯一验证过的 push URL 和精确 refspec。若 head remote 配置了
多个 push URL，必须先收敛为一个目标，否则流程在远程写入前停止：

```bash
git push <validated-push-url> <planned-head-sha>:refs/heads/<head-branch>
```

同仓库 PR 使用 `--head <head-branch>`；fork PR 使用 `--head <owner>:<head-branch>`：

```bash
gh pr create \
  --repo <base-owner/base-repo> \
  --base <base-branch> \
  --head <head-query> \
  --title <title> \
  --body-file <system-temporary-file>
```

`draft` 追加 `--draft`。正文临时文件不写入目标仓库，并在命令返回后清理。禁止依赖
`gh` 隐式推断 fork、push、title 或 body。

## 幂等验证

创建前按 base repository、base branch 和 head query 查询开放 PR：

- 没有 PR：push 并创建。
- 恰好一个且仓库、base/head 分支、title、body 和 Draft 等不可变计划字段相同：允许复用。
  远程 head 与计划 SHA 相同则不推送；远程 head 是计划 SHA 的祖先则普通快进推送。推送后
  再验证 head SHA 和完整 PR 状态。
- 多个 PR，或任一字段不同：停止。

创建或复用后验证：

- `state == OPEN`
- base branch、head branch 和 head SHA 与计划一致
- base/head repository 身份及 `isCrossRepository` 与计划一致
- title、body、`isDraft` 与计划一致
- `forbid` 策略下 `closingIssuesReferences` 为空

验证失败后不创建第二个 PR，也不自动覆盖现有 PR。push 成功但创建失败时保留远程分支；创建
成功但最终验证中断时保留已有 PR。使用相同内容重试原 apply 命令，重新发现并核验已完成动作。
远程分支与计划 SHA 相同则复用，是其祖先则普通快进推送，领先或分叉时停止。
目标仓库要求特定 Issue 策略时显式传入 `--issue-policy`；未指定时使用 `neutral`。

最终 PR 验证和适用的截图交付检查完成后报告结果。默认不等待 CI，也不要求 checks 成功；仅当用户
或目标仓库规则明确要求时，调用 Agent 才在 helper 返回后单独查询或等待 checks。CI 查询结果不能
替代上述 PR 状态、身份、正文和 head SHA 验证。

## 输出

helper 向 stdout 输出 JSON。apply 结果包含：

- PR URL 和编号
- base repository、remote 和 branch
- head repository、remote、branch 和冻结 SHA
- `is_cross_repository`、`draft`、`issue_policy`
- `branch_action`：`created`、`updated`、`reused` 或 `current`
- `push_action`：`created`、`updated` 或 `reused`
- `pr_action`：`created` 或 `reused`
- `pr_verification`：最终验证状态、PR state/title、正文 SHA-256 和远程 head SHA
- `non_screenshot_sha256`：原始非截图正文摘要，用于补传计划与复验
- 使用 `--screenshot-file` 时额外返回 `uploaded_screenshots`（描述与 URL）、
  `missing_screenshots`（缺失的描述），并在 CLI 返回错误说明时附上 `attachment_warning`
- `timings_ms`：apply 的 worktree、认证、拓扑、fetch、计划复验、PR 查询、push、创建和最终验证
  等阶段耗时；用于诊断而不是固定性能承诺
- `needs_screenshots`：UI 修改且没有截图、仍有指定附件缺失，或显式传入 `--screenshots-incomplete` 时为 `true`

常规 plan 结果包含 `current_branch`；detached checkout 为 `null`。`planned_branch_action` 使用
`would-create`、`would-update`、`would-reuse` 或 `current`，且不会执行对应 Git 写入。
`plan --apply-receipt <file>` 使用成功的 apply JSON 回执渲染后续正文，返回冻结的 PR 身份、head SHA
和预期正文。追加 `--verify-pr <number>` 时，只读核对回执中的 PR 并返回 `pr_verification`。
这两种用法均无需重新发现拓扑或检查当前 checkout 的 head 或缓存的 base。
缺少非截图正文摘要的旧回执无法用于截图补传。

调用 Agent 应直接使用成功 JSON 生成最终回执，不再为相同字段读取完整 PR 正文。只有 helper 返回
成功并且 `pr_verification.status == "passed"` 时才可声称对应版本的 PR 正文验证通过。
