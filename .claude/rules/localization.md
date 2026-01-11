# Localization Rules

## General Principles

- All user-facing UI text MUST be localized. Do not hard-code visible strings in SwiftUI/AppKit.
- For all localized keys, must update `Localizable.xcstrings` with translations for all supported languages.
- UI strings MUST use String Catalog keys directly, using this format:

  - `Text("setting.general.appearance.light_dark_appearance")`
  - The same rule applies to `Button("…")`, `Toggle("…", isOn: …)`, etc.

## Localization Key Naming Rules

- Lowercase.
- Dot-separated hierarchical path.
- Use snake_case for each segment when needed.
- No spaces, no uppercase letters.
- Keys should be stable (do not rename keys casually).

### Key Structure

Keys should follow a hierarchical structure from general to specific:

```
<scope>.<category>.<subcategory>.<element>
```

**Examples:**

- `common.done` - Common/shared strings
- `setting.general.language` - Settings → General → Language
- `setting.general.appearance.light_dark_appearance` - Settings → General → Appearance → Light/Dark Appearance
- `setting.general.startup_and_update.header` - Settings → General → Startup and Update → Header

**Naming conventions:**

- **First level (scope)**: Feature module or functional area

  - `common.` - Shared strings used across the app
  - `setting.` - Settings-related strings
  - `main.` - Main window/feature
  - `ocr.` - OCR feature
  - etc.

- **Middle levels**: Subcategories or hierarchical navigation

  - Follow the app's UI hierarchy
  - Use descriptive names that reflect the structure

- **Last level**: Specific UI element or text content
  - Describe what the text represents (e.g., `header`, `title`, `description`, `button_label`)
  - Or the actual semantic meaning (e.g., `done`, `cancel`, `language`)

## Preferred APIs (macOS 13.0+)

- SwiftUI: `Text("<key>")` (uses `LocalizedStringKey`).
- Non-SwiftUI / when a `String` is required: `String(localized: "<key>")`.

## Dynamic Values

- Do not build keys dynamically.
- For values inside a localized sentence, use a dedicated localized format string key and pass arguments via `String(localized:)` (avoid string concatenation).

## Source of Truth

- All keys and translations live in `Easydict/App/Localizable.xcstrings`.

## Adding New Keys

- Any newly introduced localization key MUST be added to `Easydict/App/Localizable.xcstrings` and have translations filled for all languages supported by the project.
