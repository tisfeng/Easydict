# Localization

- All user-facing UI text must be localized. Do not hard-code visible strings
  in SwiftUI, AppKit, scripts, or bundled web assets.
- `Localizable.xcstrings` is the app's primary string catalog. When a key is
  added or its meaning changes, inspect the catalog locales and update every
  affected locale.
- Prefer static String Catalog keys directly in UI and string APIs.
- Do not build localization keys dynamically or concatenate localized
  fragments. Localize the complete sentence and pass runtime values as
  arguments.
- Use lowercase, dot-separated keys with snake_case segments, following
  `<scope>.<category>.<subcategory>.<element>`.
- Public localization-contributor instructions live in
  `docs/user-docs/en/How-to-translate-Easydict.md` and its Chinese counterpart.
