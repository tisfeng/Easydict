# AGENTS.md

**Please use Simplified Chinese for all communication. All documentation and comments within the codebase must be written in English.**

This file provides guidance to Claude Code, Codex, and other AI agents when working with code in this repository.

## Project Overview

**Easydict** is a macOS dictionary and translation app that supports word lookup, text translation, and OCR screenshot translation.

The project is currently **actively migrating from Objective-C to Swift + SwiftUI**.

**Requirements:** Xcode 15+ (for String Catalog support), macOS 13.0+ (minimum supported).

**Note:** All new development should prefer modern Swift and SwiftUI APIs available on macOS 13.0+ to ensure cleaner, safer, and future‑proof code.

## Build Commands

In general, do not need to run `xcodebuild` commands if not demanded.

See [build.md](build.md) for common build and test commands.

## Code Architecture
****
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

## Coding Standards

See [code-style.md](code-style.md) for detailed coding rules.

## Localization

See [localization.md](localization.md) for detailed localization rules.

## Git Commit Messages

See [commit.md](commit.md) for Angular-style commit message guidelines.
