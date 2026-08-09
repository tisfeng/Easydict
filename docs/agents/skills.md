# Skills and Agent Integrations

## Local skills

- Store repository-specific executable workflows in `.agents/skills/`.
- Store local additions or stricter rules for an upstream skill in
  `.agents/overrides/` rather than editing a copied upstream skill.
- Read the target skill's `SKILL.md` before executing it, then read any overlay
  named by `AGENTS.md`.
- When using `fireworks-tech-graph`, read
  `.agents/overrides/fireworks-tech-graph-layout-rules.md`.

## Entry points

- `.claude/CLAUDE.md` is a symlink to the canonical root `AGENTS.md`.
- `.claude/skills` points to `.agents/skills`.
- Platform-specific agent wrappers should route to a canonical local skill and
  must not duplicate its workflow.

## General principles

- If work requires the OpenAI API, ChatGPT Apps SDK, Codex, or related OpenAI
  developer tools, use the OpenAI developer documentation MCP server.
- State assumptions and success criteria before non-trivial work.
- Prefer the smallest solution that satisfies the request.
- Keep changes surgical and validate them before delivery.
- Turn recurring agent failures into documentation, tooling, or environment
  improvements instead of repeatedly expanding prompts.
