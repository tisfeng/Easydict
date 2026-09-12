# `tisfeng/skills` 来源参考

- 核对日期：2026-09-11。
- 来源：`https://github.com/tisfeng/skills`。
- 采用版本：`v0.3.8`。
- peeled commit：`d79827eebdb94a7d71240f9b5a07cc0a2260c395`。
- Tag 签名状态：annotated、unsigned；核验时同时固定 tag 和 peeled commit。
- Skills 安装器：`skills@1.5.25`。

## 采用范围

同步 `code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr` 与
`worktree-rebase-merge` 六个完整 Skill 目录；不再采用任何 Codex 子代理。

上游从 `v0.3.5` 起删除 Codex 子代理资产、安装器代码与 `@tisfeng/codex-agents` 包，只发布
平台无关的 Skills。Easydict 随该决定移除 `.codex/agents/`、`.codex/agents-lock.json` 与
`.codex/config.toml`，规划、审查和测试改由主 Agent 按 Skill 直接执行。

`v0.3.4 → v0.3.8` 的实际 Skill 内容变化集中在 `git-commit`、`review`、`review-pr`、
`submit-pr` 和 `worktree-rebase-merge`；`code-simplifier` 内容未变化，lock 仍统一记录同一 ref。
上游同时把技能内部契约收回 Skill，宿主规则只引用稳定入口，不再依赖内部章节名。

`code-simplifier` 同时包含 `electron-typescript.md` 与 `swift-xcode.md` 条件规则。Easydict
不删减不适用的 Electron reference；具体任务只按 Skill 路由读取适用内容。

上游仓库的 `.agents/skills/<name> -> ../../skills/<name>` 链接用于发现当前 checkout 的公开
Skill 源码，不属于消费方安装内容。Easydict 继续使用 `--copy --full-depth` 保存完整受管快照，
不引入这些上游自用链接。

## 已核验安装形式

`skills@1.5.25` 没有 `--cwd` 选项，项目安装必须从目标仓库根目录执行；不要把未知参数当作
临时目录或目标目录覆盖。以下命令会直接更新当前仓库的 `.agents/skills/` 和
`skills-lock.json`：

```bash
npx -y skills@1.5.25 add \
  https://github.com/tisfeng/skills/tree/v0.3.8 \
  --skill code-simplifier git-commit review review-pr submit-pr worktree-rebase-merge \
  --agent codex --yes --copy --full-depth
```

npm 默认缓存可能包含 root-owned 文件并返回 `EPERM`；用独立的 `npm_config_cache` 运行安装器。

`skills-lock.json` 记录 tag、入口路径和内容哈希（sha256；把 Skill 目录内全部文件按相对路径
排序后拼接路径与内容再哈希）。2026-09-11 重算六个 Skill 与 `fireworks-tech-graph` 的哈希，
全部与 lock 一致。

`submit-pr` 需要 Python 3.10 或更高版本；同一任务的 `plan` 与 `apply` 使用同一个已核验
解释器，项目命令示例优先使用 Python 3.12。Easydict 的系统 `/usr/bin/python3` 3.9.6 不满足
该要求，不通过本地修改受管脚本绕过运行时依赖。2026-09-11 使用 Python 3.12 运行
`git-commit` 19 项、`review` 10 项、`review-pr` 99 项、`submit-pr` 38 项、
`worktree-rebase-merge` 9 项测试，共 175 项通过。

## 重新核对条件

- 发布新的统一版本。
- 安装器版本、lock 格式或技能集合发生变化。
- 上游重新引入平台专属资产，或项目规则无法覆盖某项必要差异。
