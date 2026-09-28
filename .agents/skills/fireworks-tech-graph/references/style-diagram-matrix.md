# Style-to-Diagram-Type Adaptation Guide

Not all styles work equally well for every diagram type. Use this guide to pick the best style.

## Engineering-first styles (9–12)

Styles 9–12 pair a visual language with an executable semantic contract. They
are deliberately specialized rather than universal skins.

| Style | Required evidence | Visual fingerprint | Prompt cues | Fallback | Never blend with |
|---|---|---|---|---|---|
| 9 C4 Review Canvas | One declared C4 level, responsibilities, technology, labeled protocols | Warm review board, C4 type headers, dashed review stamp, deterministic pencil echo | `C4 review board`, `C4 评审画布`, `ADR 评审图` | Styles 1–7 generic architecture | Region/VPC bands, event stations, live metric chips |
| 10 Cloud Fabric | Region/network/workload ownership and named cross-boundary mechanisms | Cloud grid, nested ownership spines, neutral manifest glyphs, deployment-mode stamp | `deployment topology`, `多区域部署图`, `Region/VPC 归属图` | Styles 1–7 when deployment facts are absent | C4 abstraction labels, station numbering, golden-signal cards |
| 11 Event Transit | Topics, ordered processors, consumer groups, junctions, DLQ/state | Thin metro rails, numbered stations, fixed arrowheads, role-specific terminals | `event metro map`, `事件地铁图`, `Kafka 拓扑图` | Generic flow style when stream evidence is absent | Cloud nesting, C4 cards, SRE dashboards |
| 12 Ops Pulse | Fixed window, four golden signals, statuses, one critical path and trace | Live stamp, status rails, metric windows, numbered hops, trace ruler | `reliability pulse`, `事故排查视图`, `黄金信号追踪图` | Generic architecture when measured evidence is absent | Deployment ownership, event rail metaphor, C4 review marks |

All four official fixtures use the `showcase` composition contract: at least
40px node spacing, 20px container gutter, zero bridge crossings, at most two
bends per edge, and no semantic edge duplicated for visual effects.

## Architecture Diagram
| Style | Suitability | Notes |
|-------|----------|
| 1 Flat Icon | Excellent | Default choice; colorful node fills, clear layering |
| 2 Dark Terminal | Excellent | Popular for dev blogs; use colored borders on dark bg |
| 3 Blueprint | Excellent | Perfect for formal architecture docs |
| 4 Notion Clean | Good | Minimal, works for inline docs |
| 5 Glassmorphism | Good | Striking for presentations and product pages |
| 6 Claude Official | Good | Warm aesthetic, Anthropic-style presentations |
| 7 OpenAI Official | Good | Clean, precise; minimal borders, brand green accents |
| 8 Dark Luxury *(AI-authored)* | Excellent | Premium editorial; gold-on-black layers stand out for architecture docs |

## Class Diagram / ER Diagram
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Good | Colored headers per class category |
| 2 Dark Terminal | Good | High contrast for code-like diagrams |
| 3 Blueprint | Excellent | Best for formal UML documentation |
| 4 Notion Clean | Excellent | Clean, minimal; ideal for Notion-embedded diagrams |
| 5 Glassmorphism | Poor | Glass effects distract from structural content |
| 6 Claude Official | Excellent | Warm, readable; good for documentation |
| 7 OpenAI Official | Excellent | Minimal aesthetic matches UML precision |
| 8 Dark Luxury *(AI-authored)* | Fair | Non-standard dark bg for UML; use only for premium editorial contexts |

## Sequence Diagram
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Good | Clear lifelines; activation boxes visible |
| 2 Dark Terminal | Good | Good for dev articles; dashed lifelines visible |
| 3 Blueprint | Excellent | Formal, technical documentation |
| 4 Notion Clean | Excellent | Best for Notion-embedded sequence diagrams |
| 5 Glassmorphism | Poor | Glass effects make lifelines hard to read |
| 6 Claude Official | Excellent | Ward contrast |
| 7 OpenAI Official | Excellent | Minimal, precise; ideal for API docs |
| 8 Dark Luxury *(AI-authored)* | Good | Dramatic contrast; dark lifelines suit developer blogs and premium tech docs |

## Flowchart / Process Flow
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Default; colorful decision diamonds |
| 2 Dark Terminal | Good | Works well for dev workflow diagrams |
| 3 Blueprint | Good | Formal process documentation |
| 4 Notion Clean | Good | Clean for SOPs and inline docs |
| 5 Glassmorphism | Good | Striking for product demos |
| 6 Claude Official | Good | Warm aesthetic for presentations |
| 7 OpenAI Official | Good | Clean and minimal |
| 8 Dark Luxury *(AI-authored)* | Good | Striking for premium process documentation |

