#!/usr/bin/env python3
"""Structured SVG checks used by validate-svg.sh.

The validator intentionally uses only the Python standard library so it works
inside a freshly installed skill without adding another runtime dependency.
"""

from __future__ import annotations

import argparse
import math
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, Optional, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import fireworks_geometry as geometry  # noqa: E402
import composition_quality as quality  # noqa: E402
from svg_canvas import parse_svg as parse_svg_source  # noqa: E402


NUMBER_RE = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
PATH_TOKEN_RE = re.compile(r"[AaCcHhLlMmQqSsTtVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
URL_REF_RE = re.compile(r"url\(\s*#([^\s)]+)\s*\)")
MARKER_ATTRIBUTES = ("marker-start", "marker-mid", "marker-end")
EXCLUDED_ROLES = {"background", "bridge-mask", "container", "decoration", "label", "legend", "reserved"}
IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

Point = tuple[float, float]
Matrix = tuple[float, float, float, float, float, float]


@dataclass(frozen=True)
class Bounds:
    left: float
    top: float
    right: float
    bottom: float


@dataclass(frozen=True)
class Collision:
    edge: str
    obstacle: str


@dataclass(frozen=True)
class ElementContext:
    element: ET.Element
    matrix: Matrix
    role: Optional[str]
    in_defs: bool


def local_name(tag: str) -> str:
    return tag.split("}", 1)[-1]


def parse_number(value: Optional[str], default: Optional[float] = 0.0) -> Optional[float]:
    if value is None:
        return default
    match = NUMBER_RE.match(value.strip())
    if not match:
        return default
    return float(match.group(0))


def multiply(left: Matrix, right: Matrix) -> Matrix:
    a1, b1, c1, d1, e1, f1 = left
    a2, b2, c2, d2, e2, f2 = right
    return (
        a1 * a2 + c1 * b2,
        b1 * a2 + d1 * b2,
        a1 * c2 + c1 * d2,
        b1 * c2 + d1 * d2,
        a1 * e2 + c1 * f2 + e1,
        b1 * e2 + d1 * f2 + f1,
    )


def transform_point(matrix: Matrix, point: Point) -> Point:
    a, b, c, d, e, f = matrix
    x, y = point
    return (a * x + c * y + e, b * x + d * y + f)


def parse_transform(value: Optional[str]) -> Matrix:
    result = IDENTITY
    if not value:
        return result
    for name, raw_values in re.findall(r"([A-Za-z]+)\s*\(([^)]*)\)", value):
        values = [float(item) for item in NUMBER_RE.findall(raw_values)]
        name = name.lower()
        current = IDENTITY
        if name == "matrix" and len(values) == 6:
            current = tuple(values)  # type: ignore[assignment]
        elif name == "translate" and values:
            current = (1, 0, 0, 1, values[0], values[1] if len(values) > 1 else 0)
        elif name == "scale" and values:
            current = (values[0], 0, 0, values[1] if len(values) > 1 else values[0], 0, 0)
        elif name == "rotate" and values:
            angle = math.radians(values[0])
            rotation = (math.cos(angle), math.sin(angle), -math.sin(angle), math.cos(angle), 0, 0)
            if len(values) >= 3:
                cx, cy = values[1], values[2]
                current = multiply(
                    multiply((1, 0, 0, 1, cx, cy), rotation),
                    (1, 0, 0, 1, -cx, -cy),
                )
            else:
                current = rotation
        elif name == "skewx" and len(values) == 1:
            current = (1, 0, math.tan(math.radians(values[0])), 1, 0, 0)
        elif name == "skewy" and len(values) == 1:
            current = (1, math.tan(math.radians(values[0])), 0, 1, 0, 0)
        result = multiply(result, current)
    return result


def infer_role(element: ET.Element, inherited: Optional[str]) -> Optional[str]:
    explicit = element.get("data-graph-role")
    if explicit:
        return explicit.strip().lower()
    identity = " ".join(filter(None, (element.get("id"), element.get("class")))).lower()
    if any(token in identity for token in ("legend", "key-box", "key_box")):
        return "legend"
    if local_name(element.tag) == "g":
        text = " ".join("".join(child.itertext()) for child in element if local_name(child.tag) == "text").lower()
        if "legend" in text:
            return "legend"
    return inherited


def walk(element: ET.Element, matrix: Matrix = IDENTITY, role: Optional[str] = None, in_defs: bool = False) -> Iterator[ElementContext]:
    current_matrix = multiply(matrix, parse_transform(element.get("transform")))
    current_role = infer_role(element, role)
    current_in_defs = in_defs or local_name(element.tag) == "defs"
    yield ElementContext(element, current_matrix, current_role, current_in_defs)
    child_role = current_role if current_role in {"background", "bridge-mask", "decoration", "label", "legend", "node", "reserved"} else None
    for child in element:
        yield from walk(child, current_matrix, child_role, current_in_defs)


def canvas_size(root: ET.Element) -> Point:
    values = [float(item) for item in NUMBER_RE.findall(root.get("viewBox", ""))]
    if len(values) == 4:
        return values[2], values[3]
    return (
        float(parse_number(root.get("width"), 0.0) or 0.0),
        float(parse_number(root.get("height"), 0.0) or 0.0),
    )


def metadata_bounds(context: ElementContext) -> Optional[Bounds]:
    values = [float(item) for item in NUMBER_RE.findall(context.element.get("data-graph-bounds", ""))]
    if len(values) != 4:
        return None
    left, top, right, bottom = values
    if not all(math.isfinite(value) for value in values) or right < left or bottom < top:
        return None
    return transformed_bounds(
        context.matrix,
        ((left, top), (right, top), (right, bottom), (left, bottom)),
    )


def bounds_from_points(points: Sequence[Point]) -> Optional[Bounds]:
    if not points:
        return None
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    return Bounds(min(xs), min(ys), max(xs), max(ys))


def transformed_bounds(matrix: Matrix, points: Sequence[Point]) -> Optional[Bounds]:
    return bounds_from_points([transform_point(matrix, point) for point in points])


def shape_bounds(context: ElementContext, canvas: Point) -> Optional[Bounds]:
    element = context.element
    tag = local_name(element.tag)
    role = context.role
    if context.in_defs or role in EXCLUDED_ROLES:
        return None

    declared = metadata_bounds(context)
    if declared is not None and role == "node":
        return declared

    if tag == "rect":
        x = float(parse_number(element.get("x"), 0.0) or 0.0)
        y = float(parse_number(element.get("y"), 0.0) or 0.0)
        width = parse_number(element.get("width"), None)
        height = parse_number(element.get("height"), None)
        if width is None or height is None or width <= 0 or height <= 0:
            return None
        canvas_width, canvas_height = canvas
        if role != "node":
            if element.get("x") is None and element.get("y") is None:
                return None
            if height <= 28 or width <= 8:
                return None
            nearly_canvas = canvas_width > 0 and canvas_height > 0 and width >= canvas_width * 0.9 and height >= canvas_height * 0.9
            if nearly_canvas:
                return None
            container_like = bool(element.get("stroke-dasharray")) or element.get("fill", "").strip().lower() == "none"
            if container_like and (
                (canvas_width > 0 and width >= canvas_width * 0.45)
                or (canvas_height > 0 and height >= canvas_height * 0.45)
            ):
                return None
        return transformed_bounds(
            context.matrix,
            ((x, y), (x + width, y), (x + width, y + height), (x, y + height)),
        )

    if tag in {"circle", "ellipse"}:
        cx = float(parse_number(element.get("cx"), 0.0) or 0.0)
        cy = float(parse_number(element.get("cy"), 0.0) or 0.0)
        rx = float(parse_number(element.get("r") or element.get("rx"), 0.0) or 0.0)
        ry = float(parse_number(element.get("r") or element.get("ry"), 0.0) or 0.0)
        if rx < 12 or ry < 12:
            return None
        return transformed_bounds(
            context.matrix,
            ((cx - rx, cy - ry), (cx + rx, cy - ry), (cx + rx, cy + ry), (cx - rx, cy + ry)),
        )

    if tag in {"polygon", "polyline"} and not has_marker(element):
        values = [float(item) for item in NUMBER_RE.findall(element.get("points", ""))]
        points = list(zip(values[::2], values[1::2]))
        if len(points) < 3:
            return None
        return transformed_bounds(context.matrix, points)
    return None


def has_marker(element: ET.Element) -> bool:
    return any(element.get(attribute) for attribute in MARKER_ATTRIBUTES)


def marker_references(root: ET.Element) -> tuple[set[str], set[str]]:
    definitions = {
        element.get("id", "")
        for element in root.iter()
        if local_name(element.tag) == "marker" and element.get("id")
    }
    references: set[str] = set()
    for element in root.iter():
        for attribute in MARKER_ATTRIBUTES:
            value = element.get(attribute, "")
            references.update(URL_REF_RE.findall(value))
    return definitions, references


def sample_quadratic(start: Point, control: Point, end: Point, steps: int = 12) -> list[Point]:
    return [
        (
            (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0],
            (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1],
        )
        for t in (index / steps for index in range(1, steps + 1))
    ]


def sample_cubic(start: Point, first: Point, second: Point, end: Point, steps: int = 16) -> list[Point]:
    return [
        (
            (1 - t) ** 3 * start[0] + 3 * (1 - t) ** 2 * t * first[0] + 3 * (1 - t) * t**2 * second[0] + t**3 * end[0],
            (1 - t) ** 3 * start[1] + 3 * (1 - t) ** 2 * t * first[1] + 3 * (1 - t) * t**2 * second[1] + t**3 * end[1],
        )
        for t in (index / steps for index in range(1, steps + 1))
    ]


def sample_arc(
    start: Point,
    rx: float,
    ry: float,
    rotation: float,
    large_arc: bool,
    sweep: bool,
    end: Point,
    steps: int = 20,
) -> list[Point]:
    """Sample an SVG endpoint-parameterized elliptical arc."""

    rx, ry = abs(rx), abs(ry)
    if rx <= 1e-9 or ry <= 1e-9 or start == end:
        return [end]
    phi = math.radians(rotation % 360)
    cos_phi, sin_phi = math.cos(phi), math.sin(phi)
    dx = (start[0] - end[0]) / 2
    dy = (start[1] - end[1]) / 2
    x_prime = cos_phi * dx + sin_phi * dy
    y_prime = -sin_phi * dx + cos_phi * dy
    scale = (x_prime * x_prime) / (rx * rx) + (y_prime * y_prime) / (ry * ry)
    if scale > 1:
        factor = math.sqrt(scale)
        rx *= factor
        ry *= factor
    numerator = max(
        0.0,
        rx * rx * ry * ry - rx * rx * y_prime * y_prime - ry * ry * x_prime * x_prime,
    )
    denominator = rx * rx * y_prime * y_prime + ry * ry * x_prime * x_prime
    coefficient = 0.0 if denominator <= 1e-12 else math.sqrt(numerator / denominator)
    if large_arc == sweep:
        coefficient = -coefficient
    center_x_prime = coefficient * (rx * y_prime / ry)
    center_y_prime = coefficient * (-ry * x_prime / rx)
    center_x = cos_phi * center_x_prime - sin_phi * center_y_prime + (start[0] + end[0]) / 2
    center_y = sin_phi * center_x_prime + cos_phi * center_y_prime + (start[1] + end[1]) / 2

    def angle(vector: Point) -> float:
        return math.atan2(vector[1], vector[0])

    start_angle = angle(((x_prime - center_x_prime) / rx, (y_prime - center_y_prime) / ry))
    end_angle = angle(((-x_prime - center_x_prime) / rx, (-y_prime - center_y_prime) / ry))
    delta = end_angle - start_angle
    if sweep and delta < 0:
        delta += math.tau
    elif not sweep and delta > 0:
        delta -= math.tau
    return [
        (
            center_x + rx * math.cos(start_angle + delta * index / steps) * cos_phi
            - ry * math.sin(start_angle + delta * index / steps) * sin_phi,
            center_y + rx * math.cos(start_angle + delta * index / steps) * sin_phi
            + ry * math.sin(start_angle + delta * index / steps) * cos_phi,
        )
        for index in range(1, steps + 1)
    ]


def path_routes(path_data: str, *, arc_chords: bool = False) -> list[list[Point]]:
    tokens = PATH_TOKEN_RE.findall(path_data or "")
    routes: list[list[Point]] = []
    points: list[Point] = []
    index = 0
    command = ""
    current = (0.0, 0.0)
    start = current
    previous_cubic: Optional[Point] = None
    previous_quadratic: Optional[Point] = None

    def read(count: int) -> Optional[list[float]]:
        nonlocal index
        if index + count > len(tokens) or any(re.fullmatch(r"[A-Za-z]", token) for token in tokens[index : index + count]):
            return None
        values = [float(token) for token in tokens[index : index + count]]
        index += count
        return values

    def absolute(x: float, y: float, relative: bool) -> Point:
        return (current[0] + x, current[1] + y) if relative else (x, y)

    while index < len(tokens):
        if re.fullmatch(r"[A-Za-z]", tokens[index]):
            command = tokens[index]
            index += 1
        if not command:
            return []
        relative = command.islower()
        op = command.upper()
        if op == "Z":
            if current != start:
                points.append(start)
            current = start
            previous_cubic = previous_quadratic = None
            command = ""
            continue
        count = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7}.get(op)
        if count is None:
            return []
        values = read(count)
        if values is None:
            return []

        if op == "M":
            if points:
                routes.append(points)
            current = absolute(values[0], values[1], relative)
            start = current
            points = [current]
            command = "l" if relative else "L"
        elif op == "L":
            current = absolute(values[0], values[1], relative)
            points.append(current)
        elif op == "H":
            current = (current[0] + values[0], current[1]) if relative else (values[0], current[1])
            points.append(current)
        elif op == "V":
            current = (current[0], current[1] + values[0]) if relative else (current[0], values[0])
            points.append(current)
        elif op == "C":
            first = absolute(values[0], values[1], relative)
            second = absolute(values[2], values[3], relative)
            end = absolute(values[4], values[5], relative)
            points.extend(sample_cubic(current, first, second, end))
            current, previous_cubic = end, second
            previous_quadratic = None
        elif op == "S":
            first = (2 * current[0] - previous_cubic[0], 2 * current[1] - previous_cubic[1]) if previous_cubic else current
            second = absolute(values[0], values[1], relative)
            end = absolute(values[2], values[3], relative)
            points.extend(sample_cubic(current, first, second, end))
            current, previous_cubic = end, second
            previous_quadratic = None
        elif op == "Q":
            control = absolute(values[0], values[1], relative)
            end = absolute(values[2], values[3], relative)
            points.extend(sample_quadratic(current, control, end))
            current, previous_quadratic = end, control
            previous_cubic = None
        elif op == "T":
            control = (2 * current[0] - previous_quadratic[0], 2 * current[1] - previous_quadratic[1]) if previous_quadratic else current
            end = absolute(values[0], values[1], relative)
            points.extend(sample_quadratic(current, control, end))
            current, previous_quadratic = end, control
            previous_cubic = None
        elif op == "A":
            end = absolute(values[5], values[6], relative)
            if arc_chords:
                points.append(end)
            else:
                points.extend(
                    sample_arc(
                        current,
                        values[0],
                        values[1],
                        values[2],
                        bool(values[3]),
                        bool(values[4]),
                        end,
                    )
                )
            current = end
            previous_cubic = previous_quadratic = None
        if op not in {"C", "S", "Q", "T"}:
            previous_cubic = previous_quadratic = None
    if points:
        routes.append(points)
    return routes


