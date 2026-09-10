---
name: worktree-rebase-merge
description: 完成 worktree 变更：必要时为 detached checkout 创建 Conventional 分支，提交并 rebase 到目标分支，再从目标 worktree 合并；源、目标相同时直接提交。默认目标为远程默认分支。
---

# Worktree Rebase/Merge 工作流

提交源分支，将其 rebase 到目标分支，再在目标分支的 worktree 中合并。源、目标相同
时只提交，不执行 rebase 或 merge。当前主 Agent 直接按本 Skill 完成检查、Git 操作和回执。

## 执行方式

- 开始前确认集成授权、允许路径与提交范围、用户限制，以及源和目标的 Git 状态。已读且未
  变化的规则和检查结果可以复用。
- 需要新提交时使用 `git-commit` 的暂存决策、完整提交信息预览和提交前后校验；已有干净
  源提交时直接继续集成，不重新起草提交信息。用户的确认、预览和暂缓限制仍然有效。
- Git 写操作串行执行。写入前复验相关 HEAD、分支、索引、工作树与占用及进行中的操作；
  发现非预期变化时停止相关写入并保留现场。写入后确认变化符合预期，再继续下一步。
- rebase 前记录源提交范围与目标 OID，rebase 后核对改写结果。merge 前确认源干净、目标
  仍为记录的 OID，且目标 worktree 分支和占用未发生非预期变化；不隐式再次 rebase。
- 不使用 reset、强制移动 ref、stash 或 clean 清理现场；冲突按下文规则处理。
- 已知 Git 元数据或 worktree 路径受限时，直接为已授权命令申请必要提权；同轮复用已确认
  的权限边界，避免先运行必然失败的命令。审批拒绝时保留现场并报告原因。

## 快速执行协议

保持本 Skill 的全部授权、分支、暂存、写前复验、rebase 结果核对、目标 OID、冲突恢复和完整
回执门禁；优化的是可预测成功路径中的模型往返与工具输出，不是减少 Git 安全步骤。

- `<worktree-skill-dir>` 指实际加载的本 Skill 目录。预检优先运行一次只读检查器：

  ```bash
  python3 "<worktree-skill-dir>/scripts/collect-integration-facts.py" \
    --source <source-path> [--target <target-branch>] \
    [--source-branch <detached-candidate>]
  ```

  未提供 `--target` 时，检查器按本 Skill 规则实时解析远程 HEAD，并与本地 source 事实并行收集；
  提供目标时不查询远程。普通集成只输出目标分支对应的 checkout、精确 source/target OID、
  状态、进行中操作、detached 候选动作及完整提交范围，不输出全量 refs/worktrees；source 与目标
  相同时立即返回 `direct-commit`，不读取 worktree 清单或提交范围。
- 检查器退出 `0` 才表示本次快照收集稳定；退出 `2` 表示收集期间发生漂移，退出 `1` 表示无法
  可靠读取。它不判断用户授权、不修改 Git，也不替代每次写入前的即时复验。JSON 的
  `schema_version`、`stable`、必要字段和退出状态必须一起验证，不能只解析部分 stdout。
- 运行时支持程序化工具调用时，把互不依赖的只读检查并行执行，并在一个程序中按顺序等待已授权
  的分支挂接、唯一暂存/提交、rebase、目标复验、merge 和回执采集。每条 Git 写命令仍是独立
  工具调用和独立权限边界；不要创建负责 stage、commit、rebase 或 merge 的宽泛写入 runner。
- 每个命令工具调用只有明确完成且 `exit_code === 0` 才能继续。运行中会话或缺少退出码必须继续
  等待；非零退出、审批拒绝、漂移、冲突或结果歧义立即停止程序并返回当前阶段、冻结 OID、必要
  状态和恢复位置。非命令工具使用其原生成功与错误契约。不得把一次程序化调用当作事务，也不得
  从批次开头自动重跑已经成功的 Git 写操作。
- 模型只在目标或 remote 歧义、detached 分支意图、范围和提交信息语义、用户确认、真实漂移、
  不能确定等价的 rebase 结果及需要产品判断的冲突上介入。确定性检查与预期完全一致时继续下一
  命令，只在最终回执返回完整事实；未变化的 status、refs、worktree 清单、log 和 diff 不重复输出。

首次 source raw patch 仍按 `git-commit` 完整交给模型审核。首次快照得到目标分支后，后续即时
复验使用显式 `--target`，避免再次查询远程；已经加载且未变化的规则和回执模板不要重复读取。

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
- 创建源提交时使用 `git-commit` 的 **准备与暂存**、**先确定模式** 和 **提交与可见预览**。
  明确调用本 Skill 属于显式集成交付；空索引按该 Skill 选择允许的暂存范围，不另设停止规则。
  仅预览或只读时不创建分支、worktree、消息文件，也不暂存或执行 rebase/merge。

## 预检

- 在分支检查前解析目标分支。如果 remote 选择存在歧义、实时远程 HEAD 不可用或无法
  解析，或者解析出的本地目标分支不存在，则停止并要求用户指定或确认目标分支。
- 默认使用 **快速执行协议**的只读检查器一次取得当前分支、精确本地目标分支、source/target
  OID、status、目标 worktree 和提交范围；检查器不可用时才分别运行等价只读 Git 命令。
