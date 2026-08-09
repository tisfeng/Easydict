# Agent Structure Migration

**Status:** completed
**Created:** 2026-08-09
**Updated:** 2026-08-09
**Owner:** Easydict maintainers
**Links:** `AGENTS.md`, `docs/agents/`, `docs/user-docs/`

## Goal

Separate agent rules, implementation architecture, task records, and public
English/Chinese documentation while keeping repository links and contributor
entry points valid.

## Scope

- Includes moving public docs, moving the selection-flow diagram, splitting
  `AGENTS.md`, adding lifecycle templates, and adding structural validation.
- Excludes Swift/Objective-C behavior, Xcode project metadata, and release logic.

## Constraints

- Keep `.claude/CLAUDE.md` as the symlink to the canonical `AGENTS.md`.
- Do not add repository governance Markdown to the Xcode project.
- Preserve public document filenames where possible to minimize link churn.

## Milestones

- [x] Move public English and Chinese documentation under `docs/user-docs/`.
- [x] Move the selection flow under `docs/architecture/`.
- [x] Split the root agent rules into task-specific documents.
- [x] Add and validate plan/history lifecycle tooling.
- [x] Complete link, shell, and repository hygiene checks.

## Validation

- `git diff --check`
- `bash -n scripts/*.sh`
- `scripts/check-agent-docs.sh`
- Verify all README and public-document local links.

## Decision log

- 2026-08-09: Use `docs/user-docs/en|zh` to distinguish public documents from
  internal agent and architecture knowledge.
- 2026-08-09: Keep public filenames stable; update only paths and known stale
  root README references during the move.

## Progress log

- 2026-08-09: Moved public docs and created the agent rule split.
- 2026-08-09: Added generators and structure checks; local links and shell
  syntax passed. Archived this plan after completing the migration.
