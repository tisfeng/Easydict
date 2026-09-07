---
name: worktree-rebase-merge
description: 完成 worktree 变更：必要时为 detached checkout 创建 Conventional 分支，提交并 rebase 到目标分支，再从目标 worktree 合并；源、目标相同时直接提交。默认目标为远程默认分支。
---

# Worktree Rebase/Merge 工作流

提交源分支，将其 rebase 到目标分支，再在目标分支的 worktree 中合并。源、目标相同
时只提交，不执行 rebase 或 merge。Git 写操作由 `git_delivery` 在同一 Agent 内遵循
`git-commit` Skill 处理，不递归委派。

## 委派执行协议

此 Skill 不在 frontmatter 绑定模型。主 Agent 在确认 `integration` 授权、允许路径、
初始 Git 快照和用户限制后，串行委派 `.codex/agents/git-delivery.toml`，其固定模型和
推理强度是本流程的执行配置。

1. `prepare` 阶段只读：`git_delivery` 解析目标、检查源/目标 worktree、识别是否需要
   新提交，并返回预检证据和完整提交信息草稿。不得创建分支、临时 worktree、暂存或写入
   `commit_message.txt`。
2. 若需要新提交，主 Agent 必须在主对话中原样显示 `提交信息预览` 和完整草稿。默认模式
   显示后可继续；确认、仅预览或仅草稿模式必须等待用户。若源已提交且干净，返回
   `preexisting-source-commit`，无需提交信息预览。
3. 主 Agent 向同一 `git_delivery` 发送 `apply` 后，该 Agent 重新检查 HEAD、索引、
   源/目标 worktree 和范围。任何漂移都会使草稿失效并进入 protected，不得写入。
4. 通过重验后，`git_delivery` 执行本 Skill 后续的分支、提交、rebase、merge 和报告收集。
   主 Agent 最后独立核验结果并向用户交付。

索引为空而本流程允许 `git-commit` 的唯一一次暂存时，prepare 只能读取并冻结候选路径、
未暂存 raw patch 与未跟踪文件内容摘要，再据此起草。apply 先重验候选快照；一致后才按
允许路径或无路径限制时的一次 `git add .` 暂存，并核对 staged raw patch 未超出候选范围且
与草稿依据一致。不一致时进入 protected，返回新的 prepare，不得提交。

`git_delivery` 仅在明确的 `integration` 授权中可创建源分支、临时 worktree、commit、
rebase 或 merge；始终不得 fetch、pull、push、reset、强制移动 ref、stash、clean 或递归
委派。只有完全位于允许路径且不需产品语义判断的机械冲突可以处理，其他冲突必须保留
现场并返回主 Agent。

## 默认规则

- 用户提供目标分支时使用该分支，否则解析仓库远程默认分支。
- 解析远程默认分支时优先选择 `origin`；如果不存在 `origin` 且恰好只有一个 remote，
  则使用该 remote。通过 `git ls-remote --symref <remote> HEAD` 查询实时远程 HEAD，
  读取 `ref: refs/heads/<branch> HEAD` 行，再移除 `refs/heads/` 前缀。该只读查询不是
  fetch 或 pull。
- 如果实时远程 HEAD 查询失败或没有 branch ref，不要静默信任缓存的
  `refs/remotes/<remote>/HEAD`。只能读取该 symbolic ref 以报告候选回退值，然后停止
  并要求用户指定或确认目标分支。
- 将当前 checkout 视为源分支。如果处于 detached 状态，继续前先创建源分支。
- 除非用户明确要求，否则不要 fetch、pull 或 push。
- 只暂存用户选定的文件、已经暂存的提交文件、`git-commit` 在空索引时唯一一次
  `git add .`，或冲突解决文件。

## 预检

- 在分支检查前解析目标分支。如果 remote 选择存在歧义、实时远程 HEAD 不可用或无法
  解析，或者解析出的本地目标分支不存在，则停止并要求用户指定或确认目标分支。
- 运行 `git branch --show-current`、`git branch --list <target-branch>` 和
  `git status --short`。
- 对 detached HEAD，在选择直接提交或普通 rebase/merge 模式前先遵循
  **挂接 Detached HEAD**。
- 如果源分支和目标分支解析为同一分支，进入直接提交模式。
- 普通 rebase/merge 模式运行 `git worktree list`。
- 从 `git worktree list` 中查找 branch 恰好为 `<target-branch>` 的现有目标
  worktree。存在时使用该路径完成最终合并。
