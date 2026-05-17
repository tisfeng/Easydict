# AGENTS.md

Guidance for AI agents working in this repository.

## Project Overview

**Easydict** is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation.

**Note:** New development should use modern Swift and SwiftUI APIs available on macOS 13.0+.

## Code Architecture

### Directory Structure

```
Easydict/
├── Easydict/                             # App source root
│   ├── App/                              # App entry, bridge, plist, assets, localization
│   │   ├── PrefixHeader.pch              # Shared Objective-C precompiled header
│   │   ├── Easydict-Bridging-Header.h    # Swift and Objective-C bridge declarations
│   │   └── ...                           # Other app entry, plist, and localization files
│   │
│   ├── Swift/                            # Primary development environment
│   │   ├── Feature/                      # Product feature modules
│   │   │   ├── Screenshot/               # Screenshot feature
│   │   │   ├── ActionManager/            # Action routing and execution
│   │   │   ├── Configuration/            # Runtime configuration features
│   │   │   ├── DefaultAPIKeys/           # Built-in service key configuration
│   │   │   ├── HTTPServer/               # Local HTTP server support
│   │   │   ├── Localization/             # Localization helpers and tooling
│   │   │   └── Shortcut/                 # Keyboard shortcut model and UI
│   │   │
│   │   ├── Model/                        # Shared app data models
│   │   ├── Service/                      # Translation, dictionary, OCR, and AI services
│   │   │   ├── Model/                    # Shared service request and response models
│   │   │   ├── Dictionary/               # Local dictionary and rendering services
│   │   │   ├── OpenAI/                   # OpenAI-compatible service integration
│   │   │   ├── Apple/                    # Apple dictionary, OCR, speech, and translation
│   │   │   ├── ClaudeCode/               # Claude Code CLI service integration
│   │   │   └── ...                       # Other provider-specific services
│   │   │
│   │   ├── Utility/                      # Cross-feature utilities and helpers
│   │   │   ├── Appearance/               # App appearance helpers
│   │   │   ├── AppleScript/              # AppleScript execution utilities
│   │   │   ├── EventMonitor/             # Global event monitoring and workflows
│   │   │   ├── Extensions/               # Swift, AppKit, SwiftUI, Foundation extensions
│   │   │   └── Views/                    # Shared utility views
│   │   │
│   │   └── View/                         # Shared SwiftUI and AppKit-facing views
│   │
│   └── objc/                             # Legacy code - maintenance only
│       ├── Libraries/                    # Bundled legacy helper libraries
│       ├── StatusItem/                   # Legacy menu bar status item code
│       ├── Utility/                      # Legacy helper categories and utilities
│       └── ViewController/               # Legacy window and query controllers
│
├── EasydictTests/                        # Unit tests
└── Pods/                                 # CocoaPods dependencies and integration project
```

## Xcode Project Metadata

Unless the user explicitly says otherwise, when adding or moving files, also update `Easydict.xcodeproj/project.pbxproj` so the files appear in Xcode's navigator.

- By default, every newly added project file, including developer-facing
  documentation such as Markdown or HTML files, must have a matching
  `PBXFileReference` under the correct `PBXGroup`.
- Do not add documentation files to build phases such as `Resources` unless the file is
  intentionally shipped at runtime.

## Build Commands

Run `xcodebuild` only when:

- The substantive code changes exceed 100 lines. Documentation comment-only edits do not
  count toward this threshold.
- The user explicitly asks for a build or test run.
- The task runs `/code-simplifier`.

Do not run multiple `xcodebuild` commands concurrently against the same workspace and DerivedData location. Concurrent runs can contend for the shared build database, intermediates, and test bundles, which leads to flaky conflicts.

`xcodebuild` may take several minutes. Wait for it to finish.

If the default Xcode DerivedData location fails because of permission, cache, or
runner state, use an external DerivedData directory instead of a repo-local one:

`-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Codex`

After the build or test completes, remove that DerivedData directory before
finishing the task.

Common build and test commands:

```bash

# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Test (builds and runs a test in one command)
xcodebuild test \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify

# Build for testing
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# e.g. run specific test class, -only-testing:<Target>/<TestClass>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify

# e.g. run specific test method, -only-testing:<Target>/<TestClass>/<testMethod>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify
```

Recommended usage:

- `build`: default validation after code changes.
- `test`: simplest one-shot test run; builds and runs tests in one command.
- `build-for-testing` + `test-without-building`: preferred when rerunning the same tests
  repeatedly.
- `test-without-building` requires a compatible prior `build-for-testing` with the same
  workspace, scheme, destination, configuration, and DerivedData location.
- If code or build settings changed, rerun `build-for-testing` before
  `test-without-building`.
- Prefer `-only-testing:` when debugging a specific test class or method.

## Coding Standards

### Core Rules

- Write new code in Swift/SwiftUI only. Legacy Objective-C may receive bug fixes, but no
  new features.
- Keep main project Swift and SwiftUI source files ideally under 300 lines and
  never over 500 without strong justification. This line-count guideline does
  not apply to bundled runtime extensions, scripts, generated files, or other
  non-Swift support modules.
- Avoid single-letter variable names except trivial loop indices.
- Avoid `static` functions and variables unless type-level semantics clearly require them.
  Utility types may use `static`.
- Do not extract one-off literals into variables or constants unless they are reused or
  have clear semantic meaning. Name a one-off constant only when a magic number has
  distinctive visual or domain meaning.
- Prefer `for … where` over `for` plus inline `if` filtering.
- Prefer async/await over callback-based completion handlers for new async work.

### Documentation Rules

