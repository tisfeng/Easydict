## 2026-10-17 | Add verified Codex custom models

**Links:** [Plan](../../exec-plans/completed/2026-10/2026-10-15-codex-custom-models.md)

### Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

### Request

Allow new model IDs without an app release when the account and pinned component support them.
Provide an isolated preview and keep the feature separate from Fast PR #1360.

### Changes

- Verify and save custom IDs; remove the typed ID; keep saved models in the normal picker.
- Verify reasoning overrides before saving; preserve the previous value on failure or cancellation.
- Add settings dividers, centered input and small red errors; remove the recovery button and manual-status text.
- Update six locales and user documentation. The local preview also retains Fast and its translation-menu toggle.

### Design

Custom requests use a private App Server and a text-only catalog with existing official login.
No credential copying or inferred model capabilities. Future protocol changes may require an update.

### Validation

- Existing tests: 63 passed; 25 related tests passed after the final logic change. Final UI build succeeded.
- gpt-6.1-sol: Low/Max requests succeeded; High was saved in the preview.
- UI: invalid ID rejected without saving; typed removal and re-addition worked; same-model selection kept High.
- Diff checks, six-locale coverage and both patches' application to 2.23.0 passed.
- Preview build 2026101706 preserves login, service lists and gpt-6.1-sol / High / Fast on. Release app unchanged.

### Affected files

- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexCLIServiceConfigurationView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict/objc/ViewController/View/ResultView/EZResultView.m` (combined preview only)
- `docs/user-docs/en/GUIDE.md`, `docs/user-docs/zh/GUIDE.md`, `scripts/codex-runtime/README.md`

### Follow-up

User approved publication on 2026-10-17. The custom-only branch passed all 63 existing Codex tests.
Local scripted-transport probes against its compiled app confirmed rejection/cancellation preserve model
and effort. Validation tools remain local. Final centering compiled; visual signoff remains with the user.
