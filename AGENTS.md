# AGENTS.md

**Please use Simplified Chinese for all communication. All documentation and comments within the codebase must be written in English.**

This file provides guidance to Claude Code, Codex, and other AI agents when working with code in this repository.

## Project Overview

**Easydict** is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation.

The project is currently **actively migrating from Objective-C to Swift + SwiftUI**.

**Requirements:** Xcode 15+ (for String Catalog support), macOS 13.0+ (minimum supported).

**Note:** All new development should prefer modern Swift and SwiftUI APIs available on macOS 13.0+ to ensure cleaner, safer, and future‑proof code.

## Code Architecture

### Directory Structure

- `Easydict/App/` - App entry point, bridging header, assets, localization
- `Easydict/Swift/` - **Primary development environment** (all new code)
  - `Service/` - Translation services (Google, Bing, DeepL, OpenAI, etc.)
  - `Feature/` - Feature modules
  - `Model/` - Data models
  - `Utility/` - Extensions and helpers
  - `View/` - SwiftUI views
- `Easydict/objc/` - **Legacy code - Maintenance only, no extensions**
  - `Service/` - Remaining Obj-C services (Baidu, language detection)
  - `ViewController/` - Window and query view controllers
  - `MMKit/` - Utility framework
- `EasydictTests/` - Unit tests

### Service Architecture

Translation services inherit from a base query service. Each service lives in its own directory under `Swift/Service/` with:

- Main service class (e.g., `GoogleService.swift`)
- Supporting models and extensions as needed

### Key Patterns

- Swift Package Manager for almost all Swift dependencies (Alamofire, Defaults, etc.)
- CocoaPods for dependency management (AFNetworking, ReactiveObjC, etc.)
- Bridging header at `Easydict/App/Easydict-Bridging-Header.h`
- PCH file at `Easydict/App/PrefixHeader.pch`
- String localization uses Xcode String Catalogs (`Localizable.xcstrings` files)

## Build Commands

Run `xcodebuild` only when either of the following is true:

- The total number of changed lines is greater than 100.
- The user explicitly asks for a build or test run.
- The task runs `/code-simplifier`.

Do not run `xcodebuild build`, `build-for-testing`, or `test` concurrently against the same workspace and DerivedData location.

Be aware that `xcodebuild` may take several minutes to finish. If the project contains many source files or dependencies, wait patiently for the command to complete.

When adding or moving Swift files, also update `Easydict.xcodeproj/project.pbxproj`.

Common build and test commands:

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

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
- `build-for-testing` + `test-without-building`: preferred when rerunning the same tests repeatedly.
- `test-without-building` requires a compatible prior `build-for-testing` with the same workspace, scheme, destination, configuration, and DerivedData location.
- If code or build settings changed, rerun `build-for-testing` before `test-without-building`.
- Prefer `-only-testing:` when debugging a specific test class or method.

## Coding Standards

### Core Rules

- Add English documentation comments for every class, struct, and function.
- Add inline comments for key functions or complex logic when the reasoning is not obvious.
- Write new code in Swift/SwiftUI only. Legacy Objective-C may receive bug fixes, but no new features.
- Prefer modern Swift and SwiftUI APIs available on macOS 13.0+.
- Keep source files ideally under 300 lines and never over 500 without strong justification.
- Avoid single-letter variable names except trivial loop indices.
- Avoid `static` functions and variables unless type-level semantics clearly require them. Utility types may use `static`.
- Prefer `for … where` over `for` plus inline `if` filtering.
- Prefer async/await over callback-based completion handlers for new async work.

### Naming Rules

- Use `UpperCamelCase` for directories and files that are compiled by Xcode, including Swift, Objective-C, and test source files.
- Use `kebab-case` for directories and files that are not compiled by Xcode, including runtime-managed disk paths, scripts, and exported artifacts.
- Treat `AppPathManager` runtime directories under `Application Support/<bundle>` as non-compiled filesystem artifacts, so every path component defined there must use `kebab-case`.

### Testing Rules

- Each test source file may declare at most one `@Suite` type. Move shared fixtures, mocks, and helper functions into separate support files without `@Suite`.

### Libraries and API Usage

- Use **SFSafeSymbols** type-safe APIs instead of hard-coded SF Symbol strings.
- Prefer `Image(systemSymbol: .chevronRight)` over `Image(systemName: "chevron.right")`.
- Prefer `Label("MyText", systemSymbol: .cCircle)` over `Label("MyText", systemImage: "c.circle")`.
- In SwiftUI, use `foregroundStyle<S>(_ style: S)` instead of deprecated `foregroundColor(_:)`.
- In SwiftUI, use `background(alignment:content:)` or trailing-closure `background { ... }` for background views instead of deprecated `background(_:alignment:)`. Keep `Color` and material `ShapeStyle` backgrounds on their dedicated overloads.
- Use `Alamofire` async/await APIs for network requests.
- Use `Defaults` for user preferences and settings; avoid introducing new direct `UserDefaults` usage.

## Localization

### Core Rules

- All user-facing UI text must be localized. Do not hard-code visible strings in SwiftUI or AppKit.
- UI strings must use String Catalog keys directly, for example `Text("setting.general.appearance.light_dark_appearance")`. The same rule applies to `Button`, `Toggle`, and similar APIs.
- Use `Text("<key>")` in SwiftUI and `String(localized: "<key>")` when a `String` is required.
- Do not build localization keys dynamically. For interpolated values, use a dedicated localized format string and pass arguments via `String(localized:)`.

### Key Naming

- Keys must be lowercase, dot-separated, and use snake_case segments where needed.
- Do not use spaces or uppercase letters, and do not rename keys casually.
- Follow the hierarchical shape `<scope>.<category>.<subcategory>.<element>`.
- Keep names aligned with app structure and meaning:
  - `common.done`
  - `setting.general.language`
  - `setting.general.appearance.light_dark_appearance`
  - `setting.general.startup_and_update.header`
- Use the first level for the feature scope such as `common`, `setting`, or `ocr`, middle levels for UI hierarchy, and the last level for the exact element or semantic meaning.

### Source of Truth

- `Easydict/App/Localizable.xcstrings` is the single source of truth for all keys and translations. Every new localization key must be added there with translations for all supported languages.

## Git Commit Messages

See [SKILL.md](.agents/skills/git-commit/SKILL.md) for Angular-style commit message guidelines.

## MCP Servers

Always use the OpenAI developer documentation MCP server if you need to work with the OpenAI API, ChatGPT Apps SDK, Codex,… without me having to explicitly ask.
