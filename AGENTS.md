# AGENTS.md

Guidance for AI agents working in this repository.

## Project Rules

Project-specific context, repository layout, build commands, and local operating rules.

### Project Overview

Easydict is a macOS dictionary and translation app that supports word lookup, text
translation, and OCR screenshot translation.

### Platform and Language

- Supports macOS 13.0+.
- Uses SwiftUI for all new UI components and views.

### Directory Structure

```
Easydict/
├── Easydict/                         # App source root
│   ├── App/                       # App entry, pch, bridge, plist, assets, localization
│   │
│   ├── Swift/                     # Swift source root
│   │   ├── Feature/               # Product feature modules
│   │   │   ├── ActionManager/     # Action routing and execution
│   │   │   ├── Screenshot/        # Screenshot feature
│   │   │   ├── Shortcut/          # Keyboard shortcut model and UI
│   │   │   └── ...                # Other product features
│   │   │
│   │   ├── Service/               # Translation and AI provider implementations
│   │   │   ├── Model/             # Service request and response models
│   │   │   ├── Google/            # Google translation service
│   │   │   ├── OpenAI/            # OpenAI-compatible service integration
│   │   │   └── ...                # Other translation and AI services
│   │   │
│   │   ├── Model/                 # Shared app data models
│   │   ├── Utility/               # Cross-feature utilities and helpers
│   │   │   ├── EventMonitor/      # Global event monitoring and triggers
│   │   │   ├── Extensions/        # Swift, AppKit, SwiftUI, Foundation extensions
│   │   │   └── ...                # Other shared utilities
│   │   │
│   │   └── View/                  # Shared SwiftUI and AppKit-facing views
│   │
│   └── objc/                      # Legacy code - maintenance only
│       ├── Libraries/             # Bundled legacy helper libraries
│       ├── Utility/               # Legacy helper categories and utilities
│       └── ViewController/        # Legacy window and query controllers
│
├── EasydictTests/                    # Unit tests
└── Pods/                          # CocoaPods dependencies and integration project
```

### Build and Test Commands

Run `xcodebuild` only when:

- Swift, Objective-C, or other Xcode-compiled app source changes exceed 100
  substantive lines. Xcode project/workspace metadata, documentation, scripts,
  and comment-only edits do not count toward this trigger.
- Unit test source files under `EasydictTests/**/*.swift` are added or changed.
- The user explicitly asks for a build or test run.

Evaluate the 100-line trigger only after implementation is complete. Use the final
task-owned diff, count added and deleted substantive lines together instead of using
an estimate or net line count, exclude blank lines and unrelated pre-existing changes,
and recalculate before finishing if the implementation changes again.

Do not run multiple `xcodebuild` commands concurrently against the same workspace and
DerivedData location. Concurrent runs can contend for the shared build database,
intermediates, and test bundles, which leads to flaky conflicts.

`xcodebuild` may take several minutes. Wait for it to finish.

If the default Xcode DerivedData location fails because of permission, cache, or runner
state, use an temporary external DerivedData directory instead of a repo-local one:

`-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Temporary`

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

- `build`: default validation when `xcodebuild` validation is required.
- `test`: simplest one-shot test run; builds and runs tests in one command.
- When unit test source files change, use `xcodebuild test` for the first validation.
  Scope it with `-only-testing:<Target>/<TestSuiteOrClass>` for the changed test when
  possible; if the mapping is unclear, run the relevant broader test target or suite.
- `build-for-testing` + `test-without-building`: preferred when rerunning the same tests
  repeatedly.
- `test-without-building` requires a compatible prior `build-for-testing` with the same
  workspace, scheme, destination, configuration, and DerivedData location.
- If code or build settings changed, rerun `build-for-testing` before
  `test-without-building`.
- Prefer `-only-testing:` when debugging a specific test class or method.

### Localization

- All user-facing UI text must be localized. Do not hard-code visible strings in SwiftUI,
  AppKit, scripts, or bundled web assets that users can see.
