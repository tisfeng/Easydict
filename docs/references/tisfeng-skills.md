# `tisfeng/skills` 来源参考

- 核对日期：2026-09-08。
- 来源：`https://github.com/tisfeng/skills`。
- 采用版本：`v0.3.0`。
- peeled commit：`ccc74f119f61d672cfd0cb57c07a259b7bc78614`。
- Skills 安装器：`skills@1.5.24`。
- Codex 子代理安装器：`@tisfeng/codex-agents@0.3.0`。

## 采用范围

同步 `code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr` 与
`worktree-rebase-merge` 六个完整 Skill 目录，以及 `planner`、`reviewer`、`tester` 与
`git-delivery` 四个子代理。

`code-simplifier v0.3.0` 同时包含 `electron-typescript.md` 与 `swift-xcode.md` 条件规则。
Easydict 不删减不适用的 Electron reference；具体任务只按 Skill 路由读取适用内容。

## 已核验安装形式

`skills@1.5.24` 没有 `--cwd` 选项，项目安装必须从目标仓库根目录执行；不要把未知参数当作
临时目录或目标目录覆盖。以下命令会直接更新当前仓库的 `.agents/skills/` 和
`skills-lock.json`：

```bash
npx -y skills@1.5.24 add \
  https://github.com/tisfeng/skills/tree/v0.3.0 \
  --skill '*' --agent codex --yes --copy --full-depth

npx -y @tisfeng/codex-agents@0.3.0 add 'tisfeng/skills#v0.3.0' \
  --agent planner --agent reviewer --agent tester --agent git-delivery
```

第一次接管已有且尚无 lock 的不同 agent TOML 时，可以在冻结并核对四个目标后为该次命令
增加 `--force`。以后升级到新 tag 时重新执行带新版本来源的 `add`，不默认强制覆盖。

Skills lock 记录 tag、入口路径和内容哈希；agents lock 额外记录精确 revision 与文件哈希。
两种 lock 的重装和更新语义不能互相推导，实际字段以安装器输出为准。

`submit-pr v0.3.0` 使用 `zip(..., strict=True)`，需要 Python 3.10 或更高版本。2026-09-08
核验时，Easydict 默认 `/usr/bin/python3` 3.9.6 会在相关测试中失败，改用已安装的 Python
3.14.6 后 21 项测试全部通过。现行解释器选择规则写在
[`git-workflow.md`](../agents/git-workflow.md)，不通过本地修改受管脚本绕过该边界。

## 重新核对条件

- 发布新的统一版本。
- 安装器、lock 格式或技能集合发生变化。
- 项目规则无法覆盖某项必要差异，需要评估是否回到上游修改。
