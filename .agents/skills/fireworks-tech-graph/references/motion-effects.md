# Focused SVG-to-GIF Motion

Motion has one public contract:

```text
generated semantic SVG -> validated animated GIF
```

PNG and JPEG are not accepted as animation inputs. Animated WebP, MP4, WebM,
poster generation, and the old offline motion-review player are not part of this
surface. Static SVG/PNG rendering and the single-file interactive HTML exporter
remain unchanged.

## Simplest prompts

Use the most recently generated SVG when the user says:

- `让这张图动起来`
- `生成 GIF`
- `制作 GIF`
- `把刚才的 SVG 转成 GIF`
- `Generate a GIF`
- `Animate this diagram`
- `Animate this SVG as a GIF`

No format, preset, duration, or frame-rate wording is needed. The default is a
960px-wide, 5.75-second, 20fps, 115-frame, infinitely looping GIF. `auto` reads the
style id and explicit `data-motion-*` edge metadata from the generated SVG.

The input must satisfy one of the twelve approved motion-scene contracts. Exact
source bytes are not pinned, so validated title and content variants of a
supported topology are accepted. The role/stage/order schedule, route direction,
required source colors, and geometry remain fail-closed; `auto` does not infer
missing metadata or apply reviewed motion to an arbitrary same-style topology.
The only motion media artifact is GIF. Unless `--report` supplies another path,
the CLI also writes `<output>.motion.json` with the validation evidence.

## ByteByteGo-derived rules

Six measured ByteByteGo newsletter GIFs use short 2.10–2.75 second loops at a
uniform 20 or 33.33fps. Only 1.20–3.56% of their canvases change over a loop and
every measured frame is unique. The default loop extends to 5.75 seconds so the
accepted 1.8-second construction leaves frames 38–109 for a clearly readable,
continuously moving operating state. This project applies those lessons as a reusable technical-diagram contract:

1. Frame 0 keeps nodes and regions readable while every connector is absent.
2. Existing routes draw on in semantic order, then settle with their direction markers.
3. Nodes, labels, containers, marker geometry, and the camera remain fixed.
4. Connector overlap is scene-pinned: Styles 4 and 12 use one active build, plans that call for two enforce two, and Style 7's exact parallel governance schedule reaches three. The completed topology gets a noticeable operating hold.
5. Samples use a uniform GIF-native cadence; no 6/7-centisecond alternation.
6. The final slot is a real animation sample, never a copied opening frame.
7. Every settled route carries marker-free operating motion toward the target. Styles 1–4 retain their approved packet-head, terminal-evidence, Blueprint-bead, and Notion-card identities. Styles 5–12 use a separate rail/signature family per scene and remain legible at 50% review size.

## Approved default gate

Styles 1–12 are enabled and their signature, speed, path, geometry, and
construction contracts are user-approved. The shared `+2s-settled-flow`
timing revision was approved on 2026-07-17, so new default 5.75-second packages
record `review_status: user-approved`. The explicit 3.75-second and 2.75-second
compatibility timelines remain available when requested.

### Style 1 — Memory Weave

Style 1 follows eight explicit route roles:

| Frames | Role | Edge meaning |
|---:|---|---|
| `1–8` | `ingress` | user request |
| `5–12` | `reason` | application to model |
| `9–16` | `extract` | fact extraction |
| `13–20` | `transform` | extracted facts |
| `17–24` | `resolve` | conflict resolution |
| `21–28` | `memory-write` | durable write |
| `25–32` | `memory-read` | memory relation/read |
| `29–36` | `response-context` | context to response |

The `connector-draw-on-with-persistent-data-flow` primitive transiently hides all immutable
source edges and their route-owned label groups. Each route gets one marker-free
linear draw clone and one settled clone that restores the original marker at
arrival. Its label plate and text appear only with that settled route; label
geometry never moves. The topology is complete by frame 36. From frames `36–114`,
every settled route gets an adjacent marker-free, filter-free pair that preserves
the source path direction. The `persistent-data-flow-stream` body uses memory-cyan
`#06b6d4`, rounded caps and joins, opacity `.90`, width
`min(4.0px, max(3.0px, source stroke × 1.60))`, and dash pattern `16 25`. Style 1's
current 2.4px source routes therefore resolve to exactly 3.84px. Its immediately
following `persistent-data-flow-head` clone stays inside that body with color
`#e0f2fe`, width `2.20px`, opacity `.98`, rounded caps and joins, and pattern
`6 35`. Both patterns have a 41-unit period; the head dash offset is always the
body offset minus 10 units, placing the bright six-unit segment over the leading
six units of the cyan body. Neither clone carries a marker, filter, glow, or blur.

