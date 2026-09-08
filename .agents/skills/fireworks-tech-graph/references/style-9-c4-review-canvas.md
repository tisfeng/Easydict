# Style 9: C4 Review Canvas

A review-room canvas for C4 context, container, and component diagrams. The
warm paper surface and deterministic pencil echoes make design discussion feel
human while the underlying geometry remains exact.

## Best fit

- Architecture Decision Records and design reviews
- C4 context, container, or component views
- Responsibility and dependency reviews
- Diagrams that need annotations without looking like a slide template

## Visual tokens

| Token | Value |
|---|---|
| Canvas | `#f7f2e8` |
| Card | `#fffdf7` |
| Primary text | `#24312f` |
| Boundary | `#8c7d68`, dashed |
| Primary relationship | `#365f56` |
| State change | `#a44a3f` |
| Data/read | `#356a8a` |
| Asynchronous | `#7a5c99` |

Use Avenir/system sans-serif. Keep type labels uppercase and small; keep
descriptions sentence-like and technologies terse.

## Required semantic contract

Select `semantic_profile: "c4-review"` and provide:

- `diagram_type: "c4"`
- one `c4_level`: `context`, `container`, or `component`
- `scope`, `title`, integer `rough_seed`, and a legend
- every node: `c4_type`, `label`, and `description`
- container/component nodes: `technology` and a card at least `170×96`
- every relationship: short `label` and explicit `protocol`

Do not mix a deeper C4 element into a higher-level view. The runtime rejects a
component in a container view and rejects unknown boundary parents.

## Roughness without geometry drift

The `rough_seed` creates stable decorative second strokes. Decorations use
`data-graph-role="decoration"`; the ordinary orthogonal path remains the only
semantic edge. A seed must reproduce byte-identical SVG across runs.

Never jitter:

- node bounds or port anchors
- the semantic route or arrowhead
- label bounds
- container gutters

## Composition rules

- One abstraction level per canvas
- At least `40px` between nodes and `20px` inside boundaries
- Zero undeclared crossings and zero bridge crossings for official samples
- At most two bends per relationship; prefer aligned straight paths
- Put external people/systems outside the system boundary with a clear gutter
- Keep labels short enough to sit in whitespace, not on top of cards
- Wrap responsibility copy to at most two lines; keep technology in the lower-right safe area

## Signature checklist

- Top-right dashed review stamp showing the C4 level and review state
- Uppercase C4 type, responsibility copy, and a separate technology footer on each card
- Dashed external-system cards and deterministic pencil echoes that never alter geometry
- Two-line relationship badges: action first, protocol in brackets below

## Prompt cues

- English: `C4 review board`, `ADR review canvas`, `container responsibility review`
- 中文：`C4 评审画布`、`ADR 评审图`、`职责边界评审图`
- Copyable cue: `Use Style 9 C4 Review Canvas; show one C4 level, responsibilities, technologies, review state, and relationship protocols.`

## Do not blend with

Do not add Region/VPC ownership bands, event-metro stations, or golden-signal
metric chips. If those facts dominate the request, route to Style 10, 11, or
12 instead of turning the C4 review into a mixed abstraction canvas.

## Fixture

`fixtures/c4-review-canvas-style9.json` demonstrates a checkout container
review with a deterministic seed and a 100-point showcase composition score.
