# Style 11: Event Transit

A transit-map metaphor for event-driven systems. Topics are rails, processing
steps are stations, declared junctions are branch points, and dead letters get
a visibly separate route.

## Best fit

- Kafka/Pulsar/NATS topology reviews
- Event choreography and consumer-group discussions
- Stream processing, retry, and DLQ runbooks
- Schema evolution and materialized-view pipelines

## Visual tokens

| Token | Value |
|---|---|
| Canvas | `#fbf7ee` with transit dots |
| Card | `#fffdf8` |
| Primary rail | `#e4475b` |
| State projection | `#00897b` |
| Read/consumer | `#2563eb` |
| DLQ | `#c62828`, dashed |
| Text | `#17213c` |

The dark casing beneath a rail is decoration. The colored path with
`data-graph-role="edge"` remains the ordinary semantic connector. Semantic
rails use a maximum `2.8px` stroke and fixed user-space arrowheads so markers do
not grow with line width.

## Required semantic contract

Select `semantic_profile: "event-transit"` and provide:

- `diagram_type: "event_stream"`
- one to four topics, each with unique `id` and `color`
- every node: `transit_role` and optional/required topic metadata
- stations/junctions: `operation`
- consumers: `consumer_group`
- rail stations: unique integer `station_order`
- rail edges: `transit_type: "rail"`, topic id, `right → left` ports

A rail edge must connect consecutive station orders on one horizontal
centerline with at least `64px` clearance. A dead-letter edge must target a
real `dlq` node. Multiple rail departures are only valid from a `junction`.

## Composition rules

- One horizontal centerline per topic rail
- Use branches only where the node is declared as a junction
- Put DLQ and state-store terminals below their owning station
- Reserve dashed red for dead-letter/retry semantics
- Show partition, lag, or schema facts as short badges
- Zero bridge crossings and no duplicated rail overlay in official samples
- Keep at least `64px` clear rail between adjacent station cards
- Use compact user-space arrowheads and a subtle casing; the semantic rail stays at or below `2.8px`

## Signature checklist

- Dark top-right `EVENT METRO` line stamp and a signed topic-line count
- Numbered station medallions, compact midpoint chevrons, and one rail centerline per topic
- Distinct junction dot, dashed DLQ terminal with `×`, and state-store terminal with a square glyph
- Partition, schema, latency, fan-out, lag, replay, and state badges attached to stations

## Prompt cues

- English: `event metro map`, `topic rail map`, `Kafka topology`, `stream choreography map`
- 中文：`事件地铁图`、`事件轨道图`、`Topic 线路图`、`Kafka 拓扑图`
- Copyable cue: `Use Style 11 Event Transit; render topics as thin metro rails, processors as numbered stations, declared junctions, consumer groups, DLQ, and state projections.`

## Do not blend with

Do not nest Region/VPC deployment boundaries, label cards as C4 containers, or
attach golden-signal dashboards to every station. A request/response flow with
no topic, consumer-group, or stream evidence should use a generic flow style.

## Fixture

`fixtures/event-transit-style11.json` shows a checkout event line with schema
validation, fraud enrichment, a declared junction, DLQ, and materialized state.