def edge_routes(context: ElementContext) -> list[list[Point]]:
    element = context.element
    tag = local_name(element.tag)
    explicit_edge = context.role == "edge"
    if (
        context.in_defs
        or context.role in {"background", "bridge-mask", "decoration", "label", "legend", "node", "reserved"}
        or (not explicit_edge and not has_marker(element))
    ):
        return []
    if tag == "line":
        routes = [[
            (float(parse_number(element.get("x1"), 0.0) or 0.0), float(parse_number(element.get("y1"), 0.0) or 0.0)),
            (float(parse_number(element.get("x2"), 0.0) or 0.0), float(parse_number(element.get("y2"), 0.0) or 0.0)),
        ]]
    elif tag == "polyline":
        values = [float(item) for item in NUMBER_RE.findall(element.get("points", ""))]
        routes = [list(zip(values[::2], values[1::2]))]
    elif tag == "path":
        routes = path_routes(
            element.get("d", ""),
            arc_chords=bool(element.get("data-bridges")),
        )
    else:
        return []
    return [
        [transform_point(context.matrix, point) for point in route]
        for route in routes
    ]


def segment_hits_bounds(start: Point, end: Point, bounds: Bounds, epsilon: float = 1e-5) -> bool:
    left, right = bounds.left + epsilon, bounds.right - epsilon
    top, bottom = bounds.top + epsilon, bounds.bottom - epsilon
    if left >= right or top >= bottom:
        return False
    x1, y1 = start
    dx, dy = end[0] - x1, end[1] - y1
    low, high = 0.0, 1.0
    for p, q in ((-dx, x1 - left), (dx, right - x1), (-dy, y1 - top), (dy, bottom - y1)):
        if abs(p) < epsilon:
            if q < 0:
                return False
            continue
        ratio = q / p
        if p < 0:
            low = max(low, ratio)
        else:
            high = min(high, ratio)
        if low > high:
            return False
    return high - low > epsilon and high > epsilon and low < 1 - epsilon


