# 通用 GitHub PR 提交 Skill

**Status:** completed
**Created:** 2026-08-24
**Updated:** 2026-08-24
**Owner:** Easydict maintainers
**Links:** `../../histories/2026-08/2026-08-24-generic-submit-pr-skill.md`

## 任务契约

- 任务模式：`implementation`
- 用户目标：保留仓库内 `submit-pr` Skill 的严格 PR 格式规则，同时让它能从任意
  GitHub 项目 checkout 安全创建或复用 PR。
- 允许动作：修改 Skill 指令、helper、测试、UI 元数据和对应 Agent 文档；运行本地
  单元测试与静态检查；验证后自动创建一次本地提交。
- 允许修改路径：`.agents/skills/submit-pr/**`、`docs/agents/skills.md`、本计划和
  对应历史记录。
- 预期交付物：通用 repository/remote/base/head/fork 发现、四段式模板兼容、Issue
  策略、严格只读 plan 和幂等 apply。
- 验收标准：不再硬编码 Easydict 仓库身份；四段式、Angular 标题和 Conventional
  分支规则保持；测试覆盖同仓库、fork、多 remote、模板和幂等边界；不 push。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`scheduled after final validation`

## 输入来源

- 用户明确请求：在当前仓库路径保留 Skill，只泛化内容和执行目标。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、
  `docs/agents/skills.md`、`docs/agents/testing.md`。
- 附件或引用材料：None
- 仅作为证据的内容：现有 `submit-pr` Skill、helper、测试和 PR 模板。

## 目标

将 `submit-pr` 从固定 `tisfeng/Easydict`、`origin/dev` 和同仓库 PR 的实现，改为根据
目标 checkout 动态发现 GitHub 拓扑的通用工作流，同时继续强制统一的 PR 内容、标题和
任务分支格式。

## 范围

- 包含范围：仓库与 remote 发现、默认 base、fork PR、动态保护分支、模板扩展、Issue
  策略、plan/apply 安全边界、测试和文档。
- 不包含范围：移动或复制 Skill、创建 fork、支持非 GitHub 托管、review、merge、
  reviewer/label 管理、修改现有 PR。

## 背景

- 原行为：helper 固定 `tisfeng/Easydict`、`origin/dev`、同仓库 PR 和
  `.tmp/submit-pr/` 状态路径。
- 相关文件：`.agents/skills/submit-pr/`、`docs/agents/skills.md`。
- 约束：四段式、Angular-style 标题和 Conventional 分支名必须保留；`plan` 必须零
  写入；`apply` 不得 force push 或覆盖已有 PR。

## 风险与缓解

- 风险：多 remote 或 fork 场景选错目标。
  - 缓解措施：显式参数优先，校验 fetch/push repository 和 fork 网络，存在歧义时停止。
- 风险：目标仓库模板的额外要求丢失。
  - 缓解措施：保留固定四段式骨架、兼容语义标题，并保留 checklist 与额外段落。
- 风险：重复执行创建第二个 PR。
  - 缓解措施：按 base/head repository 和 branch 精确查询，并验证冻结 SHA 和正文。

## 里程碑

- [x] 确认范围和约束。
- [x] 泛化 helper 数据模型和执行状态机。
- [x] 更新 Skill、reference、UI 元数据和 Agent 路由文档。
- [x] 扩充模板、remote、fork、Issue 策略与幂等测试。
- [x] 完成验证和历史记录。
- [x] 将本计划移到 `completed/`。

## 验证

- `python3 -m py_compile`：通过，缓存重定向到 `/private/tmp`。
- `python3 .agents/skills/submit-pr/tests/test_submit_pr.py`：17 个测试通过。
- `quick_validate.py .agents/skills/submit-pr`：`Skill is valid!`。
- `git diff --check`：通过。
- 手动检查：Skill 本体没有固定 Easydict repository、remote 或 base 常量；helper 保持
  executable bit；测试只使用本地 bare remote 和 fake `gh`。

## 决策记录

- 2026-08-24：Skill 继续保存在 Easydict 仓库，不创建全局副本或 overlay。
- 2026-08-24：四段式、Angular 标题和 Conventional 分支名是通用质量规范，不随仓库
  身份泛化而移除。
- 2026-08-24：Issue 自动关闭采用 `neutral`、`allow`、`forbid` 策略；Easydict 使用
  `forbid`。
- 2026-08-24：remote 的 fetch URL 决定 base 身份，push URL 决定 head 身份，以支持
  单 remote pushurl fork。
- 2026-08-24：移除仓库内 `.tmp/submit-pr/` 状态文件，apply 的 PR 正文使用系统临时
  文件；恢复依赖远程分支和开放 PR 的幂等查询。

## 进度记录

- 2026-08-24：完成现状审计和任务边界确认。
- 2026-08-24：完成 helper、文档与 17 个隔离测试，进入自动本地提交。
