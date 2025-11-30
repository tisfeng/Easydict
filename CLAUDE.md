# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Please use Simplified Chinese to communicate with me, and use English for code comments.**

## Project Overview

Easydict is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation. The project is currently **actively migrating from Objective-C to Swift + SwiftUI**.

**IMPORTANT:** We are in an active migration phase. **Prohibit adding any new Objective-C files**. All new code must be implemented using Swift/SwiftUI.

## Build Commands

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Build from command line
xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict

# Run all tests (May cost much time)
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict 

# Run specific test class
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/UtilityFunctionsTests

# Run specific test method
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/UtilityFunctionsTests/testAES
```

**Requirements:** Xcode 15+ (for String Catalog support), macOS 13.0+

## Code Quality & Formatting

The project integrates SwiftLint and SwiftFormat to maintain code quality and consistency:

- SwiftLint: Static analysis tool based on Google Swift Style Guide
- SwiftFormat: Automatic code formatter compliant with Google Swift guidelines
- 
Usage
Both tools are integrated into Xcode build phases - no manual execution required:
```
# Code quality checks and formatting run automatically during build
xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict
```

### Configuration

- swiftlint.yml - SwiftLint rules and exceptions
- swiftformat - SwiftFormat formatting behavior

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

### Obj-C to Swift Migration

The project follows a phased migration plan (see `MIGRATION_PROGRESS.md`):
- AI services: 100% complete
- Translation services: ~46% complete (Google, Bing, Youdao, DeepL, NiuTrans migrated)
- Core infrastructure: ~50% complete

**Migration Rules:**
- **Must migrate to Swift before modifying Objective-C code**
- All new functionality MUST be implemented in Swift/SwiftUI
- Objective-C code only allows bug fixes, feature extensions are prohibited
- When modifying existing Obj-C code, evaluate migration feasibility first

### Service Architecture

Translation services inherit from a base query service. Each service lives in its own directory under `Swift/Service/` with:
- Main service class (e.g., `GoogleService.swift`)
- Supporting models and extensions as needed

### Key Patterns

- CocoaPods for dependency management (AFNetworking, Masonry, ReactiveObjC, etc.)
- Bridging header at `Easydict/App/Easydict-Bridging-Header.h`
- String localization uses Xcode String Catalogs (`.xcstrings` files)
- URL Scheme support: `easydict://query?text=xxx`

## Code Contribution Iron Rules

**MANDATORY REQUIREMENTS FOR ALL CONTRIBUTORS:**

1. **Prohibit adding any new Objective-C files** (.m, .h files)
2. All new code MUST be implemented using Swift/SwiftUI
3. Swift/SwiftUI is the only future tech stack for this project
4. Must migrate to Swift before modifying existing Objective-C code
5. Objective-C legacy code: bug fixes only, no feature extensions
6. Any pull request adding new Objective-C code will be rejected

## Commit Style

Follow Angular Conventional Commit format:
```
<type>(<scope>): <description>

[optional body]
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`

For Obj-C to Swift migrations, use: `refactor(objc-to-swift): migrate <Component> to Swift`

## Development Notes

- Use `Easydict-debug.xcconfig` for local development team configuration (git-ignored)
- To ignore local changes to xcconfig: `git update-index --skip-worktree Easydict-debug.xcconfig`
- The app uses private APIs, so it cannot be published to the Mac App Store
