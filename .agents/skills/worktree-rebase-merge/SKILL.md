---
name: worktree-rebase-merge
description: 完成 worktree 变更：必要时为 detached checkout 创建 Conventional 分支，提交并 rebase 到目标分支，再从目标 worktree 合并；源、目标相同时直接提交。默认目标为远程默认分支。
---

# Worktree Rebase/Merge 工作流

提交源分支，将其 rebase 到目标分支，再在目标分支的 worktree 中合并。源、目标相同
时只提交，不执行 rebase 或 merge。Git 提交步骤由 `git-commit` Skill 处理。

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
- 在直接提交模式下完全委托给 `git-commit` skill：暂存范围、空索引时唯一一次
  `git add .`、提交信息起草、提交执行、权限重试和清理都遵循 `git-commit`。
- 不创建临时源分支，不运行 `git rebase` 或 `git merge`，不查找目标 worktree，
  不创建临时目标 worktree，也不 fetch、pull 或 push。
- 提交步骤后使用 `git-commit` 的 **Post-Commit Report**，并说明没有执行 rebase、
  merge 或 push。

## 提交源分支

- 对已暂存的源变更使用 `git-commit` 机制。暂存区限定、空索引时唯一允许的一次
  `git add .`、提交信息起草、提交执行、权限重试和清理均由该 skill 负责。在普通
  rebase/merge 模式下，本工作流覆盖 `git-commit` 默认模式的报告顺序；在直接提交
  模式下遵循 `git-commit` 报告。
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

- 如果预检发现 `<target-branch>` 只有脏 worktree，则通过 `git-commit` 完成源提交并
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
  `git diff --stat <target-branch>...<source-branch>` 检查完整集成范围。
- 将该范围与当前请求及本工作流处理的源提交比较。如果目标是推断得出且范围包含无关
  或异常宽泛的既有历史，则停止并要求用户确认目标分支。rebase 成功或无操作不代表
  范围验证通过。
- 从源 worktree 运行 `git rebase <target-branch>`。
- 出现冲突时检查 `git status --short`，按语义解决，只暂存已解决文件，并运行
  `git rebase --continue`。遇到产品决策或不安全冲突时停止。
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
- 出现 merge 冲突时，使用与 rebase 相同的语义解决规则，然后只暂存已解决文件并运行
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