Both layers advance together by `-6.0` SVG user units per rendered frame toward
the target: 6px/frame or 120px/s at 960px, and 3px/frame or 60px/s at 50% review
scale. Their shared phase is `(motionStage × 7 + motionOrder × 3) mod 41`; the
request/reason/extract/facts/resolved/write/relate/context phase order is
`[7, 14, 21, 28, 31, 35, 1, 8]`. Period 41 and step 6 are coprime, so the 39
stream samples do not repeat a phase. Frames 36, 37, and 38 use pair-layer factors
`.30`, `.65`, and `1.00`; frames `38–109` hold full body/head opacities `.90`/`.98`.
Frames `110–114` keep both layers advancing while multiplying settled topology,
labels, body, and head opacity by `1.00`, `.7575`, `.515`, `.2725`, and `.03`.
Sampling uses `time × fps − 0.5`, so frames `0–35` match the accepted raw Chromium
baseline exactly.
This keeps the reset in motion and leaves frame 74 distinct from the connector-free
frame 0. Runtime geometry sentinels also fail closed unless `ingress` travels right,
`resolve` travels left, and `memory-write` follows down → left → down while the
dash offset remains negative; declaring source/target metadata alone is not enough.

### Style 2 — Dark Terminal evidence trace

Style 2 selects the `tool-grounding` scene by SVG style metadata. Its schedule is
keyed by the exact `(data-motion-role, data-motion-order)` pair, so two grounding
routes remain independently addressable and every expected key must appear exactly
once. The source edge stage and route color are validated before rendering.

| Frames | Stage | Role / order | Evidence transition | Body color |
|---:|---:|---|---|---|
| `1–8` | `1` | `ingress / 0` | query enters the application | `#a855f7` |
| `5–12` | `2` | `delegate / 0` | application delegates to the model | `#a855f7` |
| `9–16` | `3` | `tool-call / 0` | model issues the terminal command | `#38bdf8` |
| `13–20` | `4` | `inspect / 0` | terminal output is inspected | `#38bdf8` |
| `17–24` | `5` | `index / 0` | inspected evidence enters the index | `#22c55e` |
| `21–28` | `6` | `grounding / 0` | indexed evidence returns to grounding | `#fb7185` |
| `25–32` | `6` | `grounding / 1` | grounding reaches the answer context | `#fb7185` |
| `29–36` | `7` | `answer / 0` | grounded answer returns to the user | `#f97316` |

After each route settles, it receives one adjacent, marker-free, filter-free pair.
The `terminal-evidence-stream` body inherits that source route's stroke, uses width
`min(3.8px, max(3.0px, source stroke × 1.50))`, opacity `.94`, and dash pattern
`15 26`. Style 2's 2.3px routes resolve to exactly 3.45px. The immediately following
`terminal-command-head` is white `#f8fafc`, 2.0px wide, opacity `1.00`, and uses
pattern `5 36`; its offset is the body offset minus 10 units. Both advance by
`-6.0` SVG user units per rendered frame, equal to 6px/frame at 960px and 3px/frame
at 50% review size. The phase formula is
`(motionStage × 6 + motionOrder × 3) mod 41`, producing
`[6, 12, 18, 24, 30, 36, 39, 1]` in schedule order. Period 41 and step 6 are
coprime, so all 39 stream samples remain phase-unique.

All eight directions are runtime sentinels: `ingress / 0` right;
`delegate / 0` down → left → down; `tool-call / 0` right; `inspect / 0` down;
`index / 0` right → up; `grounding / 0` up → left → up; `grounding / 1` right;
and `answer / 0` right. The body/head pair fades in on frames `36–38`, holds full
opacity on frames `38–109`, then keeps moving while sharing the five-frame reset.

One scene signature appears over the terminal prompt: `terminal-prompt-cursor`.
The renderer requires exactly one `data-node-id="terminal"` node and exactly one
unchanged `_` source text within it. A 2.2px-high `#a7f3d0` rectangle is derived
from that underscore's runtime `getBBox()` and placed in a separate signature
layer. It changes opacity only: from frames `16–69`, each 16-frame period has eight
bright frames at `.95` followed by eight absent frames. Its cadence runs through
`reset_start - 1`; frames `110–114` multiply a
bright cursor by the shared reset opacity. The source underscore remains visible
and unmutated. Terminal text typing, scan lines, glows, camera motion, and animated
backgrounds are outside this scene contract.

### Style 3 — Blueprint distribution wave

