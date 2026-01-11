# Core Coding Rules

## General Requirements

- Add documentation comments in English for every class, struct, and function.

## Language Requirements

- New code must be written in Swift/SwiftUI only; do not add Objective-C files.
- Legacy Objective-C code may receive bug fixes but no new features.
- Prefer modern Swift and SwiftUI APIs available on macOS 13.0+.

## Style Guidelines

- Keep individual source files ideally under 300 lines; never exceed 500 unless justified.
- Avoid single-letter variable names; use descriptive identifiers (loop indices are the rare exception).
- Prefer `for … where` over `for` plus inline `if` filtering.
- Prefer async/await over callback-based completion handlers for new async work.

## Localization

- All user-facing UI text MUST be localized. Do not hard-code visible strings in SwiftUI/AppKit.

- UI strings MUST use String Catalog keys directly, using this format:

  - `Text("setting.general.appearance.light_dark_appearance")`
  - The same rule applies to `Button("…")`, `Label("…", systemImage: …)`, `Toggle("…", isOn: …)`, etc.

- Localization keys MUST follow these naming rules:

  - Lowercase.
  - Dot-separated hierarchical path.
  - Use snake_case for each segment when needed.
  - No spaces, no uppercase letters.
  - Keys should be stable (do not rename keys casually).

- Preferred APIs (macOS 13.0+):

  - SwiftUI: `Text("<key>")` (uses `LocalizedStringKey`).
  - Non-SwiftUI / when a `String` is required: `String(localized: "<key>")`.

- Dynamic values:

  - Do not build keys dynamically.
  - For values inside a localized sentence, use a dedicated localized format string key and pass arguments via `String(localized:)` (avoid string concatenation).

- Source of truth:

  - All keys and translations live in `Scoco/App/Localizable.xcstrings`.

- When adding new keys:
  - Any newly introduced localization key MUST be added to `Scoco/App/Localizable.xcstrings` and have translations filled for all languages supported by the project.
