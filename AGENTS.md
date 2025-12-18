# AGENTS.md - Easydict Project Guide

**Please use Simplified Chinese for all communication. All documentation and comments within the codebase must be written in English.**

This file guides AI coding agents working in this repository. Content mirrors `CLAUDE.md` and should remain in English.

## Project Overview

**Easydict** is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation. 

The project is currently **actively migrating from Objective-C to Swift + SwiftUI**.

## Build Commands

```bash
# Open workspace in Xcode (NOT the .xcodeproj)
open Easydict.xcworkspace

# Build
xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath ./DerivedData | xcbeautify

# Build for testing
xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath ./DerivedData | xcbeautify

# Run specific test method (without building), -only-testing:<Target>/<TestClass>/<testMethod>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData \
  -only-testing:EasydictTests/StitchImageTests/stitchGameImagesLowOverlap | xcbeautify

# Run specific test class (without building), -only-testing:<Target>/<TestClass>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ./DerivedData \
  -only-testing:EasydictTests/StitchImageTests | xcbeautify

  # Run all tests (without building) (May cost much time)
xcodebuild test-without-building -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath ./DerivedData | xcbeautify
```

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

- CocoaPods for dependency management (AFNetworking, Masonry, ReactiveObjC, etc.)
- Bridging header at `Easydict/App/Easydict-Bridging-Header.h`
- String localization uses Xcode String Catalogs (`.xcstrings` files)

## Code Contribution Iron Rules

**MANDATORY REQUIREMENTS FOR ALL CONTRIBUTORS:**

1. **Prohibit adding any new Objective-C files** (.m, .h files)
2. All new code MUST be implemented using Swift/SwiftUI
3. Swift/SwiftUI is the only future tech stack for this project
4. Objective-C legacy code: bug fixes only, no feature extensions
5. All class and struct and function need proper documentation comments in English
