#!/usr/bin/env python3
"""Style catalog and semantic contracts for engineering-specific diagrams.

The visual style and engineering meaning are separate inputs.  Styles 9-12
select a useful default semantic profile, while ``semantic_profile: generic``
keeps the visual theme available to other diagram types and regression tests.
"""

from __future__ import annotations

import json
import math
from functools import lru_cache
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Optional, Sequence


class SemanticContractError(ValueError):
    """Raised when a diagram violates a selected engineering contract."""


STYLE_NAMES: dict[int, str] = {
    1: "Flat Icon",
    2: "Dark Terminal",
    3: "Blueprint",
    4: "Notion Clean",
    5: "Glassmorphism",
    6: "Claude Official",
    7: "OpenAI",
    8: "Dark Luxury",
    9: "C4 Review Canvas",
    10: "Cloud Fabric",
    11: "Event Transit",
    12: "Ops Pulse",
}

STYLE_DEFAULT_PROFILES = {
    9: "c4-review",
    10: "cloud-fabric",
    11: "event-transit",
    12: "ops-pulse",
}

PROFILE_ALIASES = {
    "generic": "generic",
    "none": "generic",
    "c4": "c4-review",
    "c4 review": "c4-review",
    "c4 review canvas": "c4-review",
    "architecture review board": "c4-review",
    "c4 评审画布": "c4-review",
    "架构评审画布": "c4-review",
    "c4-review": "c4-review",
    "cloud": "cloud-fabric",
    "cloud deployment": "cloud-fabric",
    "deployment topology": "cloud-fabric",
    "multi region deployment map": "cloud-fabric",
    "云部署拓扑": "cloud-fabric",
    "多区域部署图": "cloud-fabric",
    "cloud fabric": "cloud-fabric",
    "cloud-fabric": "cloud-fabric",
    "event stream": "event-transit",
    "event-stream": "event-transit",
    "event metro map": "event-transit",
    "topic rail map": "event-transit",
    "事件地铁图": "event-transit",
    "事件轨道图": "event-transit",
    "kafka": "event-transit",
    "event transit": "event-transit",
    "event-transit": "event-transit",
    "observability": "ops-pulse",
    "reliability pulse": "ops-pulse",
    "golden signals trace": "ops-pulse",
    "可靠性脉冲": "ops-pulse",
    "sre trace 评审": "ops-pulse",
    "otel": "ops-pulse",
    "ops pulse": "ops-pulse",
    "ops-pulse": "ops-pulse",
}


def _token(value: object) -> str:
    return " ".join(str(value).strip().lower().replace("_", " ").replace("-", " ").split())


STYLE_ALIASES: dict[str, int] = {}
for _style_id, _style_name in STYLE_NAMES.items():
    STYLE_ALIASES[_token(_style_name)] = _style_id
    STYLE_ALIASES[f"style {_style_id}"] = _style_id
    STYLE_ALIASES[f"风格 {_style_id}"] = _style_id
    STYLE_ALIASES[f"风格{_style_id}"] = _style_id
STYLE_ALIASES.update(
    {
        "flat": 1,
        "terminal": 2,
        "dark terminal": 2,
        "notion": 4,
        "glass": 5,
        "claude": 6,
        "openai official": 7,
        "review canvas": 9,
        "c4 canvas": 9,
        "c4 review": 9,
        "adr review canvas": 9,
        "architecture review board": 9,
        "c4 评审": 9,
        "c4 评审画布": 9,
        "adr 评审图": 9,
        "架构评审画布": 9,
        "职责边界评审图": 9,
        "cloud deployment": 10,
        "deployment topology": 10,
        "multi region deployment map": 10,
        "region vpc ownership map": 10,
        "cloud landing zone map": 10,
        "云部署拓扑": 10,
        "多区域部署图": 10,
        "region vpc 归属图": 10,
        "云 landing zone 图": 10,
        "event stream": 11,
        "event metro": 11,
        "event metro map": 11,
        "topic rail map": 11,
        "kafka topology": 11,
        "stream choreography map": 11,
        "事件轨道图": 11,
        "事件地铁图": 11,
        "topic 线路图": 11,
        "kafka 拓扑图": 11,
        "sre": 12,
        "observability": 12,
        "reliability pulse": 12,
        "incident investigation view": 12,
        "sre trace review": 12,
        "golden signals trace": 12,
        "运维脉冲图": 12,
        "可靠性脉冲": 12,
        "事故排查视图": 12,
        "sre trace 评审": 12,
        "黄金信号追踪图": 12,
    }
)


