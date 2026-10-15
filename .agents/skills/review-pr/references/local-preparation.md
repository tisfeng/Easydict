# PR 本地准备与 latest-base

仅在用户允许 Git 准备的 PR 审查中读取。用户要求只读、不改变 Git 状态或不切分支时，
不使用本协议绕过限制。

## 分支与 remote 安全

- contributor remote 名称必须与 PR head repository owner login 完全一致。
  同名 remote 已指向其他位置时停止并请用户决定。
- 默认本地模式优先使用 PR head 分支名。先核验 GitHub 当前用户、PR 作者、head 仓库和
  分支身份；同名分支不是身份相同的充分证据。
- 本人 PR 的同名分支与远程一致时直接复用，落后时仅 fast-forward；允许保留实际指向准确
  head repository/branch 的等价 upstream remote 别名，缺少 upstream 时设置准确 head upstream。
- 本人分支领先且包含完整远程 head 时保留本地提交，以 `git_objects` 模式准备：本地 HEAD
  不回退，审查对象固定为远程 SHA。分叉、错误 upstream、受保护名称或与 base 同名时停止，
  报告具体原因，不静默新建 review 分支。
- 本人同名分支在其他 worktree 打开时，核实目标存在、分支匹配且干净后复用该 checkout；
  保留原 checkout 的分支、HEAD 和文件状态，后续命令以回执的 `checkout.path` 为 cwd。
  原 checkout 可有未提交变更，目标 checkout 脏或不可用时停止，不强行切换或另建分支。
- 非本人或作者身份无法确认时，沿用准确 head 的准备规则；同名分支 upstream 不匹配、领先、
  分叉或被其他 worktree 占用时创建 `review/pr-<number>-<head-short-sha>`，不改变冲突分支。
- 既有 review 分支只在它干净、位于准确 head 且 tracking `<owner>/<head-branch>` 时复用；
  否则停止。不 detached checkout remote-tracking ref 或以 fetch ref 绕过 PR 身份验证。
- 除非用户明确要求隔离 worktree 或 latest-base，不创建其他命名的分支。

多阶段 review 必须把首次回执中的 `checkout.branch` 传给 `--reuse-branch`，在回执路径
继续。helper 复验远程冻结 head、分支身份和 upstream；本人分支在普通审查中可以领先于
该 head，按 `git_objects` 模式保留，其他分支必须准确匹配。分叉、身份或 upstream 漂移时
停止，不自动切换到新分支。请求 latest-base 时仍要求分支准确位于远程 head，领先时停止，
由用户决定额外提交的处理或授权隔离集成，不能把本地提交混入 PR head/base 集成证据。

显式 worktree 模式使用：

- 普通审查分支：`review/pr-<number>-<head-short-sha>`。
- latest-base 分支：`review/pr-<number>-merge-<head-short-sha>`。
- 路径：`../.review-pr-worktrees/<repo>/pr-<number>[-merge]-<head-short-sha>`。

审查后保留分支或 worktree 供调试，不自动删除。

## 准备 helper

使用初始证据快照的 `headRefOid` 作为 `--expected-head`。普通本地审查：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" \
  --expected-head <head-sha> --json <pr-ref>
```

显式隔离 worktree：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" \
  --worktree --expected-head <head-sha> --json <pr-ref>
```

只在用户明确授权 latest-base 时，为对应命令增加 `--merge-latest`。仅有
`schema_version: 2`、`status: prepared`，且 repo/number、head、base、merge-base、
checkout/upstream 与初始证据和实际本地状态一致时才接受回执。准备回执升级不改变远程
snapshot 的版本；旧回执不能证明本地领先模式已正确验证。

- `head_sha` 和 `review.head_sha` 均为冻结的远程 PR head；`checkout.head_sha` 为实际本地 HEAD。
- `review.mode` 为 `checkout`、`git_objects` 或 `integration`。前者要求本地 HEAD 等于远程；
  `git_objects` 仅允许本人同名分支干净且领先；`integration` 单独验证 head/base 合并。
- `review.ahead/behind` 描述最终 checkout 相对远程 head 的提交数；`git_objects` 要求 ahead
  大于零、behind 为零。它不表示额外提交已纳入远程审查。
