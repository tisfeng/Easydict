# 发布流程：Draft 冻结 appcast 提交

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：completed
- 创建日期：2026-09-19
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

当前发布流程在 Publish 阶段才把候选 appcast 写入 release worktree 并提交，导致 Draft 阶段无法审查最终 appcast；同时临时 release 分支和版本 Tag 被实现为同一个提交，无法安全地把 appcast 独立提交前移到 Draft。

## 目标与范围

- 目标结果：Draft 阶段生成、验证并冻结独立的 appcast 提交；Publish 阶段只公开 Release、推送已冻结 Git 引用、验证并清理。
- 允许修改路径：`scripts/release/`、`scripts/release/tests/`、`.agents/skills/release-easydict/`、`docs/exec-plans/`、`docs/histories/`。
- 同任务 history：`docs/histories/2026-09/2026-09-19-release-appcast-draft-flow.md`
- 用户限制：不发布新版本、不评论或关闭 Issue、不修改远程 Release；本次只修改本地流程实现与文档。
- 非目标：改变构建、公证、Sparkle 签名、Release notes 内容或 Issue 关联策略。
- 验收标准：Draft workflow 在推送临时分支前完成 appcast 提交；Tag 指向版本提交、临时分支指向 appcast 提交；Publish 不再创建 appcast 提交或准备 channel transition；相关静态与行为测试通过。

## 工作计划

1. 调整 Draft/Publish workflow 边界和 release 状态元数据，区分 version/appcast commit。
2. 修改 Draft 推送、Publish 预检、集成推送和远程验证，保持 Tag、临时分支、main、dev 的引用契约。
3. 更新 release 文档和现有测试断言；不新增超出当前授权范围的测试领域。
4. 运行 Shell/Python 静态检查与发布脚本行为测试，检查差异和工作树。
5. 完成 history，归档本计划。

## 风险与决策

- appcast 提交在 GitHub Release 公开前已存在于临时远程分支，但不进入 `main`，因此不会被公开 feed 使用；Publish 仍先公开 Release，再通过 lease 推送 `main`。
- 版本 Tag 必须继续指向版本元数据提交，不能改为 appcast 提交，否则下载版本身份和现有 Tag 语义会漂移。
- Draft 阶段的 beta predecessor transition 只修改临时 worktree/appcast candidate；Publish 阶段只验证并晋升上一 GitHub Release。
- Issue follow-up 保持在远程 Release 和 appcast 验证之后，不纳入 Draft。

## 进度

- [x] 调整 workflow 和状态元数据。
- [x] 调整 Git 引用和远程验证。
- [x] 更新文档与测试。
- [x] 完成验证。
- [x] 归档计划并写入 history。

## 验证

- `bash -n scripts/release/*.sh`、`jq -e . scripts/release/asc-workflow.json`、Python 编译、发布 workflow 与 Git flow 行为测试、`git diff --check` 均通过。
- 不运行真实 Draft/Publish、远程推送、Release 或 Issue 操作。

## 完成条件

- 所有目标脚本和测试通过验证，且 Draft/Publish 引用契约在测试中明确。
- 文档与实现一致。
- history 已记录，计划已移动至 `docs/exec-plans/completed/2026-09/`。
