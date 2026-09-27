# 同版本 Draft 安全重建

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict maintainers
**Links:** `.agents/skills/release-easydict/SKILL.md`

## 任务契约

- 任务模式：`implementation`
- 用户目标：允许以本地最新 `dev` 为来源，安全废弃同版本旧 Draft 和 Tag，并重新构建、签名、公证和创建 Draft。
- 允许动作：修改发布脚本、工作流、skill、测试与仓库文档；执行本地静态和隔离测试；自动本地提交。
- 允许修改路径：`scripts/release/`、`.agents/skills/release-easydict/`、`docs/exec-plans/`、`docs/histories/`。
- 预期交付物：`draft <version> --replace-draft` 命令、可恢复的替换状态机、自动构建号递增、成功后清理以及配套文档和测试。
- 验收标准：普通 Draft 行为不变；替换模式在新产物完成本地验证前不修改远端；只替换精确匹配的最新 GitHub Draft 和 Tag；失败可恢复；成功后不保留旧本地产物。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：增加同版本重新 Draft 参数，基于同步后的本地 `dev` 重建，构建号自动加一，替换旧 Draft/Tag，并在成功后移除废弃的本地状态。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 附件或引用材料：现有 2.22.0 GitHub Draft 与本地 `.tmp/release/2.22.0/` 状态。
- 仅作为证据的内容：当前线上 Draft 和 Tag 状态；本轮实现不会实际替换线上 2.22.0。

## 目标

新增显式 `--replace-draft` 模式。它冻结旧 Draft 和 Tag 身份，临时保存旧本地状态，使用最新已提交的本地 `dev` 在隔离工作树中重建并验证产物，随后以 lease 原子替换版本引用、删除精确的旧 Draft、创建并验证新 Draft，最后清除临时备份。

## 范围

- 包含范围：命令参数、asc 工作流参数与步骤、替换状态、构建号选择、GitHub Draft/Tag 安全检查、恢复和清理、skill 编排规则、隔离测试。
- 不包含范围：本轮实际运行 2.22.0 重建、公证或远端删除；改变普通 `draft`/`publish` 语义；清除 Apple 公证历史。

## 背景

- 当前行为：同版本 Draft 和 `.tmp/release/<version>/` 存在时，普通 `draft` 会复用旧工作树、构建号和产物。
- 相关文件：`release-easydict.sh`、`asc-workflow.json`、`release-common.sh`、`release-preflight.sh`、`release-build.sh`、`release-branch-sync.sh`、`release-github.sh` 和 release skill。
- 约束：不切换或污染用户当前 checkout；远端变更必须绑定旧 Draft 数据库 ID 和旧 Tag OID；新替换请求不能覆盖未完成的替换状态。

## 风险与缓解

- 风险：构建或公证失败后丢失可用 Draft。
  - 缓解措施：本地验证成功前保持远端 Draft/Tag 不变。
- 风险：并发发布导致删除或覆盖错误对象。
  - 缓解措施：在远端变更前重新核对 Draft 数据库 ID、创建时间、Tag OID 和页面首项，并使用 `--force-with-lease`。
- 风险：恢复时再次递增构建号或再次删除 Draft。
  - 缓解措施：首次替换冻结构建号和身份，后续只按阶段标记幂等续跑；新的替换请求遇到未完成状态直接失败。
- 风险：成功后遗留旧产物或隐藏分支。
  - 缓解措施：新 Draft 远端验证通过后执行专用清理步骤，并验证临时备份、旧工作树和旧归档分支均已移除。

## 里程碑

- [x] 确认范围和约束。
- [x] 实现替换状态、构建和远端切换。
- [x] 更新 skill、命令文档和测试。
- [x] 完成验证并将本计划移到 `completed/`。

## 验证

- 命令：`bash -n scripts/release/*.sh`
- 命令：`jq -e . scripts/release/asc-workflow.json`
- 命令：`asc workflow validate --file scripts/release/asc-workflow.json --pretty`
- 命令：发布脚本隔离测试和 release skill 测试。
- 命令：`git diff --check`
- 手动检查：普通 Draft 路径无行为变化；替换步骤顺序保证先本地验证、后远端切换、最后清理。
- 观察结果：工作流 schema 有效；10 个发布脚本测试和 17 个 release skill 测试通过；普通 Draft 与替换 Draft dry-run 均按预期展开；未执行真实构建、公证或远端发布。

## 决策记录

- 2026-08-23：使用独立 `--replace-draft` 模式，不把替换语义隐式加入普通 `draft`。
- 2026-08-23：旧本地状态仅作为失败恢复的临时备份；新 Draft 验证成功后删除，不形成永久 stale 归档。
- 2026-08-23：旧远端 Draft 保留到新产物完成本地验证；Tag 与分支引用成功切换后才删除旧 Draft。
- 2026-08-23：构建号首次按旧 Draft、本地项目和公开 appcast 的最大值加一并冻结，resume 不重复递增。

## 进度记录

- 2026-08-23：完成现有普通 Draft、工作树复用、构建号和 GitHub Draft 创建逻辑审计，开始实现独立替换状态机。
- 2026-08-23：完成实现、隔离 Git/GitHub 测试、skill 校验和 dry-run；旧线上 2.22.0 Draft 未被修改。
