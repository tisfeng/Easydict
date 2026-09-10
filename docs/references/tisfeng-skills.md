# `tisfeng/skills` 来源参考

- 核对日期：2026-09-11。
- 来源：`https://github.com/tisfeng/skills`。
- 采用版本：`v0.3.4`。
- peeled commit：`e79154ef1fc076c8c7b6b6a06b46388596d485d2`。
- Tag 签名状态：annotated、unsigned；核验时同时固定 tag 和 peeled commit。
- Skills 安装器：`skills@1.5.24`。
- Codex 子代理安装器：`@tisfeng/codex-agents@0.3.4`。

## 采用范围

同步 `code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr` 与
`worktree-rebase-merge` 六个完整 Skill 目录，以及 `planner`、`reviewer`、`tester` 三个子代理。

`v0.3.4` 的实际 Skill 内容变化集中在 `git-commit`、`review-pr`、`submit-pr` 和
`worktree-rebase-merge`；`code-simplifier`、`review` 与三个 agent TOML 内容未变化，但双 lock
仍统一记录同一版本和 revision。

`code-simplifier v0.3.4` 同时包含 `electron-typescript.md` 与 `swift-xcode.md` 条件规则。
Easydict 不删减不适用的 Electron reference；具体任务只按 Skill 路由读取适用内容。

上游仓库的 `.agents/skills/<name> -> ../../skills/<name>` 链接用于发现当前 checkout 的公开
Skill 源码，不属于消费方安装内容。Easydict 继续使用 `--copy --full-depth` 保存完整受管快照，
不引入这些上游自用链接。

## 已核验安装形式

`skills@1.5.24` 没有 `--cwd` 选项，项目安装必须从目标仓库根目录执行；不要把未知参数当作
临时目录或目标目录覆盖。以下命令会直接更新当前仓库的 `.agents/skills/` 和
`skills-lock.json`：

```bash
npx -y skills@1.5.24 add \
  https://github.com/tisfeng/skills/tree/v0.3.4 \
  --skill code-simplifier git-commit review review-pr submit-pr worktree-rebase-merge \
  --agent codex --yes --copy --full-depth

npx -y @tisfeng/codex-agents@0.3.4 add 'tisfeng/skills#v0.3.4' \
  --agent planner --agent reviewer --agent tester
```

第一次接管已有且尚无 lock 的不同 agent TOML 时，可以在冻结并核对三个目标后为该次命令
增加 `--force`。以后升级到新 tag 时重新执行带新版本来源的 `add`，不默认强制覆盖。

Skills lock 记录 tag、入口路径和内容哈希；agents lock 额外记录精确 revision 与文件哈希。
两种 lock 的重装和更新语义不能互相推导，实际字段以安装器输出为准。

`submit-pr v0.3.4` 需要 Python 3.10 或更高版本；同一任务的 `plan` 和 `apply` 使用同一个已核验
解释器，项目命令示例优先使用 Python 3.12。Easydict 的系统 `/usr/bin/python3` 3.9.6 不满足
该要求，不通过本地修改受管脚本绕过运行时依赖。2026-09-11 使用 Python 3.12.3 运行
`git-commit` 19 项、`review-pr` 35 项、`submit-pr` 32 项、`worktree-rebase-merge` 9 项测试，
并使用 Node.js 运行 6 项 agent installer 测试，共 101 项通过。

## 重新核对条件

- 发布新的统一版本。
- 安装器、lock 格式或技能集合发生变化。
- 项目规则无法覆盖某项必要差异，需要评估是否回到上游修改。