Style 3 selects the `service-blueprint` scene. SHA-256
`b8f55d9ea0c6111176d8ff50d2e844b2001ee5087a3940621e635e1b875d470d`
remains the reviewed reference source, not an exact-byte input lock. Its schedule
is keyed by the exact `(data-motion-role, data-motion-order)` pair.
Every key resolves to one immutable source edge, and every source stage and route
color is validated before rendering.

| Frames | Stage | Role / order | Blueprint transition | Body color |
|---:|---:|---|---|---|
| `1–6` | `1` | `ingress / 0` | client request enters the gateway | `#38bdf8` |
| `4–9` | `2` | `policy / 0` | gateway checks identity and policy | `#67e8f9` |
| `8–13` | `3` | `fanout / 0` | gateway opens the Order branch | `#38bdf8` |
| `11–16` | `3` | `fanout / 1` | gateway opens the Catalog branch | `#38bdf8` |
| `14–19` | `3` | `fanout / 2` | gateway opens the Billing branch | `#38bdf8` |
| `18–23` | `4` | `data-write / 0` | Order writes Postgres | `#fde047` |
| `21–26` | `4` | `data-write / 1` | Catalog writes Redis | `#fde047` |
| `24–29` | `4` | `data-write / 2` | Billing writes Warehouse | `#fde047` |
| `28–33` | `5` | `event / 0` | Billing publishes an event | `#fb7185` |
| `31–36` | `6` | `telemetry / 0` | Event Router emits metrics | `#fb7185` |

From frame 36, each settled route receives one marker-free, filter-free
`blueprint-distribution-wave` body. It inherits the source stroke, uses width
`min(3.4px, max(2.8px, source stroke × 1.40))`, opacity `.92`, rounded caps and
joins, and dash pattern `12 31`. The reviewed 2.1px routes resolve to exactly
2.94px, or 1.47px at 50% review scale. Dash offset advances by `-6.0` SVG units
per rendered frame.

Each body is paired with one `blueprint-registration-bead`: a circle with radius
3.0px, fill `#e0f2fe`, source-colored 1.2px stroke, and opacity `.98`. Its initial
path distance is the route phase. Every rendered frame advances `cx` and `cy` by
`+6.0` user units through `getPointAtLength`; the bead wraps from the target end
to the source start and never reverses. Only `cx`, `cy`, and `opacity` change.

The stage-only phase formula is
`(motionStage × 7 + motionOrder × 0) mod 43`, producing
`[7, 14, 21, 21, 21, 28, 28, 28, 35, 42]`. All three fan-out routes therefore
share phase 21, and all three equal-length data-write routes share phase 28 and
the same bead Y coordinate throughout the live interval. Period 43 and step 6
are coprime, so the 39 live samples do not repeat a body phase.

The ten runtime direction sentinels require: ingress right; policy right;
fan-out/0 down → left → down; fan-out/1 down; fan-out/2 down → right → down;
all three data writes down; event right; and telemetry down. Body dash offset
must stay negative while bead travel stays positive. Bodies and beads are absent
through frame 35, fade in with `.30`, `.65`, and `1.00` factors on frames
`36–38`, hold full opacity on frames `38–109`, then keep advancing through the
five-frame reset. Glow, blur, shadow, scan lines, node/text/camera/background
motion, halo, ripple, and terminal cursors remain outside the Style 3 contract.

### Style 4 — Notion memory-card handoff

Style 4 selects the `memory-lifecycle` scene. SHA-256
`04cf833659e82c3e1743db4042cacf839a6d784a99c32d076e36fd4776e70c1b`
remains the reviewed reference source, not an exact-byte input lock. Its exact
`(data-motion-role, data-motion-order)` schedule allows only one active
connector build:

| Frames | Stage | Role / order | Memory transition | Rail/card color |
|---:|---:|---|---|---|
| `1–4` | `1` | `sample / 0` | sensory input enters working memory | `#3b82f6` |
| `5–8` | `2` | `attend / 0` | active context reaches the agent | `#3b82f6` |
| `9–12` | `3` | `invoke / 0` | the agent invokes procedural memory | `#7c3aed` |
| `13–22` | `4` | `remember / 0` | working context enters episodic memory | `#059669` |
| `23–26` | `5` | `consolidate / 0` | episodes become semantic knowledge | `#ea580c` |
| `27–36` | `6` | `recall / 0` | semantic knowledge returns to the agent | `#ea580c` |