- `selection_reason`、`collision_reason`、`reused_branch`、`self_authored_branch_reused`、
  `reused_worktree` 和 `source_unchanged` 解释选择结果；已有 worktree 复用不等于新建隔离环境。

回执中的 `helper` 保留 `path` 和入口文件的 `sha256`，并增加：

- `files`：准备入口、指纹采集器、元数据解析器及传递依赖的相对 Skill 路径到 SHA-256 映射。
- `bundle_sha256`：对该映射按键排序、使用紧凑 JSON（逗号和冒号无空格）、UTF-8 编码后计算
  SHA-256；安装目录不参与组合哈希。显式依赖清单随准备入口的导入或调用变化同步维护。

跨阶段使用回执前，运行只读命令重新计算当前安装的准备指纹：

```bash
python3 "<review-pr-skill-dir>/scripts/prepare_helper_fingerprint.py"
```

比较 `path`、`sha256`、`files` 和 `bundle_sha256`。任一不一致或旧回执缺少新增字段时，
重新准备并重新采集证据。准备 helper 也在执行前及返回成功回执前比较指纹；缺少必要文件或
执行期间版本变化时失败，不返回成功回执。这是版本一致性检查，不是安装来源或代码可信性证明。
新增字段保持准备回执 `schema_version: 2`，不改变远程 snapshot 的字段与版本。
`failed` 回执保留停止阶段，不自动清理或重启写入。

大 PR 中已使用快照文件时，可按
[快照传输协议](snapshot-protocol.md#复用准备元数据) 传入已校验文件，减少重复元数据查询。
这不取消 helper 的实际 fetch、head/base 检查和本地状态验证。

## 普通审查与 latest-base

没有 latest-base 授权时，即使 GitHub 报告冲突或 base 领先，仍按 PR head 的提交状态审查。
checkout 或 Git 对象模式均使用回执冻结的远程 head，不以本地领先 HEAD 替代。使用：

```bash
git merge-base --is-ancestor <frozen-base-sha> <remote-head-sha>
```

检查失败表示 PR 落后，不自动合并。需要只读冲突信号时可使用：

```bash
git merge-tree <frozen-merge-base> <frozen-base-sha> <remote-head-sha>
```

只有明确要求更新最新 base、解决冲突或审查集成结果时，才使用 `--merge-latest`。
本地模式在已选的 head 同名或 collision fallback 分支上运行 `git merge --no-edit`，
保留分支名。只有显式 `--worktree --merge-latest` 使用 `review/pr-<number>-merge-...` 命名。
执行前说明可能创建本地 merge commit；未获 latest-base 授权时在创建该集成分支前停止。

## 冲突恢复

merge helper 因冲突停止时，在实际准备 checkout 中检查：

```bash
git status --short
git diff --name-only --diff-filter=U
git diff --cc
```

阅读冲突代码和周边上下文，按语义解决，不机械选择 ours/theirs。只暂存已解决文件，
然后运行 `git commit --no-edit`。worktree 模式下的所有冲突命令都在回执的 worktree 路径执行。
冲突需要产品决策或无法安全解决时保留现场并停止，不以部分 merge tree 交付审查。

## Checkout 验证

结构化准备回执已校验状态；之后漂移或旧 helper 才补充等价检查：

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git for-each-ref --format='%(upstream:short)' refs/heads/<selected-branch>
```

普通本地准备要求分支干净，分支名为 head 分支或 collision fallback；`checkout` 模式 HEAD
等于 `headRefOid`，`git_objects` 模式则验证该 SHA 是本人分支 HEAD 的祖先、回执中的本地
SHA 未漂移，并按 [证据协议](evidence-workflow.md#代码范围与语义审查) 读取冻结源码。
新建分支与 collision fallback tracking `<owner>/<head-branch>`；本人 PR 复用的同名分支可
保留名称不同但实际指向准确 head repository/branch 的 upstream。latest-base 后改为
要求 remote head 和 frozen base 都是 HEAD 的 ancestor；如产生 merge commit，两个 parent
必须分别为该 head/base。

worktree 模式要求回执路径干净并位于对应 SHA；普通分支 tracking contributor，latest-base
分支保持 local-only。确认原 checkout 的分支、HEAD 和文件状态未变，后续命令以回执路径为 cwd。
