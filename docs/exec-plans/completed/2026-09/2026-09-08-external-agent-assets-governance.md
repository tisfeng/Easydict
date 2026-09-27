# 统一外部 Skills 与 Codex 子代理资产

- 状态：completed
- 创建日期：2026-09-08
- 完成日期：2026-09-08
- 负责人：Codex
- 关联 Issue/PR：无

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 目标结果：将通用 Skills 与 Codex 子代理固定到 `tisfeng/skills v0.3.0`，从独立上游同步
  `fireworks-tech-graph`，并补齐双 lock 和文档治理。
- 允许修改路径：6 个 `.agents/skills/` 通用 Skill、`.agents/skills/fireworks-tech-graph/`、
  4 个 `.codex/agents/*.toml`、`skills-lock.json`、`.codex/agents-lock.json`、`AGENTS.md`、
  相关 `docs/agents/`、`docs/design-docs/`、`docs/references/` 以及本任务 plan/history。
- 禁止动作：修改 `.agents/skills/release-easydict/`、`.codex/config.toml`、`.claude/skills`
  链接、产品源码或远程 Git 状态；禁止在项目中直接修补外部受管资产。

## 写入前状态

- 初始 HEAD：`8abf7231120a31d37999d572f1fc851e61a51518`，分支 `dev`，相对
  `origin/dev` ahead 1。
- 初始 staged、unstaged、untracked、冲突：均为空。
- 写入前检查：pass；自动提交资格：eligible。
- 上游基线：`tisfeng/skills v0.3.0`，peeled commit
  `ccc74f119f61d672cfd0cb57c07a259b7bc78614`；`fireworks-tech-graph` 的 `main` 为
  `31fea364eda5f1852b1175f3d9e29ea31d22dcb4`。
- 安装器预检：`skills@1.5.24` 与 `@tisfeng/codex-agents@0.3.0`。
- Agent-owned paths：上述允许路径中本任务实际产生差异的文件。

## 目标与非目标

### 目标

- 安装 6 个完整通用 Skill 快照，并由 `skills-lock.json` 记录来源、版本和内容哈希。
- 安装 4 个 Codex 子代理，并由 `.codex/agents-lock.json` 固定来源、ref、revision 和哈希。
- 保持 `fireworks-tech-graph` 与 `tisfeng/skills` 来源隔离，只通过自己的上游同步。
- 保留 `release-easydict` 为项目专属 Skill，并把 Easydict 差异维护在宿主规则中。

### 非目标

- 不修改 Easydict 产品行为、Xcode 工程或发布流程。
- 不运行 PR、发布、push、pull、rebase 或 merge。
- 不修改历史记录来伪装当前规则。

## 工作计划

1. 冻结现场、核验两个上游及安装器参数。
2. 从 `tisfeng/skills v0.3.0` 同步 6 个通用 Skills 和 4 个 Codex 子代理。
3. 从独立上游同步 `fireworks-tech-graph`，确认 lock 条目没有混入共同来源。
4. 更新现行 Agent 路由、写入门禁、Git 交付规则、设计与参考资料。
5. 验证目录闭包、lock、TOML、脚本测试、相对链接和保护路径，完成独立审查。
6. 创建 history、将本计划归档到 `completed/`，按门禁自动本地提交，不 push。

## 风险与决策

- 外部快照必须安装完整目录，不能只复制 `SKILL.md`，也不能带入上游工作树中的忽略文件。
- 首次接管现有 agent TOML 使用一次受控 `--force`；后续更新默认拒绝本地漂移。
- Skills CLI 与 agents 安装器 lock 语义不同；文档分别描述，不声称两者具备相同的恢复能力。
- `code-simplifier` 保留 Electron/TypeScript 与 Swift/Xcode 两份条件 reference，不按项目技术栈裁剪。

## 进度

- [x] 冻结初始 Git 状态并核验安装器版本与两个来源。
- [x] 同步 6 个 `tisfeng/skills v0.3.0` 通用 Skills。
- [x] 同步 4 个 Codex 子代理与独立 `fireworks-tech-graph`。
- [x] 更新治理文档。
- [x] 完成静态验证与独立审查。
- [x] 创建 history，冻结交付范围并进入自动本地交付。

## 验证

- 六个通用 Skill 与四个 agent 已逐文件匹配 `v0.3.0`；fireworks 已逐文件匹配独立上游
  `31fea364eda5f1852b1175f3d9e29ea31d22dcb4`。
- `git-commit` 19 项、`review-pr` 27 项和 fireworks 141 项测试通过；fireworks 另有 6 项
  需要 Chromium、ImageMagick 或 PNG renderer 的扩展测试按上游条件跳过。
- `submit-pr` 使用默认 Python 3.9.6 时因 `zip(..., strict=True)` 失败；使用兼容的 Python
  3.14.6 重跑后 21 项全部通过。宿主规则已增加 Python 3.10 最低版本门禁。
- 独立 tester 重算七个 Skill hash、四个 agent hash 并解析 TOML/JSON，结果与双 lock
  完全一致；Shell/Python 静态检查、文档相对链接和 `git diff --check` 通过。
- 独立 reviewer 检查实际 diff、宿主 PR/交付语义和保护路径，未发现阻塞 finding。
- 本任务不修改产品代码，不运行 Xcode；静态检查不能证明当前 Codex 进程已重新发现新配置。

## 完成条件

- 两个来源边界、双 lock、项目专属例外和禁止本地修改规则均已落地。
- 必要验证和独立审查覆盖最终快照且无有效阻塞 finding。
- history 已记录结果，本计划已移入 `completed/`，本地提交完成且未 push。
