# Style 12: Ops Pulse

An operational review surface that combines service topology, the four golden
signals, one critical request path, and a correlated trace waterfall. It is
for incident and reliability work, not a screenshot of a live dashboard.

## Best fit

- Incident reviews and production-readiness reviews
- SLO/error-budget discussions
- Latency and dependency investigations
- Runbooks that connect topology to one representative trace

## Visual tokens

| Token | Value |
|---|---|
| Canvas | `#07111f` with a restrained ops grid |
| Service card | `#0d1b2a` |
| Border | `#29435d` |
| Healthy | `#22c55e` |
| Warning | `#f59e0b` |
| Critical | `#f43f5e` |
| Telemetry | `#22d3ee`, dashed |
| Trace | `#38bdf8` |

## Required semantic contract

Select `semantic_profile: "ops-pulse"` and provide:

- `diagram_type: "observability"`
- one to twelve nodes with `ops_role: "service"`
- each service: exactly `latency`, `traffic`, `errors`, and `saturation`
- every signal: `value`, `unit`, `window`, and `status`
- service cards at least `180×108` and a visible `status_label`
- a non-empty ordered `critical_path` of business edge ids
- business and telemetry edges using different `flow` tokens
- trace spans with positive duration and valid parent coverage

The critical path must be contiguous and may not include telemetry edges. A
trace waterfall has exactly one root when spans are present.

## Composition rules

- Keep service health cards in one aligned band
- Show only one highlighted critical path per view
- Telemetry export is dashed and visually subordinate
- Put the trace waterfall in its own boundary below topology
- Do not duplicate a critical edge to create glow; glow is decoration owned by
  the single semantic path
- Use a fixed observation window and display units on every signal
- Zero bridge crossings and no more than two bends per edge

## Signature checklist

- Top-right `LIVE` investigation stamp with observation window and worst status
- Status rail on every service card and four metric chips carrying explicit windows
- Numbered critical-hop markers on the single highlighted business path
- Dedicated trace boundary with a 0–100% ruler and one correlated waterfall

## Prompt cues

- English: `reliability pulse`, `incident investigation view`, `golden signals trace`, `SRE trace review`
- 中文：`可靠性脉冲`、`事故排查视图`、`黄金信号追踪图`、`SRE Trace 评审`
- Copyable cue: `Use Style 12 Ops Pulse; show a fixed observation window, four golden signals per service, one numbered critical path, telemetry export, and one correlated trace waterfall.`

## Do not blend with

Do not turn the service band into a Region/VPC deployment map, an event-metro
rail, or a C4 responsibility review. If the prompt lacks measured signals,
status, time window, and trace evidence, use a generic architecture style.

## Fixture

`fixtures/ops-pulse-style12.json` demonstrates a degraded checkout path with
four service cards, an OTel collector, and a correlated four-span trace.