def points_within_bounds(points: Sequence[Point], bounds: Bounds, epsilon: float = 1e-5) -> bool:
    return bool(points) and all(
        bounds.left - epsilon <= x <= bounds.right + epsilon
        and bounds.top - epsilon <= y <= bounds.bottom + epsilon
        for x, y in points
    )


def find_collisions(root: ET.Element) -> list[Collision]:
    contexts = list(walk(root))
    obstacles = [
        (context, bounds)
        for context in contexts
        if (bounds := shape_bounds(context, canvas_size(root))) is not None
    ]
    edges = [(context, edge_routes(context)) for context in contexts]
    legend_obstacles = [
        (context, bounds)
        for context in contexts
        if context.role == "legend" and (bounds := role_bounds(context)) is not None
    ]
    obstacles.extend(legend_obstacles)
    collisions: list[Collision] = []
    for edge_context, routes in edges:
        if not any(len(route) >= 2 for route in routes):
            continue
        # A marker path wholly inside a recognized legend is decoration. The
        # legend remains a hard obstacle for every business edge outside it.
        if routes and all(
            any(points_within_bounds(route, bounds) for _, bounds in legend_obstacles)
            for route in routes
        ):
            continue
        edge = edge_context.element
        for obstacle_context, bounds in obstacles:
            obstacle = obstacle_context.element
            if any(
                segment_hits_bounds(first, second, bounds)
                for route in routes
                for first, second in zip(route, route[1:])
            ):
                collisions.append(
                    Collision(
                        describe_element(edge),
                        describe_element(obstacle),
                    )
                )
                break
    return collisions


