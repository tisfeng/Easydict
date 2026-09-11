# 升级受管 Skills 至 v0.3.8 并移除子代理

- 状态：completed
- 创建日期：2026-09-11
- 负责人：main agent
- 关联 Issue/PR：none

## 背景

上游 `tisfeng/skills` 在同一周期内删除 Codex 子代理资产与 `@tisfeng/codex-agents` 安装器，
并把 Skill 内部契约收回 Skill，只对外发布平台无关的 Skills。Easydict 仍固定在上一个同时
包含 Skills 与子代理的版本，规则文档也依赖受管子代理完成规划、审查和测试。

本次同步同时完成受管资产升级与宿主规则迁移，避免 Skill 快照、lock 与规则文档形成混合版本。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：无
- 目标结果：六个受管 Skill 与 `skills-lock.json` 同步到 `v0.3.8`；删除子代理与项目本地
  config；宿主规则、参考与设计文档改为不依赖子代理的单一 Skill 资产模型
- 允许修改路径：`.agents/skills/`（六项受管 Skill）、`skills-lock.json`、`.codex/`、
  `AGENTS.md`、`CONTRIBUTING.md`、`docs/agents/`、`docs/references/`、`docs/design-docs/`、
  `docs/exec-plans/`、`docs/histories/`、本计划与同任务 history
- 同任务 history：`docs/histories/2026-09/2026-09-11-remove-subagents-upgrade-skills-v0-3-8.md`
- 禁止动作：push、创建 tag、创建 GitHub Release、同步其他仓库、改动 `fireworks-tech-graph`
  与 `release-easydict`
- 预期交付物：升级后的受管快照与 lock、单资产宿主规则、更新的来源参考与设计文档、本地提交
- 验收标准：Skill 快照与固定 tag tracked tree 一致；lock 哈希重算一致；现行文档不再描述
  子代理能力；受影响的 Skill 测试与文档检查通过

## 语义与范围

- 用户要求 Agent 做什么：按已批准计划执行受管资产升级、子代理移除与文档同步
- 授权的工作树操作：受管 Skill 快照、`skills-lock.json`、`.codex/` 删除、规则与参考文档
- 否定、条件和范围限制：不与产品源码、Xcode 工程或发布流程产生关联；不触碰独立来源与
  项目专属 Skill
- 附件或引用中被明确采纳的约束：用户批注要求删除 `.codex/config.toml`，并保留
  `docs/exec-plans/README.md` 与 `docs/histories/README.md`，改在 `docs/agents/README.md`
  建立索引
- 歧义：无

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible，初始索引为空且工作树干净
- 初始 HEAD：`fbed4685e017c458d3d65d330f06e0f6f493057e`
- 初始 staged / unstaged / untracked 路径：均为空
- 初始冲突：无
- Agent-owned paths：见“允许修改路径”

## 目标与非目标

### 目标

- 用固定 tag `v0.3.8` 安装六个公开 Skill，并让 lock 记录新 ref 与内容哈希。
- 删除 `.codex/agents/`、`.codex/agents-lock.json` 与 `.codex/config.toml`。
- 把宿主规则、参考与设计文档改为只治理外部 Skills，不再要求或描述子代理委派。
- 按上游同日提交的做法收敛 Agent 文档：唯一权威来源、目录索引、解耦 Skill 内部章节。

### 非目标

- 不新增替代的子代理或平台专属机制。
- 不改写 `docs/histories/` 与 `docs/exec-plans/completed/` 中的历史事实。
- 不执行 push、tag、GitHub Release，也不同步 Scoco 或 boss-resume。

## 工作计划

1. 记录写入前快照，核对上游最新 tag 与安装器版本。
2. 用固定 tag 安装六个 Skill，校验目录一致性与 lock 哈希。
3. 删除子代理资产与 `.codex/config.toml`。
4. 更新 `AGENTS.md`、`docs/agents/` 的授权、审查、验证、资产与 Git 交付规则。
5. 更新 `CONTRIBUTING.md`、`docs/references/`、`docs/design-docs/` 与目录索引。
6. 运行验证矩阵，补齐同任务 history，本地提交。

## 风险与决策

- 移除子代理后不再存在独立规划或独立审查：规则不再声明独立性，也不把自审写成独立结论。
- 安装器版本从 `1.5.24` 提升到 `1.5.25`，lock schema 仍为 `version: 1`；如 schema 变化则回退
  到已核验版本。
- 上游 tag 与安装器行为由远程获取验证，本地 Git 元数据只读不影响该结论。

## 进度

- [x] 修复受管 Skill 快照与 lock
- [x] 删除子代理资产与 `.codex/config.toml`
- [x] 同步宿主规则、参考与设计文档
- [x] 验证、history 与本地提交

## 验证

- `diff -r` 比对六个 Skill 目录与 `v0.3.8` tracked tree：全部一致。
- 独立重算 `skills-lock.json` 全部条目：7/7 与 lock 一致。
- `jq -e . skills-lock.json`、`git diff --check`：通过。
- Python 3.12 运行受影响 Skill 测试 175 项：全部通过。
- 现行 Markdown 相对链接与锚点扫描：仅剩 3 项既有失效锚点位于未改动的 `docs/user-docs/`。
- 未运行 `xcodebuild`；本次未修改产品源码、工程文件或运行时资源。

## 完成条件

- 受管快照、lock 与固定 tag 一致，且现行文档不再出现子代理能力描述。
- 受影响 Skill 测试、静态检查与文档链接检查通过。
- 差异只包含本计划允许的路径，本地提交完成且未 push。

## 完成结果

六个受管 Skill 与 `skills-lock.json` 已同步到 `v0.3.8`；`.codex` 下的子代理配置、agents lock
与项目本地 config 已删除；`AGENTS.md`、`docs/agents/`、`CONTRIBUTING.md`、参考与设计文档已改为
单一外部 Skill 资产模型。`git-workflow.md` 重命名为 `git-delivery.md`，宿主规则不再引用 Skill
内部章节。全部验证通过，本地提交，未 push。
