# 升级受管 Skills 至 v0.3.3 并优化 Agent 规则

- 日期：2026-09-10
- 状态：completed
- 关联计划：[`2026-09-10-upgrade-managed-skills-v0-3-3.md`](../../exec-plans/completed/2026-09-10-upgrade-managed-skills-v0-3-3.md)

## 用户请求

将项目依赖的 Skills 更新至 `v0.3.3`，同步适配项目 Agent 规则，并参考 OpenAI 官方延迟优化
指南整体改进工作流效率。

## 变更

- 将六项通用 Skills 固定同步到 `tisfeng/skills v0.3.3`，并将 planner、reviewer、tester 的 lock
  revision 更新为 `41555fa9a5090dd172870ba392b2dc231c767c9b`。
- 按上游升级说明删除不再发布的 `git-delivery` agent 及其单个 lock 条目，保留项目专属和独立
  Skills、Codex 配置及 Claude 链接。
- 将 Git 交付改为主 Agent 直接串行执行 `git-commit` 或 `worktree-rebase-merge`，同步新版锚点、
  可见预览、精确范围、写前复验、回执和 `submit-pr` Issue `forbid` 策略。
- 在请求、审查、验证和回复规则中加入同快照证据复用、独立检查并行、确定性工具优先和增量
  复核，减少重复上下文、LLM 调用和输出。

## 设计意图

将固定上游快照升级与宿主契约迁移作为同一原子任务，避免受管 Skill、agent lock 和项目规则
形成混合版本。工作流优化参考 OpenAI 官方
[Latency optimization](https://developers.openai.com/api/docs/guides/latency-optimization) 的减少输出、
输入、请求、并行和确定性处理原则，只减少重复工作，不削弱授权、验证和 Git 安全边界。

## 验证

- 远程 tag、npm 安装器版本、六项 Skill tracked tree、三个 agent SHA-256/revision 和双 lock
  均核验通过。
- `git-commit` 19、`review-pr` 27、`submit-pr` 26、agent installer 6，共 78 项测试通过。
- 现行 Agent 文档的 28 个相对链接和锚点、旧角色引用扫描、保护路径比较与 `git diff --check`
  通过。
- 独立 tester 验证通过；独立 reviewer 未发现 finding，并对收尾记录进行增量复核。
- 未运行 `xcodebuild`：本次未修改产品或 Xcode 内容。全新任务中的 custom agent 发现 smoke
  不在静态验证范围内。

## 受影响文件

- `.agents/skills/code-simplifier/`
- `.agents/skills/git-commit/`
- `.agents/skills/review-pr/`
- `.agents/skills/submit-pr/`
- `.agents/skills/worktree-rebase-merge/`
- `.codex/agents/git-delivery.toml`
- `.codex/agents-lock.json`
- `skills-lock.json`
- `AGENTS.md`
- `docs/agents/README.md`
- `docs/agents/build-and-test.md`
- `docs/agents/git-workflow.md`
- `docs/agents/request-boundary.md`
- `docs/agents/review.md`
- `docs/exec-plans/completed/2026-09-10-upgrade-managed-skills-v0-3-3.md`

## 后续事项

- 可在全新任务中另行 smoke 验证 planner、reviewer、tester 的运行时发现；这不影响本次仓库
  快照与静态配置验收。