def describe_element(element: ET.Element) -> str:
    tag = local_name(element.tag)
    if element.get("id"):
        return f"{tag}#{element.get('id')}"
    if tag == "path":
        path_data = re.sub(r"\s+", " ", element.get("d", "")).strip()
        return f"path[d={path_data[:72]}]"
    attributes = []
    for name in ("x", "y", "width", "height", "cx", "cy", "r", "rx", "ry"):
        if element.get(name) is not None:
            attributes.append(f"{name}={element.get(name)}")
    return f"{tag}[{' '.join(attributes)}]" if attributes else tag


def role_bounds(context: ElementContext) -> Optional[Bounds]:
    """Return explicit node/reserved/label bounds for the strict geometry gate."""

    declared = metadata_bounds(context)
    if declared is not None:
        return declared
    element = context.element
    tag = local_name(element.tag)
    if tag == "rect":
        x = float(parse_number(element.get("x"), 0.0) or 0.0)
        y = float(parse_number(element.get("y"), 0.0) or 0.0)
        width = parse_number(element.get("width"), None)
        height = parse_number(element.get("height"), None)
        if width is not None and height is not None and width >= 0 and height >= 0:
            return transformed_bounds(
                context.matrix,
                ((x, y), (x + width, y), (x + width, y + height), (x, y + height)),
            )
    if tag == "text" and context.role == "label":
        x = float(parse_number(element.get("x"), 0.0) or 0.0)
        y = float(parse_number(element.get("y"), 0.0) or 0.0)
        font_size = float(parse_number(element.get("font-size"), 12.0) or 12.0)
        anchor = element.get("text-anchor", "start")
        local = geometry.estimate_text_bounds(x, y, "".join(element.itertext()), font_size=font_size, anchor=anchor)
        return transformed_bounds(
            context.matrix,
            (
                (local[0], local[1]),
                (local[2], local[1]),
                (local[2], local[3]),
                (local[0], local[3]),
            ),
        )
    return None


