# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Please use Simplified Chinese to communicate with me, and use English for code comments.**

## Project Overview

Easydict is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation. The project is currently undergoing a gradual migration from Objective-C to Swift/SwiftUI.

## Build Commands

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Build from command line
xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict

# Run all tests
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict 

# Run specific test class
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/UtilityFunctionsTests

# Run specific test method
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/UtilityFunctionsTests/testAES
```

**Requirements:** Xcode 15+ (for String Catalog support), macOS 13.0+

## Linting and Formatting

Configuration files: `.swiftlint.yml`, `.swiftformat`

## Code Architecture

### Directory Structure

- `Easydict/App/` - App entry point, bridging header, assets, localization
- `Easydict/Swift/` - Swift code (new development)
  - `Service/` - Translation services (Google, Bing, DeepL, OpenAI, etc.)
  - `Feature/` - Feature modules
  - `Model/` - Data models
  - `Utility/` - Extensions and helpers
  - `View/` - SwiftUI views
- `Easydict/objc/` - Objective-C code (legacy, being migrated)
  - `Service/` - Remaining Obj-C services (Baidu, language detection)
  - `ViewController/` - Window and query view controllers
  - `MMKit/` - Utility framework
- `EasydictTests/` - Unit tests

### Obj-C to Swift Migration

The project follows a phased migration plan (see `MIGRATION_PROGRESS.md`):
- AI services: 100% complete
- Translation services: ~46% complete (Google, Bing, Youdao, DeepL, NiuTrans migrated)
- Core infrastructure: ~50% complete

When adding new functionality, prefer Swift. When modifying existing Obj-C code, consider migrating to Swift if the scope is reasonable.

### Service Architecture

Translation services inherit from a base query service. Each service lives in its own directory under `Swift/Service/` with:
- Main service class (e.g., `GoogleService.swift`)
- Supporting models and extensions as needed

### Key Patterns

- CocoaPods for dependency management (AFNetworking, Masonry, ReactiveObjC, etc.)
- Bridging header at `Easydict/App/Easydict-Bridging-Header.h`
- String localization uses Xcode String Catalogs (`.xcstrings` files)
- URL Scheme support: `easydict://query?text=xxx`

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