- Add a type-level comment immediately before every class, struct, enum, protocol, and
  actor. For core types, use 2-4 short sentences and keep the comment around 220-320
  English characters. For simple private helper types, use 1-2 short sentences and keep
  it under 180 characters.
- Keep comment lines within 80 characters, avoid restating obvious type or property
  names, and update comments whenever responsibilities or behavior change.
- Add English documentation comments for functions when behavior or intent is not obvious.
  Use inline comments only for non-obvious reasoning or complex logic.
- In Markdown documentation, keep normal prose as natural paragraphs. Hard-wrap only list
  items, keep them within 90 characters when practical, and preserve continuation
  indentation.
- When creating or updating source file header comments, use the current Git username in
  the `Created by ...` line. Do not use agent names such as `Codex`, `Claude`, or
  `AI Assistant`.
- Every non-exempt project source directory must include a Chinese HTML overview document
  and a same-prefix SVG technical diagram. Use the directory name converted to kebab-case
  as the shared prefix: `<directory-kebab>-overview.html` and
  `<directory-kebab>-<diagram-type>.svg`.
- Generated directories, third-party directories, platform scaffold directories, and test
  directories are exempt from the overview/SVG requirement.
- Convert `UpperCamelCase` names to kebab-case, convert spaces to hyphens, and keep names
  that are already kebab-case unchanged. For example, `DictionaryRendering/` uses
  `dictionary-rendering-overview.html` and `dictionary-rendering-architecture.svg`, while
  `GitHub Models/` uses `github-models-overview.html` and
  `github-models-architecture.svg`.
- Use a kebab-case diagram type that reflects the SVG content, such as `architecture`,
  `flow`, or `sequence`. Reuse the same directory prefix for the HTML overview document
  and its SVG so related files stay adjacent in search and Xcode.
- Generate each directory's SVG technical diagram from the complete semantic structure of
  the matching HTML overview document with the `fireworks-tech-graph` skill. Do not base
  the diagram only on the title, opening paragraph, or a few keywords; it must represent
  the responsibilities, key components, main flows, boundaries, failures, and debugging or
  test entry points described by the overview.
- When files in a directory are added, removed, renamed, or their behavior changes, update
  that directory's HTML overview document and same-prefix SVG technical diagram in the
  same change. Explain responsibilities, key components, main flows, and debugging entry
  points instead of writing a method-by-method API index.

### Skill Overlay Rules

- `.agents/overrides/` stores repo-level agent rules that are not bundled into runtime
  skills. Runtime skill-specific overlays should live inside the target skill directory.
- When using `fireworks-tech-graph`, read
  `.agents/overrides/fireworks-tech-graph-layout-rules.md` after the skill and apply the
  stricter project-level layout, connector, label, export, and rendered-review rules.
- If the base skill conflicts with its overlay, keep the stricter project-level overlay
  rule instead of editing only the upstream skill mirror.

### Naming Rules

- Use `UpperCamelCase` for directories and files that are compiled by Xcode, including
  Swift, Objective-C, and test source files.
- Use `kebab-case` for directories and files that are not compiled by Xcode, including
  app-managed runtime paths under `Application Support/<bundle>`, scripts, and exported
  artifacts.
- For new or renamed classes, structs, enums, protocols, actors, properties, parameters,
  and local variables, prefer clear, concise names, remove repeated surrounding context,
  and usually keep them within 25 characters.
- If a longer name is required by a system API, external protocol, or unavoidable domain
  term, keep it as short as possible and treat it as an exception.

### Testing Rules

- Each test source file may declare at most one `@Suite` type.
- Do not add tests for UI code or UI-focused changes.
- Add or update tests only for changes with meaningful behavior or correctness risk. Skip
  trivial pass-through code, simple glue code, obvious accessors, and behavior already
  covered elsewhere, and run the relevant tests.
- Prefer concrete production code and high-signal behavior assertions. Do not add
  test-only protocols, mocks, overrides, or invasive production hooks for low-value
  tests.

### Libraries and API Usage

- Use **SFSafeSymbols** type-safe APIs instead of hard-coded SF Symbol strings.
- Prefer `Image(systemSymbol: .chevronRight)` over `Image(systemName: "chevron.right")`.
- Prefer `Label("MyText", systemSymbol: .cCircle)` over
  `Label("MyText", systemImage: "c.circle")`.
- In SwiftUI, use `foregroundStyle<S>(_ style: S)` instead of deprecated
  `foregroundColor(_:)`.
- In SwiftUI, use `background(alignment:content:)` or trailing-closure
  `background { ... }` for background views instead of deprecated
  `background(_:alignment:)`. Keep `Color` and material `ShapeStyle` backgrounds on their
  dedicated overloads.
- Use `Alamofire` async/await APIs for network requests.
- Use `Defaults` for user preferences and settings; avoid introducing new direct
  `UserDefaults` usage.

## Localization

- All user-facing UI text must be localized. Do not hard-code visible strings in SwiftUI
  or AppKit.
- Use static String Catalog keys directly in UI and string APIs, for example
  `Text("setting.general.appearance.light_dark_appearance")`.
- Do not build localization keys dynamically or concatenate localized fragments. For text
  with runtime values, localize the full sentence with a dedicated entry and pass the
  values as arguments.
- Use lowercase, dot-separated keys with snake_case segments where needed, and do not
  rename keys casually. Follow `<scope>.<category>.<subcategory>.<element>`, for example
  `common.done` or `setting.general.appearance.light_dark_appearance`.
- `Localizable.xcstrings` manages app string localization. Whenever localized strings are
  added or changed, update the corresponding entries in this file and keep every supported
  language in sync.

## MCP Servers

Always use the OpenAI developer documentation MCP server if you need to work with the OpenAI API, ChatGPT Apps SDK, Codex,… without me having to explicitly ask.