- `Localizable.xcstrings` manages app string localization. Whenever user-facing text is
  added or its meaning changes, enumerate the catalog's current locales and update every
  one for the affected key instead of copying nearby entries.
- Use static String Catalog keys directly in UI and string APIs when possible, for example
  `Text("setting.general.appearance.light_dark_appearance")`.
- Do not build localization keys dynamically or concatenate localized fragments. For text
  with runtime values, localize the full sentence with a dedicated entry and pass the
  values as arguments.
- Use lowercase, dot-separated keys with snake_case segments where needed, and do not
  rename keys casually. Follow `<scope>.<category>.<subcategory>.<element>`, for example
  `common.done` or `setting.general.appearance.light_dark_appearance`.

## Cross-Language Code Quality Rules

These rules apply to handwritten Swift, Python, Shell, JavaScript/TypeScript, and other
source files in this repository.

### Source Organization Rules

- Organize source directories by feature or bounded responsibility once an area grows
  beyond a few files. Keep feature-specific UI, core, state, storage, services,
  utilities, and docs together.
- Keep source files focused on one clear responsibility. Prefer extracting a helper,
  module, or sibling script when a file starts mixing unrelated parsing, UI, I/O,
  orchestration, and validation concerns.
- Handwritten source files should generally stay within 500 lines. Files approaching or
  exceeding this size should be reviewed for a responsibility split before adding more
  behavior.
- Handwritten source files should not exceed 1000 lines. Existing files over this limit
  are technical debt; do not add new complex flows to them without first splitting the
  file or documenting a concrete split plan.
- Generated files, third-party code, pure data files, templates, large fixtures, and
  intentionally vendored runtime files are exempt from the line-count guideline.
- Use the language's normal section markers in longer files to group lifecycle, state
  updates, command handling, I/O, parsing, and private helpers. Do not add a section
  marker for a single isolated function unless it materially improves navigation.

### Naming Rules

- Use each language and toolchain's normal naming conventions for compiled or imported
  source files, modules, types, functions, and tests.
- Use kebab-case for non-imported documentation, exported artifacts, app-managed runtime
  paths, and standalone scripts unless surrounding tooling already requires another
  style.
- For new or renamed types, functions, properties, parameters, and local variables,
  prefer clear, concise names, remove repeated surrounding context, and usually keep
  them within 20 characters.
- If a longer name is required by a system API, external protocol, or unavoidable domain
  term, keep it as short as possible and treat it as an exception.

### Coding Practices

- Avoid single-letter variable names except trivial loop indices.
- Avoid global helpers, static or type-level functions, and mutable globals unless the
  language, module, or domain model clearly requires them. Utility modules and types may
  expose type-level helpers when that is their main responsibility.
- Do not extract one-off literals into variables or constants unless they are reused or
  have clear semantic meaning. Name a one-off constant only when a magic number has
  distinctive visual or domain meaning.
- Prefer async/await over callback-based completion handlers in languages and runtimes
  where async/await is the established option.

### Documentation Comment Rules

- Add file-level comments for non-trivial scripts or modules so readers know the entry
  point, responsibility, and important side effects.
- Add short documentation comments for complex functions, command entry points, state
  machines, parsers, I/O boundaries, and recovery/error-handling logic. Do not add
  mechanical comments for obvious getters, path helpers, or thin wrappers.
- Keep comment lines within 80 characters, avoid restating obvious type or property
  names, and update comments whenever responsibilities or behavior change.
- Use the language's normal comment style: Swift documentation comments, Python
  docstrings, Shell comments before functions, and JSDoc/TSDoc where appropriate.
- When creating or updating source file header comments, use the current Git username in
  the `Created by ...` line. Do not use agent names such as `Codex`, `Claude`, or
  `AI Assistant`.

### Test Code Rules

- Do not use the same agent session to both modify production code and add unit tests.
- Prefer assigning unit tests to a different agent from the implementation agent, for
  example Codex for production code and Claude Code for unit tests.