def resolve_style_index(data: Mapping[str, Any]) -> int:
    """Resolve numeric/name selectors and reject ambiguous or unknown themes."""

    selectors: list[tuple[str, object]] = []
    if data.get("style") is not None:
        selectors.append(("style", data["style"]))
    if data.get("visual_theme") is not None:
        selectors.append(("visual_theme", data["visual_theme"]))
    if not selectors:
        return 1

    resolved: list[tuple[str, int]] = []
    for field, raw in selectors:
        if isinstance(raw, bool):
            raise SemanticContractError(f"STYLE_SELECTOR: {field} must be a style id or name")
        if isinstance(raw, int):
            style_id = raw
        else:
            text = str(raw).strip()
            if text.isdigit():
                style_id = int(text)
            else:
                normalized = _token(text)
                if normalized not in STYLE_ALIASES:
                    raise SemanticContractError(f"STYLE_SELECTOR: unsupported {field}: {raw}")
                style_id = STYLE_ALIASES[normalized]
        if style_id not in STYLE_NAMES:
            raise SemanticContractError(f"STYLE_SELECTOR: unsupported {field}: {raw}")
        resolved.append((field, style_id))

    if len({style_id for _, style_id in resolved}) > 1:
        details = ", ".join(f"{field}={style_id}" for field, style_id in resolved)
        raise SemanticContractError(f"STYLE_SELECTOR_CONFLICT: {details}")
    return resolved[0][1]


def _fail(code: str, message: str) -> None:
    raise SemanticContractError(f"{code}: {message}")


def _require_text(item: Mapping[str, Any], field: str, path: str) -> str:
    value = str(item.get(field, "")).strip()
    if not value:
        _fail("SEMANTIC_REQUIRED", f"{path}.{field} is required")
    return value


def _number(value: Any, path: str) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError) as error:
        raise SemanticContractError(f"SEMANTIC_NUMBER: {path} must be finite") from error
    if not math.isfinite(number):
        _fail("SEMANTIC_NUMBER", f"{path} must be finite")
    return number


def _bounds(item: Mapping[str, Any], path: str) -> tuple[float, float, float, float]:
    x = _number(item.get("x"), f"{path}.x")
    y = _number(item.get("y"), f"{path}.y")
    width = _number(item.get("width"), f"{path}.width")
    height = _number(item.get("height"), f"{path}.height")
    if width <= 0 or height <= 0:
        _fail("SEMANTIC_BOUNDS", f"{path} must have positive width and height")
    return (x, y, x + width, y + height)


def _inside(inner: Sequence[float], outer: Sequence[float], inset: float) -> bool:
    return (
        inner[0] >= outer[0] + inset
        and inner[1] >= outer[1] + inset
        and inner[2] <= outer[2] - inset
        and inner[3] <= outer[3] - inset
    )


def _rectangle_gap(first: Sequence[float], second: Sequence[float]) -> float:
    horizontal = max(first[0] - second[2], second[0] - first[2], 0.0)
    vertical = max(first[1] - second[3], second[1] - first[3], 0.0)
    return math.hypot(horizontal, vertical)


def _node_map(data: Mapping[str, Any]) -> dict[str, MutableMapping[str, Any]]:
    return {
        str(node.get("id")): node
        for node in data.get("nodes", [])
        if isinstance(node, MutableMapping)
    }


