## 2026-10-17 | Add verified Codex custom models

**Links:** [PR #1366](https://github.com/tisfeng/Easydict/pull/1366), [Plan](../../exec-plans/completed/2026-10/2026-10-15-codex-custom-models.md)

### Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

### Request

Allow compatible new model IDs without an app release. Keep the feature separate from Fast PR #1360 and provide an independent preview.

### Changes

- Verify custom IDs before saving; verify reasoning overrides before applying them.
- Remove entries with an X inside the model list. Built-in entries are hidden and can be restored through Add and Verify.
- Preserve unrelated selections; choose a remaining model when removing the active entry and recover from an empty list through addition.
- Use a centered AppKit model ID field, settings dividers and small inline errors.
- Reverify the installed runtime before each private custom-model process starts.
- Update six locales and user guides. The combined local preview retains Fast and its translation-menu toggle.

### Design

Private App Servers use an explicit text-only catalog and existing official login. Cached verification cannot authorize a new custom process. No credential copying or inferred tool capabilities; future protocols may require an update.

### Validation

- Final builds succeeded; 33 existing tests in four suites passed.
- The full regression rerun stalled in existing fixture file copying and was interrupted. All 63 tests passed on the preceding model-list snapshot, before the final editor and runtime changes.
- Eight final compiled-app removal/restoration cases passed, preserving Fast. A separate isolated probe rejected component/configuration changes after warming the runtime cache.
- Preview 2026101709: repeated-letter input, backspace, paste and Return verification passed. The original physical-keyboard duplication cause was not established.
- Earlier live gpt-6.1-sol Low/Max requests succeeded; High was verified and saved. Static checks and six-locale coverage passed.

### Affected files

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/en/GUIDE.md`, `docs/user-docs/zh/GUIDE.md`, `scripts/codex-runtime/README.md`

### Follow-up

User approved updating PR #1366. Validation tools remain local. The complete test rerun remains limited by fixture copying; saved models still depend on account access and component compatibility.
