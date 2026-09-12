#!/usr/bin/env python3
"""Typed, backwards-compatible input model for Fireworks Tech Graph.

The renderer keeps accepting the historical JSON shape. This module gives
that shape a versioned semantic boundary before any layout code runs.
"""

from __future__ import annotations

import copy
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Optional, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from semantic_contracts import resolve_style_index, validate_semantic_contract  # noqa: E402
from svg_canvas import parse_viewbox  # noqa: E402


class DiagramValidationError(ValueError):
    """Raised when input cannot be normalized to diagram schema v1."""


def _finite(value: Any, path: str) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError) as error:
        raise DiagramValidationError(f"{path} must be a finite number") from error
    if not math.isfinite(number):
        raise DiagramValidationError(f"{path} must be a finite number")
    return number


@dataclass(frozen=True)
class NodeIR:
    node_id: str
    raw: Mapping[str, Any]


@dataclass(frozen=True)
class EdgeIR:
    edge_id: str
    source: Optional[str]
    target: Optional[str]
    waypoints: tuple[tuple[float, float], ...]
    raw: Mapping[str, Any]


@dataclass(frozen=True)
class DiagramIR:
    schema_version: int
    input_schema: str
    mode: str
    style_index: int
    semantic_report: Mapping[str, Any]
    nodes: tuple[NodeIR, ...]
    edges: tuple[EdgeIR, ...]
    raw: Mapping[str, Any]

    def as_dict(self) -> dict[str, Any]:
        return copy.deepcopy(dict(self.raw))


def _validate_numeric_fields(item: Mapping[str, Any], fields: Sequence[str], path: str) -> None:
    for field in fields:
        if field in item and item[field] is not None:
            _finite(item[field], f"{path}.{field}")