- 对 detached HEAD，在选择直接提交或普通 rebase/merge 模式前先遵循
  **挂接 Detached HEAD**。
- 如果源分支和目标分支解析为同一分支，进入直接提交模式。
- 普通 rebase/merge 模式解析 `git worktree list --porcelain -z`；不要把全量原始清单返回模型。
- 从解析结果中查找 branch 恰好为 `<target-branch>` 的现有目标
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
   使用 `git show-ref --verify --quiet` 和 `git worktree list --porcelain -z` 区分这些情况；
   分支不存在的退出码 `1` 是预期事实，其他非零退出才是读取失败，不要为此打印全部 refs。
   绝不 reset 或移动现有分支。
7. 验证选定的源分支，确认 `git rev-parse HEAD` 仍与记录的提交匹配，并要求
   `git status --short` 保持完全相同的 staged、unstaged 和 untracked 状态。如果挂接
   改变了内容，则停止。

不要仅为生成分支名而暂存文件。挂接后继续普通的提交、rebase 和 merge 工作流。

## 目标分支直接提交

- 仅当当前源分支与解析出的目标分支是同一分支时，使用直接提交模式。
- 在直接提交模式下，遵循 `git-commit` Skill 的 **准备与暂存**、提交信息
  起草、提交执行、权限重试和清理规则。
- 不创建临时源分支，不运行 `git rebase` 或 `git merge`，不查找目标 worktree，
  不创建临时目标 worktree，也不 fetch、pull 或 push。
- 面向用户的最终回复使用 `git-commit` 的完整 **Post-Commit Report**，并先提供
  本 Skill 的“集成结果”字段；直接提交时 `Rebase`、`Merge` 和 `Push` 均明确为未执行。
  不得以提交标题、短哈希或工具输出替代完整回执。

## 提交源分支

- 对源变更，使用 `git-commit` 的提交与校验流程。提交信息起草、提交
  执行、权限重试和清理由该 Skill 负责。在普通 rebase/merge 模式下，待 rebase 和 merge 完成后
  合并输出提交回执与集成结果；字段、统计表和实际提交信息仍以 `git-commit` 的
  **Post-Commit Report** 为唯一权威来源。
- 提交步骤前记录源 `HEAD`。只有提交步骤改变 `HEAD` 时，才将源结果分类为
  `created-this-run`；否则，如果源已经提交且干净，则分类为
  `preexisting-source-commit`。
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
  `git diff --stat <target-branch>...<source-branch>` 记录完整集成范围，供 rebase、
  merge 和最终报告使用。
- 已由稳定检查器快照取得且相关 OID 未变化时，复用其中的提交清单、完整触及路径和 merge base；
  只有范围或 OID 漂移时重新输出完整证据。
- 用户限定路径时，检查范围内每个提交触及的路径，包括后来被撤销的变更；不能只看最终净 diff。
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
  更新目标分支。通过目标 worktree 执行合并，确保目标分支、索引和工作树同步更新。
- 使用默认 Git 行为运行 `git merge <source-branch>`。除非用户明确要求，否则不要强制
  `--no-ff`、squash、再次 rebase 或 push。
- 出现 merge 冲突时，使用与 rebase 相同的机械冲突规则，然后只暂存已解决文件并运行
  `git merge --continue`。如果冲突发生在临时目标 worktree 中，保留该 worktree 并
  报告其路径供后续解决，不要删除。
- 在临时目标 worktree 中成功合并后，使用
  `git worktree remove <temporary-path>` 将其删除。
- 面向用户的最终回复先输出“集成结果”，至少包含源分支、目标分支、目标 checkout、
  源提交数、集成模式（`existing-target-worktree` 或 `temporary-target-worktree`）、Rebase、
  Merge、临时 worktree 路径与清理结果（如适用）、源/目标工作树最终状态和 Push。对于已
  挂接的 checkout，还要包含原始 detached commit 及源分支是创建还是复用。
- 集成恰好包含一个源提交时，在“集成结果”后完整附加 `git-commit` 的 **Post-Commit
  Report**，包括 Markdown 统计表和完整实际提交信息。对 `created-this-run` 使用
  `已创建提交`；对 `preexisting-source-commit` 使用
  `本次未创建新提交；合并的是源分支已有提交`，并将提交后校验如实写为
  `未执行（本次复用已有提交）`。
- 集成包含多个源提交时，在“集成结果”后以 Markdown 表格列出每个完整哈希和 subject，
  再使用统计脚本的 `--range <target-commit>...<source-commit>` 输出 `git-commit` 定义的
  Markdown 统计表。多提交范围没有单一实际提交信息；不得将任一提交 message 伪装为整个
  范围的 message，也不得因而省略完整提交清单或统计表。
- `git-commit` 是提交结果、统计表和单提交实际 message 的唯一模板来源；本 Skill 只补充
  集成事实，不另设通用提交回执。直接读取实际 Git message、完整哈希、最终状态与统计结果，
  不重新起草或翻译实际提交信息。
- 多提交统计使用记录的合并前目标 OID 与 rebase 后源 OID，避免目标已前进后读出空范围。
