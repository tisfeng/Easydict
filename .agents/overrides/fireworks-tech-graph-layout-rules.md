# Scoco Fireworks Tech Graph Layout Rules

This file is a Scoco repo-local overlay for the `fireworks-tech-graph` skill. Read the skill first, then apply these rules when generating or editing SVG technical diagrams for this repository. If this file conflicts with the upstream skill, use the stricter rule.

## Layout Contract

- Treat every bordered element as a layout contract, not only primary nodes. Notes,
  failure branches, side callouts, section boxes, and any other boxed explanatory text
  must keep their full content inside the border.
- Size each bordered element from the rendered text outward. The longest title or body
  line must still leave clear horizontal padding on both sides.
- If text does not fit, widen the box first, then reflow the text, and increase height
  when wrapped lines need more vertical room.
- Every bordered text box must keep at least 20 px of horizontal padding and 14 px of
  vertical padding in the rendered result.
- Note boxes, failure branches, and callouts that include code tokens must widen before
  they wrap. Do not hide overflow by compressing text, shrinking spacing, or relying on
  near-border placement.

## Connector Geometry

- Labeled horizontal or vertical connectors between bordered elements must keep at least
  48 px of clear channel width between the two borders.
- Unlabeled side callouts or failure branches must still keep at least 32 px of clear
  channel width between the source and target borders.
- Connector geometry must start and end on the source and target borders. Arrowheads may
  touch the target border edge, but they must not extend into any bordered element's
  interior.
- Arrow labels must keep obvious whitespace from both adjacent borders, not merely avoid
  touching them.
- If an arrow label cannot keep at least 12 px of visible whitespace on both sides, widen
  the gap or reroute the connector. Do not solve tight layouts by nudging the label into
  the remaining gap.
- If a label feels squeezed, widen the gap between elements or reroute the connector
  before trying small label nudges.

## Rendered Verification

- After creating or editing any SVG technical diagram, render it to PNG and visually
  inspect the result. Source inspection or heuristic width scans are only auxiliary
  checks and never replace rendered verification.
- Rendered PNG files are temporary verification artifacts by default. Delete them after
  visual inspection unless the task explicitly asks to keep PNG output.
- A modified SVG is not done until the rendered review confirms every title and body line
  is fully enclosed by its border.
- A modified SVG is not done until every arrow label has visible clearance from
  surrounding borders.
- A modified SVG is not done until every arrowhead stops at the target border edge instead
  of entering the box interior.
- A modified SVG is not done until every bordered text box still preserves its intended
  padding in the rendered PNG.
