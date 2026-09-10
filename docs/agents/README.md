# Agent 规则与仓库治理

本目录存放面向编码 Agent 的现行专题规则。根目录 [`AGENTS.md`](../../AGENTS.md) 是唯一任务
入口；本文件统一说明文档生命周期、维护原则和外部 Agent 资产边界，不提供第二套路由。

## 文档分层

- `docs/agents/`：当前有效的 Agent 和贡献者工作流规则。
- `docs/design-docs/`：产品与技术设计，以及需要长期维护的设计决策。
- `docs/user-docs/`：公开的英文和中文文档。
- `docs/exec-plans/`：获准 implementation 的多步骤工作计划。
- `docs/histories/`：最终产生仓库文件差异的 implementation 记录。
- `docs/references/`：反复使用的精选外部或跨仓库参考。

历史、completed plan、参考资料和其中的示例命令是证据，不是当前执行指令。只有当前任务
明确采用的内容才约束实施，并继续服从用户有效指令与现行专题规则。

## Plan 与 History

- planning 阶段的方案只出现在当前回复中，不创建或更新 active plan。
- 用户明确批准 implementation 且写入前检查（Mutation Gate）通过后，架构、协议、迁移、
  多步骤、跨模块或高风险工作在 `docs/exec-plans/active/` 创建执行计划。
- implementation 最终产生仓库文件差异时，必须在同一任务中创建或更新一条
  `docs/histories/` 记录；没有差异时不创建空记录。
- 同一任务分多轮实施时复用同一条 history。只修改 history 的任务由该记录描述自身，不递归
  创建第二条。
- 存在执行计划时，完成后移动到 `docs/exec-plans/completed/`，并让同任务 history 链接
  completed plan。
- 交付时将同任务 history 与其他任务变更一起验证和精确暂存。缺少 history 时在允许范围内
  补齐；用户明确排除该路径时不扩权，并按 Git 规则报告交付阻塞。
- 显式提交已有 staged 内容不反向要求补写 implementation history。
- plan 记录目标、授权、范围、限制、初始 Git 快照、Agent-owned paths、工作计划、风险、验证
  和完成条件；history 只记录已落地结果与关键决策，并通过链接引用已有 issue、pull request
  或 plan，不复制完整对话和讨论。

## 文档维护

- 每份现行规则只维护一个主要职责；跨职责使用链接，不复制完整条款。
- 同一专题保持内聚且不超过 500 行时，不应仅为缩短文件而继续拆分；超过约 500 行或出现多个
  独立职责时再评估拆分。
- 新增、删除或重命名规则文件时，只在根 `AGENTS.md` 维护任务路由，不建立多层索引。
- 使用相对仓库路径，不提交机器本地绝对路径。行为变化时同步更新代码、测试和受影响文档。
- 仓库治理 Markdown、plan、history、reference、skill 和公共 Markdown 的 Xcode 工程边界
  以 [`build-and-test.md`](build-and-test.md#工程文件与资源) 为准。

## 外部 Agent 资产

### 资产分类

以下内容由 `skills-lock.json` 或 `.codex/agents-lock.json` 管理，具体来源和版本以对应 lock 为准：

- Skills：`code-simplifier`、`git-commit`、`review`、`review-pr`、`submit-pr`、
  `worktree-rebase-merge`。
- Codex 子代理：`planner`、`reviewer`、`tester`。

这些目录和 TOML 是外部权威内容的项目可运行快照。Easydict 不直接修改、删减、重命名或
重新格式化；项目差异写入 `AGENTS.md` 或 `docs/agents/`。需要改变通用行为时先修改并发布
上游，再通过安装器同步完整版本。

项目专属 skill 和 reference 的语言遵循根 [`AGENTS.md`](../../AGENTS.md#始终阅读)。
外部受管快照保留上游原文，不在 Easydict 中本地修补。

`fireworks-tech-graph` 由 `yizhiyanhua-ai/fireworks-tech-graph` 独立维护，通过
`skills-lock.json` 记录自己的来源和内容哈希，不得从 `tisfeng/skills` 同步或在 Easydict 中
本地修补。

`release-easydict` 是项目专属 Skill，不登记到外部 lock，由本仓库维护；同步任何外部来源时
必须保持其目录不变。

### Lock 所有权

- `skills-lock.json` 记录 Skill 来源、ref、入口路径和安装器计算的内容哈希，不得手工修改 hash
  接受本地漂移。
- `.codex/agents-lock.json` 记录 agent 来源、ref、精确 Git revision、目标路径和文件哈希。
- lock 不替代已安装内容；仓库同时提交可离线读取和运行的完整快照。
- `.codex/config.toml` 是项目本地配置，不受 agents lock 管理。
- `.claude/skills` 指向 `.agents/skills`，不是可独立修改的副本；`.claude/CLAUDE.md` 指向根
  `AGENTS.md`。

### 写入与同步

1. 修改 `.agents/skills/` 或 `.codex/agents/` 前，读取两个 lock 并确定资产分类。
2. 普通实现、修复、review 和文档任务不得编辑外部受管路径；发现问题时报告上游和 lock 证据。
3. 只有用户明确授权同步或升级时，才使用对应安装器更新受管快照和 lock。不同来源分步执行
   并分别检查 diff，不运行不区分来源的宽泛更新。
4. 首次为已有 agent 建立 lock 时，只有冻结并核对精确 TOML 后才可使用一次 `--force`；后续
   更新依靠已记录 hash 检测漂移，不默认覆盖。
5. 上游版本明确删除受管资产且安装器不会自动清理时，只在获准的升级任务中核验发布说明、
   已安装路径和 lock 条目后，精确删除对应快照与单个 lock 条目；不扩展到其他资产。
6. 不递归复制上游工作目录；安装内容来自已核验的 tag、commit 或安装器克隆，避免带入缓存
   和构建产物。
7. 同步后验证目标集合、lock、来源内容和项目专属保护路径，再按 Git 门禁交付。

### 验证边界

- 上述通用 Skill 目录必须与所选 tag 的 tracked tree 一致。
- 受管 agent 文件的 SHA-256 必须与 agents lock 一致并使用同一 revision。
- `fireworks-tech-graph` 必须与独立上游 commit 一致，且 lock source 不指向 `tisfeng/skills`。
- `release-easydict`、`.codex/config.toml` 和 `.claude/skills` 在外部同步前后保持不变。
- 按风险验证 TOML、JSON、Skill 测试、Shell/Python 静态检查和文档相对链接。

静态检查只能证明仓库快照与配置一致；新的 custom agent 能否被 Codex 运行时发现，需要在
全新任务中另行 smoke 验证。

## 应用内置 Agent 文档

应用内置 Agent 文档、运行时资源和后端契约使用各自权威来源，不因普通仓库 Agent 文档整理
而移动或改写。运行时发布内容继续遵循其专属资源、工程和构建规则。
