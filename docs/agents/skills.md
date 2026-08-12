# Skill 与 Agent 集成

## 本地 skill

- 将仓库专用的可执行工作流存放在 `.agents/skills/`。
- 对上游 skill 的本地补充或更严格规则存放在 `.agents/overrides/`，不要修改复制的
  上游 skill。
- 执行目标 skill 前先阅读其 `SKILL.md`，然后阅读 `AGENTS.md` 指定的 overlay。
- 使用 `fireworks-tech-graph` 时，阅读
  `.agents/overrides/fireworks-tech-graph/layout.md`。

## 入口

- `.claude/CLAUDE.md` 是指向根目录规范 `AGENTS.md` 的符号链接。
- `.claude/skills` 指向 `.agents/skills`。
- 平台专用 Agent wrapper 应路由到规范的本地 skill，不要复制其工作流。