def normalize_diagram(data: Mapping[str, Any], expected_mode: str) -> DiagramIR:
    if not isinstance(data, Mapping):
        raise DiagramValidationError("diagram input must be a JSON object")
    normalized = copy.deepcopy(dict(data))
    input_schema = "v1" if "schema_version" in normalized else "legacy"
    schema_version = normalized.get("schema_version", 1)
    if isinstance(schema_version, bool) or schema_version != 1:
        raise DiagramValidationError(f"unsupported schema_version: {schema_version}")

    mode = str(normalized.get("mode") or normalized.get("template_type") or expected_mode)
    if normalized.get("mode") and mode != expected_mode:
        raise DiagramValidationError(f"mode {mode!r} conflicts with template type {expected_mode!r}")
    normalized["schema_version"] = 1
    normalized["mode"] = mode

    if normalized.get("text_policy", "report") not in {"report", "strict"}:
        raise DiagramValidationError("text_policy must be report or strict")
    _validate_numeric_fields(normalized, ("width", "height"), "diagram")
    if "viewBox" in normalized:
        box = parse_viewbox(normalized["viewBox"])
        if box[:2] != (0.0, 0.0):
            raise DiagramValidationError("generated diagrams require a viewBox origin of 0 0")
        normalized["viewBox"] = " ".join(format(number, ".15g") for number in box)
    for field in ("width", "height"):
        if field in normalized and _finite(normalized[field], f"diagram.{field}") <= 0:
            raise DiagramValidationError(f"diagram.{field} must be greater than zero")

    raw_containers = normalized.get("containers", [])
    if not isinstance(raw_containers, list):
        raise DiagramValidationError("containers must be an array")
    containers: list[dict[str, Any]] = []
    container_ids: set[str] = set()
    for index, raw_container in enumerate(raw_containers):
        if not isinstance(raw_container, Mapping):
            raise DiagramValidationError(f"containers[{index}] must be an object")
        container = copy.deepcopy(dict(raw_container))
        container_id = str(container.get("id") or "").strip()
        if not container_id:
            raise DiagramValidationError(f"containers[{index}].id must be a non-empty string")
        if container_id in container_ids:
            raise DiagramValidationError(f"duplicate container id: {container_id}")
        container_ids.add(container_id)
        container["id"] = container_id
        _validate_numeric_fields(container, ("x", "y", "width", "height"), f"containers[{index}]")
        containers.append(container)
    normalized["containers"] = containers

    raw_nodes = normalized.get("nodes", [])
    if not isinstance(raw_nodes, list):
        raise DiagramValidationError("nodes must be an array")
    nodes: list[NodeIR] = []
    node_ids: set[str] = set()
    for index, raw_node in enumerate(raw_nodes):
        if not isinstance(raw_node, Mapping):
            raise DiagramValidationError(f"nodes[{index}] must be an object")
        node = copy.deepcopy(dict(raw_node))
        node_id = str(node.get("id") or f"node-{index:03d}")
        if node_id in node_ids:
            raise DiagramValidationError(f"duplicate node id: {node_id}")
        if node_id in container_ids:
            raise DiagramValidationError(f"duplicate diagram id: {node_id}")
        node_ids.add(node_id)
        node["id"] = node_id
        _validate_numeric_fields(node, ("x", "y", "width", "height", "r", "offset_y"), f"nodes[{index}]")
        nodes.append(NodeIR(node_id, node))
    normalized["nodes"] = [copy.deepcopy(dict(node.raw)) for node in nodes]

    if "edges" in normalized and "arrows" not in normalized:
        normalized["arrows"] = normalized.pop("edges")
    raw_edges = normalized.get("arrows", [])
    if not isinstance(raw_edges, list):
        raise DiagramValidationError("arrows must be an array")
    edges: list[EdgeIR] = []
    edge_ids: set[str] = set()
    for index, raw_edge in enumerate(raw_edges):
        if not isinstance(raw_edge, Mapping):
            raise DiagramValidationError(f"arrows[{index}] must be an object")
        edge = copy.deepcopy(dict(raw_edge))
        edge_id = str(edge.get("id") or f"edge-{index:03d}")
        if edge_id in edge_ids:
            raise DiagramValidationError(f"duplicate edge id: {edge_id}")
        if edge_id in container_ids or edge_id in node_ids:
            raise DiagramValidationError(f"duplicate diagram id: {edge_id}")
        edge_ids.add(edge_id)
        edge["id"] = edge_id
        source = str(edge["source"]) if edge.get("source") is not None else None
        target = str(edge["target"]) if edge.get("target") is not None else None
        for endpoint_name, endpoint in (("source", source), ("target", target)):
            if endpoint is not None and endpoint not in node_ids:
                raise DiagramValidationError(f"arrows[{index}].{endpoint_name} references unknown node: {endpoint}")
        _validate_numeric_fields(
            edge,
            ("x1", "y1", "x2", "y2", "label_dx", "label_dy", "routing_padding", "port_clearance"),
            f"arrows[{index}]",
        )
        raw_waypoints = edge.get("route_points", [])
        if not isinstance(raw_waypoints, list):
            raise DiagramValidationError(f"arrows[{index}].route_points must be an array")
        waypoints: list[tuple[float, float]] = []
        for waypoint_index, raw_waypoint in enumerate(raw_waypoints):
            if not isinstance(raw_waypoint, (list, tuple)) or len(raw_waypoint) != 2:
                raise DiagramValidationError(
                    f"arrows[{index}].route_points[{waypoint_index}] must be [x, y]"
                )
            waypoint = (
                _finite(raw_waypoint[0], f"arrows[{index}].route_points[{waypoint_index}][0]"),
                _finite(raw_waypoint[1], f"arrows[{index}].route_points[{waypoint_index}][1]"),
            )
            waypoints.append(waypoint)
        edge["route_points"] = [[x, y] for x, y in waypoints]
        edges.append(EdgeIR(edge_id, source, target, tuple(waypoints), edge))
    normalized["arrows"] = [copy.deepcopy(dict(edge.raw)) for edge in edges]

    style_index = resolve_style_index(normalized)
    semantic_report = validate_semantic_contract(normalized)
    return DiagramIR(
        1,
        input_schema,
        mode,
        style_index,
        semantic_report,
        tuple(nodes),
        tuple(edges),
        normalized,
    )


__all__ = [
    "DiagramIR",
    "DiagramValidationError",
    "EdgeIR",
    "NodeIR",
    "normalize_diagram",
]
