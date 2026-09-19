# 澄清 Agent 规则与文档引用

- 状态：completed
- 创建日期：2026-09-10
- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal

## 目标与授权范围

按用户确认方案澄清迁移、语言、PR、委派回退和测试引用规则，更新公共指南中的本地化路径。
允许修改 AGENTS.md、相关 docs/agents、docs/references、Swift 迁移计划和中英文贡献与翻译指南，
以及本任务 plan/history。保留每次改动写 history、现有 plan 门槛、注释长度和完整提交回执；
不调整 Xcode 版本要求，不修改受管 Skill、lock 或产品代码，不推送。

## 写入前状态

- 初始 HEAD：68eb2be6c13c75b0a3d57ccac49917438e5e1bd8
- staged、unstaged、untracked、冲突：均为空。
- 写入前检查：通过；具备自动本地提交资格。
- Agent-owned paths：本任务允许范围内实际产生的差异，交付前逐项冻结。
- 同任务 history：docs/histories/2026-09/2026-09-10-clarify-agent-rules.md

## 工作计划

1. 最小修改已确认的冲突、过时引用和重复条款。
2. 检查本地链接、锚点、保留条款和中英文对应内容，委派独立 reviewer。
3. 修复有效问题，记录 history，归档计划并按 Git 门禁交付。

## 风险与决策

保留必需独立审查门禁，回退只明确阻塞范围。公共文档保持原语言；历史证据不追改。
版本信息保留在 lock 和带日期参考记录中，操作规则不重复固定版本。

## 进度与验证

- 文档修改完成；独立 reviewer 已复核正文，未发现实质问题。
- 32 份非历史 Markdown 的 139 个本地文件链接目标检查通过；新增锚点与目标标题核对一致。
- 自动对比确认 history/plan、注释长度、完整提交回执、测试原则和 Xcode 版本条款未变。
- git diff --check 通过；纯文档修改未运行 Xcode 构建或测试。
- 已记录同任务 history，计划归档，进入本地交付。
- 完成条件：约定修改落地、独立复核完成、静态检查通过、history 与计划归档完成。
