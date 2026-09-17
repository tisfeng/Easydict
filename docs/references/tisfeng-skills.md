# `tisfeng/skills` 来源参考

- 核对日期：2026-09-17。
- 来源：`https://github.com/tisfeng/skills`。
- 采用版本：`v0.6.1`。
- annotated tag object：`46a1ad4a001609e97b0d5a6a577a786bfe7287d6`。
- peeled commit：`3105de8b2d6e4e03ebf1d9242d9ed9023978f8b1`。
- Tag 签名状态：annotated、unsigned；核验时同时固定 tag 和 peeled commit。
- Skills 安装器：`skills@1.5.25`。

## 采用范围

同步 `code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr` 与
`worktree-rebase-merge` 六个完整 Skill 目录；不再采用任何 Codex 子代理。

上游从 `v0.3.5` 起删除 Codex 子代理资产、安装器代码与 `@tisfeng/codex-agents` 包，只发布
平台无关的 Skills。Easydict 随该决定移除 `.codex/agents/`、`.codex/agents-lock.json` 与
`.codex/config.toml`，规划、审查和测试改由主 Agent 按 Skill 直接执行。

`v0.3.9 → v0.4.0` 为六个公开 Skill 增加统一 UI 元数据，缩短触发描述和根入口，并把提交、
PR 审查及 worktree 集成的低频细节拆入 references。上游同时删除未调用 selector 的静态触发语料
和重复实现细节测试，保留 Git 状态、PR 身份、证据漂移、分页与远程写入门禁等高风险覆盖。

`v0.4.0 → v0.5.0` 仅改变 `submit-pr`：PR 正文改为使用 Skill 自带的固定双语模板，支持
detached checkout 在 `apply` 阶段创建或复用任务分支，并增加相应的预览、漂移与复用验证。
其余五个受管 Skill 内容不变，但 lock 中的固定 ref 同步升级。

`v0.5.0 → v0.6.0` 仅改变 `git-commit`：中文和英文正文分别强制使用本地化的
`背景/变更/影响` 与 `context/change/impact` 标记，并支持位于全部语言区块之后的单一全局
`References:` 尾段。其余五个受管 Skill 内容不变，但 lock 中的固定 ref 同步升级。

`v0.6.0 → v0.6.1` 让 `review-pr` 在当前 GitHub 用户是 PR 作者、同名本地分支可以安全
fast-forward 且 upstream 仓库与分支等价时复用该分支；他人 PR、身份不明、错误 upstream、领先或
分叉仍走 collision fallback。`worktree-rebase-merge` 仅移除 UI 展示名称中的斜杠，其余四个
受管 Skill 内容不变，但 lock 中的固定 ref 同步升级。

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
  https://github.com/tisfeng/skills/tree/v0.6.1 \
  --skill code-simplifier git-commit review review-pr submit-pr worktree-rebase-merge \
  --agent codex --yes --copy --full-depth
```

npm 默认缓存可能包含 root-owned 文件并返回 `EPERM`；用独立的 `npm_config_cache` 运行安装器。

`skills-lock.json` 记录 tag、入口路径和内容哈希（sha256；把 Skill 目录内全部文件按相对路径
排序后拼接路径与内容再哈希）。2026-09-17 重算六个 `tisfeng/skills` 目录并核对未修改的
`fireworks-tech-graph` lock，全部一致。

`submit-pr` 需要 Python 3.10 或更高版本；同一任务的 `plan` 与 `apply` 使用同一个已核验
解释器，项目命令示例优先使用 Python 3.12。Easydict 的系统 `/usr/bin/python3` 3.9.6 不满足
该要求，不通过本地修改受管脚本绕过运行时依赖。2026-09-15 使用 Python 3.14 运行内容发生变化的
`git-commit` 19 项测试并完成语法检查，全部通过。
上游仓库级格式校验不属于安装器复制的 Skill 目录；本项目另行核对 frontmatter、
`agents/openai.yaml` 和相对链接。2026-09-17 使用 Python 3.12.3 运行内容发生变化的
`review-pr` 53 项测试，并完成 Shell/Python 语法及两个变更 Skill 的结构校验。

## 重新核对条件

- 发布新的统一版本。
- 安装器版本、lock 格式或技能集合发生变化。
- 上游重新引入平台专属资产，或项目规则无法覆盖某项必要差异。