## Mind Map / Concept Map
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent branches, engaging |
| 2 Dark Terminal | Good | Neon-like branches on dark bg |
| 3 Blueprint | Poor | Blueprint grid conflicts with radial layout |
| 4 Notion Clean | Excellent | Ideal for n brainstorming |
| 5 Glassmorphism | Excellent | Stunning visual for presentations |
| 6 Claude Official | Good | Warm, readable |
| 7 OpenAI Official | Good | Clean and minimal |
| 8 Dark Luxury *(AI-authored)* | Excellent | Gold accent branches on black; radial layouts stand out in presentations |

## Data Flow Diagram
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Color-coded arrows by data type |
| 2 Dark Terminal | Excellent | Glowing data paths on dark bg |
| 3 Blueprint | Excellent | Formal data flow documentation |
| 4 Notion Clean | Good | Minimal, clean |
| 5 Glassmorphism | Poor | Distracts from flow semantics |
| 6 Claude Official | Good | Readable |
| 7 OpenAI Official | Good | Precise, minimal |
| 8 Dark Luxury *(AI-authored)* | Excellent | Color-coded data paths shine against deep black; ideal for data engineering docs |

## Use Case Diagram
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Good | Colorful use case ellipses |
| 2 Dark Terminal | Poor | Stick figures less visible on dark bg |
| 3 rint | Excellent | Classic UML aesthetic |
| 4 Notion Clean | Excellent | Perfect for product requirement docs |
| 5 Glassmorphism | Poor | Unnecessary visual noise |
| 6 Claude Official | Excellent | Warm, professional |
| 7 OpenAI Official | Excellent | Clean, precise UML |
| 8 Dark Luxury *(AI-authored)* | Fair | Stick figures less visible on deep black; use cautiously |

## State Machine Diagram
| Style | Suitability | Notes |
|-------|------------|-------|
Flat Icon | Good | Colorful states |
| 2 Dark Terminal | Good | Glowing states and transitions |
| 3 Blueprint | Excellent | Best for formal UML state machines |
| 4 Notion Clean | Excellent | Clean for documentation |
| 5 Glassmorphism | Poor | Distracts from state transitions |
| 6 Claude Official | Excellent | Readable |
| 7 OpenAI Official | Excellent | Minimal, precise |
| 8 Dark Luxury *(AI-authored)* | Good | High contrast for state transitions; editorial quality |

## Network Topology
| Style | Suitabili |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Colorful device icons |
| 2 Dark Terminal | Excellent | Cyberpunk-style network maps |
| 3 Blueprint | Excellent | Ideal for infrastructure docs |
| 4 Notion Clean | Good | Clean for IT documentation |
| 5 Glassmorphism | Good | Striking for presentations |
| 6 Claude Official | Good | Professional network diagrams |
| 7 OpenAI Official | Good | Clean infrastructure diagrams |
| 8 Dark Luxury *(AI-authored)* | Excellent | Deep black classic for infrastructure docs; gold topology lines pop |

## Comparison / Feature Matrix
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Color-coded checkmarks |
| 2 Dark Terminal | Good | Works for dev tool comparisons |
| 3 Blor | Grid conflicts with table layout |
| 4 Notion Clean | Excellent | Perfect for Notion-embedded tables |
| 5 Glassmorphism | Poor | Distabular data |
| 6 Claude Official | Excellent | Clean, warm |
| 7 OpenAI Official | Excellent | Minimal, precise |
| 8 Dark Luxury *(AI-authored)* | Fair | Dark bg non-standard for comparison tables; use cautiously |

## Timeline / Gantt
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Colorful bars by category |
| 2 Dark Terminal | Good | Works for dev roadmaps |
| 3 Blueprint | Good | Formal project plans |
| 4 Notion Clean | Excellent | Ideal for Notion project docs |
| 5 Glassmorphism | Good | Striking for keynote presentations |
| 6 Claude Official | Good | Warm, professional |
| 7 OpenAI Official | Good | Clean timeline |
| 8 Dark Luxury *(AI-authored)* | Good | Premium project roadmaps and keynote presentations |

## Agent / Memory Architecture
| Style | Suitability | Notes |
|-------|------------|-------|
| 1 Flat Icon | Excellent | Colorful layers, engaging |
| 2 Dark Terminal | Excellent | Popular for AI/ML blog posts |
| 3 Blueprint | Good | Formal AI system documentation |
| 4 Notion Clean | Good | Clean for AI research notes |
| 5 Glassmorphism | Excellent | Stunning for AI product presentations |
| 6 Claude Official | Excellent | Anthropic AI aesthetic |
| 7 OpenAI Official | Excellent | OpenAI AI aesthetic |
| 8 Dark Luxury *(AI-authored)* | Excellent | Best for premium AI system docs; champagne gold on deep black |