def bounds_inside_canvas(bounds: Bounds, canvas: Bounds, epsilon: float = 1e-5) -> bool:
    return (
        bounds.left >= canvas.left - epsilon
        and bounds.top >= canvas.top - epsilon
        and bounds.right <= canvas.right + epsilon
        and bounds.bottom <= canvas.bottom + epsilon
    )


def geometry_check(root: ET.Element) -> list[str]:
    """Audit generated business geometry using explicit semantic SVG roles."""

    contexts = list(walk(root))
    paint_order = {id(context.element): index for index, context in enumerate(contexts)}
    width, height = canvas_size(root)
    canvas = Bounds(0.0, 0.0, width, height)
    details: list[str] = []

    obstacles: list[tuple[ElementContext, Bounds]] = []
    labels: list[tuple[ElementContext, Bounds]] = []
    bridge_masks: dict[str, ElementContext] = {}
    edges: list[tuple[ElementContext, list[list[Point]]]] = []
    matched_bridges: dict[str, list[Point]] = {}

    for context in contexts:
        if context.in_defs:
            continue
        if context.role in {"node", "reserved"}:
            if context.role == "node" and context.element.get("data-graph-role") != "node" and metadata_bounds(context) is None:
                continue
            bounds = role_bounds(context)
            if bounds is not None:
                obstacles.append((context, bounds))
        elif context.role == "label":
            if context.element.get("data-graph-role") != "label" and metadata_bounds(context) is None:
                continue
            bounds = role_bounds(context)
            if bounds is not None:
                labels.append((context, bounds))
        elif context.role == "bridge-mask":
            owner = context.element.get("data-owner", "")
            if owner:
                bridge_masks[owner] = context
        elif context.role == "edge":
            routes = edge_routes(context)
            if any(len(route) >= 2 for route in routes):
                edges.append((context, routes))

    for context, bounds in [*obstacles, *labels]:
        if not bounds_inside_canvas(bounds, canvas):
            details.append(f"canvas_clip: {describe_element(context.element)} exceeds viewBox")

    for edge_context, routes in edges:
        edge = edge_context.element
        edge_name = describe_element(edge)
        if not all(
            geometry.route_inside_canvas(route, (canvas.left, canvas.top, canvas.right, canvas.bottom))
            for route in routes
            if len(route) >= 2
        ):
            details.append(f"canvas_clip: {edge_name} exceeds viewBox")
        if root.get("data-generator") == "fireworks-tech-graph" and not all(
            geometry.route_is_orthogonal(route)
            for route in routes
            if len(route) >= 2
        ):
            details.append(f"non_orthogonal: {edge_name}")
        for obstacle_context, bounds in obstacles:
            obstacle_node_id = obstacle_context.element.get("data-node-id", "")
            if obstacle_node_id and obstacle_node_id in {
                edge.get("data-source", ""),
                edge.get("data-target", ""),
            }:
                continue
            if any(
                segment_hits_bounds(first, second, bounds)
                for route in routes
                for first, second in zip(route, route[1:])
            ):
                role = obstacle_context.role or "obstacle"
                details.append(
                    f"edge_{role}: {edge_name} intersects {describe_element(obstacle_context.element)}"
                )

    for first_index, (first_context, first_routes) in enumerate(edges):
        first_element = first_context.element
        first_name = describe_element(first_element)
        for second_context, second_routes in edges[first_index + 1 :]:
            second_element = second_context.element
            second_name = describe_element(second_element)
            interactions = [
                geometry.route_interactions(
                    first_route,
                    [route for route in second_routes if len(route) >= 2],
                )
                for first_route in first_routes
                if len(first_route) >= 2
            ]
            if any(item.overlap_count for item in interactions):
                details.append(f"edge_overlap: {first_name} overlaps {second_name}")
            for point in [point for item in interactions for point in item.crossings]:
                first_bridges = geometry.parse_bridge_points(first_element.get("data-bridges"))
                second_bridges = geometry.parse_bridge_points(second_element.get("data-bridges"))
                first_owner = first_element.get("data-edge-id") or first_element.get("id", "")
                second_owner = second_element.get("data-edge-id") or second_element.get("id", "")
                first_mask = bridge_masks.get(first_owner)
                second_mask = bridge_masks.get(second_owner)
                first_valid = (
                    geometry.bridge_declared(point, first_bridges)
                    and first_mask is not None
                    and paint_order[id(second_element)] < paint_order[id(first_mask.element)] < paint_order[id(first_element)]
                    and first_mask.element.get("d") == first_element.get("d")
                    and first_mask.matrix == first_context.matrix
                )
                second_valid = (
                    geometry.bridge_declared(point, second_bridges)
                    and second_mask is not None
                    and paint_order[id(first_element)] < paint_order[id(second_mask.element)] < paint_order[id(second_element)]
                    and second_mask.element.get("d") == second_element.get("d")
                    and second_mask.matrix == second_context.matrix
                )
                # Backwards compatibility for authored SVGs predating bridge masks.
                if root.get("data-generator") != "fireworks-tech-graph":
                    first_valid = first_valid or geometry.bridge_declared(point, first_bridges)
                    second_valid = second_valid or geometry.bridge_declared(point, second_bridges)
                if not (first_valid or second_valid):
                    declared = (
                        geometry.bridge_declared(point, first_bridges)
                        or geometry.bridge_declared(point, second_bridges)
                    )
                    code = "bridge_paint_order" if declared else "edge_crossing"
                    details.append(
                        f"{code}: {first_name} crosses {second_name} at {point[0]:.2f},{point[1]:.2f}"
                    )
                if first_valid:
                    matched_bridges.setdefault(first_owner, []).append(point)
                if second_valid:
                    matched_bridges.setdefault(second_owner, []).append(point)

    for label_index, (label_context, label_bounds) in enumerate(labels):
        label_name = describe_element(label_context.element)
        owner = label_context.element.get("data-owner", "")
        label_tuple = (label_bounds.left, label_bounds.top, label_bounds.right, label_bounds.bottom)
        for obstacle_context, obstacle_bounds in obstacles:
            obstacle_tuple = (obstacle_bounds.left, obstacle_bounds.top, obstacle_bounds.right, obstacle_bounds.bottom)
            if geometry.bounds_intersect(label_tuple, obstacle_tuple):
                details.append(f"label_obstacle: {label_name} intersects {describe_element(obstacle_context.element)}")
        for edge_context, edge_routes_for_context in edges:
            edge = edge_context.element
            edge_owner = edge.get("data-edge-id") or edge.get("id", "")
            if edge_owner == owner:
                continue
            if any(
                segment_hits_bounds(first, second, label_bounds)
                for route in edge_routes_for_context
                for first, second in zip(route, route[1:])
            ):
                details.append(f"label_edge: {label_name} intersects {describe_element(edge)}")
        for other_context, other_bounds in labels[label_index + 1 :]:
            other_tuple = (other_bounds.left, other_bounds.top, other_bounds.right, other_bounds.bottom)
            if geometry.bounds_intersect(label_tuple, other_tuple):
                details.append(f"label_overlap: {label_name} intersects {describe_element(other_context.element)}")

    for edge_context, _ in edges:
        edge = edge_context.element
        owner = edge.get("data-edge-id") or edge.get("id", "")
        bridges = geometry.parse_bridge_points(edge.get("data-bridges"))
        if bridges and owner not in bridge_masks and root.get("data-generator") == "fireworks-tech-graph":
            details.append(f"bridge_mask_missing: {describe_element(edge)}")
        for bridge in bridges:
            if not geometry.bridge_declared(bridge, matched_bridges.get(owner, [])):
                details.append(
                    f"bridge_without_crossing: {describe_element(edge)} declares {bridge[0]:.2f},{bridge[1]:.2f}"
                )

    return sorted(set(details))