def _edge_map(data: Mapping[str, Any]) -> dict[str, MutableMapping[str, Any]]:
    return {
        str(edge.get("id")): edge
        for edge in data.get("arrows", [])
        if isinstance(edge, MutableMapping)
    }


def _require_graph_endpoints(
    data: Mapping[str, Any], nodes: Mapping[str, Mapping[str, Any]]
) -> dict[str, MutableMapping[str, Any]]:
    """Keep engineering profiles tied to semantic nodes, never loose coordinates."""

    edges = _edge_map(data)
    for edge_id, edge in edges.items():
        source_id = str(edge.get("source", "")).strip()
        target_id = str(edge.get("target", "")).strip()
        if not source_id or not target_id:
            _fail(
                "SEMANTIC_EDGE_ENDPOINT",
                f"arrows[{edge_id}] must declare both source and target node ids",
            )
        if source_id not in nodes or target_id not in nodes:
            _fail(
                "SEMANTIC_EDGE_ENDPOINT",
                f"arrows[{edge_id}] references unknown endpoint {source_id!r} -> {target_id!r}",
            )
    return edges


def _validate_c4(data: MutableMapping[str, Any]) -> dict[str, Any]:
    if str(data.get("diagram_type", "")).strip() != "c4":
        _fail("C4_DIAGRAM_TYPE", "diagram_type must be 'c4'")
    level = _require_text(data, "c4_level", "diagram")
    if level not in {"context", "container", "component"}:
        _fail("C4_LEVEL", f"unsupported c4_level: {level}")
    _require_text(data, "title", "diagram")
    _require_text(data, "scope", "diagram")
    seed = data.get("rough_seed")
    if isinstance(seed, bool) or not isinstance(seed, int):
        _fail("C4_ROUGH_SEED", "rough_seed must be an integer")
    if not isinstance(data.get("legend"), list) or not data.get("legend"):
        _fail("C4_LEGEND", "a non-empty legend is required")

    allowed = {
        "context": {"person", "software_system", "external_system"},
        "container": {"person", "software_system", "external_system", "container"},
        "component": {"person", "software_system", "external_system", "container", "component"},
    }[level]
    boundaries = {
        str(item.get("id")): item
        for item in data.get("containers", [])
        if isinstance(item, Mapping)
    }
    nodes = _node_map(data)
    for node_id, node in nodes.items():
        c4_type = _require_text(node, "c4_type", f"nodes[{node_id}]")
        if c4_type not in allowed:
            _fail("C4_MIXED_ABSTRACTION", f"{node_id} type {c4_type!r} is invalid for {level} view")
        _require_text(node, "label", f"nodes[{node_id}]")
        _require_text(node, "description", f"nodes[{node_id}]")
        if c4_type in {"container", "component"}:
            _require_text(node, "technology", f"nodes[{node_id}]")
            bounds = _bounds(node, f"nodes[{node_id}]")
            if bounds[2] - bounds[0] < 170 or bounds[3] - bounds[1] < 96:
                _fail("C4_CARD_SIZE", f"{node_id} must be at least 170x96")
        parent = str(node.get("parent", "")).strip()
        if parent and parent not in boundaries:
            _fail("C4_PARENT", f"{node_id} references unknown boundary {parent}")
        if parent and not _inside(
            _bounds(node, f"nodes[{node_id}]"),
            _bounds(boundaries[parent], f"containers[{parent}]"),
            20,
        ):
            _fail("C4_BOUNDARY_ESCAPE", f"{node_id} must stay 20px inside {parent}")

    edges = _require_graph_endpoints(data, nodes)
    for edge_id, edge in edges.items():
        _require_text(edge, "label", f"arrows[{edge_id}]")
        _require_text(edge, "protocol", f"arrows[{edge_id}]")
    return {"level": level, "rough_seed": seed, "elements": len(nodes)}


