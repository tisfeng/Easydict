# Codex custom models

- Status: completed
- Created: 2026-10-15
- Owner: Or1a
- Issue: None

## Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

## Background

The bundled catalog cannot expose new models without an app update.

## Goals and scope

- Result: save verified custom IDs in the managed Codex model picker on macOS 15+.
- Paths: Codex service/runtime, settings, localization and related documentation.
- History: `docs/histories/2026-10/2026-10-15-codex-custom-models.md`
- Constraints: separate from Fast PR #1360; preserve the release app and settings; no commit or PR before approval.
- Non-goals: component updates, token access, imported tools or model capabilities.
- Acceptance: exact model ID, successful translation before saving, scoped cancellation and usable recovery.

## Work plan

1. Check the pinned component and existing draft.
2. Implement isolated requests, verification, model storage and settings.
3. Validate and install a separate 2.23.0 preview; provide separate review patches.

## Risks and decisions

- Use a private App Server with an explicit text-only catalog; retain official authentication.
- Verify custom reasoning overrides before saving. Exclude Ultra because the component rewrites it.
- Model availability and future protocol compatibility are not guaranteed by a saved entry.

## Progress

- [x] Implementation, localization, review and local preview delivered.
- [x] Typed-ID removal, centered input, inline errors and requested text removal completed.

## Validation

- 63 existing Codex tests passed; 25 related tests passed after the same-model selection fix.
- gpt-6.1-sol Low/Max requests succeeded; High was saved after in-app verification.
- UI: rejected candidates stay unsaved, typed removal preserves another selection, reselecting keeps High.
- Build 2026101706 preserves login, service lists and the user's model/effort/Fast settings.
- Final centering compiled. Local probes against the compiled custom-only app confirmed rejection/cancellation preserve model and effort.

## Completion

Review patches and preview are ready. User approved publication on 2026-10-17; publish a separate custom-model PR.