def composition_contract(root: ET.Element) -> quality.CompositionContract:
    """Read the portable quality contract embedded in the SVG root."""

    raw: dict[str, object] = {
        "profile": root.get("data-quality-profile", "standard"),
    }
    attributes = {
        "max_bends_per_edge": "data-max-bends-per-edge",
        "max_total_bends": "data-max-total-bends",
        "max_route_stretch": "data-max-route-stretch",
        "max_bridged_crossings": "data-max-bridged-crossings",
        "min_node_gap": "data-min-node-gap",
        "min_container_gutter": "data-min-container-gutter",
        "min_label_clearance": "data-min-label-clearance",
        "min_segment_length": "data-min-segment-length",
    }
    for key, attribute in attributes.items():
        if root.get(attribute) is not None:
            raw[key] = root.get(attribute, "")
    return quality.resolve_contract(raw)


def composition_check(root: ET.Element) -> list[str]:
    """Enforce visual-composition budgets in addition to collision safety."""

    contexts = list(walk(root))
    contract = composition_contract(root)
    nodes: list[tuple[str, tuple[float, float, float, float]]] = []
    containers: list[tuple[str, tuple[float, float, float, float]]] = []
    labels: list[tuple[ElementContext, Bounds]] = []
    edges: list[tuple[ElementContext, list[list[Point]]]] = []

    for context in contexts:
        if context.in_defs:
            continue
        explicit = context.element.get("data-graph-role")
        bounds = role_bounds(context)
        if context.role == "node" and bounds is not None and (explicit == "node" or metadata_bounds(context) is not None):
            nodes.append(
                (
                    context.element.get("data-node-id") or context.element.get("id") or describe_element(context.element),
                    (bounds.left, bounds.top, bounds.right, bounds.bottom),
                )
            )
        elif context.role == "container" and bounds is not None and explicit == "container":
            containers.append(
                (
                    context.element.get("id") or describe_element(context.element),
                    (bounds.left, bounds.top, bounds.right, bounds.bottom),
                )
            )
        elif context.role == "label" and bounds is not None and (explicit == "label" or metadata_bounds(context) is not None):
            labels.append((context, bounds))
        if context.role == "edge" or (context.role is None and has_marker(context.element)):
            routes = edge_routes(context)
            if any(len(route) >= 2 for route in routes):
                edges.append((context, routes))

    edge_records = []
    for context, routes in edges:
        edge = context.element
        edge_id = edge.get("data-edge-id") or edge.get("id") or describe_element(edge)
        valid_routes = [route for route in routes if len(route) >= 2]
        declared_bridges = geometry.parse_bridge_points(edge.get("data-bridges"))
        for index, route in enumerate(valid_routes):
            edge_records.append(
                {
                    "id": edge_id if len(valid_routes) == 1 else f"{edge_id}:{index + 1}",
                    "route": route,
                    "bends": geometry.bend_count(route),
                    # Bridges are declared once per SVG edge element even when
                    # its path contains multiple independently drawn subpaths.
                    "bridges": declared_bridges if index == 0 else [],
                }
            )
    assessment = quality.assess_composition(
        nodes=nodes,
        containers=containers,
        edges=edge_records,
        contract=contract,
    )
    details = [
        f'composition_{str(item["code"]).lower()}: {item["element"]} '
        f'actual={item["actual"]} limit={item["limit"]}'
        for item in assessment["violations"]
    ]

    clearance = contract.min_label_clearance
    obstacle_bounds = [Bounds(*bounds) for _, bounds in nodes]
    for index, (label_context, label_bounds) in enumerate(labels):
        owner = label_context.element.get("data-owner", "")
        expanded = Bounds(
            label_bounds.left - clearance,
            label_bounds.top - clearance,
            label_bounds.right + clearance,
            label_bounds.bottom + clearance,
        )
        for obstacle in obstacle_bounds:
            if geometry.bounds_intersect(
                (expanded.left, expanded.top, expanded.right, expanded.bottom),
                (obstacle.left, obstacle.top, obstacle.right, obstacle.bottom),
            ):
                details.append(
                    f"composition_label_clearance: {describe_element(label_context.element)} is too close to a node"
                )
                break
        for edge_context, routes in edges:
            edge = edge_context.element
            edge_owner = edge.get("data-edge-id") or edge.get("id", "")
            if edge_owner == owner:
                continue
            if any(
                segment_hits_bounds(first, second, expanded)
                for route in routes
                for first, second in zip(route, route[1:])
            ):
                details.append(
                    f"composition_label_clearance: {describe_element(label_context.element)} is too close to {describe_element(edge)}"
                )
        for other_context, other_bounds in labels[index + 1 :]:
            if geometry.bounds_intersect(
                (expanded.left, expanded.top, expanded.right, expanded.bottom),
                (other_bounds.left, other_bounds.top, other_bounds.right, other_bounds.bottom),
            ):
                details.append(
                    f"composition_label_clearance: {describe_element(label_context.element)} is too close to {describe_element(other_context.element)}"
                )
    return sorted(set(details))


def parse_svg(path: Path) -> ET.Element:
    return parse_svg_source(path.read_text(encoding="utf-8"))


def run_check(path: Path, check: str) -> tuple[bool, list[str]]:
    try:
        root = parse_svg(path)
    except (ET.ParseError, OSError, ValueError) as error:
        return False, [str(error)]
    if check == "xml":
        return True, []
    if check == "markers":
        definitions, references = marker_references(root)
        missing = sorted(references - definitions)
        return not missing, [f"missing marker: {marker}" for marker in missing]
    if check == "geometry":
        details = geometry_check(root)
        return not details, details
    if check == "composition":
        details = composition_check(root)
        return not details, details
    collisions = find_collisions(root)
    details = [
        f"{item.edge} intersects {item.obstacle}"
        for item in collisions
    ]
    return not collisions, details


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("svg_file", type=Path)
    parser.add_argument("--check", choices=("xml", "markers", "collisions", "geometry", "composition"), required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ok, details = run_check(args.svg_file, args.check)
    for detail in details:
        print(detail)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
