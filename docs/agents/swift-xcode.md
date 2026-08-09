# Swift and Xcode Rules

## Source organization

- Keep each Swift file focused on one primary class or struct.
- Multiple declarations are appropriate for tightly coupled protocols, simple
  data models, private helpers, or directly supporting extensions.
- Group functions for the same protocol together and mark protocol blocks with
  `// MARK: - <ProtocolName>`.
- Use `// MARK:` sections in longer types for lifecycle, state, protocol, and
  private helper groups.
- Use `UpperCamelCase` for compiled Swift, Objective-C, and test file names.

## Swift practices

- Avoid `static` functions and variables unless type-level semantics require
  them; utility types are an exception.
- Prefer `for ... where` over a loop followed by an inline filter.
- Add a type-level documentation comment before every class, struct, enum,
  protocol, and actor. Keep core type comments to 2–4 concise sentences and
  around 220–320 English characters; keep simple private helper comments below
  180 characters.
- Add English documentation comments for non-obvious functions and reasoning.

## Xcode project metadata

When adding or moving Xcode-managed source files or runtime resources, update
the owning `Easydict.xcodeproj/project.pbxproj` so the files appear in Xcode's
navigator. Repository governance docs, plans, histories, skills, references,
and public Markdown under `docs/` do not need project references. Do not add
documentation to a build phase unless it is intentionally shipped at runtime.

## Libraries and APIs

- Use SFSafeSymbols instead of hard-coded SF Symbol strings.
- Prefer `Image(systemSymbol:)` and `Label(systemSymbol:)` type-safe APIs.
- Use `foregroundStyle` instead of deprecated `foregroundColor` in SwiftUI.
- Use trailing-closure or dedicated shape-style overloads for SwiftUI
  backgrounds instead of deprecated overloads.
- Use Alamofire async/await APIs for network requests.
- Use Defaults for user preferences; do not introduce direct UserDefaults use.

## Swift test structure

- Each test source file may declare at most one `@Suite` type.