@lru_cache(maxsize=1)
def _cloud_icons() -> tuple[str, dict[str, Mapping[str, Any]]]:
    path = Path(__file__).resolve().parents[1] / "assets" / "icons" / "cloud" / "manifest-v1.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    version = str(payload.get("version", ""))
    icons: dict[str, Mapping[str, Any]] = {}
    aliases: set[str] = set()
    for item in payload.get("icons", []):
        icon_id = str(item.get("id", "")).strip()
        if not icon_id or icon_id in icons:
            _fail("CLOUD_ICON_MANIFEST", f"duplicate or empty icon id: {icon_id}")
        icons[icon_id] = item
        for alias in item.get("aliases", []):
            normalized = _token(alias)
            if normalized in aliases:
                _fail("CLOUD_ICON_MANIFEST", f"duplicate icon alias: {alias}")
            aliases.add(normalized)
    return version, icons


def _validate_cloud(data: MutableMapping[str, Any]) -> dict[str, Any]:
    if str(data.get("diagram_type", "")).strip() != "deployment":
        _fail("CLOUD_DIAGRAM_TYPE", "diagram_type must be 'deployment'")
    platform = _require_text(data, "platform_profile", "diagram")
    if platform not in {"provider-neutral", "aws", "azure", "gcp", "kubernetes"}:
        _fail("CLOUD_PLATFORM", f"unsupported platform_profile: {platform}")
    manifest_version, icon_catalog = _cloud_icons()
    if str(data.get("icon_manifest_version", "")) != manifest_version:
        _fail("CLOUD_ICON_VERSION", f"icon_manifest_version must be {manifest_version}")

    containers = {
        str(item.get("id")): item
        for item in data.get("containers", [])
        if isinstance(item, Mapping)
    }
    if not containers or not any(item.get("deployment_kind") == "region" for item in containers.values()):
        _fail("CLOUD_BOUNDARY", "at least one region deployment boundary is required")

    def depth(container_id: str, trail: tuple[str, ...] = ()) -> int:
        if container_id in trail:
            _fail("CLOUD_BOUNDARY_CYCLE", " -> ".join((*trail, container_id)))
        parent = str(containers[container_id].get("parent", "")).strip()
        if not parent:
            return 1
        if parent not in containers:
            _fail("CLOUD_BOUNDARY_PARENT", f"{container_id} references unknown parent {parent}")
        return 1 + depth(parent, (*trail, container_id))

    depths = {container_id: depth(container_id) for container_id in containers}
    if max(depths.values()) > 4:
        _fail("CLOUD_BOUNDARY_DEPTH", "deployment nesting depth cannot exceed 4")
    for container_id, container in containers.items():
        _require_text(container, "deployment_kind", f"containers[{container_id}]")
        parent = str(container.get("parent", "")).strip()
        if parent and not _inside(_bounds(container, f"containers[{container_id}]"), _bounds(containers[parent], f"containers[{parent}]"), 16):
            _fail("CLOUD_BOUNDARY_ESCAPE", f"{container_id} must be inset inside {parent}")
    ordered_containers = list(containers.items())
    for index, (first_id, first) in enumerate(ordered_containers):
        first_parent = str(first.get("parent", "")).strip()
        for second_id, second in ordered_containers[index + 1 :]:
            if first_parent != str(second.get("parent", "")).strip():
                continue
            gap = _rectangle_gap(
                _bounds(first, f"containers[{first_id}]"),
                _bounds(second, f"containers[{second_id}]"),
            )
            if gap < 16:
                _fail("CLOUD_BOUNDARY_GAP", f"siblings {first_id} and {second_id} need 16px clearance")

    nodes = _node_map(data)
    for node_id, node in nodes.items():
        deployment_id = _require_text(node, "deployment_id", f"nodes[{node_id}]")
        if deployment_id not in containers:
            _fail("CLOUD_DEPLOYMENT", f"{node_id} references unknown deployment {deployment_id}")
        if not _inside(_bounds(node, f"nodes[{node_id}]"), _bounds(containers[deployment_id], f"containers[{deployment_id}]"), 20):
            _fail("CLOUD_NODE_ESCAPE", f"{node_id} must stay 20px inside {deployment_id}")
        icon_id = _require_text(node, "icon_id", f"nodes[{node_id}]")
        if icon_id not in icon_catalog:
            _fail("CLOUD_ICON_UNKNOWN", f"unknown icon_id: {icon_id}")
        icon = icon_catalog[icon_id]
        node.setdefault("icon_badge", icon.get("badge", "CLOUD"))
        node.setdefault("icon_color", icon.get("color", "#2563eb"))
        node.setdefault("glyph", icon.get("glyph", "service"))
        node.setdefault("icon_source", "builtin-neutral")
        node.setdefault("icon_version", manifest_version)
        lineage: list[str] = []
        current = deployment_id
        while current:
            boundary = containers[current]
            lineage.append(str(boundary.get("label", current)))
            current = str(boundary.get("parent", "")).strip()
        node.setdefault("deployment_path", " › ".join(reversed(lineage)))

    edges = _require_graph_endpoints(data, nodes)
    for edge_id, edge in edges.items():
        source = nodes[str(edge["source"])]
        target = nodes[str(edge["target"])]
        if source.get("deployment_id") != target.get("deployment_id"):
            _require_text(edge, "via", f"arrows[{edge_id}]")
    return {
        "platform": platform,
        "manifest_version": manifest_version,
        "boundaries": len(containers),
        "max_depth": max(depths.values()),
    }


