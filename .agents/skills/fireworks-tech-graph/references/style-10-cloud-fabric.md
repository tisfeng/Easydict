# Style 10: Cloud Fabric

A deployment-topology view for regions, VPCs/networks, compute, data stores,
and cross-boundary traffic. It answers “where does this run?” without turning
the diagram into a vendor icon poster.

## Best fit

- Multi-region and disaster-recovery reviews
- Cloud deployment and network ownership maps
- Kubernetes cluster/namespace placement
- Migration plans and platform boundary discussions

## Visual tokens

| Token | Value |
|---|---|
| Canvas | `#edf5fb` with a restrained blue grid |
| Card | `#ffffff` |
| Primary text | `#102a43` |
| Boundary | `#7fa3c2` |
| Traffic | `#2563eb` |
| Write | `#ea580c` |
| Data | `#059669` |
| Cross-region | `#7c3aed`, dashed |

Nested boundaries carry a small `GLOBAL`, `REGION`, or `NETWORK` badge. Nodes
use a manifest-backed neutral glyph plus provider metadata. A colored ownership
spine makes each nested deployment boundary readable even in grayscale.

## Required semantic contract

Select `semantic_profile: "cloud-fabric"` and provide:

- `diagram_type: "deployment"`
- `platform_profile`: `provider-neutral`, `aws`, `azure`, `gcp`, or `kubernetes`
- `icon_manifest_version: "2026.07-neutral.1"`
- at least one `deployment_kind: "region"` boundary
- every node: `deployment_id` and a manifest-backed `icon_id`
- every cross-deployment edge: a non-empty `via`

Boundary parents must form an acyclic tree, nesting depth is capped at four,
child boundaries stay at least `16px` inside their parent, and nodes stay at
least `20px` inside their assigned deployment.

## Icon policy

The bundled manifest contains provider-neutral geometric glyphs. It records
official AWS, Azure, and Google Cloud asset URLs as adapter metadata; it does
not redistribute vendor trademarks. If a user supplies an official icon pack,
preserve its license and version outside this repository and map it through the
manifest boundary.

Never invent a vendor service logo. Unknown `icon_id` values fail validation.

## Composition rules

- Show deployment ownership through nesting, not background color alone
- Use a shallow `global → region → network` hierarchy where possible
- Keep ingress paths vertical and regional data paths aligned
- Name cross-boundary mechanisms (`peering`, `transit gateway`, `service mesh`)
- Zero crossings in official samples; use no more than two bends per edge
- Do not encode both logical service architecture and every subnet in one view
- Reserve the icon/provider area before fitting text; no title or subtitle may cross a card edge
- Place ingress mechanism labels in inter-boundary whitespace, clear of Region and Network headers

## Signature checklist

- Pale cloud grid and explicit `global → region → network` nesting
- Ownership spines plus `GLOBAL`, `REGION`, and `NETWORK` boundary badges
- Manifest-backed globe, compute, database, gateway, stream, or observe glyphs
- Top-right platform/region/deployment-mode stamp and named cross-boundary mechanisms

## Prompt cues

- English: `multi-region deployment map`, `cloud landing zone map`, `region/VPC ownership map`
- 中文：`多区域部署图`、`云部署拓扑`、`Region/VPC 归属图`
- Copyable cue: `Use Style 10 Cloud Fabric; show global ingress, Region and VPC ownership, neutral cloud glyphs, deployment mode, and every cross-boundary mechanism.`

## Do not blend with

Do not use C4 abstraction labels, transit-map station numbering, or live SRE
metric cards. When deployment evidence is absent, fall back to a generic Style
1–7 architecture view instead of inventing cloud ownership.

## Fixture

`fixtures/cloud-fabric-style10.json` demonstrates active-active checkout
deployment with two regions, explicit VPC ownership, and neutral glyphs.