- 不要求用户主 checkout 当前位于 `<target-branch>`。如果尚无 worktree checkout
  到目标分支，计划为合并步骤创建临时目标 worktree，不要切换其他 checkout 的分支。
- 如果多个 worktree checkout 到 `<target-branch>`，使用第一个干净 worktree。如果
  所有目标 worktree 都有变更，记录每个脏目标路径及其 `git status --short` 输出。
  暂时不要接触目标 worktree 或停止；先完成源分支创建和源提交，再使用下面的脏目标
  暂停流程。

## 挂接 Detached HEAD

当 `git branch --show-current` 为空时，自动创建源分支，不暂存文件，也不改变当前提交：

1. 记录 `git rev-parse HEAD` 和完整的 `git status --short` 输出。
2. 从以下第一个有用来源推断工作的主要意图。只有前一来源为空或存在歧义时才检查后续
   来源：
   - staged diff；
   - unstaged diff 和相关未跟踪文件的内容；
   - `git log <target-branch>..HEAD` 中的提交。
3. 如果三个来源都为空，报告没有可提交或合并的内容，并停止且不创建分支。
4. 使用 `git-commit` skill 的 **Branch Name Guidance** 根据上述证据推导候选名称。
   这里只推导名称；暂时不要进入该 skill 的暂存或提交流程。
5. 使用 `git check-ref-format --branch <branch-name>` 验证候选名称。
6. 在不覆盖分支的前提下解决本地名称冲突：
   - 如果候选分支不存在，运行 `git switch -c <branch-name>`。
   - 如果它指向已记录的 detached commit，且未在其他 worktree 中 checkout，则运行
     `git switch <branch-name>` 并复用。
   - 否则依次追加 `-2`、`-3`，直到找到未使用的有效名称，再运行
     `git switch -c <numbered-branch-name>`。
   使用 `git show-ref --verify` 和 `git worktree list --porcelain` 区分这些情况。
   绝不 reset 或移动现有分支。
7. 验证选定的源分支，确认 `git rev-parse HEAD` 仍与记录的提交匹配，并要求
   `git status --short` 保持完全相同的 staged、unstaged 和 untracked 状态。如果挂接
   改变了内容，则停止。

不要仅为生成分支名而暂存文件。挂接后继续普通的提交、rebase 和 merge 工作流。

## 目标分支直接提交

- 仅当当前源分支与解析出的目标分支是同一分支时，使用直接提交模式。
- 在直接提交模式下，`git_delivery` 在同一 Agent 内遵循 `git-commit` Skill：暂存范围、
  空索引时唯一一次 `git add .`、提交信息起草、提交执行、权限重试和清理都遵循该 Skill。
- 不创建临时源分支，不运行 `git rebase` 或 `git merge`，不查找目标 worktree，
  不创建临时目标 worktree，也不 fetch、pull 或 push。
- 提交步骤后使用 `git-commit` 的 **Post-Commit Report**，并说明没有执行 rebase、
  merge 或 push。

## 提交源分支

- 对已暂存的源变更，`git_delivery` 在同一 Agent 内使用 `git-commit` 机制。暂存区限定、
  空索引时唯一允许的一次 `git add .`、提交信息起草、提交执行、权限重试和清理由该 Skill
  负责。在普通 rebase/merge 模式下，本工作流覆盖 `git-commit` 默认模式的报告顺序；在
  直接提交模式下遵循 `git-commit` 报告。
- 提交步骤前记录源 `HEAD`。只有提交步骤改变 `HEAD` 时，才将源结果分类为
  `created-this-run`；否则，如果源已经提交且干净，则分类为
  `preexisting-source-commit`。
- 创建 `commit_message.txt` 或运行 `git commit -F commit_message.txt` 前，发送一条
  普通 assistant 消息，使用固定标题 `提交信息预览`，并在 `text` 代码围栏中包含
  完整的实际拟定提交信息。
- 除 Markdown 代码围栏外，预览文字必须与之后的 `commit_message.txt` 内容完全一致。
  它不能只出现在工具输出、终端输出、隐藏推理、日志文件、`commit_message.txt` 或
  最终 Git 命令输出中。
- 正文预览可见后自动继续，除非用户明确要求确认、仅预览、仅草稿、不提交或修改
  提交信息。
- 如果 `git-commit` 报告没有可提交内容，只有源 worktree 不含未提交变更时才继续，
  并将结果标记为 `preexisting-source-commit`；否则停止并报告未提交状态。