- Do not add tests for UI code or UI-focused changes.
- Add or update tests only for changes with meaningful behavior or correctness risk. Skip
  trivial pass-through code, simple glue code, obvious accessors, and behavior already
  covered elsewhere, and run the relevant tests.
- Prefer concrete production code and high-signal behavior assertions. Do not add
  test-only protocols, mocks, overrides, or invasive production hooks for low-value
  tests.

## Swift-Xcode Rules

Reusable Swift and Xcode rules for source organization, documentation, testing, and APIs.

### Xcode Project Metadata

Unless the user explicitly says otherwise, when adding or moving files, also update the
owning `.xcodeproj/project.pbxproj` file so the files appear in Xcode's navigator.

- By default, every newly added project file, including developer-facing documentation
  such as Markdown, HTML or SVG files, must have a matching `PBXFileReference` under the
  correct `PBXGroup`.
- Do not add documentation files to build phases such as `Resources` unless the file is
  intentionally shipped at runtime.

### Swift Source Organization Rules

- Keep each Swift source file focused on one primary `class` or `struct`. Multiple
  declarations are acceptable only for tightly coupled protocols, simple pure data
  models, small private helper types, or extensions and conformance blocks that directly
  support the primary type.
- Group functions that implement the same `protocol` together instead of scattering them
  across a type.
- Mark each protocol implementation block with `// MARK: - <ProtocolName>` or an equally
  clear section title, such as `// MARK: - WCSessionDelegate`.
- Use `// MARK:` sections in longer classes and structs to organize lifecycle, state
  updates, protocol implementations, and private helpers. Do not add a `MARK` only for a
  single isolated function unless it materially improves navigation.

### Swift Naming Rules

- Use `UpperCamelCase` for directories and files that are compiled by Xcode, including
  Swift, Objective-C, and test source files.

### Swift Coding Practices

- Avoid `static` functions and variables unless type-level semantics clearly require them.
  Utility types may use `static`.
- Prefer `for … where` over `for` plus inline `if` filtering.

### Swift Documentation Comment Rules

- Add a type-level comment immediately before every class, struct, enum, protocol, and
  actor. For core types, use 2-4 short sentences and keep the comment around 220-320
  English characters. For simple private helper types, use 1-2 short sentences and keep
  it under 180 characters.
- Add English documentation comments for functions when behavior or intent is not obvious.
  Use inline comments only for non-obvious reasoning or complex logic.

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

### Swift Test Code Rules

- Each test source file may declare at most one `@Suite` type.

## General Agent Rules

Language-agnostic agent guidance for tool usage, local skill overlays, and working
habits.

### Skill Overlay Rules

- Store local skill overlay files in `.agents/overrides/`; use them to extend shared
  skill or tool instructions without editing the shared source.
- When using `fireworks-tech-graph`, read
  `.agents/overrides/fireworks-tech-graph-quality-rules.md` after the skill and apply its
  diagram quality, connector, label, export, and rendered-review rules.

### MCP Servers

Always use the OpenAI developer documentation MCP server if you need to work with the
OpenAI API, ChatGPT Apps SDK, Codex, or related developer tools.

### Agent Working Principles

#### Think Before Coding

- State assumptions, uncertainties, and tradeoffs before implementation.
- If requirements are unclear or have multiple plausible interpretations, ask before
  choosing. Mention simpler alternatives when they exist.

#### Simplicity First

- Implement the minimum solution that satisfies the request. Avoid speculative features,
  single-use abstractions, and unrequested configurability.
- If a solution grows beyond the real problem, simplify it before delivering.

#### Surgical Changes

- Touch only files and lines needed for the current request. Match existing style and
  avoid opportunistic refactors or comment and format churn.
- Remove only imports, variables, functions, or files made unused by the current change.
  Mention unrelated cleanup opportunities instead of doing them.

#### Goal-Driven Execution

- Translate tasks into verifiable success criteria and keep working until those criteria
  are met or a blocker is clear.
- For multi-step work, state a brief plan and validate with relevant tests, checks,
  builds, or manual inspection.
