# AGENTS.md

Easydict is a macOS dictionary and translation app with word lookup, text
translation, selection translation, and OCR screenshot translation.

`AGENTS.md` is the agent entry point, not the repository rulebook. The durable
rules live under `docs/agents/`; public English and Chinese documentation lives
under `docs/user-docs/`.

## Start here

- Read `docs/agents/repository-guide.md` for every task.
- Read `docs/agents/README.md` to route to task-specific rules.
- Read `docs/architecture/overview.md` when changing product code or module
  boundaries.

## Route by task

- Build or test: `docs/agents/build-and-test.md` and
  `docs/agents/testing.md`.
- Swift, Objective-C, SwiftUI, or Xcode: `docs/agents/swift-xcode.md`.
- User-facing text or String Catalog: `docs/agents/localization.md`.
- Skill or agent integration: `docs/agents/skills.md`, the target
  `.agents/skills/<skill>/SKILL.md`, and its
  `.agents/overrides/<skill>/<overlay>.md`.
- Multi-step, cross-module, or risky work: `docs/exec-plans/`.
- Completed material changes: `docs/histories/`.
- Public usage or contributor documentation: `docs/user-docs/en/` or
  `docs/user-docs/zh/`.

## Non-negotiable boundaries

- Preserve unrelated staged and unstaged worktree changes.
- Do not stage, commit, or push unless the task or an explicitly invoked
  workflow authorizes it.
- Repository governance Markdown, plans, histories, references, and skills do
  not need Xcode project references or build-phase entries.
- Use relative repository paths in documentation and keep behavior, tests, and
  relevant documentation synchronized.