def _validate_event(data: MutableMapping[str, Any]) -> dict[str, Any]:
    if str(data.get("diagram_type", "")).strip() != "event_stream":
        _fail("EVENT_DIAGRAM_TYPE", "diagram_type must be 'event_stream'")
    topics = data.get("topics", [])
    if not isinstance(topics, list) or not topics:
        _fail("EVENT_TOPICS", "topics must be a non-empty array")
    if len(topics) > 4:
        _fail("EVENT_TOPIC_LIMIT", "showcase diagrams support at most four topic rails")
    topic_colors: dict[str, str] = {}
    for index, topic in enumerate(topics):
        if not isinstance(topic, Mapping):
            _fail("EVENT_TOPIC", f"topics[{index}] must be an object")
        topic_id = _require_text(topic, "id", f"topics[{index}]")
        color = _require_text(topic, "color", f"topics[{index}]")
        if topic_id in topic_colors:
            _fail("EVENT_TOPIC_DUPLICATE", f"duplicate topic id: {topic_id}")
        topic_colors[topic_id] = color

    nodes = _node_map(data)
    allowed_roles = {"producer", "station", "junction", "consumer", "dlq", "state_store"}
    orders: dict[tuple[str, int], str] = {}
    for node_id, node in nodes.items():
        role = _require_text(node, "transit_role", f"nodes[{node_id}]")
        if role not in allowed_roles:
            _fail("EVENT_ROLE", f"unsupported transit_role {role!r} on {node_id}")
        topic_id = str(node.get("topic_id", "")).strip()
        if topic_id and topic_id not in topic_colors:
            _fail("EVENT_TOPIC_UNKNOWN", f"{node_id} references unknown topic {topic_id}")
        if topic_id:
            node.setdefault("rail_color", topic_colors[topic_id])
        if role in {"station", "junction"}:
            _require_text(node, "operation", f"nodes[{node_id}]")
        if role == "consumer":
            _require_text(node, "consumer_group", f"nodes[{node_id}]")
        if role not in {"dlq", "state_store"}:
            order = node.get("station_order")
            if isinstance(order, bool) or not isinstance(order, int):
                _fail("EVENT_STATION_ORDER", f"{node_id}.station_order must be an integer")
            key = (topic_id, order)
            if key in orders:
                _fail("EVENT_STATION_ORDER", f"duplicate order {order} for topic {topic_id}")
            orders[key] = node_id

    edges = _require_graph_endpoints(data, nodes)
    rail_outgoing: dict[str, int] = {}
    for edge_id, edge in edges.items():
        transit_type = _require_text(edge, "transit_type", f"arrows[{edge_id}]")
        source = nodes[str(edge["source"])]
        target = nodes[str(edge["target"])]
        if transit_type == "rail":
            topic_id = _require_text(edge, "topic_id", f"arrows[{edge_id}]")
            if source.get("topic_id") != topic_id or target.get("topic_id") != topic_id:
                _fail("EVENT_TOPIC_DRIFT", f"{edge_id} must connect nodes on topic {topic_id}")
            if int(target.get("station_order", -1)) != int(source.get("station_order", -2)) + 1:
                _fail("EVENT_RAIL_ORDER", f"{edge_id} must connect adjacent increasing stations")
            source_bounds = _bounds(source, f"nodes[{source.get('id')}]")
            target_bounds = _bounds(target, f"nodes[{target.get('id')}]")
            if abs((source_bounds[1] + source_bounds[3]) - (target_bounds[1] + target_bounds[3])) > 1e-6:
                _fail("EVENT_RAIL_ALIGNMENT", f"{edge_id} rail endpoints must share one horizontal centerline")
            if target_bounds[0] - source_bounds[2] < 64:
                _fail("EVENT_RAIL_LENGTH", f"{edge_id} rail must have at least 64px clearance")
            if edge.get("source_port") != "right" or edge.get("target_port") != "left":
                _fail("EVENT_RAIL_PORT", f"{edge_id} must use right-to-left ports")
            rail_outgoing[str(edge.get("source"))] = rail_outgoing.get(str(edge.get("source")), 0) + 1
        elif transit_type == "dead_letter":
            if target.get("transit_role") != "dlq":
                _fail("EVENT_DLQ_TARGET", f"{edge_id} must target a dlq node")
            edge.setdefault("dashed", True)
        elif transit_type == "branch":
            if source.get("transit_role") != "junction":
                _fail("EVENT_BRANCH_JUNCTION", f"{edge_id} must depart from a junction node")
        elif transit_type not in {"publish", "branch", "consume", "retry", "state"}:
            _fail("EVENT_EDGE_TYPE", f"unsupported transit_type: {transit_type}")
    for node_id, count in rail_outgoing.items():
        if count > 1 and nodes[node_id].get("transit_role") != "junction":
            _fail("EVENT_BRANCH_JUNCTION", f"{node_id} branches without a junction role")
    return {"topics": len(topics), "stations": len(nodes)}


