# Codex custom models

- Status: completed
- Created: 2026-10-15
- Owner: Or1a
- Issue/PR: [#1366](https://github.com/tisfeng/Easydict/pull/1366)

## Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

## Background

The bundled model catalog cannot expose new IDs without an application update.

## Goals and scope

- Result: verify, save, select and remove managed Codex models on macOS 15+.
- Paths: Codex service/runtime, settings, localization and related documentation.
- History: `docs/histories/2026-10/2026-10-15-codex-custom-models.md`
- Constraints: separate from Fast PR #1360; preserve account state and preview preferences.
- Non-goals: component updates, credential access or imported tools and model capabilities.
- Acceptance: exact IDs, successful translation before saving, safe cancellation and empty-list recovery.

## Work plan

1. Verify the pinned component and existing implementation.
2. Implement isolated requests, reasoning verification and model-list controls.
3. Build an independent release-based preview, review changes and publish after approval.

## Risks and decisions

- Custom requests use a private App Server and explicit text-only catalog with existing login.
- Reverify the installed component and configuration before each private process starts, as identified in the [runtime review](https://github.com/tisfeng/Easydict/pull/1366#discussion_r4302773518).
- Verify reasoning overrides before saving; exclude Ultra because the component rewrites it.
- Hide built-in entries without changing the runtime catalog; restore through Add and Verify.
- Use an AppKit model ID field with one editing delegate and no unchanged-text rewrites.
- Saved entries do not guarantee continued account access or future protocol compatibility.

## Progress

- [x] Implement model verification, reasoning selection and six-locale UI.
- [x] Put removal controls inside the opened model list and preserve inactive selections.
- [x] Validate and install independent preview 2026101709, retaining Fast and account state.
- [x] Address the cached-runtime review finding and build both final checkouts.
- [x] Review final changes; user approved the PR update on 2026-10-17.

## Validation

- Final custom-only build and combined 2.23.0 preview build succeeded.
- Final four-suite run: 33 existing tests passed. The full seven-suite rerun stalled in existing AccountFixture file copying and was interrupted; it did not pass.
- All 63 existing tests passed on the preceding model-list snapshot before the native editor and runtime-review changes.
- Final compiled-app probes: eight removal/restoration cases passed with Fast preserved; changed component and configuration were rejected after warming the runtime cache.
- Native preview input: repeated letters, backspace, paste and Return verification passed. The original physical-keyboard duplication cause was not established.
- Earlier live gpt-6.1-sol Low/Max requests succeeded; High was verified and saved in the preview.
- SwiftFormat, six-locale coverage, catalog/project parsing and diff checks passed. Validation tools remain local.

## Completion

Implementation and review are complete. Publication of the update to existing PR #1366 is authorized.
