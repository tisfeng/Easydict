# Cross-Language Code Quality

These rules apply to handwritten Swift, Objective-C, Python, Shell,
JavaScript/TypeScript, and other source files.

## Source organization

- Organize growing areas by feature or bounded responsibility.
- Keep source files focused on one responsibility; extract a sibling helper or
  module when parsing, UI, I/O, orchestration, and validation become mixed.
- Handwritten files should generally stay below 500 lines and must not exceed
  1000 lines without a concrete split plan.
- Generated files, third-party code, pure data, templates, large fixtures, and
  intentionally vendored runtime files are exempt from the line limit.
- Use section markers to group lifecycle, state, command handling, I/O, parsing,
  and recovery logic in longer files.

## Naming and implementation

- Follow each language's normal naming convention.
- Use kebab-case for non-imported documentation, exported artifacts,
  app-managed runtime paths, and standalone scripts.
- Prefer concise names and avoid single-letter variables except trivial loop
  indices.
- Avoid global mutable state and type-level helpers unless the domain requires
  them.
- Do not extract one-off literals without semantic meaning.
- Prefer async/await where it is established in the language and codebase.

## Documentation comments

- Add a file-level comment to non-trivial scripts or modules explaining their
  entry point, responsibility, and important side effects.
- Document complex functions, state machines, parsers, I/O boundaries, and
  recovery logic. Do not comment obvious accessors or thin wrappers.
- Keep comments concise, update them with behavior, and keep lines below 80
  characters where practical.
- Use the language's normal documentation style.
- Source file headers must use the current Git username, never an agent name.
