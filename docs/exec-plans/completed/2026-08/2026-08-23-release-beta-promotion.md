# 发布时自动提升上一 beta 版本

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Codex
**Links:** scripts/release/

## 任务契约

- 任务模式：`implementation`
- 用户目标：发布新的 beta 版本时，将上一 beta 的 Sparkle 和 GitHub Release 状态自动提升为 stable。
- 允许动作：修改发布脚本、工作流、测试、发布文档和本次变更的计划/历史文档；运行本地只读或临时目录校验；创建一次本地提交。
- 允许修改路径：`scripts/release/`、`docs/exec-plans/`、`docs/histories/2026-08/`
- 预期交付物：兼容现有 Draft、可恢复且可验证的 beta 轮换流程。
- 验收标准：2.22.0 保持 beta/prerelease；2.21.0 从 appcast beta 和 GitHub prerelease 提升为 stable；重复执行和 resume 不产生额外变化。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 初始未暂存区：`empty`
- 初始未跟踪路径：`empty`
- 自动提交结果：本计划随任务最终自动提交交付

## 目标

在 `publish` 阶段根据候选 appcast 自动识别上一 beta，持久化轮换状态，更新 Sparkle feed，并在新 beta 公开后移除上一 GitHub Release 的 prerelease 标记。

## 范围

- 包含：上一 beta 识别、候选 appcast 转换、GitHub promotion、最终远程校验、行为测试和发布文档。
- 不包含：执行真实 `publish`、更改默认 beta 频道、重新构建 2.22.0 产物或修改发布说明。

## 风险与缓解

- 风险：恢复执行时重复修改 feed 或 GitHub 状态。
  - 缓解措施：先持久化上一 beta 版本，所有转换和远程编辑保持幂等。
- 风险：误改旧 appcast 条目。
  - 缓解措施：校验器只允许上一 beta 删除 `sparkle:channel`，其他字段和旧条目必须保持不变。
- 风险：GitHub Release 与公开 feed 短暂不一致。
  - 缓解措施：先公开并验证新 beta，再推送 feed，随后提升上一 GitHub Release，最后统一验证全部远程状态。

## 里程碑

- [x] 确认现有 Draft、候选 appcast 和 GitHub Release 状态。
- [x] 实现可恢复的 appcast beta 轮换。
- [x] 实现 GitHub 上一 beta promotion 和最终验证。
- [x] 补充测试、文档并完成静态与 dry-run 验证。
- [x] 将计划移到 `completed/` 并准备自动提交。

## 验证

- `python3 scripts/release/tests/test_release_appcast.py`：通过，3 个行为测试全部成功。
- 真实 2.22.0 候选副本验证：识别 2.21.0，并得到 2.22.0 beta、2.21.0 stable。
- `python3 -m py_compile scripts/release/release-appcast.py scripts/release/tests/test_release_appcast.py`：通过。
- `bash -n scripts/release/*.sh`：通过。
- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `./scripts/release/release-easydict.sh publish 2.22.0 --dry-run`：通过，promotion 顺序正确。
- `git diff --check`：通过。
- `shellcheck`：当前环境未安装，未执行。

## 决策记录

- 2026-08-23：只在当前频道为 `beta` 时提升候选 feed 中排在当前版本之后的第一条 beta。
- 2026-08-23：promotion 在 `publish` 阶段执行，以兼容已经创建的 2.22.0 Draft 和候选 appcast。

## 进度记录

- 2026-08-23：完成当前脚本、候选 feed 和线上 Release 状态审计。
- 2026-08-23：完成 appcast 转换、GitHub promotion、远程验证、行为测试和发布文档。