def _validate_ops(data: MutableMapping[str, Any]) -> dict[str, Any]:
    if str(data.get("diagram_type", "")).strip() != "observability":
        _fail("OPS_DIAGRAM_TYPE", "diagram_type must be 'observability'")
    observation_window = _require_text(data, "observation_window", "diagram")
    nodes = _node_map(data)
    edges = _require_graph_endpoints(data, nodes)
    services = [node for node in nodes.values() if node.get("ops_role") == "service"]
    if not services or len(services) > 12:
        _fail("OPS_SERVICE_LIMIT", "an Ops Pulse view requires 1-12 service nodes")
    expected_signals = {"latency", "traffic", "errors", "saturation"}
    allowed_status = {"ok", "warn", "critical", "unknown"}
    for node in services:
        node_id = str(node.get("id"))
        status = _require_text(node, "status", f"nodes[{node_id}]")
        if status not in allowed_status:
            _fail("OPS_SERVICE_STATUS", f"unsupported status {status!r} on {node_id}")
        metrics = node.get("signals")
        if not isinstance(metrics, Mapping) or set(metrics) != expected_signals:
            _fail("OPS_GOLDEN_SIGNALS", f"{node_id} must define exactly latency, traffic, errors, saturation")
        _require_text(node, "status_label", f"nodes[{node_id}]")
        bounds = _bounds(node, f"nodes[{node_id}]")
        if bounds[2] - bounds[0] < 180 or bounds[3] - bounds[1] < 108:
            _fail("OPS_CARD_SIZE", f"{node_id} must be at least 180x108")
        normalized_signals: list[dict[str, str]] = []
        for signal_name in ("latency", "traffic", "errors", "saturation"):
            signal = metrics[signal_name]
            if not isinstance(signal, Mapping):
                _fail("OPS_SIGNAL", f"{node_id}.{signal_name} must be an object")
            value = _require_text(signal, "value", f"nodes[{node_id}].signals.{signal_name}")
            unit = _require_text(signal, "unit", f"nodes[{node_id}].signals.{signal_name}")
            window = _require_text(signal, "window", f"nodes[{node_id}].signals.{signal_name}")
            if window != observation_window:
                _fail(
                    "OPS_OBSERVATION_WINDOW",
                    f"{node_id}.{signal_name} window {window!r} must match diagram observation_window {observation_window!r}",
                )
            status = _require_text(signal, "status", f"nodes[{node_id}].signals.{signal_name}")
            if status not in allowed_status:
                _fail("OPS_SIGNAL_STATUS", f"unsupported status {status!r} on {node_id}.{signal_name}")
            normalized_signals.append(
                {"name": signal_name, "value": value, "unit": unit, "window": window, "status": status}
            )
        node["metric_badges"] = normalized_signals

    critical_path = data.get("critical_path", [])
    if not isinstance(critical_path, list) or not critical_path:
        _fail("OPS_CRITICAL_PATH", "critical_path must be a non-empty ordered edge-id list")
    if len(set(map(str, critical_path))) != len(critical_path):
        _fail("OPS_CRITICAL_PATH", "critical_path cannot repeat an edge")
    previous_target = None
    visited_services: set[str] = set()
    service_ids = {str(node.get("id")) for node in services}
    for critical_index, raw_edge_id in enumerate(critical_path):
        edge_id = str(raw_edge_id)
        if edge_id not in edges:
            _fail("OPS_CRITICAL_PATH", f"unknown critical edge: {edge_id}")
        edge = edges[edge_id]
        if edge.get("edge_kind", "business") != "business":
            _fail("OPS_CRITICAL_PATH", f"critical edge {edge_id} must be a business edge")
        source_id = str(edge.get("source"))
        target_id = str(edge.get("target"))
        if source_id not in service_ids or target_id not in service_ids:
            _fail("OPS_CRITICAL_PATH", f"critical edge {edge_id} must connect service nodes")
        if previous_target is not None and str(edge.get("source")) != previous_target:
            _fail("OPS_CRITICAL_PATH", f"critical path is discontinuous before {edge_id}")
        if not visited_services:
            visited_services.add(source_id)
        if target_id in visited_services:
            _fail("OPS_CRITICAL_PATH", f"critical path repeats service {target_id}")
        visited_services.add(target_id)
        previous_target = target_id
        edge["critical"] = True
        edge["critical_path_id"] = str(data.get("critical_path_id", "critical-1"))
        edge["critical_hop"] = critical_index + 1
        edge["critical_hops"] = len(critical_path)

    business_flows = {
        str(edge.get("flow", "control"))
        for edge in edges.values()
        if edge.get("edge_kind", "business") == "business"
    }
    telemetry_flows = {
        str(edge.get("flow", "async"))
        for edge in edges.values()
        if edge.get("edge_kind") == "telemetry"
    }
    if business_flows & telemetry_flows:
        _fail("OPS_FLOW_SEMANTICS", "business and telemetry edges must use different flow tokens")

    spans = [node for node in nodes.values() if node.get("ops_role") == "trace_span"]
    if not spans:
        _fail("OPS_TRACE_REQUIRED", "an Ops Pulse view requires one correlated trace waterfall")
    span_map = {str(span.get("span_id")): span for span in spans}
    if len(span_map) != len(spans):
        _fail("OPS_SPAN_ID", "trace span ids must be unique")
    roots = 0
    root_span: Optional[Mapping[str, Any]] = None
    for span in spans:
        span_id = _require_text(span, "span_id", f"nodes[{span.get('id')}]")
        start = _number(span.get("start_ms"), f"spans[{span_id}].start_ms")
        duration = _number(span.get("duration_ms"), f"spans[{span_id}].duration_ms")
        if duration <= 0:
            _fail("OPS_SPAN_DURATION", f"{span_id} duration must be positive")
        parent_id = str(span.get("parent_span", "")).strip()
        if not parent_id:
            roots += 1
            root_span = span
            continue
        parent = span_map.get(parent_id)
        if parent is None:
            _fail("OPS_SPAN_PARENT", f"{span_id} references unknown parent span {parent_id}")
        parent_start = _number(parent.get("start_ms"), f"spans[{parent_id}].start_ms")
        parent_duration = _number(parent.get("duration_ms"), f"spans[{parent_id}].duration_ms")
        if start < parent_start or start + duration > parent_start + parent_duration:
            _fail("OPS_SPAN_COVERAGE", f"{span_id} must be contained by {parent_id}")
    if spans and roots != 1:
        _fail("OPS_SPAN_ROOT", "trace waterfall must contain exactly one root span")
    for span_id, span in span_map.items():
        seen: set[str] = set()
        current_id = span_id
        current = span
        while current.get("parent_span"):
            if current_id in seen:
                _fail("OPS_SPAN_CYCLE", f"trace parent cycle contains {current_id}")
            seen.add(current_id)
            current_id = str(current.get("parent_span"))
            if current_id not in span_map:
                break
            current = span_map[current_id]
    if root_span is not None:
        root_bounds = _bounds(root_span, f"spans[{root_span.get('span_id')}]")
        root_start = _number(root_span.get("start_ms"), "root_span.start_ms")
        root_duration = _number(root_span.get("duration_ms"), "root_span.duration_ms")
        pixels_per_ms = (root_bounds[2] - root_bounds[0]) / root_duration
        origin_x = root_bounds[0] - root_start * pixels_per_ms
        for span in spans:
            span_id = str(span.get("span_id"))
            span_bounds = _bounds(span, f"spans[{span_id}]")
            start = _number(span.get("start_ms"), f"spans[{span_id}].start_ms")
            duration = _number(span.get("duration_ms"), f"spans[{span_id}].duration_ms")
            expected_x = origin_x + start * pixels_per_ms
            expected_width = duration * pixels_per_ms
            if abs(span_bounds[0] - expected_x) > 1.5 or abs((span_bounds[2] - span_bounds[0]) - expected_width) > 1.5:
                _fail("OPS_SPAN_SCALE", f"{span_id} x/width must encode start_ms/duration_ms on the root time scale")
    return {
        "services": len(services),
        "spans": len(spans),
        "critical_edges": len(critical_path),
        "observation_window": observation_window,
    }


