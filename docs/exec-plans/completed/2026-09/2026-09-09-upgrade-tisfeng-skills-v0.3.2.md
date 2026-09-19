# 升级 `tisfeng/skills` 至 v0.3.2

## 任务摘要与授权

- 用户请求：同步 Easydict 项目依赖的 `tisfeng/skills v0.3.2`。
- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 初始 HEAD：`70f7abd4e7d341f16b54aa448142d6f76d5429aa`（detached HEAD）。
- 初始 staged、unstaged、untracked 与冲突：均为空。
- 上游目标：annotated tag `v0.3.2`，peeled commit
  `826b0a868f5802da8a4f2b90c8ac92e6cb2577b2`。

## 目标与边界

- 同步六个通用 Skill 与四个 Codex 子代理，更新双 lock 和宿主版本说明。
- 保留 `release-easydict`、`fireworks-tech-graph`、`.codex/config.toml`、`.claude/skills`
  与 `.claude/CLAUDE.md`；不修改产品代码、不 push。
- Agent-owned paths：六个 `.agents/skills/` 受管目录、四个 `.codex/agents/*.toml`、
  `skills-lock.json`、`.codex/agents-lock.json`、相关宿主文档、本 plan 与同任务 history。

## 工作计划

1. 固定 tag、核验安装器和旧快照，使用各自安装器从准确 tag 同步。
2. 复核受管目录、锁文件、保护路径与宿主版本/交付接口。
3. 运行上游受影响 Skill 测试、JSON/TOML/文档与 diff 静态检查，并独立审查最终快照。
4. 写入 history、归档本计划，按 `auto-exact` 精确暂存并执行本地 Angular-style 提交。

## 验证与完成条件

- 受管目录逐文件匹配 `v0.3.2` tracked tree；agents lock 的 revision 与 file hash 一致。
- 不受本次来源管理的路径保持不变；无 Xcode 或远程 Git 状态变更。
- `git diff --check`、JSON/TOML 解析、文档链接与受影响的上游测试通过，独立 review 无阻塞项。

## 进度

- [x] 固定 tag 并同步六个 Skill 与四个子代理。
- [x] 更新双 lock、宿主基线、安装命令与暂存策略委派接口。
- [x] 完成逐文件、lock、保护路径、测试和独立审查。
- [x] 归档计划并准备本地交付。
