# Visual quality and exact text

## Readability

The generator retains each style's palette, material, radius, stroke and motion
signature. `scripts/style_quality.py` strengthens supporting text on its default
opaque canvas toward a 4.5:1 contrast target. This is a token-level measurement,
not certification for custom fills, translucent glass, font size or every pixel.
Inspect the final raster at the intended reading size.

- Flat Icon / Notion / OpenAI: keep quiet white space, make captions and section
  labels readable instead of using nearly invisible gray.
- Dark Terminal / Ops Pulse: retain accent-coded routes and dark surfaces; lift
  auxiliary text, not glow intensity. Keep status identifiable by text as well as color.
- Blueprint: preserve the engineering grid, cyan linework and registration details.
- Glassmorphism: keep the panel translucency; test text on the composited panel.
- Claude: retain warm paper and brown hierarchy with readable secondary text.
- C4 Review Canvas: preserve responsibilities and protocols; use both description
  lines for Chinese as well as spaced words. Never hide an essential responsibility.
- Cloud Fabric: preserve region/VPC nesting; strengthen ownership labels without
  introducing competing connector colors.
- Event Transit: preserve route directions, station ordering and the distinct DLQ.
- Dark Luxury: keep the AI-authored restrained gold/serif composition; exact text,
  geometry and visual checks apply just as they do to generated styles.

## Text completeness

`layout.json.typography` reports visible truncation, full source copy and a recovery
hint. `data-full-text` preserves provenance but does not make hidden text visible.
Use `text_policy: "strict"` to reject truncation. Widen the card, use an approved
short label, or split views. CJK descriptions wrap at character boundaries rather
than discarding the second line. Font width estimates remain heuristic; Noto Sans
CJK SC is included as a cross-platform fallback, not bundled or auto-installed.

## Export and verification

Prefer the unified `export-png` command, 1920px by default. Its root-canvas parser
supports viewBox-only SVG, decimal/physical dimensions and nonzero SVG origins;
the JSON layout generator itself uses origin 0 0. Export rejects oversized images
and active/external SVG content. Confirm PNG dimensions and inspect actual text.

Use the public style fixtures for identity, the shared quality-baseline fixtures
for comparison, and long-text fixtures/tests for readability. Adding metadata or
passing XML checks alone never proves a visually successful diagram.
