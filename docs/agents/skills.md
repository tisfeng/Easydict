# 外部 Skill 资产

## 背景与设计

Easydict 直接从仓库运行共享 Skills，安装内容需要可离线审查和历史复现；只引用外部目录缺少
稳定证据，项目各自修改副本又会产生行为和安全差异。

- 外部仓库统一维护通用内容；`skills-lock.json` 登记的目录是外部权威内容的完整项目快照，
  可离线读取和运行。
- lock 记录来源、ref、入口路径和内容哈希，通过重算检查本地漂移，不替代实际安装内容。
- Swift/Xcode、本地化和发布等项目政策写入宿主规则；通用 Git、Review 和交付算法由受管
  Skill 维护，不通过本地修补或 fork 改写。
- 独立第三方 Skill 保持自身来源；项目专属 Skill 由 Easydict 维护。

取舍：仓库保存较大的第三方快照，换取离线可用、可审查和可回滚；跟踪可移动分支时需额外
记录同步 commit，上游提供稳定 tag 后优先采用 tag。重新评估条件：安装器改变 lock、hash 或
安装目录；上游改变仓库、发布方式或 Skill 路径；项目差异无法继续由宿主规则表达。

## 操作规则

- 普通任务不得修改受管快照或手工调整 hash；只有用户明确要求升级时才使用安装器同步。
- 不同来源分别同步，并按下方来源基线的版本和命令核验，不递归复制上游工作目录。
- `fireworks-tech-graph` 保持独立来源；`release-easydict` 是不进入 lock 的项目专属 Skill。
- `.claude/skills` 指向 `.agents/skills`，不是独立副本。
- 同步后核对来源 tree、目录 hash、lock、项目专属 Skill 和符号链接，并运行风险匹配的静态
  检查与 Skill 测试。

## 项目专属发布 Skill

`release-easydict` 不进入受管 Skill lock；它编排 Easydict 的 Draft、Publish、Release
恢复、发布后日志同步和 Issue 跟进。首次设置 Apple/App Store Connect、证书、Keychain、
Sparkle 和 GitHub 凭据，以及主要发布命令，见 [`release-easydict.md`](release-easydict.md)。

## 来源基线：tisfeng/skills

- 核对日期：2026-09-20；来源：`https://github.com/tisfeng/skills`；安装器 `skills@1.5.25`。
- 采用版本：`v0.6.2`；annotated tag `b30ebbc0599fbf29bb563052b119de5967bd10a8`（unsigned），
  peeled commit `ee30f149f523a76b14df55884fe149a549798d2f`；核验时同时固定 tag 和 peeled
  commit。
- 采用范围：`code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr`、
  `worktree-rebase-merge` 六个完整 Skill 目录，不采用其他上游内容。

```bash
npx -y skills@1.5.25 add \
  https://github.com/tisfeng/skills/tree/v0.6.2 \
  --skill code-simplifier git-commit review review-pr submit-pr worktree-rebase-merge \
  --agent codex --yes --copy --full-depth
```

- 安装器没有 `--cwd` 选项，必须从仓库根目录执行；npm 默认缓存可能包含 root-owned 文件并
  返回 `EPERM`，用独立的 `npm_config_cache` 运行安装器。
- `skills-lock.json` 的内容哈希为 sha256：把 Skill 目录内全部文件按相对路径排序后拼接路径
  与内容再哈希。
- 上游仓库级格式校验不随安装器复制，升级时另行核对 frontmatter、`agents/openai.yaml` 和
  相对链接。
- `code-simplifier` 同时包含 Electron 与 Swift 条件规则，不删减不适用部分，任务中按 Skill
  路由读取适用内容。
- 上游 `.agents/skills/<name> -> ../../skills/<name>` 链接是上游自用的源码发现机制，快照
  继续使用 `--copy --full-depth` 保存完整目录，不引入这些链接。
- `submit-pr` 需要 Python 3.10 或更高版本；同一任务的 plan 与 apply 使用同一个已核验解释
  器，项目命令示例优先使用 Python 3.12；不通过本地修改受管脚本绕过运行时依赖。
- 重新核对条件：发布新的统一版本；安装器版本、lock 格式或技能集合变化；上游重新引入平台
  专属资产。

## 来源基线：fireworks-tech-graph

- 核对日期：2026-09-13；来源：
  `https://github.com/yizhiyanhua-ai/fireworks-tech-graph`；上游 Skill 路径
  `skills/fireworks-tech-graph`；本地安装路径 `.agents/skills/fireworks-tech-graph/`。
- 采用 ref `main`，同步时 commit `31fea364eda5f1852b1175f3d9e29ea31d22dcb4`；安装器
  `skills@1.5.25`；完整同步上游 Skill 目录，不接受本地内容修改。

```bash
npx -y skills@1.5.25 add \
  https://github.com/yizhiyanhua-ai/fireworks-tech-graph/tree/main/skills/fireworks-tech-graph \
  --skill fireworks-tech-graph --agent codex --yes --copy --full-depth
```

- 命令只选择该来源和 Skill；同步后检查 `.agents/skills/fireworks-tech-graph/` 与
  `skills-lock.json` 中对应条目，不用跨来源的整项目更新代替，也不手工调整 computed hash。
  Easydict 直接从 `.agents/skills/` 读取该 Skill，不维护根 `skills/` 兼容别名。
- 大小写不敏感文件系统上，仓库 ignore 规则可能误匹配并静默排除受管文件（如 `Icon?` 匹配
  `assets/icons/`）；为受管路径保留精确的 ignore 例外，同步后核对目录哈希与上游 tracked
  tree 一致。
- 重新核对条件：`main` 指向新 commit 且用户明确要求同步；上游发布稳定 tag 或移动、拆分
  Skill 路径；安装器改变复制内容、hash 或 lock 字段。
