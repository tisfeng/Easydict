# Release 性能优化

- 状态：completed
- 创建日期：2026-09-19
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

2.23.0 的 Draft/Publish 运行暴露出构建缓存未复用、每步耗时不可观测和发布构建环境不稳定的问题。用户批准使用长期专用 build worktree，并要求保留现有发布功能和安全边界，只优化流程速度。

## 目标与范围

- 目标结果：为发布流程增加可恢复的逐步骤耗时记录，复用长期 build worktree 和 Release DerivedData，并在增量 Archive 失败时安全回退 clean Archive。
- 允许修改路径：`scripts/release/`、`scripts/release/tests/`、`.agents/skills/release-easydict/references/`、`docs/exec-plans/`、`docs/histories/`。
- 同任务 history：`docs/histories/2026-09/2026-09-19-release-performance.md`
- 用户限制：不改变发布功能、远程分支边界、签名、公证、appcast 和最终验证；不 push。
- 非目标：本轮不改 GitHub 资产并行上传、notarization submission 复用或 Publish 网络查询合并。
- 验收标准：shell 语法和现有 release 测试通过；新缓存路径有 fingerprint 和并发锁；普通 Archive 不默认 clean，失败时最多 clean 回退一次；失败和 resume 状态可诊断；工作树保持可提交状态。

## 工作计划

1. 为 release-common 增加 step timing、缓存路径和 build worktree/锁辅助函数。
2. 让 release-build 在版本提交后计算 fingerprint，使用长期 build worktree 和稳定 DerivedData，执行增量 Archive 与 clean fallback。
3. 增加针对 timing、缓存元数据和 worktree 安全边界的测试。
4. 运行 focused tests、shellcheck/语法检查和 `git diff --check`。
5. 使用 review 技能审查变更，修复有效 finding 后复验。
6. 更新 history，归档本计划并创建本地提交，不 push。

## 风险与决策

- 长期 worktree 只用于构建，不替代版本/appcast release worktree，也不接入正式分支推送。
- DerivedData fingerprint 不包含源码提交 SHA，避免每个版本号变化导致全量失效；源码提交单独写入发布元数据供审计。
- 增量构建失败后只在受保护的 cache 路径内清理并重试一次；签名、公证、stapling 和验证不跳过。
- 同时只允许一个进程切换长期 build worktree；锁异常残留时报告持有者，不静默覆盖。

## 进度

- [x] timing、缓存和锁辅助函数
- [x] build worktree 与增量 Archive
- [x] 测试与验证
- [x] review、history 和提交

## 验证

- 记录 focused test、shell 语法、静态 diff 检查和 review 结果。
- 已通过：`asc workflow validate --file scripts/release/asc-workflow.json --pretty`。
- 已通过：`bash -n scripts/release/*.sh`、31 个 release 测试、30 个 skill 测试、Python 编译检查、`git diff --check`。
- 已完成只读 review：确认 build worktree 不参与远程推送，缓存路径和锁受保护，强制 clean 和增量失败回退路径互斥，resume 校验版本提交和 worktree HEAD。
- 真实 Xcode Archive 不在本轮自动运行，避免触发长时间签名/公证流程；需在下一次 Draft 运行测量命中效果。

## 完成条件

- 变更通过针对性测试和 review。
- history 已记录实际变更和未运行的真实发布验证。
- 计划归档到 `docs/exec-plans/completed/2026-09/`。
- 创建本地 Angular-style commit，未 push。
