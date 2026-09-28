#!/usr/bin/env python3
"""Shared composition-quality contract for generated and authored diagrams.

Geometry safety answers whether a diagram is technically valid.  This module
adds the stricter presentation rules used by the official showcase fixtures:
short orthogonal routes, deliberate whitespace, clear labels, and zero bridge
crossings whenever the topology can be composed without them.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any, Mapping, Optional, Sequence


Point = tuple[float, float]
Bounds = tuple[float, float, float, float]


@dataclass(frozen=True)
class CompositionContract:
    profile: str
    max_bends_per_edge: int
    max_total_bends: int
    max_route_stretch: float
    max_bridged_crossings: int
    min_node_gap: float
    min_container_gutter: float
    min_label_clearance: float
    min_segment_length: float

    def as_dict(self) -> dict[str, Any]:
        return {
            "profile": self.profile,
            "max_bends_per_edge": self.max_bends_per_edge,
            "max_total_bends": self.max_total_bends,
            "max_route_stretch": self.max_route_stretch,
            "max_bridged_crossings": self.max_bridged_crossings,
            "min_node_gap": self.min_node_gap,
            "min_container_gutter": self.min_container_gutter,
            "min_label_clearance": self.min_label_clearance,
            "min_segment_length": self.min_segment_length,
        }


PROFILES: dict[str, CompositionContract] = {
    "standard": CompositionContract(
        profile="standard",
        max_bends_per_edge=12,
        max_total_bends=100,
        max_route_stretch=5.0,
        max_bridged_crossings=8,
        min_node_gap=0.0,
        min_container_gutter=0.0,
        min_label_clearance=2.0,
        min_segment_length=0.0,
    ),
    "showcase": CompositionContract(
        profile="showcase",
        max_bends_per_edge=2,
        max_total_bends=8,
        max_route_stretch=1.35,
        max_bridged_crossings=0,
        min_node_gap=40.0,
        min_container_gutter=20.0,
        min_label_clearance=4.0,
        min_segment_length=16.0,
    ),
}


def _number(value: Any, fallback: float) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return fallback
    return number if math.isfinite(number) else fallback


def resolve_contract(raw: Any = None) -> CompositionContract:
    """Resolve a profile name or a mapping with profile overrides."""

    if isinstance(raw, Mapping):
        profile = str(raw.get("profile", "standard")).strip().lower()
        overrides = raw
    else:
        profile = str(raw or "standard").strip().lower()
        overrides = {}
    if profile not in PROFILES:
        raise ValueError(f"unsupported composition profile: {profile}")
    base = PROFILES[profile]
    values = base.as_dict()
    for key in values:
        if key == "profile" or key not in overrides:
            continue
        values[key] = _number(overrides[key], float(values[key]))
    for key in ("max_bends_per_edge", "max_total_bends", "max_bridged_crossings"):
        values[key] = int(values[key])
    if any(float(values[key]) < 0 for key in values if key != "profile"):
        raise ValueError("composition quality limits must be non-negative")
    return CompositionContract(**values)


def rectangle_gap(first: Bounds, second: Bounds) -> float:
    """Return the Euclidean whitespace between two axis-aligned rectangles."""

    horizontal = max(first[0] - second[2], second[0] - first[2], 0.0)
    vertical = max(first[1] - second[3], second[1] - first[3], 0.0)
    return math.hypot(horizontal, vertical)


def bounds_area(bounds: Bounds) -> float:
    return max(0.0, bounds[2] - bounds[0]) * max(0.0, bounds[3] - bounds[1])


def containing_container(node: Bounds, containers: Sequence[tuple[str, Bounds]]) -> Optional[tuple[str, Bounds]]:
    center = ((node[0] + node[2]) / 2, (node[1] + node[3]) / 2)
    matches = [
        item
        for item in containers
        if item[1][0] <= center[0] <= item[1][2] and item[1][1] <= center[1] <= item[1][3]
    ]
    return min(matches, key=lambda item: bounds_area(item[1])) if matches else None


def container_gutter(node: Bounds, container: Bounds) -> float:
    return min(
        node[0] - container[0],
        node[1] - container[1],
        container[2] - node[2],
        container[3] - node[3],
    )


def route_stretch(points: Sequence[Point]) -> float:
    if len(points) < 2:
        return 1.0
    length = sum(abs(x2 - x1) + abs(y2 - y1) for (x1, y1), (x2, y2) in zip(points, points[1:]))
    direct = abs(points[-1][0] - points[0][0]) + abs(points[-1][1] - points[0][1])
    return 1.0 if direct <= 1e-9 else length / direct


def segment_lengths(points: Sequence[Point]) -> list[float]:
    return [abs(x2 - x1) + abs(y2 - y1) for (x1, y1), (x2, y2) in zip(points, points[1:])]


def assess_composition(
    *,
    nodes: Sequence[tuple[str, Bounds]],
    containers: Sequence[tuple[str, Bounds]],
    edges: Sequence[Mapping[str, Any]],
    contract: CompositionContract,
) -> dict[str, Any]:
    """Return deterministic showcase metrics and actionable violations."""

    violations: list[dict[str, Any]] = []
    total_bends = 0
    total_bridges = 0
    max_stretch = 1.0
    shortest_segment: Optional[float] = None

    for edge in edges:
        edge_id = str(edge.get("id", "edge"))
        points = [tuple(map(float, point)) for point in edge.get("route", [])]
        bends = int(edge.get("bends", max(0, len(points) - 2)))
        bridges = len(edge.get("bridges", []))
        stretch = route_stretch(points)
        lengths = [length for length in segment_lengths(points) if length > 1e-6]
        local_shortest = min(lengths) if lengths else None
        total_bends += bends
        total_bridges += bridges
        max_stretch = max(max_stretch, stretch)
        if local_shortest is not None:
            shortest_segment = local_shortest if shortest_segment is None else min(shortest_segment, local_shortest)
        if bends > contract.max_bends_per_edge:
            violations.append({
                "code": "EDGE_BEND_BUDGET",
                "element": edge_id,
                "actual": bends,
                "limit": contract.max_bends_per_edge,
            })
        if stretch > contract.max_route_stretch + 1e-6:
            violations.append({
                "code": "EDGE_ROUTE_STRETCH",
                "element": edge_id,
                "actual": round(stretch, 3),
                "limit": contract.max_route_stretch,
            })
        if local_shortest is not None and local_shortest + 1e-6 < contract.min_segment_length:
            violations.append({
                "code": "EDGE_MICRO_SEGMENT",
                "element": edge_id,
                "actual": round(local_shortest, 2),
                "limit": contract.min_segment_length,
            })

    if total_bends > contract.max_total_bends:
        violations.append({
            "code": "TOTAL_BEND_BUDGET",
            "element": "diagram",
            "actual": total_bends,
            "limit": contract.max_total_bends,
        })
    if total_bridges > contract.max_bridged_crossings:
        violations.append({
            "code": "BRIDGE_BUDGET",
            "element": "diagram",
            "actual": total_bridges,
            "limit": contract.max_bridged_crossings,
        })

    minimum_gap: Optional[float] = None
    for index, (first_id, first) in enumerate(nodes):
        for second_id, second in nodes[index + 1 :]:
            gap = rectangle_gap(first, second)
            minimum_gap = gap if minimum_gap is None else min(minimum_gap, gap)
            if gap + 1e-6 < contract.min_node_gap:
                violations.append({
                    "code": "NODE_GAP",
                    "element": f"{first_id},{second_id}",
                    "actual": round(gap, 2),
                    "limit": contract.min_node_gap,
                })

    minimum_gutter: Optional[float] = None
    for node_id, node in nodes:
        match = containing_container(node, containers)
        if not match:
            continue
        container_id, container = match
        gutter = container_gutter(node, container)
        minimum_gutter = gutter if minimum_gutter is None else min(minimum_gutter, gutter)
        if gutter + 1e-6 < contract.min_container_gutter:
            violations.append({
                "code": "CONTAINER_GUTTER",
                "element": f"{node_id}@{container_id}",
                "actual": round(gutter, 2),
                "limit": contract.min_container_gutter,
            })

    penalty = (
        len(violations) * 12
        + total_bridges * 8
        + max(0, total_bends - len(edges)) * 2
    )
    return {
        "profile": contract.profile,
        "ok": not violations,
        "score": max(0, 100 - penalty),
        "metrics": {
            "total_bends": total_bends,
            "bridged_crossings": total_bridges,
            "max_route_stretch": round(max_stretch, 3),
            "minimum_node_gap": round(minimum_gap, 2) if minimum_gap is not None else None,
            "minimum_container_gutter": round(minimum_gutter, 2) if minimum_gutter is not None else None,
            "shortest_segment": round(shortest_segment, 2) if shortest_segment is not None else None,
        },
        "limits": contract.as_dict(),
        "violations": violations,
    }


__all__ = [
    "Bounds",
    "CompositionContract",
    "PROFILES",
    "assess_composition",
    "resolve_contract",
    "route_stretch",
]
