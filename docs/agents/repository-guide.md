# Repository Guide

## Purpose

Easydict is a macOS dictionary and translation app that supports word lookup,
text translation, and OCR screenshot translation. Repository knowledge should
be versioned in files so that humans and agents can reproduce the reasoning.

Match the user's language in replies. If the current request is in English,
reply in English; otherwise follow the language already used in the request.

## General principles

- If work requires the OpenAI API, ChatGPT Apps SDK, Codex, or related OpenAI
  developer tools, use the OpenAI developer documentation MCP server.
- State assumptions and success criteria before non-trivial work.
- Prefer the smallest solution that satisfies the request.
- Keep changes surgical and validate them before delivery.
- Turn recurring agent failures into documentation, tooling, or environment
  improvements instead of repeatedly expanding prompts.

## Documentation boundaries

- `AGENTS.md` routes to this directory and does not duplicate these rules.
- `docs/agents/` contains internal agent and contributor workflow knowledge.
- `docs/architecture/` records current implementation boundaries and flows.
- `docs/user-docs/` contains public English and Chinese documentation.
- `docs/exec-plans/` contains multi-step work plans.
- `docs/histories/` records completed material changes.
- Use relative paths in repository documentation; do not commit machine-local
  absolute paths.
- Update code, tests, and affected documentation in the same task when behavior
  changes.

## Git safety

- Preserve the user's existing staged and unstaged separation.
- Do not stage, commit, or push unless the task or an explicitly invoked
  workflow authorizes it.
- Do not rewrite or discard unrelated worktree changes.
- Before pushing, synchronize the target branch with the latest remote state.
- Keep commits focused on one coherent behavior or documentation change.

## Xcode project boundary

Only Xcode-managed source files, runtime resources, and documentation that is
intentionally shown in the Xcode navigator need project metadata. Agent rules,
plans, histories, references, and public Markdown under `docs/` do not need
`PBXFileReference` entries and must not be added to build phases unless they are
intentionally shipped at runtime.

## Task workflow

1. State assumptions and success criteria before making a non-trivial change.
2. For architecture, protocol, migration, or multi-round work, create an
   execution plan under `docs/exec-plans/active/`.
3. Validate with the narrowest relevant checks and record important results.
4. Move completed plans to `docs/exec-plans/completed/`.
5. Record material completed changes in `docs/histories/`.

Use the repository's existing GitHub issues and pull requests for discussion;
do not duplicate their entire conversation in a history file.
