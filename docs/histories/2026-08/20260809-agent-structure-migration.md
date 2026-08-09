## 2026-08-09 | Task: migrate agent documentation structure

**Links:** `AGENTS.md`, `docs/exec-plans/completed/2026-08-09-agent-structure-migration.md`

### User request

Separate Easydict's agent rules and documentation by responsibility, and place
the existing English and Chinese public documents under a dedicated directory.

### Changes

- Moved `docs/en` and `docs/zh` to `docs/user-docs/en` and
  `docs/user-docs/zh`.
- Moved the selection-flow diagram to `docs/architecture/`.
- Moved the long-term Swift migration roadmap from the repository root to
  `docs/exec-plans/active/` and repaired its lifecycle links.
- Replaced the long root `AGENTS.md` with a routing entry point and split the
  rules into `docs/agents/`.
- Added architecture, plan, history, design-document, and reference indexes.
- Added generators and a structural documentation checker.

### Design intent

Agent instructions, implementation facts, task records, and public documents
have different readers and update lifecycles. Separating them keeps the root
agent prompt short while preserving discoverable public links and a single
source of truth for repository rules.

### Validation

- `git diff --check`: passed.
- `bash -n scripts/*.sh`: passed.
- `scripts/check-agent-docs.sh`: passed.
- Local README and public-document links: checked after migration.

### Affected files

- `AGENTS.md`
- `docs/agents/`
- `docs/architecture/`
- `docs/user-docs/`
- `docs/exec-plans/`
- `docs/histories/`
- `README.md`
- `README_ZH.md`
- `scripts/`

### Follow-ups

- Keep future architecture and task history documents aligned with their
  lifecycle indexes.
