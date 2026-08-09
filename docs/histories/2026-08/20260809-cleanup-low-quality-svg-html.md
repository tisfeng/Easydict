## 2026-08-09 | Task: clean up low-quality SVG and HTML documentation

**Links:** `AGENTS.md`

### User request

Remove obsolete directory-level SVG and HTML documentation while retaining the
small set of useful architecture diagrams and runtime HTML resources.

### Changes

- Removed six low-value architecture SVG files, including Baidu, Markdown,
  ClaudeCode, CodexCLI, AppleDictionary, and the CodexCLI test copy.
- Removed six directory overview HTML files.
- Kept seven core architecture or release-flow SVG files and the runtime
  `dictionary-result.html` template.
- Removed deleted-file references from `Easydict.xcodeproj/project.pbxproj`.
- Left Markdown documentation, icon assets, and `.agents` skill resources
  unchanged.

### Design intent

The current agent-documentation rules no longer require directory-level HTML or
SVG artifacts. Keeping only diagrams with clear architectural or operational
value reduces navigation noise without removing runtime resources or the more
useful Markdown documentation.

### Validation

- `rsvg-convert` on the seven retained SVG files: passed.
- `plutil -lint Easydict.xcodeproj/project.pbxproj`: passed.
- Deleted-document reference scan: passed with no residual references.
- `git diff --check`: passed.

### Affected files

- `Easydict.xcodeproj/project.pbxproj`
- Selected SVG and HTML documentation files under `Easydict/`,
  `EasydictTests/`, and `release-scripts/`
- `docs/histories/2026-08/20260809-cleanup-low-quality-svg-html.md`

### Follow-ups

- None.
