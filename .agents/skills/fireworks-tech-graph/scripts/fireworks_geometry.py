#!/usr/bin/env python3
"""Deterministic geometry primitives shared by the renderer and SVG checker.

The module deliberately uses only the Python standard library.  Generated
diagrams can therefore enforce the same routing contract in a fresh Agent
Skill install, in CI, and in the post-render artifact checker.
"""

from __future__ import annotations

import math
import unicodedata
from dataclasses import dataclass
from typing import Iterable, Optional, Sequence


Point = tuple[float, float]
Bounds = tuple[float, float, float, float]
EPSILON = 1e-6


@dataclass(frozen=True)
class SegmentInteraction:
    kind: str
    point: Optional[Point] = None
    overlap_length: float = 0.0


@dataclass(frozen=True)
class RouteInteractions:
    crossings: tuple[Point, ...]
    overlap_count: int
    overlap_length: float


def almost_equal(first: float, second: float, epsilon: float = EPSILON) -> bool:
    return abs(first - second) <= epsilon


def same_point(first: Point, second: Point, epsilon: float = EPSILON) -> bool:
    return almost_equal(first[0], second[0], epsilon) and almost_equal(first[1], second[1], epsilon)


def segment_axis(first: Point, second: Point) -> str:
    if almost_equal(first[1], second[1]):
        return "horizontal"
    if almost_equal(first[0], second[0]):
        return "vertical"
    return "other"


def route_is_orthogonal(points: Sequence[Point]) -> bool:
    return all(segment_axis(first, second) != "other" for first, second in zip(points, points[1:]))


def route_length(points: Sequence[Point]) -> float:
    return sum(math.hypot(second[0] - first[0], second[1] - first[1]) for first, second in zip(points, points[1:]))


def bend_count(points: Sequence[Point]) -> int:
    axes = [segment_axis(first, second) for first, second in zip(points, points[1:]) if not same_point(first, second)]
    return sum(first != second for first, second in zip(axes, axes[1:]))


def bounds_intersect(first: Bounds, second: Bounds, padding: float = 0.0) -> bool:
    left_a, top_a, right_a, bottom_a = first
    left_b, top_b, right_b, bottom_b = second
    return not (
        right_a + padding <= left_b
        or right_b + padding <= left_a
        or bottom_a + padding <= top_b
        or bottom_b + padding <= top_a
    )


def expand_bounds(bounds: Bounds, padding: float) -> Bounds:
    left, top, right, bottom = bounds
    return (left - padding, top - padding, right + padding, bottom + padding)


def point_in_bounds(point: Point, bounds: Bounds, *, padding: float = 0.0, interior: bool = False) -> bool:
    x, y = point
    left, top, right, bottom = bounds
    if interior:
        return left + padding < x < right - padding and top + padding < y < bottom - padding
    return left - padding <= x <= right + padding and top - padding <= y <= bottom + padding


def bounds_inside(inner: Bounds, outer: Bounds, padding: float = 0.0) -> bool:
    left, top, right, bottom = inner
    outer_left, outer_top, outer_right, outer_bottom = outer
    return (
        left >= outer_left + padding
        and top >= outer_top + padding
        and right <= outer_right - padding
        and bottom <= outer_bottom - padding
    )


def route_inside_canvas(points: Sequence[Point], canvas: Bounds, margin: float = 0.0) -> bool:
    left, top, right, bottom = canvas
    safe = (left + margin, top + margin, right - margin, bottom - margin)
    return all(point_in_bounds(point, safe) for point in points)


def _orientation(first: Point, second: Point, third: Point) -> float:
    return (second[0] - first[0]) * (third[1] - first[1]) - (second[1] - first[1]) * (third[0] - first[0])


def _on_segment(point: Point, first: Point, second: Point, epsilon: float = EPSILON) -> bool:
    return (
        min(first[0], second[0]) - epsilon <= point[0] <= max(first[0], second[0]) + epsilon
        and min(first[1], second[1]) - epsilon <= point[1] <= max(first[1], second[1]) + epsilon
        and abs(_orientation(first, second, point)) <= epsilon
    )