- 提交步骤后重新运行 `git status --short`。除非用户明确另行决定，只从干净的源
  worktree 执行 rebase。

## 脏目标暂停

- 如果预检发现 `<target-branch>` 只有脏 worktree，则由 `git_delivery` 通过 `git-commit` 完成源提交并
  要求源 worktree 干净，然后在范围检查、rebase、merge 或 push 前停止。
- 在该恢复路径中，绝不对脏目标 worktree 执行暂存、提交、stash、restore、clean 或
  其他修改。
- 报告源分支和提交哈希、每个脏目标路径及脏文件，并说明源变更已经提交，而目标
  worktree 保持不变。明确说明尚未运行 rebase、merge 和 push。
- 要求用户清理目标 worktree 并回复 `继续`。继续时重新执行目标解析、
  `git worktree list` 和目标干净状态检查。除非源分支出现新变更，否则复用现有干净
  源提交；如有新变更，在 rebase 前通过 `git-commit` 提交。
- 如果继续时所有目标 worktree 仍然有变更，则报告剩余脏状态并再次暂停，不创建新的
  源提交。

## Rebase

- rebase 前使用 `git log --oneline <target-branch>..<source-branch>` 和
  `git diff --stat <target-branch>...<source-branch>` 记录完整集成范围，供 rebase、
  merge 和最终报告使用。
- 用户明确调用本 skill 且未限定提交范围时，
  `<target-branch>..<source-branch>` 中的全部源提交均属于本次集成范围。允许范围包含
  多个独立功能提交，不根据提交主题与当前对话的语义相关性暂停。
- 如果用户明确限定了需要集成或排除的提交，而实际源提交范围与该限定不一致，则停止并
  要求用户决定如何处理；不要通过 reset、交互式 rebase、丢弃提交或 cherry-pick 静默
  改写集成范围。
- 从源 worktree 运行 `git rebase <target-branch>`。
- 出现冲突时检查 `git status --short`；只处理完全位于允许路径且不需要产品语义判断的
  机械冲突，随后只暂存已解决文件并运行 `git rebase --continue`。遇到产品决策或不安全
  冲突时停止。
- rebase 后要求源 worktree 干净，运行 `git diff --check <target-branch>...HEAD`；只有
  仓库规则或涉及代码要求时才运行更广泛的验证。

## 合并与最终报告

- 确认 rebase 后的源 worktree 干净。
- 如果预检时找到现有目标 worktree，确认它干净，并从该路径执行合并。
- 如果没有现有目标 worktree，则在仓库外创建临时目标 worktree，例如
  `/tmp/worktree-rebase-merge-<repo>-<target>-<pid>`，并运行
  `git worktree add <temporary-path> <target-branch>`。合并前确认临时 worktree 位于
  `<target-branch>` 且保持干净。
- 不要仅为进入 `<target-branch>` 而切换用户主 checkout。
- 不要使用 `git update-ref`、`git branch -f` 或其他绕过 worktree 的底层 ref 命令
  更新目标分支。使用真实目标 worktree，让 Git 将分支、索引和文件保持在可理解状态。
- 使用默认 Git 行为运行 `git merge <source-branch>`。除非用户明确要求，否则不要强制
  `--no-ff`、squash、再次 rebase 或 push。
- 出现 merge 冲突时，使用与 rebase 相同的机械冲突规则，然后只暂存已解决文件并运行
  `git merge --continue`。如果冲突发生在临时目标 worktree 中，保留该 worktree 并
  报告其路径供后续解决，不要删除。
- 在临时目标 worktree 中成功合并后，使用
  `git worktree remove <temporary-path>` 将其删除。
- 报告源分支、目标分支、目标 checkout 路径、源提交数量、目标合并模式
  （`existing-target-worktree` 或 `temporary-target-worktree`）、创建临时目标
  worktree 时的路径、合并结果和最终干净状态。对于已挂接的 checkout，还要报告原始
  detached commit，以及源分支是创建还是复用。除非用户要求 push，否则说明未执行。
- 如果集成恰好包含一个源提交，以该提交的 `git-commit` **Post-Commit Report** 收尾。
  对 `created-this-run` 使用 `已创建提交`；对 `preexisting-source-commit` 使用
  `本次未创建新提交；合并的是源分支已有提交`。
- 如果集成包含多个源提交，列出每个完整哈希和 subject，再使用统计脚本的
  `--range <target-commit>...<source-commit>` 报告总计、代码和文档文本变动。不要将
  某一条提交信息当作整个范围的提交信息。