From frame 36, all six settled paths receive a marker-free, filter-free
`notion-memory-rail`. Each rail uses destination-memory color, width
`min(3.0px, max(2.4px, source stroke × 1.50))`, opacity `.88`, round caps and
joins, and dash pattern `12 35`. The reviewed 1.8px paths resolve to exactly
2.70px, or 1.35px at 50% review size. The phase formula
`(motionStage × 7 + motionOrder × 0) mod 47` produces
`[7, 14, 21, 28, 35, 42]`; dash offset advances by `-6.0` user units per frame.
Period 47 and step 6 are coprime, so none of the 39 live rail samples repeats.

Each rail is paired with one `notion-memory-card` group. Its white outer rect is
`x=-7`, `y=-5`, `14×10`, `rx=2`, with a 1.4px semantic-color stroke. Two 2px
butt-cap ink lines use `shape-rendering="crispEdges"` and run from `(-4.5,-2)`
to `(4,-2)` and from `(-4.5,2)` to `(0.5,2)`. The exact normalized starting-progress vector is
`[0.08, 0.22, 0.36, 0.50, 0.64, 0.78]`; distance is
`8 + progress × (pathLength − 16)`. Cards keep 8px clearance from both endpoints,
advance `+6.0` path units per rendered frame, wrap from target clearance to
source clearance, and animate only group `transform` and `opacity`.

Direction sentinels require sample, attend, and invoke to point right at `0°`;
remember to point down at `90°`; consolidate to point right at `0°`; and recall
to point up at `-90°`. Rails and cards are absent through frame 35, fade in with
`.30`, `.65`, and `1.00` factors on frames `36–38`, hold full opacity on frames
`38–109`, and keep advancing during the shared five-frame reset. Cards and rails
remain below route labels and nodes. Generic packet heads, circular beads,
terminal cursors, glow, blur, shadow, scan lines, node/text/camera/background
motion, halo, and ripple remain outside the Style 4 contract.

### Styles 5–12 — approved signatures and shared timing

All eight approved style contracts preserve immutable source paths, labels, nodes, containers,
text, and markers. They reuse the connector-free opening, exact semantic draw-on,
frames `36–38` live fade, frames `38–109` operating hold, and moving `110–114`
reset. Live rails never exceed their source stroke width or their scene ceiling.

| Style | Preset | Rail | Signature / auxiliary | Travel | Style / timing status |
|---:|---|---|---|---:|---|
| 5 | `agent-orchestration` | `glass-handoff-rail` | 14×9 `glass-task-capsule`; coordinator halo | 6px/frame | approved / `+2s` approved |
| 6 | `governed-runtime` | `governance-thread` | 12×12 `policy-seal` | 6px/frame | approved / `+2s` approved |
| 7 | `token-stream` | `api-token-rail` | three-cell `token-train` | 6px/frame | approved / `+2s` approved |
| 8 | `golden-circuit` | `luxury-circuit-rail` | `gem-tracer`; only its gem halo is filtered | 6px/frame | approved / `+2s` approved |
| 9 | `review-trace` | `review-trace-rail` | `review-cursor` | 5px/frame | approved / `+2s` approved |
| 10 | `cloud-flow` | `cloud-flow-rail` | region chevrons, replication capsule, availability pulses | 6px/frame | approved / `+2s` approved |
| 11 | `event-transit` | `event-transit-rail` | event train, exception/projection cars, dwell rings | 5px/frame | approved / `+2s` approved |
| 12 | `ops-pulse` | incident / telemetry rails | ECG/export heads, trace reveals, `waterfall-scanner` | 5px/frame | approved / `+2s` approved |

Styles 8, 11, and 12 use `(data-motion-role, data-motion-stage,
data-motion-order)` because repeated roles must stay independently addressable.
Styles 10–12 add only explicit motion metadata to their source fixtures; stripping
`data-motion-role`, `data-motion-stage`, and `data-motion-order` reproduces the
pre-animation static SVG geometry exactly.

## CLI

```bash
SKILL_ROOT="${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}"
python3 "$SKILL_ROOT/scripts/fireworks.py" animate diagram.svg diagram.gif
```

Optional controls remain deliberately small:

```bash
python3 "$SKILL_ROOT/scripts/fireworks.py" animate diagram.svg diagram.gif \
  --preset auto --duration 5.75 --fps 20 --width 960 \
  --report diagram.motion.json
```

Use `--dry-run` to validate identity, semantics, geometry, timeline, output path,
and render budget without launching Chrome or writing artifacts. `duration × fps`
must be a whole number of at least 55 frames. Width × height × frame count may
not exceed 600 million rendered pixels.

## Runtime