def segment_interaction(first_a: Point, first_b: Point, second_a: Point, second_b: Point) -> Optional[SegmentInteraction]:
    """Return a proper crossing, touch, or collinear overlap for two segments."""

    first_axis = segment_axis(first_a, first_b)
    second_axis = segment_axis(second_a, second_b)

    if first_axis == second_axis == "horizontal" and almost_equal(first_a[1], second_a[1]):
        start = max(min(first_a[0], first_b[0]), min(second_a[0], second_b[0]))
        end = min(max(first_a[0], first_b[0]), max(second_a[0], second_b[0]))
        if end - start > EPSILON:
            return SegmentInteraction("overlap", overlap_length=end - start)
        if almost_equal(start, end):
            return SegmentInteraction("touch", (start, first_a[1]))
        return None

    if first_axis == second_axis == "vertical" and almost_equal(first_a[0], second_a[0]):
        start = max(min(first_a[1], first_b[1]), min(second_a[1], second_b[1]))
        end = min(max(first_a[1], first_b[1]), max(second_a[1], second_b[1]))
        if end - start > EPSILON:
            return SegmentInteraction("overlap", overlap_length=end - start)
        if almost_equal(start, end):
            return SegmentInteraction("touch", (first_a[0], start))
        return None

    if first_axis == "horizontal" and second_axis == "vertical":
        point = (second_a[0], first_a[1])
        if _on_segment(point, first_a, first_b) and _on_segment(point, second_a, second_b):
            return SegmentInteraction("crossing", point)
        return None

    if first_axis == "vertical" and second_axis == "horizontal":
        point = (first_a[0], second_a[1])
        if _on_segment(point, first_a, first_b) and _on_segment(point, second_a, second_b):
            return SegmentInteraction("crossing", point)
        return None

    # General line intersection keeps the artifact checker useful for authored
    # SVGs and sampled curves. Collinear diagonal overlap is intentionally
    # treated conservatively as an overlap.
    o1 = _orientation(first_a, first_b, second_a)
    o2 = _orientation(first_a, first_b, second_b)
    o3 = _orientation(second_a, second_b, first_a)
    o4 = _orientation(second_a, second_b, first_b)
    if abs(o1) <= EPSILON and abs(o2) <= EPSILON and abs(o3) <= EPSILON and abs(o4) <= EPSILON:
        candidates = [point for point in (first_a, first_b, second_a, second_b) if _on_segment(point, first_a, first_b) and _on_segment(point, second_a, second_b)]
        unique = unique_points(candidates)
        if len(unique) >= 2:
            return SegmentInteraction("overlap", overlap_length=max(math.dist(a, b) for a in unique for b in unique))
        if unique:
            return SegmentInteraction("touch", unique[0])
        return None
    if o1 * o2 <= EPSILON and o3 * o4 <= EPSILON:
        denominator = (first_a[0] - first_b[0]) * (second_a[1] - second_b[1]) - (first_a[1] - first_b[1]) * (second_a[0] - second_b[0])
        if abs(denominator) <= EPSILON:
            return None
        determinant_first = first_a[0] * first_b[1] - first_a[1] * first_b[0]
        determinant_second = second_a[0] * second_b[1] - second_a[1] * second_b[0]
        x = (determinant_first * (second_a[0] - second_b[0]) - (first_a[0] - first_b[0]) * determinant_second) / denominator
        y = (determinant_first * (second_a[1] - second_b[1]) - (first_a[1] - first_b[1]) * determinant_second) / denominator
        point = (x, y)
        if _on_segment(point, first_a, first_b) and _on_segment(point, second_a, second_b):
            return SegmentInteraction("crossing", point)
    return None


def unique_points(points: Iterable[Point], tolerance: float = 0.01) -> list[Point]:
    result: list[Point] = []
    for point in points:
        rounded = (round(point[0], 2), round(point[1], 2))
        if not any(same_point(rounded, existing, tolerance) for existing in result):
            result.append(rounded)
    return result


def is_shared_route_endpoint(point: Point, first: Sequence[Point], second: Sequence[Point], tolerance: float = 0.01) -> bool:
    return any(same_point(point, endpoint, tolerance) for endpoint in (first[0], first[-1])) and any(
        same_point(point, endpoint, tolerance) for endpoint in (second[0], second[-1])
    )


def route_interactions(route: Sequence[Point], others: Sequence[Sequence[Point]]) -> RouteInteractions:
    crossings: list[Point] = []
    overlap_count = 0
    overlap_length = 0.0
    for other in others:
        if len(other) < 2:
            continue
        for first_a, first_b in zip(route, route[1:]):
            for second_a, second_b in zip(other, other[1:]):
                interaction = segment_interaction(first_a, first_b, second_a, second_b)
                if interaction is None:
                    continue
                if interaction.kind == "overlap":
                    overlap_count += 1
                    overlap_length += interaction.overlap_length
                    continue
                if interaction.point is None or is_shared_route_endpoint(interaction.point, route, other):
                    continue
                if interaction.kind in {"crossing", "touch"}:
                    crossings.append(interaction.point)
    return RouteInteractions(tuple(unique_points(crossings)), overlap_count, round(overlap_length, 2))


