# Codex custom models and Fast mode

- Status: completed
- Created: 2026-10-15
- Owner: Or1a
- Issue/PR: [#1366](https://github.com/tisfeng/Easydict/pull/1366)

## Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

## Background

Users need to add compatible new model IDs and control Fast processing with ChatGPT sign-in.

## Goals and scope

- Result: verify, save, select and remove models; share a Fast switch between settings and the translation model menu.
- Paths: Codex service/runtime, settings, result menu, localization and related documentation.
- History: `docs/histories/2026-10/2026-10-15-codex-custom-models.md`
- Constraints: one combined PR; preserve account state, model/effort choices and preview preferences.
- Non-goals: component updates, credential access or imported tools and model capabilities.
- Acceptance: verify before saving, scoped cancellation, empty-list recovery and correct Fast parameters.

## Work plan

1. Verify the pinned component and implement isolated custom-model requests.
2. Integrate Fast settings, request parameters and the translation-menu control.
3. Build, validate and review the combined implementation before updating the PR.

## Risks and decisions

- Custom requests use private App Servers and explicit text-only catalogs with existing login.
- Reverify installed components and configuration before private processes start.
- Verify reasoning overrides before saving; hide built-in entries without changing the runtime catalog.
- Both Fast controls share the existing per-service preference; changes invalidate only that service's managed requests.
- Preserve the dev branch's Copilot model menu and unrelated translations.
- Saved models and Fast processing remain subject to account access and component compatibility.

## Progress

- [x] Implement and preview custom-model management and the native input field.
- [x] Integrate Fast across built-in/custom translation and verification paths.
- [x] Validate shared controls, request tiers, cancellation and model-list recovery.
- [x] Review final changes; updating the combined PR and retiring the standalone PR are authorized.

- [x] Verify and fix custom Fast tier admission on component 0.153.4.
- [x] Repair automatic selection after empty-list recovery; build and review.

- [x] Include reasoning compatibility in recovery selection and revalidate.

## Validation

- Combined build succeeded; 33 existing tests in four suites passed.
- Four local transport cases confirmed priority/default parameters for built-in and custom profiles, preserving model and effort.
- Local checks confirmed shared Fast controls, scoped invalidation and no managed Fast menu in local CLI mode.
- Eight model removal/restoration cases passed against the combined build, preserving Fast.
- Review follow-up: 0.153.4 accepted custom priority/default tiers after the fix; fourteen local selection checks passed, including unsupported saved efforts, and 33 existing tests passed again.
- Earlier isolated cache checks rejected changed components/configuration; native preview input checks passed.
- Full account/runtime suites were not repeated after the earlier fixture-copy stall. Validation tools remain local.
- SwiftFormat, six-locale coverage, JSON and diff checks passed.

## Completion

The combined PR is published. Review follow-up fixes are validated locally for user review before pushing.
