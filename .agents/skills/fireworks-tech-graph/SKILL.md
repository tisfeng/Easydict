---
name: fireworks-tech-graph
description: >-
  Create precise SVG technical diagrams, export PNG or offline HTML, and animate
  supported semantic SVGs to GIF. Use for architecture, UML, agent, cloud or
  workflow diagrams; not photos, raster art or statistical charts.
---

# Fireworks Tech Graph

One portable Agent Skill for Codex and Claude Code. SVG is the canonical artifact;
PNG, offline HTML and supported GIF motion are output routes. Preserve requested
labels, topology and meaning; a successful command is not a visual quality verdict.

## Locate and select

Resolve the directory containing this file as `SKILL_ROOT`. Use
`${CLAUDE_SKILL_DIR}` in Claude Code or the absolute directory in Codex's loaded
skill metadata. Do not assume cwd or a previous shell variable persists.

Use the installed version for the task. Run `version` for source/version questions
and `doctor` when diagnosing a missing renderer, font or dependency; do not make
installation, updates or a complete test suite prerequisites for every diagram.

```bash
SKILL_ROOT="${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}"
python3 "$SKILL_ROOT/scripts/fireworks.py" version
```

- Honor the user's diagram type, content and style; choose sensible reversible
  details from the brief. Ask only for a material missing engineering fact or
  a choice the user explicitly reserved. A request to draw includes local rendering.
- Styles 1–7 and 9–12 have JSON generators. Style 8 (Dark Luxury) remains
  AI-authored SVG: use its style reference, then the same validation/export gates.
- Default to Style 1 Flat Icon when no user/workspace preference applies. Load the
  actual matching file from [the style matrix](references/style-diagram-matrix.md).
  Read other styles only for a requested comparison.
- Styles 9–12 default to C4, cloud, event and observability semantic contracts.
  Validate facts before layout; do not invent responsibilities, protocols or metrics.
- Adapt an existing valid SVG directly when appropriate. JSON generation is not
  required for every edit. Use [diagram/layout guidance](references/diagram-layout-reference.md)
  and [icons](references/icons.md) only for the relevant type or symbols.

## Generate and check

Reuse the user's current brief and artifact; an extra planning document is optional.
For JSON work, select `text_policy: "strict"` when all labels must be visible exactly.
The compatible `report` default preserves full labels in SVG metadata and reports
any visible truncation. Resolve that warning before claiming complete exact text.
For polished work apply the [composition contract](references/composition-quality-contract.md).

```bash
SKILL_ROOT="${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}"
python3 "$SKILL_ROOT/scripts/fireworks.py" validate architecture input.json
python3 "$SKILL_ROOT/scripts/fireworks.py" render architecture input.json diagram.svg --report layout.json
python3 "$SKILL_ROOT/scripts/fireworks.py" check diagram.svg
python3 "$SKILL_ROOT/scripts/fireworks.py" export-png diagram.svg diagram.png --width 1920
```

`check` validates SVG identity, marker references, generic collisions, semantic
geometry and composition. Inspect the report's typography and palette scope;
heuristic text widths do not replace inspecting the actual rendered font.
Use [visual quality guidance](references/visual-quality.md) for readability and
style-specific refinements. Keep one semantic connector per business edge.

## Additional outputs

- **PNG:** prefer `export-png`, which reads root canvas dimensions, limits output
  size, writes atomically and reads the PNG dimensions back. Alternate renderer
  details are in [PNG export](references/png-export.md).
- **HTML:** `fireworks.py export-html diagram.svg diagram.html`. One sanitized
  offline file provides pan/zoom, source copy and static image downloads.
- **GIF:** “Generate a GIF”, “Animate this diagram”, “生成 GIF”, “制作 GIF” and
  “让这张图动起来” select the existing semantic SVG's motion route. Styles 1–12 are enabled
  for the documented scene contracts; arbitrary same-style topologies are not
  promised. Load [motion effects](references/motion-effects.md) and run
  `fireworks.py animate diagram.svg diagram.gif`. Default is 960px, 20fps, 5.75s
  with the `+2s-settled-flow` preset and a `.motion.json` report. Historical
  `user-approved` fields describe maintainer-reviewed presets, not authorization
  from the current user to publish, spend or send data.

## Verify the requested outcome

Inspect the final PNG at intended reading size when image viewing is available:
check text completeness, contrast, font substitution, hierarchy, spacing, clipping,
arrow direction, crossings and labels. Preserve style palette and material while
fixing defects. Reuse an unchanged reviewed render; do not keep adding tests or
polish after acceptance passes. If viewing is unavailable, explicitly mark the
visual check skipped and do not claim visual correctness.

After a failed check, use its element IDs and geometry to make a focused repair;
change the approach after two unchanged failures. Widen/split an overfull diagram
instead of hiding required copy or endlessly shrinking type. Do not silently
weaken semantic or composition constraints to obtain a pass.

Complete every requested local output and its applicable checks, then report file
paths, dimensions, visual review and residual limitations. A first SVG does not
complete a requested PNG/GIF/HTML package. Publication or remote delivery requires
its own scope-matching authorization; existing authorization is not requested twice.
