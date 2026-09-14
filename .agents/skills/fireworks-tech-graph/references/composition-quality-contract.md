# Composition Quality Contract

This contract applies to every visual style. Style references control color,
typography, material, corner radius, and decorative treatment. They never
weaken geometry or composition quality.

## Official showcase profile

Use `"quality_profile": "showcase"` for official samples and polished delivery
artifacts. The renderer and validator enforce all of these budgets:

| Metric | Showcase limit |
|---|---:|
| Edge crossings | 0 |
| Bridge jumps | 0 |
| Bends on one edge | 2 maximum |
| Bends in the six-node reference topology | 8 maximum |
| Route length / direct Manhattan length | 1.35 maximum |
| Shortest route segment | 16px minimum |
| Node-to-node whitespace | 40px minimum |
| Node-to-container gutter | 20px minimum |
| Edge-label clearance from unrelated geometry | 4px minimum |

The six-node reference topology currently scores 100 with four total bends,
zero crossings, zero bridges, a route-stretch maximum of 1.0, 50px minimum
node spacing, and 20px minimum container gutter.

## Layout grammar

1. Establish containers, their header reservations, and node rows before any
   edge is routed.
2. Keep nodes in a row aligned to the same y coordinate and use consistent
   heights for equivalent semantic roles.
3. Reserve one empty inter-container corridor for cross-layer routes. A route
   may cross a container boundary only through an open gap and must not run on
   top of the border.
4. Route the primary horizontal flow first. Route cross-layer context and
   feedback paths through separate, non-overlapping corridor segments.
5. Use distinct node ports when several edges share a side. Never stack
   multiple arrowheads on one coordinate.
6. Prefer a monotone orthogonal route. If a connection needs more than two
   bends, change the node placement before adding waypoints.
7. Treat every external title, subtitle, tag, side label, edge label, legend,
   footer, and title block as an obstacle with measurable bounds.
8. Keep legends outside business-flow corridors. Use a single horizontal row
   when the canvas has enough width.
9. Fit long single-line node titles to the card width. Do not let text touch or
   cross the node border.
10. If the topology cannot meet the showcase limits, simplify the composition,
    split it into focused diagrams, or explicitly use the standard profile for
    a non-showcase engineering stress artifact.

## Style identity boundary

Styles may vary these properties freely within their own reference:

- background, palette, semantic accent colors;
- font family, title alignment, and typographic hierarchy;
- card fill, border treatment, shadow, glow, and corner radius;
- blueprint title blocks, terminal chrome, or restrained brand details.

Styles must share these structural properties for a direct comparison:

- topology and edge direction;
- row/column alignment;
- port assignment and corridor positions;
- crossing, bridge, bend, stretch, spacing, and gutter budgets;
- semantic SVG roles required by the validator.

Visual effects never create a second business connector. Pencil echoes, rail
casings, critical-path glow, and similar layers use
`data-graph-role="decoration"` with `data-owner`; exactly one ordinary
`data-graph-role="edge"` carries the source, target, route, and arrowhead.

## Validation

Run both gates before delivery:

```bash
python3 scripts/validate_svg.py diagram.svg --check geometry
python3 scripts/validate_svg.py diagram.svg --check composition
```

`scripts/validate-svg.sh` runs both automatically. A successful render without
these gates is still a draft.

Dense legacy diagrams live under `fixtures/stress/`. They preserve routing
pressure cases and are not visual quality references. The public 12-style
showcase keeps a distinct engineering scene for every style. The internal
`fixtures/quality-baseline/` set applies one shared Agent Runtime Architecture
topology to all 11 generator-backed styles; Style 8 remains the static,
AI-authored exception.

## Text and raster evidence

Apply [visual-quality.md](visual-quality.md) after geometry passes. Use `text_policy: "strict"` when labels must remain visible in full, inspect `typography` and `palette` in the layout report, and verify the raster at its intended reading size.
