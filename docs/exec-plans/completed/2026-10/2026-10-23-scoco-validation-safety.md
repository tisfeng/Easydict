# 移植 Scoco 应用验证实例保护规则

- 状态：completed
- 创建日期：2026-10-23
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

## 背景

周度同步从已检查的 Scoco `9d1dacad5968acac52d62b0b1f37b21870c346ac` 增量检查至 `276fa5d1efa211da75763025fa3190ee2f8522a9`，共 8 个提交。Scoco 远端 dev 与本地 tip 一致。Easydict 主 checkout 的本地 dev 为 `b4eced749d492d283f451f88e5504413e4533f44`，本任务基于已核实的最新 origin/dev `8d80bfa219dde99c9c1f2760b59b2df72ad4adef`，不更新用户主 checkout。

## 目标与范围

- 目标结果：移植适用的单实例验证和 bundle ID 保护规则，记录所有候选状态及增量检查点。
- 允许修改路径：`docs/agents/build-and-test.md`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-10/2026-10-23-scoco-validation-safety.md`
- 用户限制：独立工作树、本地提交；不 push、不创建 PR、不自动合并 dev、不改动运行中的应用。
- 非目标：移植 Scoco 专属启动/云端认证与发布功能，自动调整 QR QoS，重构 OCR，新增测试。
- 验收标准：仅文档差异，静态和语义检查通过，记录暂缓项；完成本地提交。

## 工作计划

1. 核对来源 8 个提交、远端开发基线及目标等价实现。
2. 适配 `18bdb49cf62d9ce13c5d9aceef22dbe21f4d06fd` 的实例管理规则及 `6e863b0292374185ca14171eb6966f02b0fc3fef` 中的 bundle ID 文档规则；保留目标现有验证矩阵和测试授权规则。
3. 检查差异、相对链接、章节与命令保留情况，更新 history 并归档计划。
4. 使用 git-commit 技能提交，只暂存范围内文档。

## 风险与决策

- 本轮仅治理文档，无生产代码或测试变更，按 AGENTS.md 豁免生产代码 review；仍做文档语义核对。
- Scoco `bd01b8dc5617415d40d8fc2a2ca3d49761645b65` 会降低 QR 调度优先级，后续记录仍注明警告未解决；目标已具备 perform 返回后完成的边界，QoS 取舍暂缓，不标记为已移植。
- `276fa5d1efa211da75763025fa3190ee2f8522a9` 的重组主要消除 Scoco 的截图/OCR 包装层；目标没有相同重复结构，不复制模块拆分。
- 既有 CSS 修复已在目标以 `b4eced749` 收录，不重复移植；源工作树只读。
- 本任务使用 codex/ 前缀遵循自动化指令；通过统一分支工具的显式名称校验。

## 进度

- [x] 完成增量筛选与基线核对。
- [x] 完成文档适配与静态验证。
- [x] 更新 history、归档计划并完成提交准备。

## 验证

- `git diff --check` 通过。
- 静态核对确认 Bash 命令块逐字未变、测试授权与工程组织章节逐字未变、新实例管理章节唯一且保留 Easydict 的 DerivedData 路径。
- 文档语义核对：默认复用用户实例、明确多实例例外、只终止本任务实例、查询不会重新启动应用；保持同 bundle ID 测试宿主限制。无适用的生产代码 review 要求。
- 来源 dev 的远端 SHA 已通过 GitHub API 和 Git 读取确认。SSH 签名读取一度延迟，目标 origin/dev 通过 HTTPS fetch 更新并复验；未更改远程配置。
- 纯文档任务不运行 Xcode 构建、测试或应用；未新增测试。

## 完成条件

- 只修改 3 个指定文档，静态检查通过，候选台账包含暂缓项和来源检查点。
- 计划归档，完成本地提交及消息校验；保持主 checkout 与 Scoco 工作树不变。
