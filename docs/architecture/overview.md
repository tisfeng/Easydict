# Easydict Architecture Overview

Easydict is a macOS dictionary and translation app. It supports direct word
lookup, text translation, selection-based translation, OCR screenshot
translation, and multiple translation or AI providers.

The app supports macOS 13.0 and later. New UI components use SwiftUI; existing
AppKit and Objective-C boundaries remain where platform integration requires
them.

## Source layout

```text
Easydict/
├── App/                         # Entry points, assets, plist, localization
├── Swift/
│   ├── Feature/                 # Product features and action flows
│   ├── Model/                   # Shared data models
│   ├── Service/                 # Translation and AI providers
│   ├── Utility/                 # Event monitors and cross-feature helpers
│   └── View/                    # Shared SwiftUI and AppKit-facing views
└── objc/                        # Legacy Objective-C implementation

EasydictTests/                   # Unit and behavior tests
Easydict.xcodeproj/              # Xcode project and shared schemes
Easydict.xcworkspace/            # Workspace and SwiftPM integration
release-scripts/                 # Release, signing, packaging, and appcast flow
```

## Runtime boundaries

- App entry points and shared state live under `Easydict/App` and the relevant
  Swift feature modules.
- Translation providers implement service-specific requests and response
  parsing under `Easydict/Swift/Service`.
- Selection, shortcut, screenshot, and action routing belong to feature modules;
  reusable event and Foundation/AppKit helpers belong under `Utility`.
- Objective-C code remains a legacy boundary. New UI and product components use
  SwiftUI unless an existing AppKit or Objective-C integration requires another
  boundary.
- Tests should exercise concrete behavior at the narrowest stable boundary and
  avoid coupling to view implementation details.

## Build and validation boundary

The primary Xcode entry point is `Easydict.xcworkspace` with the `Easydict`
scheme. Build and test triggers and commands live in
`../agents/build-and-test.md`; this document records architecture rather than
duplicating the command matrix.

## Documentation boundary

- Internal agent rules: `../agents/`.
- Public English and Chinese guides: `../user-docs/en/` and
  `../user-docs/zh/`.
- Current task plans and completed work records: `../exec-plans/` and
  `../histories/`.
