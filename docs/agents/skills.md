# Skills and Agent Integrations

## Local skills

- Store repository-specific executable workflows in `.agents/skills/`.
- Store local additions or stricter rules for an upstream skill in
  `.agents/overrides/` rather than editing a copied upstream skill.
- Read the target skill's `SKILL.md` before executing it, then read any overlay
  named by `AGENTS.md`.
- When using `fireworks-tech-graph`, read
  `.agents/overrides/fireworks-tech-graph/layout.md`.

## Entry points

- `.claude/CLAUDE.md` is a symlink to the canonical root `AGENTS.md`.
- `.claude/skills` points to `.agents/skills`.
- Platform-specific agent wrappers should route to a canonical local skill and
  must not duplicate its workflow.