def route_crossing_count(route: Sequence[Point], others: Sequence[Sequence[Point]]) -> int:
    return len(route_interactions(route, others).crossings)


def route_overlap_length(route: Sequence[Point], others: Sequence[Sequence[Point]]) -> float:
    return route_interactions(route, others).overlap_length


def estimate_text_width(text: str, font_size: float = 12.0, weight: float = 1.0) -> float:
    units = 0.0
    for character in text:
        if unicodedata.combining(character):
            continue
        east_asian = unicodedata.east_asian_width(character)
        if east_asian in {"W", "F"}:
            units += 1.0
        elif character.isspace():
            units += 0.36
        elif character in "ilI.,:;!'`|":
            units += 0.32
        elif character in "MW@#%&":
            units += 0.82
        else:
            units += 0.58
    return max(font_size * 1.5, units * font_size * weight)


def estimate_text_bounds(
    x: float,
    y: float,
    text: str,
    *,
    font_size: float = 12.0,
    anchor: str = "start",
    padding: float = 0.0,
) -> Bounds:
    width = estimate_text_width(text, font_size)
    if anchor == "middle":
        left = x - width / 2
    elif anchor == "end":
        left = x - width
    else:
        left = x
    top = y - font_size * 0.82
    return (left - padding, top - padding, left + width + padding, y + font_size * 0.24 + padding)


def parse_bridge_points(raw: Optional[str]) -> list[Point]:
    if not raw:
        return []
    points: list[Point] = []
    for token in raw.split(";"):
        parts = token.strip().split(",")
        if len(parts) != 2:
            continue
        try:
            points.append((float(parts[0]), float(parts[1])))
        except ValueError:
            continue
    return points


def bridge_declared(point: Point, bridges: Sequence[Point], tolerance: float = 1.0) -> bool:
    return any(same_point(point, bridge, tolerance) for bridge in bridges)


def format_number(value: float) -> str:
    rounded = round(value, 2)
    if float(rounded).is_integer():
        return str(int(rounded))
    return str(rounded)


def path_with_bridges(route: Sequence[Point], bridges: Sequence[Point], radius: float = 5.0) -> str:
    """Build an SVG path, adding a deterministic arc at declared crossings."""

    if not route:
        return ""
    commands = [f"M {format_number(route[0][0])},{format_number(route[0][1])}"]
    remaining = unique_points(bridges)
    for start, end in zip(route, route[1:]):
        axis = segment_axis(start, end)
        if axis == "horizontal":
            direction = 1.0 if end[0] >= start[0] else -1.0
            candidates = [
                point
                for point in remaining
                if almost_equal(point[1], start[1], 0.1)
                and min(start[0], end[0]) + radius * 1.5 < point[0] < max(start[0], end[0]) - radius * 1.5
            ]
            candidates.sort(key=lambda point: direction * point[0])
            last_coordinate = start[0]
            for x, y in candidates:
                if abs(x - last_coordinate) < radius * 2.5:
                    continue
                before = x - direction * radius
                after = x + direction * radius
                commands.append(f"L {format_number(before)},{format_number(y)}")
                sweep = 0 if direction > 0 else 1
                commands.append(f"A {format_number(radius)} {format_number(radius)} 0 0 {sweep} {format_number(after)},{format_number(y)}")
                last_coordinate = after
            commands.append(f"L {format_number(end[0])},{format_number(end[1])}")
        elif axis == "vertical":
            direction = 1.0 if end[1] >= start[1] else -1.0
            candidates = [
                point
                for point in remaining
                if almost_equal(point[0], start[0], 0.1)
                and min(start[1], end[1]) + radius * 1.5 < point[1] < max(start[1], end[1]) - radius * 1.5
            ]
            candidates.sort(key=lambda point: direction * point[1])
            last_coordinate = start[1]
            for x, y in candidates:
                if abs(y - last_coordinate) < radius * 2.5:
                    continue
                before = y - direction * radius
                after = y + direction * radius
                commands.append(f"L {format_number(x)},{format_number(before)}")
                sweep = 1 if direction > 0 else 0
                commands.append(f"A {format_number(radius)} {format_number(radius)} 0 0 {sweep} {format_number(x)},{format_number(after)}")
                last_coordinate = after
            commands.append(f"L {format_number(end[0])},{format_number(end[1])}")
        else:
            commands.append(f"L {format_number(end[0])},{format_number(end[1])}")
    return " ".join(commands)
