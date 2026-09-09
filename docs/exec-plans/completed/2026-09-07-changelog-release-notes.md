# 以版本 Changelog 统一 Release Notes

- 状态：completed
- 创建日期：2026-09-07
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1283

## 背景

当前发布流程可以从临时 notes 文件或 GitHub 自动生成正文，Sparkle appcast 又会尝试从
文件或线上 Release 获取正文，因而 GitHub Release、appcast 和人工编辑内容存在多个来源
及生成时序不一致的风险。需要新增按版本保存的仓库内 Markdown，并让所有发布表面从同一
文件派生。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：none
- 目标结果：`changelog/<version>.md` 成为 Release Notes 唯一正文来源，GitHub Release
  与 Sparkle appcast 均验证其派生结果，并用 2.22.0 完成迁移验证。
- 允许修改路径：`changelog/`、`scripts/release/`、`.agents/skills/release-easydict/`、
  `docs/exec-plans/`、`docs/histories/2026-09/`。
- 同任务 history：`docs/histories/2026-09/2026-09-07-changelog-release-notes.md`
- 禁止动作：不发布新版本，不编辑线上 2.22.0 Release，不 push，不移动或创建 tag，不运行
  真实 draft/publish/release。
- 预期交付物：changelog 目录、2.22.0 迁移文件、确定性 Markdown 渲染与一致性校验、发布
  流程接入、行为测试、completed plan、history 和本地提交。
- 验收标准：2.22.0 Markdown 与线上 Release 正文一致；appcast 的 2.22.0 description 与
  Markdown 渲染结果一致；新发布强制使用版本 Markdown；漂移和缺失正文会阻断流程；相关
  静态检查与离线测试通过。

## 语义与范围

- 用户要求 Agent 做什么：按已确认方案修改并完整落地。
- 授权的工作树、artifact 和 external service 操作：修改并验证上述仓库文件；只读查询
  2.22.0 GitHub Release 作为迁移基准；按默认规则本地提交。
- 否定、条件和范围限制：暂时不发新版本，只迁移测试 2.22.0。
- 前轮仍有效的授权和限制：Markdown 是单一正文源；GitHub Release 与 changelog 保持
  一致；Sparkle appcast 从 changelog 生成更新日志；允许后续手动编辑。
- 附件或引用中被明确采纳的约束：PR #1283 的现有发布脚本是实施基线。
- 歧义：none

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；implementation 已授权、初始索引和工作树为空，用户未
  禁止本地提交。
- 初始 HEAD：`6987fb589cc21198c07011111022bcc1e6a480d0`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`changelog/`、`scripts/release/`、
  `.agents/skills/release-easydict/`、
  `docs/exec-plans/active/2026-09-07-changelog-release-notes.md`、
  `docs/exec-plans/completed/2026-09-07-changelog-release-notes.md`、
  `docs/histories/2026-09/2026-09-07-changelog-release-notes.md`。

## 目标与非目标

### 目标

- 新增 `changelog/README.md` 和与线上 2.22.0 Release 正文对应的 `2.22.0.md`。
- 提供确定性的 Markdown 校验、SHA-256 快照、Sparkle HTML 渲染和远端正文比对。
- 发布脚本默认且只接受 `changelog/<version>.md`，Draft 创建和验证使用同一冻结内容。
- appcast 生成与验证必须读取冻结 changelog，不再联网抓取正文或降级到不完整渲染器。
- 同步更新发布 Skill、文档和测试，使手动编辑入口与恢复边界清晰。

### 非目标

- 不迁移 2.22.0 以前版本。
- 不修改 2.22.0 线上 Release、公开 appcast 或发布资产。
- 不执行 Xcode 构建、公证、签名、上传、GitHub Draft 或 Issue 跟进。

## 工作计划

1. 迁移线上 2.22.0 正文并定义 changelog 文件规范。
2. 实现统一的 Markdown 校验、渲染、快照及 GitHub 正文一致性检查。
3. 将 release preflight、GitHub Draft、Sparkle 生成和最终验证接入冻结 changelog。
4. 调整发布入口、Skill 和维护文档，移除临时 notes 作为第二正文源的语义。
5. 补充回归测试，并用本地 appcast 和线上 2.22.0 进行只读迁移验证。
6. 运行独立 review 与测试，修复有效问题，归档计划和 history 后本地提交。

## 风险与决策

- GitHub API 返回的正文可能使用 CRLF；一致性比较只规范化 CRLF/LF 和单个文件结尾换行，
  不改动 Markdown 的其他空白或内容。
- Markdown 渲染器固定为仓库声明版本；缺少或版本不匹配时立即失败，避免环境相关输出。
- notes 哈希写入忽略的发布状态，并在 resume、Draft、publish 和验证阶段重新检查，防止
  人工编辑后继续使用旧 appcast。
- 版本 Tag 仍指向版本构建快照；正文必须在启动发布前提交到 `dev`，本次不改 tag。

## 进度

- [x] 核对最新 PR head、初始 Git 状态和 2.22.0 线上正文。
- [x] 新增 changelog 与统一正文工具。
- [x] 接入发布脚本、Skill 和文档。
- [x] 补充并运行主 Agent 验证。
- [x] 完成独立 review、history 和计划归档。

## 验证

- 发布脚本测试：26 个通过。
- Release Skill 测试：23 个通过。
- 2.22.0 线上 Release 正文与 changelog 只读比对：通过。
- 2.22.0 本地 appcast description 与 changelog 渲染严格比对：通过。
- 变更 Shell `bash -n`、workflow JSON/asc validation、Python compile、Skill validation 和
  `git diff --check`：通过。
- 独立 reviewer：最终无 P1/P2 finding；确认 resume 远程副作用门禁、Git index 与工作树
  双重漂移检查，以及 Markdown/raw HTML 链接边界均已闭环。
- 独立 tester：最新快照 26 个发布测试、23 个 Skill 测试和 2.22.0 三方一致性验证通过。
- 不运行 `xcodebuild`；变更不涉及 Xcode 编译源码或 Swift 测试。

## 完成条件

- 2.22.0 三方内容验证通过且没有远程写入。
- 缺失、正文漂移、渲染器不一致和 appcast 漂移都有失败测试。
- 发布脚本、JSON、Python、Markdown 和 Git diff 检查通过。
- 独立 review/test 覆盖最终实现快照。
- completed plan 与 history 记录最终结果并创建本地提交。