SVG-to-GIF export needs Node.js 22.12+, FFmpeg/FFprobe, Chrome/Chromium, and either
`puppeteer` or `puppeteer-core`:

```bash
brew install ffmpeg
for SKILL_ROOT in \
  "$HOME/.agents/skills/fireworks-tech-graph" \
  "$HOME/.claude/skills/fireworks-tech-graph"
do
  [ -d "$SKILL_ROOT" ] || continue
  npm install --prefix "$SKILL_ROOT" --ignore-scripts --no-save --package-lock=false puppeteer-core@25.3.0
  python3 "$SKILL_ROOT/scripts/fireworks.py" doctor
done
```

Set `FIREWORKS_CHROME_PATH` for a nonstandard Chrome install. Set
`FIREWORKS_PUPPETEER_PATH` to an explicit trusted module directory when keeping
the Node runtime elsewhere. Renderer resolution never searches the caller's
working directory, so installing `puppeteer-core` in the diagram project does
not make it available to a copied Skill. A `skills --copy` install creates two
independent roots, so each existing root needs its own runtime installation.
Chrome sandboxing is enabled by default; the no-sandbox override is reserved for
isolated CI runners.

## Quality contract

- Require a fireworks-tech-graph SVG with `viewBox`, valid semantic metadata, and
  explicit motion role, stage, and order on every reviewed edge.
- Sanitize SVG and block scripts, event handlers, external references, active CSS,
  and browser network requests.
- Pass XML, marker, geometry, and composition checks before rendering.
- Preserve the source SHA-256 and assert the static DOM before every frame capture.
- Hide source edges and route labels with a transient stylesheet; insert draw,
  settled-marker, per-style stream-body, packet-head, registration-bead, or
  memory-card decorations below nodes. Keep each Style 1/2 head immediately
  after its body, keep Style 3 beads and Style 4 cards below route labels and
  nodes, and keep the arrival-label layer above every motion path. Keep Style 2's
  opacity-only cursor above the terminal node without mutating its source underscore.
- Render uniform frame-center samples on a manual timeline.
- Compare Style 1 raw Chromium frames `0–35` from 55-frame and 75-frame timelines;
  their hashes must match before GIF palette quantization. Keep a separate 75-frame
  raw baseline for the approved Style 1 worker and require every post-change frame
  to remain byte-identical.
- Raster-test Style 2's body/head layering, 6px/frame full-scale travel,
  3px/frame half-scale travel, semantic route colors, all eight direction
  sentinels, cursor cadence, and five-frame reset before GIF encoding.
- Raster-test Style 3's connector-free opening, ten bodies and ten registration
  beads, 6px/frame full-scale and 3px/frame half-scale bead travel, stage-locked
  fan-out/data-write synchrony, all ten directions, and source-DOM integrity.
- Preserve separate 75-frame raw Chromium baselines for approved Styles 1–3 and
  require every post-change frame to remain byte-identical.
- Render every style at 75 and 115 frames and accept all 852 raw comparisons for
  frames `0–70` through a three-tier compatibility gate: binary SHA-256 exact,
  decoded RGBA exact, then guarded compositor-antialias equivalence. The guarded
  tier requires AE ≤ 128, normalized RMSE ≤ 0.001, every connected difference
  component to be at most 2px wide or high, and every component to remain on an
  edge or node border. Report each tier separately. DOM and per-style signature
  geometry remain strict-exact before GIF palette quantization.
- Raster-test Style 4's connector-free opening, sequential six-route arrivals,
  six semantic rails and six outlined cards, 8px endpoint clearance, 6px/frame
  full-scale and 3px/frame half-scale travel, exact progress/phase/rotation
  vectors, all six directions, and source-DOM integrity. After real Chromium
  capture and 50% point downsampling, horizontal, downward, and upward cards
  must each retain two non-touching unequal-length ink strokes with a complete
  background row or column between them.
- Require exact codec, dimensions, duration, and frame count from FFprobe.
- Require exact raw and encoded frame counts and zero adjacent duplicates. Keep
  every frame unique through 75 frames. For longer timelines, require at least 75
  unique rasters and allow repeated hashes inside full-opacity frames `38–109`.
  Frame `110` is the sole permitted boundary repeat because its unchanged reset
  opacity is exactly `1.00`; classify it as `intentional_reset_boundary_repeat`.
  Frames `111–114` remain globally distinct. Record all repeated frame indices
  and embed infinite GIF looping.
- Install the GIF and optional JSON report atomically.
- Treat 500KB as the focused artifact target and report deterministic size advice.
- Deliver one live GIF plus a phase contact sheet for each style review.