def validate_semantic_contract(data: MutableMapping[str, Any]) -> dict[str, Any]:
    """Validate and enrich a normalized diagram payload."""

    style_index = resolve_style_index(data)
    raw_profile = data.get("semantic_profile")
    if raw_profile is None:
        profile = STYLE_DEFAULT_PROFILES.get(style_index, "generic")
    else:
        normalized = _token(raw_profile)
        if normalized not in PROFILE_ALIASES:
            _fail("SEMANTIC_PROFILE", f"unsupported semantic_profile: {raw_profile}")
        profile = PROFILE_ALIASES[normalized]
    data["semantic_profile"] = profile

    validators = {
        "c4-review": _validate_c4,
        "cloud-fabric": _validate_cloud,
        "event-transit": _validate_event,
        "ops-pulse": _validate_ops,
    }
    details = validators[profile](data) if profile in validators else {}
    return {
        "ok": True,
        "style": style_index,
        "visual_theme": STYLE_NAMES[style_index],
        "profile": profile,
        "details": details,
    }


__all__ = [
    "PROFILE_ALIASES",
    "STYLE_ALIASES",
    "STYLE_DEFAULT_PROFILES",
    "STYLE_NAMES",
    "SemanticContractError",
    "resolve_style_index",
    "validate_semantic_contract",
]
