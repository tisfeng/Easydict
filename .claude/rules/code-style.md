# Core Coding Rules

## General Requirements

- Add documentation comments in English for every class, struct, and function.
- For key functions or complex logic, add detailed inline comments explaining the purpose and reasoning.

## Language Requirements

- New code must be written in Swift/SwiftUI only; do not add Objective-C files.
- Legacy Objective-C code may receive bug fixes but no new features.
- Prefer modern Swift and SwiftUI APIs available on macOS 13.0+.

## Style Guidelines

- Keep individual source files ideally under 300 lines; never exceed 500 unless justified.
- Avoid single-letter variable names; use descriptive identifiers (loop indices are the rare exception).
- Prefer `for … where` over `for` plus inline `if` filtering.
- Prefer async/await over callback-based completion handlers for new async work.

## SF Symbols

This project includes the third-party library **SFSafeSymbols** to use SF Symbols more safely.

- Use SFSafeSymbols' type-safe APIs to reference SF Symbols instead of hard-coded strings.
- Prefer `Image(systemSymbol: .chevronRight)` over `Image(systemName: "chevron.right")`.
- Prefer `Label("MyText", systemSymbol: .cCircle)` over `Label("MyText", systemImage: "c.circle")`.
