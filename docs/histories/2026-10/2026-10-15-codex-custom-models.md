## 2026-10-17 | Add Codex custom models and Fast mode

**Links:** [PR #1366](https://github.com/tisfeng/Easydict/pull/1366), [Plan](../../exec-plans/completed/2026-10/2026-10-15-codex-custom-models.md)

### Execution context

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode 27.0 (27A5194q)`

### Request

Add compatible model IDs and Fast controls in one PR, retaining the independent preview and existing account settings.

### Changes

- Verify model IDs and reasoning overrides before saving; remove entries inside the model list and restore hidden built-ins through verification.
- Share Fast between settings and the translation model menu, preserving model and effort.
- Pass Fast through built-in/custom translation and account verification; invalidate stale requests for the affected service.
- Keep the native centered input, text-only isolation and component/configuration rechecks.
- Declare custom priority tiers and select verified additions when the previous selection is unavailable.
- Update six locales and both user guides without replacing unrelated dev-branch behavior.

### Design

Custom requests use private App Servers and existing official login. Fast selects the priority/default tier through the same request chain. Preferences remain scoped to each service; no credential copying or imported tool capabilities.

### Validation

- Combined build and 33 existing tests passed.
- Four local transport cases confirmed Fast on/off for built-in/custom profiles; shared controls and scoped invalidation passed.
- Eight model removal/restoration cases passed with Fast preserved.
- Component 0.153.4 ignored custom Fast before the tier declaration; it accepted priority/default afterward without account access or translation requests.
- Seven local selection checks passed, including stale IDs, hidden selections, failure and cancellation; valid selections and Fast were preserved.
- Earlier native preview input and runtime-cache rejection checks remain applicable. Full account/runtime suites were not repeated after the fixture-copy stall.
- SwiftFormat, six-locale coverage, JSON and diff checks passed. Validation tools remain local.

### Affected files

- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/`
- `Easydict/objc/ViewController/View/ResultView/EZResultView.m`
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/en/GUIDE.md`, `docs/user-docs/zh/GUIDE.md`

### Follow-up

Model access and Fast availability depend on the account and pinned component. The complete regression rerun remains limited by fixture copying.
