#!/usr/bin/env python3
"""
Style-driven SVG diagram generator.

Usage:
  python3 generate-from-template.py <template-type> <output-path> [data-json]

This generator intentionally does more than "fill a template".
It encodes the visual language from the documented style guides so the output
tracks the showcase quality more closely than the previous generic renderer.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import heapq
import json
import math
import os
import re
import sys
from dataclasses import dataclass
from typing import Dict, List, Mapping, Optional, Sequence, Tuple
from xml.sax.saxutils import escape

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import fireworks_geometry as geometry  # noqa: E402
import composition_quality as quality  # noqa: E402
from diagram_ir import normalize_diagram  # noqa: E402
from semantic_contracts import STYLE_NAMES, resolve_style_index  # noqa: E402
from svg_canvas import parse_viewbox  # noqa: E402
from style_quality import READABILITY_TOKENS, palette_report, text_quality_report  # noqa: E402

Point = Tuple[float, float]
Bounds = Tuple[float, float, float, float]

TEMPLATE_DIR = os.path.join(SCRIPT_DIR, "..", "templates")
DEFAULT_VIEWBOX = {
    "architecture": (960, 600),
    "data-flow": (960, 600),
    "flowchart": (960, 640),
    "sequence": (960, 700),
    "comparison": (960, 620),
    "timeline": (960, 520),
    "mind-map": (960, 620),
    "agent": (960, 700),
    "memory": (960, 720),
    "use-case": (960, 600),
    "class": (960, 700),
    "state-machine": (960, 620),
    "er-diagram": (960, 680),
    "network-topology": (960, 620),
}

FLOW_ALIASES = {
    "main": "control",
    "api": "control",
    "control": "control",
    "write": "write",
    "read": "read",
    "data": "data",
    "async": "async",
    "feedback": "feedback",
    "neutral": "neutral",
}

MARKER_IDS = {
    "control": "arrowA",
    "write": "arrowB",
    "read": "arrowC",
    "data": "arrowE",
    "async": "arrowF",
    "feedback": "arrowG",
    "neutral": "arrowH",
}

STYLE_PROFILES: Dict[int, Dict[str, object]] = {
    1: {
        "name": "Flat Icon",
        "font_family": "'Helvetica Neue', Helvetica, Arial, 'PingFang SC', 'Microsoft YaHei', 'Microsoft JhengHei', 'SimHei', sans-serif",
        "background": "#ffffff",
        "shadow": True,
        "title_align": "center",
        "title_fill": "#111827",
        "title_size": 30,
        "subtitle_fill": "#6b7280",
        "subtitle_size": 14,
        "node_fill": "#ffffff",
        "node_stroke": "#d1d5db",
        "node_radius": 10,
        "node_shadow": "url(#shadowSoft)",
        "section_fill": "none",
        "section_stroke": "#dbe5f1",
        "section_dash": "6 5",
        "section_label_fill": "#2563eb",
        "section_sub_fill": "#94a3b8",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.4,
        "arrow_colors": {
            "control": "#7c3aed",
            "write": "#10b981",
            "read": "#2563eb",
            "data": "#f97316",
            "async": "#7c3aed",
            "feedback": "#ef4444",
            "neutral": "#6b7280",
        },
        "arrow_label_bg": "#ffffff",
        "arrow_label_opacity": 0.94,
        "arrow_label_fill": "#6b7280",
        "type_label_fill": "#9ca3af",
        "type_label_size": 12,
        "text_primary": "#111827",
        "text_secondary": "#6b7280",
        "text_muted": "#94a3b8",
        "legend_fill": "#6b7280",
    },
    2: {
        "name": "Dark Terminal",
        "font_family": "'SF Mono', 'Fira Code', Menlo, 'Microsoft YaHei', 'SimHei', monospace",
        "background": "#0f172a",
        "shadow": False,
        "title_align": "center",
        "title_fill": "#e2e8f0",
        "title_size": 30,
        "subtitle_fill": "#94a3b8",
        "subtitle_size": 14,
        "node_fill": "#111827",
        "node_stroke": "#334155",
        "node_radius": 10,
        "node_shadow": "",
        "section_fill": "rgba(15,23,42,0.28)",
        "section_stroke": "#334155",
        "section_dash": "7 6",
        "section_label_fill": "#38bdf8",
        "section_sub_fill": "#64748b",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.3,
        "arrow_colors": {
            "control": "#a855f7",
            "write": "#22c55e",
            "read": "#38bdf8",
            "data": "#fb7185",
            "async": "#f59e0b",
            "feedback": "#f97316",
            "neutral": "#94a3b8",
        },
        "arrow_label_bg": "#0f172a",
        "arrow_label_opacity": 0.92,
        "arrow_label_fill": "#cbd5e1",
        "type_label_fill": "#64748b",
        "type_label_size": 12,
        "text_primary": "#e2e8f0",
        "text_secondary": "#94a3b8",
        "text_muted": "#64748b",
        "legend_fill": "#94a3b8",
    },
    3: {
        "name": "Blueprint",
        "font_family": "'SF Mono', 'Fira Code', Menlo, 'Microsoft YaHei', 'SimHei', monospace",
        "background": "#082f49",
        "shadow": False,
        "title_align": "center",
        "title_fill": "#e0f2fe",
        "title_size": 30,
        "subtitle_fill": "#7dd3fc",
        "subtitle_size": 14,
        "node_fill": "#0b3b5e",
        "node_stroke": "#67e8f9",
        "node_radius": 8,
        "node_shadow": "",
        "section_fill": "none",
        "section_stroke": "#0ea5e9",
        "section_dash": "6 4",
        "section_label_fill": "#67e8f9",
        "section_sub_fill": "#7dd3fc",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.1,
        "arrow_colors": {
            "control": "#67e8f9",
            "write": "#22d3ee",
            "read": "#38bdf8",
            "data": "#fde047",
            "async": "#c084fc",
            "feedback": "#fb7185",
            "neutral": "#bae6fd",
        },
        "arrow_label_bg": "#082f49",
        "arrow_label_opacity": 0.9,
        "arrow_label_fill": "#e0f2fe",
        "type_label_fill": "#7dd3fc",
        "type_label_size": 11,
        "text_primary": "#e0f2fe",
        "text_secondary": "#bae6fd",
        "text_muted": "#7dd3fc",
        "legend_fill": "#bae6fd",
    },
    4: {
        "name": "Notion Clean",
        "font_family": "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, 'PingFang SC', 'Microsoft YaHei', 'Microsoft JhengHei', 'SimHei', sans-serif",
        "background": "#ffffff",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#111827",
        "title_size": 18,
        "subtitle_fill": "#9ca3af",
        "subtitle_size": 13,
        "node_fill": "#f9fafb",
        "node_stroke": "#e5e7eb",
        "node_radius": 4,
        "node_shadow": "",
        "section_fill": "none",
        "section_stroke": "#e5e7eb",
        "section_dash": "",
        "section_label_fill": "#9ca3af",
        "section_sub_fill": "#d1d5db",
        "title_divider": True,
        "section_upper": True,
        "arrow_width": 1.8,
        "arrow_colors": {
            "control": "#3b82f6",
            "write": "#3b82f6",
            "read": "#3b82f6",
            "data": "#3b82f6",
            "async": "#9ca3af",
            "feedback": "#9ca3af",
            "neutral": "#d1d5db",
        },
        "arrow_label_bg": "#ffffff",
        "arrow_label_opacity": 0.96,
        "arrow_label_fill": "#6b7280",
        "type_label_fill": "#9ca3af",
        "type_label_size": 11,
        "text_primary": "#111827",
        "text_secondary": "#374151",
        "text_muted": "#9ca3af",
        "legend_fill": "#6b7280",
    },
    5: {
        "name": "Glassmorphism",
        "font_family": "'Helvetica Neue', Helvetica, Arial, 'PingFang SC', 'Microsoft YaHei', 'Microsoft JhengHei', 'SimHei', sans-serif",
        "background": "#0f172a",
        "shadow": True,
        "title_align": "center",
        "title_fill": "#f8fafc",
        "title_size": 30,
        "subtitle_fill": "#cbd5e1",
        "subtitle_size": 14,
        "node_fill": "rgba(255,255,255,0.12)",
        "node_stroke": "rgba(255,255,255,0.28)",
        "node_radius": 18,
        "node_shadow": "url(#shadowGlass)",
        "section_fill": "rgba(255,255,255,0.05)",
        "section_stroke": "rgba(255,255,255,0.18)",
        "section_dash": "7 6",
        "section_label_fill": "#e2e8f0",
        "section_sub_fill": "#94a3b8",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.2,
        "arrow_colors": {
            "control": "#c084fc",
            "write": "#34d399",
            "read": "#60a5fa",
            "data": "#fb923c",
            "async": "#f472b6",
            "feedback": "#f59e0b",
            "neutral": "#cbd5e1",
        },
        "arrow_label_bg": "rgba(15,23,42,0.7)",
        "arrow_label_opacity": 1,
        "arrow_label_fill": "#e2e8f0",
        "type_label_fill": "#cbd5e1",
        "type_label_size": 12,
        "text_primary": "#f8fafc",
        "text_secondary": "#cbd5e1",
        "text_muted": "#94a3b8",
        "legend_fill": "#cbd5e1",
    },
    6: {
        "name": "Claude Official",
        "font_family": "'Helvetica Neue', Helvetica, Arial, 'PingFang SC', 'Microsoft YaHei', 'Microsoft JhengHei', 'SimHei', sans-serif",
        "background": "#f8f6f3",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#141413",
        "title_size": 24,
        "subtitle_fill": "#8f8a80",
        "subtitle_size": 13,
        "node_fill": "#fffcf7",
        "node_stroke": "#d9d0c3",
        "node_radius": 10,
        "node_shadow": "",
        "section_fill": "none",
        "section_stroke": "#ded8cf",
        "section_dash": "5 4",
        "section_label_fill": "#8b7355",
        "section_sub_fill": "#b4aba0",
        "title_divider": True,
        "section_upper": True,
        "arrow_width": 2.0,
        "arrow_colors": {
            "control": "#d97757",
            "write": "#7b8b5c",
            "read": "#8c6f5a",
            "data": "#b45309",
            "async": "#9a6fb0",
            "feedback": "#7c5c96",
            "neutral": "#8f8a80",
        },
        "arrow_label_bg": "#f8f6f3",
        "arrow_label_opacity": 0.96,
        "arrow_label_fill": "#6b6257",
        "type_label_fill": "#a29a8f",
        "type_label_size": 11,
        "text_primary": "#141413",
        "text_secondary": "#6b6257",
        "text_muted": "#a29a8f",
        "legend_fill": "#6b6257",
    },
    7: {
        "name": "OpenAI",
        "font_family": "'Helvetica Neue', Helvetica, Arial, 'PingFang SC', 'Microsoft YaHei', 'Microsoft JhengHei', 'SimHei', sans-serif",
        "background": "#ffffff",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#0f172a",
        "title_size": 24,
        "subtitle_fill": "#64748b",
        "subtitle_size": 13,
        "node_fill": "#ffffff",
        "node_stroke": "#dce5e3",
        "node_radius": 14,
        "node_shadow": "",
        "section_fill": "none",
        "section_stroke": "#e2e8f0",
        "section_dash": "5 4",
        "section_label_fill": "#10a37f",
        "section_sub_fill": "#94a3b8",
        "title_divider": True,
        "section_upper": True,
        "arrow_width": 2.0,
        "arrow_colors": {
            "control": "#10a37f",
            "write": "#0f766e",
            "read": "#0891b2",
            "data": "#f59e0b",
            "async": "#64748b",
            "feedback": "#475569",
            "neutral": "#94a3b8",
        },
        "arrow_label_bg": "#ffffff",
        "arrow_label_opacity": 0.96,
        "arrow_label_fill": "#475569",
        "type_label_fill": "#94a3b8",
        "type_label_size": 11,
        "text_primary": "#0f172a",
        "text_secondary": "#475569",
        "text_muted": "#94a3b8",
        "legend_fill": "#475569",
    },
    9: {
        "name": "C4 Review Canvas",
        "font_family": "'Avenir Next', Avenir, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif",
        "background": "#f7f2e8",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#24312f",
        "title_size": 27,
        "subtitle_fill": "#6f756f",
        "subtitle_size": 13,
        "node_fill": "#fffdf7",
        "node_stroke": "#365f56",
        "node_radius": 7,
        "node_shadow": "",
        "section_fill": "rgba(255,253,247,0.48)",
        "section_stroke": "#8c7d68",
        "section_dash": "9 6",
        "section_label_fill": "#5b5144",
        "section_sub_fill": "#8c7d68",
        "title_divider": False,
        "section_upper": False,
        "arrow_width": 2.0,
        "arrow_colors": {
            "control": "#365f56",
            "write": "#a44a3f",
            "read": "#356a8a",
            "data": "#c06b35",
            "async": "#7a5c99",
            "feedback": "#b13e53",
            "neutral": "#746b60",
        },
        "arrow_label_bg": "#f7f2e8",
        "arrow_label_opacity": 0.94,
        "arrow_label_fill": "#4b5563",
        "type_label_fill": "#8a6f43",
        "type_label_size": 10,
        "text_primary": "#24312f",
        "text_secondary": "#5f665f",
        "text_muted": "#8a8d86",
        "legend_fill": "#5f665f",
        "canvas_treatment": "review",
    },
    10: {
        "name": "Cloud Fabric",
        "font_family": "Inter, 'Helvetica Neue', 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif",
        "background": "#edf5fb",
        "shadow": True,
        "title_align": "left",
        "title_fill": "#102a43",
        "title_size": 27,
        "subtitle_fill": "#52718d",
        "subtitle_size": 13,
        "node_fill": "#ffffff",
        "node_stroke": "#9bb7cf",
        "node_radius": 12,
        "node_shadow": "url(#shadowSoft)",
        "section_fill": "rgba(255,255,255,0.54)",
        "section_stroke": "#7fa3c2",
        "section_dash": "7 5",
        "section_label_fill": "#315d7e",
        "section_sub_fill": "#7892a8",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.2,
        "arrow_colors": {
            "control": "#2563eb",
            "write": "#ea580c",
            "read": "#0891b2",
            "data": "#059669",
            "async": "#7c3aed",
            "feedback": "#db2777",
            "neutral": "#64748b",
        },
        "arrow_label_bg": "#f7fbfe",
        "arrow_label_opacity": 0.96,
        "arrow_label_fill": "#334e68",
        "type_label_fill": "#6b879d",
        "type_label_size": 10,
        "text_primary": "#102a43",
        "text_secondary": "#486581",
        "text_muted": "#829ab1",
        "legend_fill": "#486581",
        "canvas_treatment": "cloud",
    },
    11: {
        "name": "Event Transit",
        "font_family": "'Avenir Next', Avenir, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif",
        "background": "#fbf7ee",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#17213c",
        "title_size": 27,
        "subtitle_fill": "#6e6a61",
        "subtitle_size": 13,
        "node_fill": "#fffdf8",
        "node_stroke": "#c9c2b4",
        "node_radius": 24,
        "node_shadow": "",
        "section_fill": "rgba(255,255,255,0.38)",
        "section_stroke": "#d4cbbb",
        "section_dash": "4 5",
        "section_label_fill": "#514c43",
        "section_sub_fill": "#8d867b",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.8,
        "arrow_colors": {
            "control": "#e4475b",
            "write": "#00897b",
            "read": "#2563eb",
            "data": "#f59e0b",
            "async": "#7c3aed",
            "feedback": "#c62828",
            "neutral": "#7a746a",
        },
        "arrow_label_bg": "#fbf7ee",
        "arrow_label_opacity": 0.96,
        "arrow_label_fill": "#4b5563",
        "type_label_fill": "#7a746a",
        "type_label_size": 10,
        "text_primary": "#17213c",
        "text_secondary": "#5e5a52",
        "text_muted": "#8d867b",
        "legend_fill": "#5e5a52",
        "canvas_treatment": "transit",
        "rail_casing": "#514c43",
    },
    12: {
        "name": "Ops Pulse",
        "font_family": "'SF Mono', 'Fira Code', Menlo, 'Microsoft YaHei', monospace",
        "background": "#07111f",
        "shadow": False,
        "title_align": "left",
        "title_fill": "#eff6ff",
        "title_size": 27,
        "subtitle_fill": "#8aa4bd",
        "subtitle_size": 13,
        "node_fill": "#0d1b2a",
        "node_stroke": "#29435d",
        "node_radius": 12,
        "node_shadow": "",
        "section_fill": "rgba(13,27,42,0.72)",
        "section_stroke": "#28445f",
        "section_dash": "6 5",
        "section_label_fill": "#38bdf8",
        "section_sub_fill": "#6f8ba5",
        "title_divider": False,
        "section_upper": True,
        "arrow_width": 2.4,
        "arrow_colors": {
            "control": "#f59e0b",
            "write": "#22c55e",
            "read": "#38bdf8",
            "data": "#fb7185",
            "async": "#22d3ee",
            "feedback": "#f43f5e",
            "neutral": "#7892a8",
        },
        "arrow_label_bg": "#07111f",
        "arrow_label_opacity": 0.94,
        "arrow_label_fill": "#cbd5e1",
        "type_label_fill": "#6f8ba5",
        "type_label_size": 10,
        "text_primary": "#eff6ff",
        "text_secondary": "#9fb3c8",
        "text_muted": "#647f99",
        "legend_fill": "#9fb3c8",
        "canvas_treatment": "ops",
    },
}


@dataclass
class Node:
    node_id: str
    kind: str
    shape: str
    data: Dict[str, object]
    bounds: Bounds
    cx: float
    cy: float


@dataclass
class ArrowRender:
    edge_id: str
    path_svg: str
    label_svg: str
    label_bounds: Optional[Bounds]
    route: List[Point]
    report: Dict[str, object]


def style_value(style: Dict[str, object], key: str) -> object:
    return style[key]


def to_float(value: object, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def normalize_text(value: object) -> str:
    return escape(str(value)) if value is not None else ""


def normalize_attribute(value: object) -> str:
    return escape(str(value), {'"': "&quot;"}) if value is not None else ""


def safe_identifier(value: object, fallback: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.:-]+", "-", str(value or fallback)).strip("-")
    return cleaned or fallback


_RESERVED_DOM_IDS = frozenset(
    set(MARKER_IDS.values())
    | {
        "blueprint-title-block",
        "blueprintGrid",
        "cloudGradient",
        "cloudGrid",
        "footer",
        "glowBlue",
        "glowGreen",
        "glowOrange",
        "glowPurple",
        "legend",
        "legend-zone",
        "opsGradient",
        "opsGrid",
        "pulseGlow",
        "reviewGrid",
        "shadowGlass",
        "shadowSoft",
        "style-signature",
        "terminalGradient",
        "transitDots",
    }
)
_EDGE_DOM_SUFFIXES = (
    "-bridge-mask",
    "-critical-glow",
    "-direction",
    "-hop",
    "-label",
    "-rail-casing",
    "-review-stroke",
)


def allocate_dom_identifier(base: str, used: set[str], suffixes: Sequence[str] = ()) -> str:
    """Allocate one deterministic SVG id while preserving readable ids when safe."""

    candidate = safe_identifier(base, "element")
    sequence = 2
    while any(identifier in used for identifier in (candidate, *(candidate + suffix for suffix in suffixes))):
        candidate = f"{safe_identifier(base, 'element')}-{sequence}"
        sequence += 1
    used.add(candidate)
    used.update(candidate + suffix for suffix in suffixes)
    return candidate


# Style 8 is AI-authored: the AI reads references/style-8-dark-luxury.md and hand-crafts
# the SVG directly. It cannot be driven by this template generator.
_AI_AUTHORED_STYLES: Dict[int, str] = {8: "Style 8 (Dark Luxury)"}
_AI_AUTHORED_MSG = (
    "{name} is an AI-authored style and cannot be used with generate-from-template.py. "
    "Load references/style-8-dark-luxury.md for the full spec and hand-craft the SVG directly."
)


def parse_style(raw: object) -> Tuple[int, Dict[str, object]]:
    index = resolve_style_index({"style": raw}) if raw is not None else 1
    if index in _AI_AUTHORED_STYLES:
        raise ValueError(_AI_AUTHORED_MSG.format(name=_AI_AUTHORED_STYLES[index]))
    if index not in STYLE_PROFILES:
        raise ValueError(f"Unsupported style: {raw}")
    profile = copy.deepcopy(STYLE_PROFILES[index])
    profile.update(READABILITY_TOKENS.get(index, {}))
    profile["font_family"] = str(profile["font_family"]).replace("'Microsoft YaHei'", "'Noto Sans CJK SC', 'Microsoft YaHei'")
    return index, profile


def parse_template_viewbox(template_type: str) -> Tuple[float, float]:
    template_path = os.path.join(TEMPLATE_DIR, f"{template_type}.svg")
    if os.path.exists(template_path):
        with open(template_path, "r", encoding="utf-8") as handle:
            content = handle.read()
        match = re.search(r'viewBox="0 0 ([0-9.]+) ([0-9.]+)"', content)
        if match:
            return float(match.group(1)), float(match.group(2))
    return DEFAULT_VIEWBOX.get(template_type, (960, 600))


def render_defs(style_index: int, style: Dict[str, object]) -> str:
    marker_size = "8" if style_index == 4 else "12" if style_index == 11 else "10"
    marker_height = "6" if style_index == 4 else "9" if style_index == 11 else "7"
    ref_x = "7" if style_index == 4 else "11" if style_index == 11 else "9"
    ref_y = "3" if style_index == 4 else "4.5" if style_index == 11 else "3.5"
    marker_units = ' markerUnits="userSpaceOnUse"' if style_index == 11 else ""
    color_map = style_value(style, "arrow_colors")
    marker_lines = []
    for key, color in color_map.items():
        marker_id = MARKER_IDS.get(key, "arrowA")
        marker_lines.append(
            f'    <marker id="{marker_id}" markerWidth="{marker_size}" markerHeight="{marker_height}" '
            f'refX="{ref_x}" refY="{ref_y}" orient="auto"{marker_units}>'
        )
        if style_index == 4:
            marker_lines.append(f'      <polygon points="0 0, 8 3, 0 6" fill="{color}"/>')
        elif style_index == 11:
            marker_lines.append(f'      <polygon points="0 0, 12 4.5, 0 9" fill="{color}"/>')
        else:
            marker_lines.append(f'      <polygon points="0 0, 10 3.5, 0 7" fill="{color}"/>')
        marker_lines.append("    </marker>")

    filters = []
    if style_value(style, "shadow"):
        filters.extend(
            [
                '    <filter id="shadowSoft" x="-20%" y="-20%" width="140%" height="160%">',
                '      <feDropShadow dx="0" dy="3" stdDeviation="6" flood-color="#0f172a" flood-opacity="0.12"/>',
                "    </filter>",
                '    <filter id="shadowGlass" x="-20%" y="-20%" width="140%" height="160%">',
                '      <feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#020617" flood-opacity="0.28"/>',
                "    </filter>",
            ]
        )

    if style_index == 3:
        filters.extend(
            [
                '    <pattern id="blueprintGrid" width="32" height="32" patternUnits="userSpaceOnUse">',
                '      <path d="M 32 0 L 0 0 0 32" fill="none" stroke="#0ea5e9" stroke-opacity="0.12" stroke-width="1"/>',
                "    </pattern>",
            ]
        )
    if style_index == 2:
        filters.extend(
            [
                '    <linearGradient id="terminalGradient" x1="0%" y1="0%" x2="100%" y2="100%">',
                '      <stop offset="0%" stop-color="#0f0f1a"/>',
                '      <stop offset="100%" stop-color="#1a1a2e"/>',
                "    </linearGradient>",
                '    <filter id="glowBlue" x="-30%" y="-30%" width="160%" height="160%">',
                '      <feDropShadow dx="0" dy="0" stdDeviation="5" flood-color="#3b82f6" flood-opacity="0.65"/>',
                "    </filter>",
                '    <filter id="glowPurple" x="-30%" y="-30%" width="160%" height="160%">',
                '      <feDropShadow dx="0" dy="0" stdDeviation="5" flood-color="#a855f7" flood-opacity="0.72"/>',
                "    </filter>",
                '    <filter id="glowGreen" x="-30%" y="-30%" width="160%" height="160%">',
                '      <feDropShadow dx="0" dy="0" stdDeviation="5" flood-color="#22c55e" flood-opacity="0.62"/>',
                "    </filter>",
                '    <filter id="glowOrange" x="-30%" y="-30%" width="160%" height="160%">',
                '      <feDropShadow dx="0" dy="0" stdDeviation="5" flood-color="#f97316" flood-opacity="0.62"/>',
                "    </filter>",
            ]
        )
    if style_index == 9:
        filters.extend(
            [
                '    <pattern id="reviewGrid" width="24" height="24" patternUnits="userSpaceOnUse">',
                '      <circle cx="1" cy="1" r="0.8" fill="#8c7d68" fill-opacity="0.18"/>',
                "    </pattern>",
            ]
        )
    if style_index == 10:
        filters.extend(
            [
                '    <linearGradient id="cloudGradient" x1="0%" y1="0%" x2="100%" y2="100%">',
                '      <stop offset="0%" stop-color="#f8fcff"/>',
                '      <stop offset="100%" stop-color="#dfedf7"/>',
                "    </linearGradient>",
                '    <pattern id="cloudGrid" width="32" height="32" patternUnits="userSpaceOnUse">',
                '      <path d="M 32 0 L 0 0 0 32" fill="none" stroke="#7fa3c2" stroke-opacity="0.10" stroke-width="1"/>',
                "    </pattern>",
            ]
        )
    if style_index == 11:
        filters.extend(
            [
                '    <pattern id="transitDots" width="28" height="28" patternUnits="userSpaceOnUse">',
                '      <circle cx="2" cy="2" r="0.9" fill="#8d867b" fill-opacity="0.12"/>',
                "    </pattern>",
            ]
        )
    if style_index == 12:
        filters.extend(
            [
                '    <linearGradient id="opsGradient" x1="0%" y1="0%" x2="100%" y2="100%">',
                '      <stop offset="0%" stop-color="#07111f"/>',
                '      <stop offset="100%" stop-color="#0b1b2e"/>',
                "    </linearGradient>",
                '    <pattern id="opsGrid" width="36" height="36" patternUnits="userSpaceOnUse">',
                '      <path d="M 36 0 L 0 0 0 36" fill="none" stroke="#38bdf8" stroke-opacity="0.055" stroke-width="1"/>',
                "    </pattern>",
                '    <filter id="pulseGlow" x="-30%" y="-30%" width="160%" height="160%">',
                '      <feDropShadow dx="0" dy="0" stdDeviation="4" flood-color="#f59e0b" flood-opacity="0.62"/>',
                "    </filter>",
            ]
        )

    styles = [
        f"    text {{ font-family: {style_value(style, 'font_family')}; }}",
        f"    .title {{ font-size: {style_value(style, 'title_size')}px; font-weight: 700; fill: {style_value(style, 'title_fill')}; }}",
        f"    .subtitle {{ font-size: {style_value(style, 'subtitle_size')}px; font-weight: 500; fill: {style_value(style, 'subtitle_fill')}; }}",
        f"    .section {{ font-size: 13px; font-weight: 700; fill: {style_value(style, 'section_label_fill')}; letter-spacing: 1.4px; }}",
        f"    .section-sub {{ font-size: 12px; font-weight: 500; fill: {style_value(style, 'section_sub_fill')}; }}",
        f"    .node-title {{ font-weight: 700; fill: {style_value(style, 'text_primary')}; }}",
        f"    .node-sub {{ font-weight: 500; fill: {style_value(style, 'text_secondary')}; }}",
        f"    .node-type {{ font-size: {style_value(style, 'type_label_size')}px; font-weight: 700; fill: {style_value(style, 'type_label_fill')}; letter-spacing: 0.08em; }}",
        f"    .arrow-label {{ font-size: 12px; font-weight: 600; fill: {style_value(style, 'arrow_label_fill')}; }}",
        f"    .legend {{ font-size: 12px; font-weight: 500; fill: {style_value(style, 'legend_fill')}; }}",
        f"    .footnote {{ font-size: 12px; font-weight: 500; fill: {style_value(style, 'text_muted')}; }}",
        f"    .metric-label {{ font-size: 8.5px; font-weight: 700; fill: {style_value(style, 'text_muted')}; text-transform: uppercase; }}",
        f"    .metric-value {{ font-size: 9.5px; font-weight: 700; fill: {style_value(style, 'text_primary')}; }}",
    ]
    return "\n".join(
        ["  <defs>"] + marker_lines + filters + ["    <style>"] + styles + ["    </style>", "  </defs>"]
    )


def render_canvas(style_index: int, style: Dict[str, object], width: float, height: float) -> str:
    background = str(style_value(style, "background"))
    if style_index == 2:
        parts = [f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="url(#terminalGradient)"/>']
    elif style_index == 9:
        parts = [
            f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="{background}"/>',
            f'  <rect data-graph-role="decoration" width="{width}" height="{height}" fill="url(#reviewGrid)"/>',
        ]
    elif style_index == 10:
        parts = [
            f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="url(#cloudGradient)"/>',
            f'  <rect data-graph-role="decoration" width="{width}" height="{height}" fill="url(#cloudGrid)"/>',
        ]
    elif style_index == 11:
        parts = [
            f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="{background}"/>',
            f'  <rect data-graph-role="decoration" width="{width}" height="{height}" fill="url(#transitDots)"/>',
        ]
    elif style_index == 12:
        parts = [
            f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="url(#opsGradient)"/>',
            f'  <rect data-graph-role="decoration" width="{width}" height="{height}" fill="url(#opsGrid)"/>',
        ]
    else:
        parts = [f'  <rect data-graph-role="background" width="{width}" height="{height}" fill="{background}"/>']

    return "\n".join(parts)


def title_position(style: Dict[str, object], width: float) -> Tuple[float, str]:
    if style_value(style, "title_align") == "left":
        return 48.0, "start"
    return width / 2.0, "middle"


def render_title_block(style: Dict[str, object], data: Dict[str, object], width: float) -> Tuple[str, float]:
    title = normalize_text(data.get("title", "Diagram"))
    subtitle = normalize_text(data.get("subtitle", ""))
    x, anchor = title_position(style, width)
    if anchor == "middle":
        parts = [f'  <text x="{x}" y="56" text-anchor="{anchor}" class="title">{title}</text>']
        cursor_y = 82
        if subtitle:
            parts.append(f'  <text x="{x}" y="{cursor_y}" text-anchor="{anchor}" class="subtitle">{subtitle}</text>')
            cursor_y += 24
        return "\n".join(parts), cursor_y + 10

    parts = [f'  <text x="{x}" y="48" text-anchor="{anchor}" class="title">{title}</text>']
    cursor_y = 72
    if subtitle:
        parts.append(f'  <text x="{x}" y="{cursor_y}" text-anchor="{anchor}" class="subtitle">{subtitle}</text>')
        cursor_y += 18
    if style_value(style, "title_divider"):
        parts.append(
            f'  <line x1="48" y1="{cursor_y + 10}" x2="{width - 48}" y2="{cursor_y + 10}" '
            f'stroke="{style_value(style, "section_stroke")}" stroke-width="1"/>'
        )
        cursor_y += 26
    return "\n".join(parts), cursor_y + 8


def render_window_controls(data: Dict[str, object], style_index: int, width: float) -> str:
    controls = data.get("window_controls")
    if not controls:
        return ""
    if controls is True:
        controls = ["#ef4444", "#f59e0b", "#10b981"]
    if style_index != 2:
        return ""
    cursor_x = 20.0
    lines = []
    for color in controls:
        lines.append(f'  <circle cx="{cursor_x}" cy="20" r="5.5" fill="{color}"/>')
        cursor_x += 18
    return "\n".join(lines)


def render_header_meta(data: Dict[str, object], style: Dict[str, object], width: float) -> str:
    meta_left = normalize_text(data.get("meta_left", ""))
    meta_center = normalize_text(data.get("meta_center", ""))
    meta_right = normalize_text(data.get("meta_right", ""))
    if not any([meta_left, meta_center, meta_right]):
        return ""
    fill = str(data.get("meta_fill", style_value(style, "text_muted")))
    size = to_float(data.get("meta_size", 11))
    lines = []
    if meta_left:
        lines.append(f'  <text x="28" y="24" font-size="{size}" font-weight="600" fill="{fill}">{meta_left}</text>')
    if meta_center:
        lines.append(f'  <text x="{width / 2}" y="24" text-anchor="middle" font-size="{size}" font-weight="600" fill="{fill}">{meta_center}</text>')
    if meta_right:
        lines.append(f'  <text x="{width - 28}" y="24" text-anchor="end" font-size="{size}" font-weight="600" fill="{fill}">{meta_right}</text>')
    return "\n".join(lines)


def render_style_signature(style_index: int, data: Dict[str, object], width: float) -> str:
    """Expose each engineering style's domain evidence as a compact visual fingerprint."""

    if style_index not in {9, 10, 11, 12}:
        return ""
    badge_width = 176.0
    badge_height = 34.0
    x = width - 48 - badge_width
    y = 22.0
    if style_index == 9:
        level = str(data.get("c4_level", "review")).upper()
        state = str(data.get("review_state", "REVIEW READY")).upper()
        top_raw = f"C4 · {level} VIEW"
        top_text, top_size = fit_single_line_text(top_raw, badge_width - 46, preferred=8.5, minimum=6.2)
        state_text, state_size = fit_single_line_text(state, badge_width - 46, preferred=8, minimum=6.2)
        return "\n".join(
            [
            '  <g id="style-signature" data-graph-role="decoration" data-style-signature="c4-review-board">',
                f'    <rect x="{x}" y="{y}" width="{badge_width}" height="{badge_height}" rx="7" fill="#fffdf7" stroke="#8c7d68" stroke-width="1.2" stroke-dasharray="6 4"/>',
                f'    <path d="M {x + 12} {y + 17} l 5 5 9 -11" fill="none" stroke="#365f56" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
                f'    <text data-full-text="{normalize_attribute(top_raw)}" x="{x + 34}" y="{y + 14}" font-size="{top_size}" font-weight="800" fill="#8a6f43">{normalize_text(top_text)}</text>',
                f'    <text data-full-text="{normalize_attribute(state)}" x="{x + 34}" y="{y + 27}" font-size="{state_size}" font-weight="700" fill="#5f665f">{normalize_text(state_text)}</text>',
                "  </g>",
            ]
        )
    if style_index == 10:
        platform = str(data.get("platform_profile", "cloud")).upper()
        mode = str(data.get("deployment_mode", "DEPLOYMENT MAP")).upper()
        regions = sum(
            1
            for container in data.get("containers", [])
            if isinstance(container, Mapping) and container.get("deployment_kind") == "region"
        )
        top_raw = f"{platform} · {regions} REGIONS"
        top_text, top_size = fit_single_line_text(top_raw, badge_width - 55, preferred=8.5, minimum=6.2)
        mode_text, mode_size = fit_single_line_text(mode, badge_width - 55, preferred=8, minimum=6.2)
        return "\n".join(
            [
            '  <g id="style-signature" data-graph-role="decoration" data-style-signature="cloud-ownership-map">',
                f'    <rect x="{x}" y="{y}" width="{badge_width}" height="{badge_height}" rx="9" fill="#ffffff" fill-opacity="0.82" stroke="#7fa3c2" stroke-width="1.1"/>',
                f'    <rect x="{x + 11}" y="{y + 9}" width="14" height="14" rx="4" fill="#dbeafe" stroke="#2563eb" stroke-width="1"/>',
                f'    <rect x="{x + 20}" y="{y + 13}" width="14" height="14" rx="4" fill="#dcfce7" stroke="#059669" stroke-width="1"/>',
                f'    <text data-full-text="{normalize_attribute(top_raw)}" x="{x + 43}" y="{y + 14}" font-size="{top_size}" font-weight="800" fill="#315d7e">{normalize_text(top_text)}</text>',
                f'    <text data-full-text="{normalize_attribute(mode)}" x="{x + 43}" y="{y + 27}" font-size="{mode_size}" font-weight="700" fill="#52718d">{normalize_text(mode_text)}</text>',
                "  </g>",
            ]
        )
    if style_index == 11:
        topics = data.get("topics", [])
        line_count = len(topics) if isinstance(topics, list) else 0
        line_code = str(data.get("line_code", "EVENT METRO")).upper()
        signature_width = 226.0
        signature_x = width - 48 - signature_width
        line_code_text, line_code_size = fit_single_line_text(
            line_code, signature_width - 58, preferred=8.5, minimum=6.2
        )
        detail_raw = f"{line_count} TOPIC LINES · DECLARED STOPS"
        detail_text, detail_size = fit_single_line_text(
            detail_raw, signature_width - 58, preferred=8, minimum=6.2
        )
        return "\n".join(
            [
            '  <g id="style-signature" data-graph-role="decoration" data-style-signature="event-metro-map">',
                f'    <rect x="{signature_x}" y="{y}" width="{signature_width}" height="{badge_height}" rx="7" fill="#17213c" stroke="#514c43" stroke-width="1"/>',
                f'    <line x1="{signature_x + 12}" y1="{y + 17}" x2="{signature_x + 36}" y2="{y + 17}" stroke="#e4475b" stroke-width="3"/>',
                f'    <circle cx="{signature_x + 18}" cy="{y + 17}" r="4" fill="#fbf7ee" stroke="#e4475b" stroke-width="2"/>',
                f'    <circle cx="{signature_x + 31}" cy="{y + 17}" r="4" fill="#fbf7ee" stroke="#e4475b" stroke-width="2"/>',
                f'    <text data-full-text="{normalize_attribute(line_code)}" x="{signature_x + 46}" y="{y + 14}" font-size="{line_code_size}" font-weight="800" fill="#ffffff">{normalize_text(line_code_text)}</text>',
                f'    <text data-full-text="{normalize_attribute(detail_raw)}" x="{signature_x + 46}" y="{y + 27}" font-size="{detail_size}" font-weight="700" fill="#f3d5d9">{normalize_text(detail_text)}</text>',
                "  </g>",
            ]
        )

    services = [
        node
        for node in data.get("nodes", [])
        if isinstance(node, Mapping) and node.get("ops_role") == "service"
    ]
    rank = {"unknown": 0, "ok": 1, "warn": 2, "critical": 3}
    worst = max(
        (str(node.get("status", "unknown")) for node in services),
        key=lambda item: rank.get(item, 0),
        default="unknown",
    )
    window = str(data.get("observation_window", ""))
    if not window:
        for node in services:
            signals = node.get("signals")
            if isinstance(signals, Mapping):
                first_signal = next((value for value in signals.values() if isinstance(value, Mapping)), None)
                if first_signal:
                    window = str(first_signal.get("window", ""))
                    break
    status_color = {"ok": "#22c55e", "warn": "#f59e0b", "critical": "#f43f5e", "unknown": "#64748b"}.get(worst, "#64748b")
    top_raw = f'LIVE · {window.upper() or "WINDOW"}'
    detail_raw = f"{worst.upper()} · CORRELATED TRACE"
    top_text, top_size = fit_single_line_text(top_raw, badge_width - 70, preferred=8.5, minimum=6.2)
    detail_text, detail_size = fit_single_line_text(detail_raw, badge_width - 70, preferred=8, minimum=6.2)
    return "\n".join(
        [
            '  <g id="style-signature" data-graph-role="decoration" data-style-signature="ops-live-investigation">',
            f'    <rect x="{x}" y="{y}" width="{badge_width}" height="{badge_height}" rx="7" fill="#0d1b2a" stroke="#29435d" stroke-width="1.1"/>',
            f'    <circle cx="{x + 15}" cy="{y + 17}" r="4" fill="{status_color}"/>',
            f'    <path d="M {x + 25} {y + 18} h 5 l 3 -6 5 12 4 -8 h 7" fill="none" stroke="#38bdf8" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>',
            f'    <text data-full-text="{normalize_attribute(top_raw)}" x="{x + 58}" y="{y + 14}" font-size="{top_size}" font-weight="800" fill="#eff6ff">{normalize_text(top_text)}</text>',
            f'    <text data-full-text="{normalize_attribute(detail_raw)}" x="{x + 58}" y="{y + 27}" font-size="{detail_size}" font-weight="700" fill="{status_color}">{normalize_text(detail_text)}</text>',
            "  </g>",
        ]
    )


def render_blueprint_title_block(
    data: Dict[str, object],
    style: Dict[str, object],
    style_index: int,
    width: float,
    height: float,
) -> Tuple[str, Optional[Bounds]]:
    if style_index != 3:
        return "", None
    block = data.get("blueprint_title_block")
    if not block:
        return "", None
    block_width = to_float(block.get("width", 256))
    block_height = to_float(block.get("height", 92))
    x = to_float(block.get("x", width - block_width - 28))
    y = to_float(block.get("y", height - block_height - 18))
    title = normalize_text(block.get("title", data.get("title", "")))
    subtitle = normalize_text(block.get("subtitle", "SYSTEM ARCHITECTURE"))
    left_caption = normalize_text(block.get("left_caption", "REV: 1.0"))
    center_caption = normalize_text(block.get("center_caption", "AUTO-GENERATED"))
    right_caption = normalize_text(block.get("right_caption", "DWG: ARCH-001"))
    stroke = str(block.get("stroke", style_value(style, "section_stroke")))
    fill = str(block.get("fill", "#0b3552"))
    title_fill = str(block.get("title_fill", style_value(style, "text_primary")))
    sub_fill = str(block.get("subtitle_fill", style_value(style, "section_label_fill")))
    muted_fill = str(block.get("muted_fill", style_value(style, "text_muted")))
    footer_top = y + 54
    column_width = block_width / 3
    caption_width = max(24.0, column_width - 12)

    def caption_size(value: str) -> float:
        estimated = geometry.estimate_text_width(value, 9.5)
        return round(max(6.0, min(9.5, 9.5 * caption_width / max(estimated, 1.0))), 2)

    caption_y = min(y + block_height - 4, footer_top + max(12.0, block_height - 54) / 2 + 3)
    captions = (
        (left_caption, x + column_width / 2, muted_fill),
        (center_caption, x + block_width / 2, sub_fill),
        (right_caption, x + block_width - column_width / 2, muted_fill),
    )
    lines = [
        f'  <rect x="{x}" y="{y}" width="{block_width}" height="{block_height}" fill="{fill}" stroke="{stroke}" stroke-width="1.2"/>',
        f'  <line x1="{x}" y1="{y + 18}" x2="{x + block_width}" y2="{y + 18}" stroke="{stroke}" stroke-width="1"/>',
        f'  <line x1="{x}" y1="{y + 54}" x2="{x + block_width}" y2="{y + 54}" stroke="{stroke}" stroke-width="1"/>',
        f'  <line x1="{x + column_width}" y1="{footer_top}" x2="{x + column_width}" y2="{y + block_height}" stroke="{stroke}" stroke-width="0.7"/>',
        f'  <line x1="{x + 2 * column_width}" y1="{footer_top}" x2="{x + 2 * column_width}" y2="{y + block_height}" stroke="{stroke}" stroke-width="0.7"/>',
        f'  <text x="{x + block_width / 2}" y="{y + 13}" text-anchor="middle" font-size="10" font-weight="600" fill="{muted_fill}">{subtitle}</text>',
        f'  <text x="{x + block_width / 2}" y="{y + 42}" text-anchor="middle" font-size="18" font-weight="700" fill="{title_fill}">{title}</text>',
    ]
    lines.extend(
        f'  <text x="{caption_x}" y="{caption_y}" text-anchor="middle" font-size="{caption_size(caption)}" '
        f'font-weight="600" fill="{caption_fill}">{caption}</text>'
        for caption, caption_x, caption_fill in captions
    )
    return "\n".join(lines), rectangle_bounds(x - 6, y - 6, block_width + 12, block_height + 12)


def infer_shape(kind: str) -> str:
    mapping = {
        "rect": "rect",
        "double_rect": "rect",
        "cylinder": "rect",
        "document": "rect",
        "folder": "rect",
        "terminal": "rect",
        "hexagon": "rect",
        "circle_cluster": "cluster",
        "user_avatar": "rect",
        "bot": "rect",
        "speech": "rect",
        "icon_box": "rect",
    }
    return mapping.get(kind, "rect")


def node_bounds(data: Dict[str, object]) -> Bounds:
    kind = str(data.get("kind", data.get("shape", "rect")))
    x = to_float(data.get("x"))
    y = to_float(data.get("y"))
    if kind == "circle":
        r = to_float(data.get("r", 50))
        return (x - r, y - r, x + r, y + r)
    width = to_float(data.get("width", 180))
    height = to_float(data.get("height", 76))
    return (x, y, x + width, y + height)


def normalize_node(node_data: Dict[str, object], fallback_id: str) -> Node:
    kind = str(node_data.get("kind", node_data.get("shape", "rect")))
    bounds = node_bounds(node_data)
    left, top, right, bottom = bounds
    return Node(
        node_id=str(node_data.get("id", fallback_id)),
        kind=kind,
        shape=infer_shape(kind),
        data=node_data,
        bounds=bounds,
        cx=(left + right) / 2,
        cy=(top + bottom) / 2,
    )


def anchor_on_side(node: Node, side: str, offset: float = 0.0) -> Point:
    left, top, right, bottom = node.bounds
    cx, cy = node.cx, node.cy
    side = side.lower()
    safe_x = min(max(cx + offset, left + 12), right - 12)
    safe_y = min(max(cy + offset, top + 12), bottom - 12)
    if side == "left":
        return (left, safe_y)
    if side == "right":
        return (right, safe_y)
    if side == "top":
        return (safe_x, top)
    if side == "bottom":
        return (safe_x, bottom)
    if side == "top-left":
        return (left, top)
    if side == "top-right":
        return (right, top)
    if side == "bottom-left":
        return (left, bottom)
    if side == "bottom-right":
        return (right, bottom)
    return (cx, cy)


def anchor_point(node: Node, toward: Point, port: Optional[str] = None, offset: float = 0.0) -> Point:
    if port:
        return anchor_on_side(node, port, offset)
    left, top, right, bottom = node.bounds
    dx = toward[0] - node.cx
    dy = toward[1] - node.cy
    width = right - left
    height = bottom - top
    if abs(dx) * height >= abs(dy) * width:
        return (right, node.cy) if dx >= 0 else (left, node.cy)
    return (node.cx, bottom) if dy >= 0 else (node.cx, top)


def expand_bounds(bounds: Bounds, padding: float) -> Bounds:
    left, top, right, bottom = bounds
    return (left - padding, top - padding, right + padding, bottom + padding)


def segment_hits_bounds(p1: Point, p2: Point, bounds: Bounds) -> bool:
    x1, y1 = p1
    x2, y2 = p2
    left, top, right, bottom = bounds
    eps = 1e-6

    if abs(y1 - y2) < eps:
        y = y1
        if not (top + eps < y < bottom - eps):
            return False
        seg_left = min(x1, x2)
        seg_right = max(x1, x2)
        overlap_left = max(seg_left, left)
        overlap_right = min(seg_right, right)
        if overlap_right - overlap_left <= eps:
            return False
        if abs(overlap_left - x1) < eps and abs(overlap_right - x1) < eps:
            return False
        if abs(overlap_left - x2) < eps and abs(overlap_right - x2) < eps:
            return False
        return True

    if abs(x1 - x2) < eps:
        x = x1
        if not (left + eps < x < right - eps):
            return False
        seg_top = min(y1, y2)
        seg_bottom = max(y1, y2)
        overlap_top = max(seg_top, top)
        overlap_bottom = min(seg_bottom, bottom)
        if overlap_bottom - overlap_top <= eps:
            return False
        if abs(overlap_top - y1) < eps and abs(overlap_bottom - y1) < eps:
            return False
        if abs(overlap_top - y2) < eps and abs(overlap_bottom - y2) < eps:
            return False
        return True

    return False


def segment_axis(p1: Point, p2: Point) -> str:
    if abs(p1[1] - p2[1]) < 1e-6:
        return "horizontal"
    if abs(p1[0] - p2[0]) < 1e-6:
        return "vertical"
    return "other"


def port_axis(port: Optional[str]) -> Optional[str]:
    if not port:
        return None
    port = port.lower()
    if port in {"left", "right"}:
        return "horizontal"
    if port in {"top", "bottom"}:
        return "vertical"
    return None


def offset_point(point: Point, port: Optional[str], distance: float) -> Point:
    if not port:
        return point
    x, y = point
    port = port.lower()
    if port == "left":
        return (x - distance, y)
    if port == "right":
        return (x + distance, y)
    if port == "top":
        return (x, y - distance)
    if port == "bottom":
        return (x, y + distance)
    return point


def clear_port_point(
    endpoint: Point,
    port: Optional[str],
    desired_distance: float,
    obstacles: Sequence[Bounds],
    canvas_bounds: Optional[Bounds],
) -> Point:
    """Choose the longest safe straight lead from a node port."""

    distances = [desired_distance * fraction for fraction in (1.0, 0.75, 0.5, 0.35, 0.2, 0.0)]
    for distance in distances:
        candidate = offset_point(endpoint, port, distance)
        if canvas_bounds is not None and not geometry.point_in_bounds(candidate, canvas_bounds):
            continue
        if any(
            geometry.point_in_bounds(candidate, obstacle, interior=True)
            or segment_hits_bounds(endpoint, candidate, obstacle)
            for obstacle in obstacles
        ):
            continue
        return candidate
    return endpoint


def route_length(points: Sequence[Point]) -> float:
    return sum(abs(x1 - x2) + abs(y1 - y2) for (x1, y1), (x2, y2) in zip(points, points[1:]))


def route_uses_lane(points: Sequence[Point], value: float, axis: str, tolerance: float = 1.0) -> bool:
    if axis == "x":
        return any(abs(x - value) <= tolerance for x, _ in points)
    return any(abs(y - value) <= tolerance for _, y in points)


def collision_count(points: Sequence[Point], obstacles: Sequence[Bounds]) -> int:
    """Count how many (segment, obstacle) pairs collide."""
    return sum(
        1
        for p1, p2 in zip(points, points[1:])
        for obs in obstacles
        if segment_hits_bounds(p1, p2, obs)
    )


def route_is_orthogonal(points: Sequence[Point]) -> bool:
    return all(segment_axis(p1, p2) != "other" for p1, p2 in zip(points, points[1:]))


def route_crossing_count(points: Sequence[Point], existing_routes: Sequence[Sequence[Point]]) -> int:
    return geometry.route_crossing_count(points, existing_routes)


def route_score(
    points: Sequence[Point],
    hint_x: Sequence[float],
    hint_y: Sequence[float],
    source_port: Optional[str],
    target_port: Optional[str],
    existing_routes: Sequence[Sequence[Point]] = (),
) -> float:
    length = route_length(points)
    bends = max(0, len(points) - 2)
    score = length + bends * 22
    if len(points) >= 2 and source_port:
        first_axis = segment_axis(points[0], points[1])
        if first_axis != port_axis(source_port):
            score += 180
    if len(points) >= 2 and target_port:
        last_axis = segment_axis(points[-2], points[-1])
        if last_axis != port_axis(target_port):
            score += 180
    for lane in hint_x:
        score -= 28 if route_uses_lane(points, lane, "x") else 0
    for lane in hint_y:
        score -= 28 if route_uses_lane(points, lane, "y") else 0
    interactions = geometry.route_interactions(points, existing_routes)
    score += len(interactions.crossings) * 640
    score += interactions.overlap_count * 900 + interactions.overlap_length * 18
    return score


def simplify_points(points: Sequence[Point], protected: Sequence[Point] = ()) -> List[Point]:
    protected_points = {(round(point[0], 2), round(point[1], 2)) for point in protected}
    simplified: List[Point] = []
    for x, y in points:
        pt = (round(x, 2), round(y, 2))
        if simplified and pt == simplified[-1]:
            continue
        simplified.append(pt)

    collapsed: List[Point] = []
    for point in simplified:
        if len(collapsed) < 2:
            collapsed.append(point)
            continue
        x0, y0 = collapsed[-2]
        x1, y1 = collapsed[-1]
        x2, y2 = point
        # A same-axis reversal adds length and can create sub-pixel hairpins
        # when two port-clearance leads nearly meet.  The straight segment
        # from the first to the third point covers the same safe corridor, so
        # collapse both monotonic and reversing collinear triples unless the
        # middle point is an explicit user waypoint.
        collinear_vertical = x0 == x1 == x2
        collinear_horizontal = y0 == y1 == y2
        if (collinear_vertical or collinear_horizontal) and (x1, y1) not in protected_points:
            collapsed[-1] = point
        else:
            collapsed.append(point)
    return collapsed


def route_collides(points: Sequence[Point], obstacles: Sequence[Bounds]) -> bool:
    return collision_count(points, obstacles) > 0


def visibility_grid_route(
    start: Point,
    end: Point,
    obstacles: Sequence[Bounds],
    *,
    canvas_bounds: Optional[Bounds],
    hint_x: Sequence[float],
    hint_y: Sequence[float],
    existing_routes: Sequence[Sequence[Point]],
) -> Optional[List[Point]]:
    """Find a deterministic rectilinear route on an obstacle visibility grid."""

    if start == end:
        return [start]
    if canvas_bounds is None:
        all_x = [start[0], end[0], *[value for bounds in obstacles for value in (bounds[0], bounds[2])]]
        all_y = [start[1], end[1], *[value for bounds in obstacles for value in (bounds[1], bounds[3])]]
        canvas_bounds = (min(all_x) - 64, min(all_y) - 64, max(all_x) + 64, max(all_y) + 64)
    canvas_left, canvas_top, canvas_right, canvas_bottom = canvas_bounds
    inset = 4.0

    x_values = {
        round(start[0], 2),
        round(end[0], 2),
        round((start[0] + end[0]) / 2, 2),
        round(canvas_left + inset, 2),
        round(canvas_right - inset, 2),
        *[round(value, 2) for value in hint_x],
    }
    y_values = {
        round(start[1], 2),
        round(end[1], 2),
        round((start[1] + end[1]) / 2, 2),
        round(canvas_top + inset, 2),
        round(canvas_bottom - inset, 2),
        *[round(value, 2) for value in hint_y],
    }
    for left, top, right, bottom in obstacles:
        x_values.update((round(left, 2), round(right, 2)))
        y_values.update((round(top, 2), round(bottom, 2)))
    for route in existing_routes:
        for x, y in route:
            for delta in (-10.0, 0.0, 10.0):
                x_values.add(round(x + delta, 2))
                y_values.add(round(y + delta, 2))

    x_values = {value for value in x_values if canvas_left - 1e-6 <= value <= canvas_right + 1e-6}
    y_values = {value for value in y_values if canvas_top - 1e-6 <= value <= canvas_bottom + 1e-6}
    points = {
        (x, y)
        for x in sorted(x_values)
        for y in sorted(y_values)
        if not any(geometry.point_in_bounds((x, y), bounds, interior=True) for bounds in obstacles)
    }
    points.update((start, end))

    adjacency: Dict[Point, List[Point]] = {point: [] for point in points}
    by_y: Dict[float, List[Point]] = {}
    by_x: Dict[float, List[Point]] = {}
    for point in points:
        by_y.setdefault(point[1], []).append(point)
        by_x.setdefault(point[0], []).append(point)

    def connect(line: Sequence[Point], sort_key: int) -> None:
        ordered = sorted(line, key=lambda point: (point[sort_key], point[1 - sort_key]))
        for first, second in zip(ordered, ordered[1:]):
            if any(segment_hits_bounds(first, second, obstacle) for obstacle in obstacles):
                continue
            adjacency[first].append(second)
            adjacency[second].append(first)

    for line in by_y.values():
        connect(line, 0)
    for line in by_x.values():
        connect(line, 1)

    # State includes the incoming axis so bends have an explicit cost.
    start_state = (start, "")
    distances: Dict[Tuple[Point, str], float] = {start_state: 0.0}
    paths: Dict[Tuple[Point, str], Tuple[Point, ...]] = {start_state: (start,)}
    queue: List[Tuple[float, Tuple[Point, ...], Point, str]] = [(0.0, (start,), start, "")]
    best_end: Optional[Tuple[float, Tuple[Point, ...]]] = None

    while queue:
        cost, path_key, point, incoming = heapq.heappop(queue)
        state = (point, incoming)
        if cost > distances.get(state, float("inf")) + 1e-6 or path_key != paths.get(state):
            continue
        if point == end:
            best_end = (cost, path_key)
            break
        for neighbor in sorted(adjacency.get(point, [])):
            axis = segment_axis(point, neighbor)
            if axis == "other":
                continue
            distance = abs(neighbor[0] - point[0]) + abs(neighbor[1] - point[1])
            segment_route = [point, neighbor]
            interactions = geometry.route_interactions(segment_route, existing_routes)
            extra = distance
            if incoming and incoming != axis:
                extra += 22.0
            extra += len(interactions.crossings) * 640.0
            extra += interactions.overlap_count * 10000.0 + interactions.overlap_length * 30.0
            if axis == "vertical" and any(abs(point[0] - value) <= 1 for value in hint_x):
                extra -= min(18.0, distance * 0.08)
            if axis == "horizontal" and any(abs(point[1] - value) <= 1 for value in hint_y):
                extra -= min(18.0, distance * 0.08)
            next_state = (neighbor, axis)
            next_cost = cost + extra
            next_path = (*path_key, neighbor)
            old_cost = distances.get(next_state, float("inf"))
            old_path = paths.get(next_state)
            if next_cost < old_cost - 1e-6 or (
                abs(next_cost - old_cost) <= 1e-6 and (old_path is None or next_path < old_path)
            ):
                distances[next_state] = next_cost
                paths[next_state] = next_path
                heapq.heappush(queue, (next_cost, next_path, neighbor, axis))

    if best_end is None:
        return None
    return simplify_points(list(best_end[1]))


def build_orthogonal_route(
    start: Point,
    end: Point,
    obstacles: Sequence[Bounds],
    arrow_data: Dict[str, object],
    *,
    canvas_bounds: Optional[Bounds] = None,
    existing_routes: Sequence[Sequence[Point]] = (),
) -> List[Point]:
    raw_waypoints = arrow_data.get("route_points") or []
    if raw_waypoints:
        waypoints: List[Point] = []
        for index, raw_point in enumerate(raw_waypoints):
            if not isinstance(raw_point, (list, tuple)) or len(raw_point) != 2:
                raise ValueError(f"route waypoint {index + 1} must be [x, y]")
            waypoint = (to_float(raw_point[0]), to_float(raw_point[1]))
            if any(geometry.point_in_bounds(waypoint, bounds, interior=True) for bounds in obstacles):
                raise ValueError(f"route waypoint {index + 1} intersects an obstacle: {waypoint}")
            if canvas_bounds is not None and not geometry.point_in_bounds(waypoint, canvas_bounds):
                raise ValueError(f"route waypoint {index + 1} is outside the canvas: {waypoint}")
            waypoints.append(waypoint)

        mandatory = [start, *waypoints, end]
        assembled: List[Point] = []
        for index, (segment_start, segment_end) in enumerate(zip(mandatory, mandatory[1:])):
            segment_data = dict(arrow_data)
            segment_data.pop("route_points", None)
            if index > 0:
                segment_data.pop("source_port", None)
            if index < len(mandatory) - 2:
                segment_data.pop("target_port", None)
            occupied_routes: List[Sequence[Point]] = list(existing_routes)
            if len(assembled) >= 2:
                occupied_routes.append(assembled)
            segment_route = build_orthogonal_route(
                segment_start,
                segment_end,
                obstacles,
                segment_data,
                canvas_bounds=canvas_bounds,
                existing_routes=occupied_routes,
            )
            if assembled:
                assembled.extend(segment_route[1:])
            else:
                assembled.extend(segment_route)
        result = simplify_points(assembled, waypoints)
        if not route_is_orthogonal(result):
            raise ValueError("explicit route waypoints could not be connected orthogonally")
        if any(waypoint not in result for waypoint in waypoints):
            raise ValueError("explicit route waypoint was not preserved")
        if route_collides(result, obstacles):
            raise ValueError("explicit route waypoints cannot be connected without crossing an obstacle")
        return result

    sx, sy = start
    ex, ey = end
    routing_padding = to_float(arrow_data.get("routing_padding", 24))
    port_clearance = to_float(arrow_data.get("port_clearance", max(18, routing_padding * 0.85)))
    source_port = str(arrow_data.get("source_port", "")).strip().lower() or None
    target_port = str(arrow_data.get("target_port", "")).strip().lower() or None
    inner_start = clear_port_point(start, source_port, port_clearance, obstacles, canvas_bounds)
    inner_end = clear_port_point(end, target_port, port_clearance, obstacles, canvas_bounds)
    ssx, ssy = inner_start
    eex, eey = inner_end
    expanded: List[Bounds] = []
    for bounds in obstacles:
        padded = expand_bounds(bounds, routing_padding)
        # Mandatory waypoints are exact. If one sits inside a clearance halo,
        # keep the real obstacle hard while locally relaxing only that halo.
        if any(
            geometry.point_in_bounds(point, padded, interior=True)
            and not geometry.point_in_bounds(point, bounds, interior=True)
            for point in (start, end, inner_start, inner_end)
        ):
            expanded.append(bounds)
        else:
            expanded.append(padded)
    hint_x = [to_float(value) for value in arrow_data.get("corridor_x", [])]
    hint_y = [to_float(value) for value in arrow_data.get("corridor_y", [])]
    lane_x = sorted({ssx, eex, round((ssx + eex) / 2, 2), *hint_x, *[b[0] for b in expanded], *[b[2] for b in expanded]})
    lane_y = sorted({ssy, eey, round((ssy + eey) / 2, 2), *hint_y, *[b[1] for b in expanded], *[b[3] for b in expanded]})
    if expanded:
        left_rail = min(b[0] for b in expanded) - 24
        right_rail = max(b[2] for b in expanded) + 24
        top_rail = min(b[1] for b in expanded) - 24
        bottom_rail = max(b[3] for b in expanded) + 24
    else:
        left_rail = min(ssx, eex) - 48
        right_rail = max(ssx, eex) + 48
        top_rail = min(ssy, eey) - 48
        bottom_rail = max(ssy, eey) + 48

    candidates = [
        [start, inner_start, inner_end, end],
        [start, inner_start, (eex, ssy), inner_end, end],
        [start, inner_start, (ssx, eey), inner_end, end],
        [start, inner_start, ((ssx + eex) / 2, ssy), ((ssx + eex) / 2, eey), inner_end, end],
        [start, inner_start, (ssx, (ssy + eey) / 2), (eex, (ssy + eey) / 2), inner_end, end],
        [start, inner_start, (left_rail, ssy), (left_rail, eey), inner_end, end],
        [start, inner_start, (right_rail, ssy), (right_rail, eey), inner_end, end],
        [start, inner_start, (ssx, top_rail), (eex, top_rail), inner_end, end],
        [start, inner_start, (ssx, bottom_rail), (eex, bottom_rail), inner_end, end],
    ]
    for x in lane_x:
        candidates.append([start, inner_start, (x, ssy), (x, eey), inner_end, end])
    for y in lane_y:
        candidates.append([start, inner_start, (ssx, y), (eex, y), inner_end, end])
    for x in hint_x:
        for y in hint_y:
            candidates.append([start, inner_start, (x, ssy), (x, y), (eex, y), inner_end, end])

    visibility = visibility_grid_route(
        inner_start,
        inner_end,
        expanded,
        canvas_bounds=canvas_bounds,
        hint_x=hint_x,
        hint_y=hint_y,
        existing_routes=existing_routes,
    )
    if visibility:
        candidates.append([start, *visibility, end])

    best_route: Optional[List[Point]] = None
    best_score = float("inf")
    for candidate in candidates:
        simplified = simplify_points(candidate)
        if not route_is_orthogonal(simplified):
            continue
        if canvas_bounds is not None and not geometry.route_inside_canvas(simplified, canvas_bounds):
            continue
        coll = collision_count(simplified, expanded)
        score = route_score(simplified, hint_x, hint_y, source_port, target_port, existing_routes)
        if coll == 0:
            if score < best_score or (abs(score - best_score) < 1e-6 and (best_route is None or tuple(simplified) < tuple(best_route))):
                best_score = score
                best_route = simplified

    if best_route is not None:
        return best_route
    raise ValueError("no collision-free orthogonal route satisfies the current constraints")


def choose_label_position(points: Sequence[Point]) -> Point:
    segments = list(zip(points, points[1:]))
    if not segments:
        return points[0]
    best = max(segments, key=lambda seg: abs(seg[0][0] - seg[1][0]) + abs(seg[0][1] - seg[1][1]))
    return ((best[0][0] + best[1][0]) / 2, (best[0][1] + best[1][1]) / 2)


def color_for_flow(style: Dict[str, object], arrow_data: Dict[str, object]) -> str:
    if arrow_data.get("color"):
        return str(arrow_data["color"])
    flow = FLOW_ALIASES.get(str(arrow_data.get("flow", "control")).lower(), "control")
    return str(style_value(style, "arrow_colors")[flow])


def marker_for_color(style: Dict[str, object], color: str, arrow_data: Dict[str, object]) -> str:
    if arrow_data.get("marker"):
        return f"url(#{arrow_data['marker']})"
    colors = style_value(style, "arrow_colors")
    for name, token in colors.items():
        if token == color:
            return f"url(#{MARKER_IDS.get(name, 'arrowA')})"
    return "url(#arrowA)"


def render_label_badge(x: float, y: float, text: str, style: Dict[str, object], label_style: str = "offset") -> str:
    width = max(36.0, geometry.estimate_text_width(text, 12) + 14)
    parts: List[str] = []
    if label_style == "badge":
        bg = style_value(style, "arrow_label_bg")
        opacity = style_value(style, "arrow_label_opacity")
        parts.append(f'  <rect x="{round(x - width / 2, 2)}" y="{round(y - 10, 2)}" width="{width}" height="20" rx="6" fill="{bg}" opacity="{opacity}"/>')
    parts.append(f'  <text x="{round(x, 2)}" y="{round(y + 4, 2)}" text-anchor="middle" class="arrow-label">{normalize_text(text)}</text>')
    return "\n".join(parts)


def rectangle_bounds(x: float, y: float, width: float, height: float) -> Bounds:
    return (x, y, x + width, y + height)


def bounds_intersect(a: Bounds, b: Bounds, padding: float = 0.0) -> bool:
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    return not (
        ax2 + padding <= bx1
        or bx2 + padding <= ax1
        or ay2 + padding <= by1
        or by2 + padding <= ay1
    )


def estimate_label_bounds(x: float, y: float, text: str) -> Bounds:
    width = max(36.0, geometry.estimate_text_width(text, 12) + 14)
    return rectangle_bounds(x - width / 2, y - 10, width, 20)


def render_dual_label_badge(x: float, y: float, primary: str, secondary: str, style: Dict[str, object]) -> str:
    width = max(
        42.0,
        geometry.estimate_text_width(primary, 11.5) + 16,
        geometry.estimate_text_width(secondary, 8.5) + 16,
    )
    bg = style_value(style, "arrow_label_bg")
    opacity = style_value(style, "arrow_label_opacity")
    return "\n".join(
        [
            f'  <rect x="{round(x - width / 2, 2)}" y="{round(y - 16, 2)}" width="{round(width, 2)}" height="32" rx="7" fill="{bg}" opacity="{opacity}"/>',
            f'  <text x="{round(x, 2)}" y="{round(y - 1, 2)}" text-anchor="middle" class="arrow-label" font-size="11.5">{normalize_text(primary)}</text>',
            f'  <text x="{round(x, 2)}" y="{round(y + 11, 2)}" text-anchor="middle" font-size="8.5" font-weight="800" fill="{style_value(style, "type_label_fill")}">[{normalize_text(secondary)}]</text>',
        ]
    )


def estimate_dual_label_bounds(x: float, y: float, primary: str, secondary: str) -> Bounds:
    width = max(
        42.0,
        geometry.estimate_text_width(primary, 11.5) + 16,
        geometry.estimate_text_width(secondary, 8.5) + 16,
    )
    return rectangle_bounds(x - width / 2, y - 16, width, 32)


def section_header_text(container: Dict[str, object], style: Dict[str, object]) -> str:
    if container.get("header_text"):
        text = str(container.get("header_text", ""))
    else:
        label = str(container.get("label", ""))
        prefix = str(container.get("header_prefix", "")).strip()
        separator = str(container.get("header_separator", " // " if prefix else ""))
        text = f"{prefix}{separator}{label}" if prefix else label
    if style_value(style, "section_upper") and not container.get("preserve_case"):
        text = text.upper()
    return text


def deterministic_jitter(seed: object, element_id: object, pass_index: int, amplitude: float = 1.5) -> float:
    """Return stable decorative jitter without relying on process-randomized hash()."""

    digest = hashlib.sha256(f"{seed}:{element_id}:{pass_index}".encode("utf-8")).digest()
    unit = int.from_bytes(digest[:4], "big") / float(2**32 - 1)
    return round((unit * 2.0 - 1.0) * amplitude, 3)


def render_section(container: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(container["x"])
    y = to_float(container["y"])
    width = to_float(container["width"])
    height = to_float(container["height"])
    rx = to_float(container.get("rx", 16 if style_value(style, "name") != "Notion Clean" else 4))
    fill = str(container.get("fill", style_value(style, "section_fill")))
    stroke = str(container.get("stroke", style_value(style, "section_stroke")))
    dash = str(container.get("stroke_dasharray", style_value(style, "section_dash")))
    label = section_header_text(container, style)
    subtitle = str(container.get("subtitle", ""))
    side_label = str(container.get("side_label", "")).strip()
    side_label_fill = str(container.get("side_label_fill", style_value(style, "text_secondary")))
    side_label_size = to_float(container.get("side_label_size", 14))
    side_label_weight = str(container.get("side_label_weight", "600"))
    side_label_anchor = str(container.get("side_label_anchor", "end"))
    lines = [f'  <rect data-graph-role="container" x="{x}" y="{y}" width="{width}" height="{height}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="1.4"']
    if dash:
        lines[-1] += f' stroke-dasharray="{dash}"'
    lines[-1] += "/>"
    treatment = str(style.get("canvas_treatment", ""))
    if treatment == "review":
        seed = container.get("_rough_seed", 0)
        element_id = container.get("id", label or "container")
        dx = deterministic_jitter(seed, element_id, 1)
        dy = deterministic_jitter(seed, element_id, 2)
        lines.append(
            f'  <rect data-graph-role="decoration" x="{x + 2 + dx}" y="{y + 2 + dy}" '
            f'width="{width - 4}" height="{height - 4}" rx="{max(3, rx - 1)}" fill="none" '
            f'stroke="{stroke}" stroke-width="0.9" stroke-dasharray="13 7" opacity="0.42"/>'
        )
    elif treatment == "cloud" and container.get("deployment_kind"):
        deployment_kind = str(container.get("deployment_kind", ""))
        badge = normalize_text(deployment_kind.upper())
        badge_width = max(54.0, geometry.estimate_text_width(str(container.get("deployment_kind", "")), 9) + 18)
        spine_color = {"global": "#2563eb", "region": "#0891b2", "network": "#7c3aed"}.get(deployment_kind, "#7fa3c2")
        lines.append(
            f'  <rect data-graph-role="decoration" x="{x + width - badge_width - 14}" y="{y + 10}" '
            f'width="{badge_width}" height="18" rx="9" fill="#dbeafe" stroke="#93c5fd" stroke-width="0.8"/>'
        )
        lines.append(
            f'  <text data-graph-role="decoration" x="{x + width - badge_width / 2 - 14}" y="{y + 22.5}" '
            f'text-anchor="middle" font-size="9" font-weight="700" fill="#315d7e">{badge}</text>'
        )
        lines.append(
            f'  <line data-graph-role="decoration" x1="{x + 8}" y1="{y + 42}" x2="{x + 8}" y2="{y + height - 14}" '
            f'stroke="{spine_color}" stroke-width="2.2" stroke-linecap="round" opacity="0.72"/>'
        )
    elif treatment == "transit":
        lines.append(
            f'  <line data-graph-role="decoration" x1="{x + 18}" y1="{y + 34}" x2="{x + width - 18}" y2="{y + 34}" '
            f'stroke="{stroke}" stroke-width="1" stroke-dasharray="2 7" opacity="0.35"/>'
        )
    elif treatment == "ops":
        lines.append(
            f'  <line data-graph-role="decoration" x1="{x + 14}" y1="{y + 34}" x2="{x + width - 14}" y2="{y + 34}" '
            f'stroke="#38bdf8" stroke-width="1" opacity="0.16"/>'
        )
        if "trace" in str(container.get("id", "")).lower():
            ruler_left = x + width - 244
            ruler_right = x + width - 24
            lines.append(
                f'  <line data-graph-role="decoration" x1="{ruler_left}" y1="{y + 22}" x2="{ruler_right}" y2="{y + 22}" '
                f'stroke="#38bdf8" stroke-width="1" opacity="0.42"/>'
            )
            for index in range(5):
                tick_x = ruler_left + (ruler_right - ruler_left) * index / 4
                lines.append(
                    f'  <line data-graph-role="decoration" x1="{tick_x}" y1="{y + 18}" x2="{tick_x}" y2="{y + 26}" '
                    f'stroke="#38bdf8" stroke-width="1" opacity="0.52"/>'
                )
                lines.append(
                    f'  <text data-graph-role="decoration" x="{tick_x}" y="{y + 14}" text-anchor="middle" '
                    f'font-size="7" font-weight="700" fill="#6f8ba5">{index * 25}%</text>'
                )
    if label:
        lines.append(f'  <text x="{x + 18}" y="{y + 24}" class="section">{normalize_text(label)}</text>')
    if subtitle:
        lines.append(f'  <text x="{x + 18}" y="{y + 44}" class="section-sub">{normalize_text(subtitle)}</text>')
    if side_label:
        side_x = to_float(container.get("side_label_x", max(28, x - 18)))
        side_y = to_float(container.get("side_label_y", y + height / 2))
        lines.append(
            f'  <text x="{side_x}" y="{side_y}" text-anchor="{side_label_anchor}" dominant-baseline="middle" '
            f'font-size="{side_label_size}" font-weight="{side_label_weight}" fill="{side_label_fill}">{normalize_text(side_label)}</text>'
        )
    return "\n".join(lines)


def container_header_bounds(container: Dict[str, object], style: Optional[Dict[str, object]] = None) -> Optional[Bounds]:
    label = section_header_text(container, style) if style is not None else str(container.get("header_text", "") or container.get("label", ""))
    label = label.strip()
    subtitle = str(container.get("subtitle", "")).strip()
    if not label and not subtitle:
        return None
    x = to_float(container["x"])
    y = to_float(container["y"])
    width = to_float(container["width"])
    header_height = to_float(container.get("header_height", 54 if subtitle else 30))
    label_width = geometry.estimate_text_width(label, 13) if label else 0.0
    subtitle_width = geometry.estimate_text_width(subtitle, 12) if subtitle else 0.0
    reserved_width = min(width - 12, max(label_width, subtitle_width) + 30)
    return rectangle_bounds(x + 8, y + 6, reserved_width, header_height)


def label_position_candidates(points: Sequence[Point], text: str = "") -> List[Point]:
    segments = list(zip(points, points[1:]))
    if not segments:
        return [points[0]]
    ranked_segments = sorted(
        segments,
        key=lambda seg: abs(seg[0][0] - seg[1][0]) + abs(seg[0][1] - seg[1][1]),
        reverse=True,
    )
    candidates: List[Point] = []
    horizontal_offset = 17.0
    vertical_offset = max(22.0, geometry.estimate_text_width(text, 12) / 2 + 10)
    global_x = (min(point[0] for point in points) + max(point[0] for point in points)) / 2
    global_y = (min(point[1] for point in points) + max(point[1] for point in points)) / 2
    for (x1, y1), (x2, y2) in ranked_segments:
        length = abs(x1 - x2) + abs(y1 - y2)
        if length < 34:
            continue
        centers = [
            ((x1 + x2) / 2, (y1 + y2) / 2),
            (x1 * 0.7 + x2 * 0.3, y1 * 0.7 + y2 * 0.3),
            (x1 * 0.3 + x2 * 0.7, y1 * 0.3 + y2 * 0.7),
        ]
        for mx, my in centers:
            if abs(y1 - y2) < 1e-6:
                candidates.extend([(mx, my - horizontal_offset), (mx, my + horizontal_offset), (mx, my - 30), (mx, my + 30), (mx, my)])
                candidates.extend([(global_x, my - horizontal_offset), (global_x, my + horizontal_offset)])
            elif abs(x1 - x2) < 1e-6:
                candidates.extend([(mx - vertical_offset, my), (mx + vertical_offset, my), (mx - vertical_offset - 14, my), (mx + vertical_offset + 14, my), (mx, my)])
                candidates.extend([(mx - vertical_offset, global_y), (mx + vertical_offset, global_y)])
            else:
                candidates.extend([(mx, my - 16), (mx, my + 16), (mx, my)])
    return candidates or [choose_label_position(points)]


def route_clearance_bounds(points: Sequence[Point], padding: float = 3.0) -> List[Bounds]:
    result: List[Bounds] = []
    for first, second in zip(points, points[1:]):
        left = min(first[0], second[0]) - padding
        right = max(first[0], second[0]) + padding
        top = min(first[1], second[1]) - padding
        bottom = max(first[1], second[1]) + padding
        result.append((left, top, right, bottom))
    return result


def choose_label_position_avoiding(
    points: Sequence[Point],
    text: str,
    occupied: Sequence[Bounds],
    *,
    routes: Sequence[Sequence[Point]] = (),
    canvas_bounds: Optional[Bounds] = None,
    dx: float = 0.0,
    dy: float = -4.0,
) -> Point:
    route_bounds = [bounds for route in routes for bounds in route_clearance_bounds(route)]
    offset_options = [
        (dx, dy),
        (0.0, -4.0),
        (0.0, 0.0),
        (0.0, -14.0),
        (0.0, 14.0),
        (-18.0, -4.0),
        (18.0, -4.0),
        (-32.0, 0.0),
        (32.0, 0.0),
    ]
    for candidate in label_position_candidates(points, text):
        for offset_x, offset_y in offset_options:
            adjusted = (candidate[0] + offset_x, candidate[1] + offset_y)
            label_box = estimate_label_bounds(adjusted[0], adjusted[1], text)
            if canvas_bounds is not None and not geometry.bounds_inside(label_box, canvas_bounds, 4):
                continue
            if any(bounds_intersect(label_box, other, 4) for other in occupied):
                continue
            if any(bounds_intersect(label_box, other, 1) for other in route_bounds):
                continue
            return adjusted
    raise ValueError(f"no collision-free label position for {text!r}")


def legend_layout(data: Dict[str, object], legend: Sequence[Dict[str, object]], width: float, height: float) -> Optional[Tuple[float, float, Bounds]]:
    if not legend:
        return None
    orientation = str(data.get("legend_orientation", "vertical")).strip().lower()
    if orientation not in {"vertical", "horizontal"}:
        raise ValueError("legend_orientation must be vertical or horizontal")
    x = to_float(data.get("_legend_x", data.get("legend_x", 42)))
    default_y = height - 82 if orientation == "horizontal" else height - (len(legend) * 22 + 34)
    y = to_float(data.get("_legend_y", data.get("legend_y", default_y)))
    position = str(data.get("legend_position", "bottom-left"))
    label_widths = [geometry.estimate_text_width(str(item.get("label", "")), 12) for item in legend]
    if orientation == "horizontal":
        block_width = sum(40 + label_width + 28 for label_width in label_widths) - 18
        block_height = 28
    else:
        block_width = 40 + max(label_widths, default=84) + 12
        block_height = len(legend) * 22 + 6
    if "_legend_x" not in data and position == "bottom-right":
        x = to_float(data.get("legend_x", width - block_width - 42))
    elif "_legend_x" not in data and position == "top-right":
        x = to_float(data.get("legend_x", width - block_width - 42))
        y = to_float(data.get("legend_y", 96))
    elif "_legend_x" not in data and position == "top-left":
        x = to_float(data.get("legend_x", 42))
        y = to_float(data.get("legend_y", 96))
    return (x, y, rectangle_bounds(x - 10, y - 14, block_width + 20, block_height + 18))


def route_hint_points(arrow: Dict[str, object], node_map: Dict[str, Node]) -> List[Point]:
    source = node_map.get(str(arrow.get("source"))) if arrow.get("source") else None
    target = node_map.get(str(arrow.get("target"))) if arrow.get("target") else None
    start_hint = (to_float(arrow.get("x1")), to_float(arrow.get("y1")))
    end_hint = (to_float(arrow.get("x2")), to_float(arrow.get("y2")))
    if source is not None:
        toward = end_hint if target is None else (target.cx, target.cy)
        start = anchor_point(source, toward, str(arrow.get("source_port")) if arrow.get("source_port") else None)
    else:
        start = start_hint
    if target is not None:
        toward = start_hint if source is None else (source.cx, source.cy)
        end = anchor_point(target, toward, str(arrow.get("target_port")) if arrow.get("target_port") else None)
    else:
        end = end_hint
    waypoints = [(to_float(point[0]), to_float(point[1])) for point in (arrow.get("route_points") or [])]
    return [start, *waypoints, end]


def resolve_legend_layout(
    data: Dict[str, object],
    legend: Sequence[Dict[str, object]],
    width: float,
    height: float,
    obstacles: Sequence[Bounds],
    arrows: Sequence[Dict[str, object]],
    node_map: Dict[str, Node],
) -> Optional[Dict[str, object]]:
    requested = legend_layout(data, legend, width, height)
    if requested is None:
        return None
    requested_x, requested_y, requested_bounds = requested
    hint_routes = [route_hint_points(arrow, node_map) for arrow in arrows if arrow.get("route_points")]
    canvas = (0.0, 0.0, width, height)

    def is_safe(bounds: Bounds) -> bool:
        if not geometry.bounds_inside(bounds, canvas, 8):
            return False
        if any(bounds_intersect(bounds, obstacle, 6) for obstacle in obstacles):
            return False
        return not any(
            segment_hits_bounds(first, second, bounds)
            for route in hint_routes
            for first, second in zip(route, route[1:])
        )

    if is_safe(requested_bounds):
        return {
            "requested": [round(requested_x, 2), round(requested_y, 2)],
            "actual": [round(requested_x, 2), round(requested_y, 2)],
            "moved": False,
            "bounds": requested_bounds,
        }
    if data.get("legend_locked"):
        raise ValueError("locked legend intersects diagram content or a mandatory route")

    block_width = requested_bounds[2] - requested_bounds[0]
    block_height = requested_bounds[3] - requested_bounds[1]
    candidates: List[Tuple[float, float]] = []
    for top in range(84, max(85, int(height - block_height - 8)) + 1, 8):
        for left in range(8, max(9, int(width - block_width - 8)) + 1, 8):
            x = left + 10
            y = top + 14
            candidates.append((float(x), float(y)))
    candidates.sort(key=lambda point: (abs(point[0] - requested_x) + abs(point[1] - requested_y), point[1], point[0]))
    for x, y in candidates:
        bounds = (x - 10, y - 14, x - 10 + block_width, y - 14 + block_height)
        if is_safe(bounds):
            data["_legend_x"] = x
            data["_legend_y"] = y
            return {
                "requested": [round(requested_x, 2), round(requested_y, 2)],
                "actual": [round(x, 2), round(y, 2)],
                "moved": True,
                "bounds": bounds,
            }
    raise ValueError("no collision-free legend position is available")


def footer_layout(data: Dict[str, object], width: float, height: float) -> Optional[Tuple[float, float, Bounds]]:
    text = str(data.get("footer", "")).strip()
    if not text:
        return None
    footer_width = max(140, len(text) * 7)
    x = to_float(data.get("footer_x", 42))
    y = to_float(data.get("footer_y", height - 16))
    position = str(data.get("footer_position", "bottom-left"))
    if position == "bottom-right":
        x = to_float(data.get("footer_x", width - footer_width - 42))
    return (x, y, rectangle_bounds(x, y - 12, footer_width, 16))


def render_tags(node: Dict[str, object], x: float, y: float, style: Dict[str, object]) -> List[str]:
    tags = node.get("tags", [])
    if not tags:
        return []
    cursor_x = x
    lines = []
    for tag in tags:
        label = normalize_text(tag.get("label", ""))
        width = max(62, len(str(tag.get("label", ""))) * 8 + 18)
        fill = tag.get("fill", "#eff6ff")
        stroke = tag.get("stroke", "#bfdbfe")
        text_fill = tag.get("text_fill", style_value(style, "arrow_colors")["read"])
        lines.append(
            f'  <rect x="{cursor_x}" y="{y}" width="{width}" height="16" rx="3" fill="{fill}" stroke="{stroke}" stroke-width="1"/>'
        )
        lines.append(
            f'  <text x="{cursor_x + width / 2}" y="{y + 11.5}" text-anchor="middle" font-size="11" font-weight="500" fill="{text_fill}">{label}</text>'
        )
        cursor_x += width + 8
    return lines


def fitted_text_size(text: str, available_width: float, *, preferred: float = 18.0, minimum: float = 12.0) -> float:
    """Keep a single-line node title inside its card without manual tuning."""

    estimated = geometry.estimate_text_width(text, preferred, weight=1.08)
    if estimated <= max(1.0, available_width):
        return preferred
    scaled = max(minimum, preferred * available_width / max(estimated, 1.0))
    return math.floor(scaled * 100) / 100


def fit_single_line_text(
    text: object,
    available_width: float,
    *,
    preferred: float = 18.0,
    minimum: float = 12.0,
) -> Tuple[str, float]:
    """Fit one line, then fail visually closed with an ellipsis at the minimum size."""

    value = " ".join(str(text or "").split())
    size = fitted_text_size(value, available_width, preferred=preferred, minimum=minimum)
    if geometry.estimate_text_width(value, size, weight=1.08) <= available_width:
        return value, size
    candidate = value
    while candidate and geometry.estimate_text_width(candidate + "…", size, weight=1.08) > available_width:
        candidate = candidate[:-1].rstrip()
    return (candidate + "…" if candidate else "…"), size


def wrap_text_lines(text: object, available_width: float, *, font_size: float = 11.5, max_lines: int = 2) -> List[str]:
    """Balance short card copy across lines and fail visually closed with an ellipsis."""

    value = " ".join(str(text or "").split())
    if not value:
        return []
    if geometry.estimate_text_width(value, font_size) <= available_width:
        return [value]
    if max_lines <= 1:
        return [fit_single_line_text(value, available_width, preferred=font_size, minimum=font_size)[0]]
    words = value.split()
    # Chinese/Japanese text has valid line breaks without spaces. Keep complete
    # grapheme-like clusters together and use the second line before truncating.
    if any(ord(character) >= 0x2e80 for character in value):
        clusters = []
        import unicodedata
        for character in value:
            if clusters and (unicodedata.combining(character) or character in "\ufe0f\ufe0e"):
                clusters[-1] += character
            else:
                clusters.append(character)
        lines = []
        current = ""
        for cluster in clusters:
            candidate = current + cluster
            if current and geometry.estimate_text_width(candidate, font_size, weight=1.08) > available_width and len(lines) < max_lines - 1:
                lines.append(current.rstrip())
                current = cluster.lstrip()
            else:
                current = candidate
        if current:
            lines.append(current)
        return [fit_single_line_text(line, available_width, preferred=font_size, minimum=font_size)[0]
                for line in lines]
    if max_lines == 2 and len(words) > 1:
        candidates: List[Tuple[Tuple[float, float], List[str]]] = []
        for index in range(1, len(words)):
            candidate = [" ".join(words[:index]), " ".join(words[index:])]
            widths = [geometry.estimate_text_width(line, font_size) for line in candidate]
            overflow = sum(max(0.0, width - available_width) for width in widths)
            candidates.append(((overflow, abs(widths[0] - widths[1])), candidate))
        lines = min(candidates, key=lambda item: item[0])[1]
    else:
        lines = []
        current = ""
        for word in words:
            candidate = f"{current} {word}".strip()
            if current and geometry.estimate_text_width(candidate, font_size) > available_width:
                lines.append(current)
                current = word
            else:
                current = candidate
        if current:
            lines.append(current)
        if len(lines) > max_lines:
            lines = lines[: max_lines - 1] + [" ".join(lines[max_lines - 1 :])]

    fitted: List[str] = []
    for line in lines[:max_lines]:
        candidate = line
        while len(candidate) > 1 and geometry.estimate_text_width(candidate, font_size) > available_width:
            candidate = candidate[:-1].rstrip()
        if candidate != line:
            candidate = candidate.rstrip(" …") + "…"
            while len(candidate) > 1 and geometry.estimate_text_width(candidate, font_size) > available_width:
                candidate = candidate[:-2].rstrip() + "…"
        fitted.append(candidate)
    return fitted


def render_review_node(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 180))
    height = to_float(node.get("height", 84))
    fill = str(node.get("fill", style_value(style, "node_fill")))
    stroke = str(node.get("stroke", style_value(style, "node_stroke")))
    seed = node.get("_rough_seed", 0)
    element_id = node.get("id", "review-card")
    dx = deterministic_jitter(seed, element_id, 1)
    dy = deterministic_jitter(seed, element_id, 2)
    raw_c4_type = str(node.get("c4_type", node.get("type_label", "element")))
    c4_type_raw = raw_c4_type.upper().replace("_", " ")
    c4_type_text, c4_type_size = fit_single_line_text(
        c4_type_raw, width - 28, preferred=to_float(style_value(style, "type_label_size"), 10), minimum=7.5
    )
    c4_type = normalize_text(c4_type_text)
    external_dash = ' stroke-dasharray="6 4"' if raw_c4_type == "external_system" else ""
    title_raw = str(node.get("label", ""))
    title_text, title_size = fit_single_line_text(title_raw, width - 28, preferred=15, minimum=10.5)
    title = normalize_text(title_text)
    description_raw = str(node.get("description", node.get("sublabel", "")))
    technology_raw = str(node.get("technology", ""))
    technology_text, technology_size = fit_single_line_text(
        technology_raw, width - 24, preferred=9.5, minimum=7.5
    )
    technology = normalize_text(technology_text)
    description_size = 11.5
    description_lines = wrap_text_lines(description_raw, width - 28, font_size=description_size, max_lines=2)
    lines = [
        f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="7" fill="{fill}" stroke="{stroke}" '
        f'stroke-width="1.8"{external_dash}/>',
        f'  <path data-graph-role="decoration" d="M {x + 7 + dx} {y + 2 + dy} H {x + width - 7 + dx} '
        f'Q {x + width - 2 + dx} {y + 2 + dy} {x + width - 2 + dx} {y + 8 + dy} '
        f'V {y + height - 7 + dy}" fill="none" stroke="{stroke}" stroke-width="0.8" opacity="0.42"/>',
        f'  <text data-text-role="type" data-full-text="{normalize_attribute(c4_type_raw)}" '
        f'data-text-max-width="{width - 28}" x="{x + 14}" y="{y + 18}" class="node-type" '
        f'font-size="{c4_type_size}">{c4_type}</text>',
        f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" '
        f'data-text-max-width="{width - 28}" x="{x + 14}" y="{y + 41}" class="node-title" '
        f'font-size="{title_size}" text-anchor="start">{title}</text>',
    ]
    if description_lines:
        description_y = y + (56 if len(description_lines) > 1 else 60)
        for index, description_line in enumerate(description_lines):
            lines.append(
                f'  <text data-text-role="description" data-line="{index + 1}" '
                f'data-full-text="{normalize_attribute(description_raw)}" x="{x + 14}" '
                f'y="{description_y + index * 14}" class="node-sub" font-size="{description_size}" '
                f'text-anchor="start">{normalize_text(description_line)}</text>'
            )
    if technology:
        lines.append(
            f'  <text data-text-role="technology" data-full-text="{normalize_attribute(technology_raw)}" '
            f'data-text-max-width="{width - 24}" x="{x + width - 12}" y="{y + height - 9}" '
            f'text-anchor="end" font-size="{technology_size}" font-weight="700" '
            f'fill="{style_value(style, "type_label_fill")}">{technology}</text>'
        )
    return "\n".join(lines)


def render_cloud_glyph(glyph: str, cx: float, cy: float, color: str) -> List[str]:
    """Render manifest-backed neutral geometry without bundling vendor logos."""

    common = f'fill="none" stroke="{color}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"'
    if glyph == "globe":
        return [
            f'  <circle cx="{cx}" cy="{cy}" r="11" {common}/>',
            f'  <path d="M {cx - 11} {cy} H {cx + 11} M {cx} {cy - 11} C {cx - 6} {cy - 5} {cx - 6} {cy + 5} {cx} {cy + 11} M {cx} {cy - 11} C {cx + 6} {cy - 5} {cx + 6} {cy + 5} {cx} {cy + 11}" {common}/>',
        ]
    if glyph == "database":
        return [
            f'  <ellipse cx="{cx}" cy="{cy - 8}" rx="11" ry="4" {common}/>',
            f'  <path d="M {cx - 11} {cy - 8} V {cy + 8} C {cx - 11} {cy + 13} {cx + 11} {cy + 13} {cx + 11} {cy + 8} V {cy - 8}" {common}/>',
            f'  <path d="M {cx - 11} {cy} C {cx - 11} {cy + 5} {cx + 11} {cy + 5} {cx + 11} {cy}" {common}/>',
        ]
    if glyph == "gateway":
        return [
            f'  <path d="M {cx} {cy - 12} L {cx + 12} {cy} L {cx} {cy + 12} L {cx - 12} {cy} Z" {common}/>',
            f'  <path d="M {cx - 6} {cy} H {cx + 6} M {cx + 3} {cy - 3} L {cx + 6} {cy} L {cx + 3} {cy + 3}" {common}/>',
        ]
    if glyph == "stream":
        return [
            f'  <path d="M {cx - 12} {cy - 7} H {cx + 5} M {cx - 5} {cy} H {cx + 12} M {cx - 12} {cy + 7} H {cx + 5}" {common}/>',
            f'  <circle cx="{cx + 8}" cy="{cy - 7}" r="2.4" fill="{color}"/><circle cx="{cx - 8}" cy="{cy}" r="2.4" fill="{color}"/><circle cx="{cx + 8}" cy="{cy + 7}" r="2.4" fill="{color}"/>',
        ]
    if glyph == "observe":
        return [
            f'  <path d="M {cx - 13} {cy} Q {cx} {cy - 12} {cx + 13} {cy} Q {cx} {cy + 12} {cx - 13} {cy} Z" {common}/>',
            f'  <path d="M {cx - 6} {cy} H {cx - 2} L {cx + 1} {cy - 5} L {cx + 4} {cy + 5} L {cx + 7} {cy}" {common}/>',
        ]
    return [
        f'  <rect x="{cx - 11}" y="{cy - 9}" width="22" height="18" rx="4" {common}/>',
        f'  <path d="M {cx - 6} {cy - 3} H {cx + 6} M {cx - 6} {cy + 3} H {cx + 3}" {common}/>',
    ]


def render_cloud_node(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 160))
    height = to_float(node.get("height", 72))
    fill = str(node.get("fill", style_value(style, "node_fill")))
    stroke = str(node.get("stroke", style_value(style, "node_stroke")))
    icon_color = str(node.get("icon_color", "#2563eb"))
    glyph = str(node.get("glyph", "compute"))
    provider = normalize_text(str(node.get("provider", node.get("platform", "cloud"))).upper())
    title_raw = str(node.get("label", ""))
    subtitle_raw = str(node.get("sublabel", node.get("service", "")))
    available_text_width = max(28.0, width - 78)
    title_text, title_size = fit_single_line_text(title_raw, available_text_width, preferred=13.5, minimum=10.5)
    subtitle_text, subtitle_size = fit_single_line_text(subtitle_raw, available_text_width, preferred=11.5, minimum=9.5)
    title = normalize_text(title_text)
    subtitle = normalize_text(subtitle_text)
    icon_box_size = min(42.0, max(28.0, height - 16.0))
    icon_box_x = x + 12
    icon_box_y = y + (height - icon_box_size) / 2
    icon_center_x = icon_box_x + icon_box_size / 2
    icon_center_y = y + height / 2
    lines = [
        f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="12" fill="{fill}" stroke="{stroke}" stroke-width="1.4" filter="url(#shadowSoft)"/>',
        f'  <rect x="{icon_box_x}" y="{icon_box_y}" width="{icon_box_size}" height="{icon_box_size}" rx="11" fill="{icon_color}" opacity="0.12" stroke="{icon_color}" stroke-width="1.2"/>',
        f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" x="{x + 66}" y="{y + 31}" text-anchor="start" class="node-title" font-size="{title_size}">{title}</text>',
        f'  <text data-text-role="subtitle" data-full-text="{normalize_attribute(subtitle_raw)}" x="{x + 66}" y="{y + 50}" text-anchor="start" class="node-sub" font-size="{subtitle_size}">{subtitle}</text>',
        f'  <text x="{x + width - 10}" y="{y + 14}" text-anchor="end" font-size="8.5" font-weight="800" fill="{style_value(style, "type_label_fill")}">{provider}</text>',
    ]
    lines[2:2] = render_cloud_glyph(glyph, icon_center_x, icon_center_y, icon_color)
    return "\n".join(lines)


def render_transit_node(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 140))
    height = to_float(node.get("height", 72))
    role = str(node.get("transit_role", "station"))
    color = str(node.get("rail_color", node.get("stroke", style_value(style, "arrow_colors")["control"])))
    if role == "dlq":
        color = str(node.get("stroke", style_value(style, "arrow_colors")["feedback"]))
    fill = str(node.get("fill", style_value(style, "node_fill")))
    title_raw = str(node.get("label", ""))
    subtitle_raw = str(node.get("sublabel", node.get("operation", "")))
    text_width = max(36.0, width - 50)
    title_text, title_size = fit_single_line_text(title_raw, text_width, preferred=13.5, minimum=10.5)
    subtitle_text, subtitle_size = fit_single_line_text(subtitle_raw, text_width, preferred=11.5, minimum=9.2)
    title = normalize_text(title_text)
    subtitle = normalize_text(subtitle_text)
    badge = normalize_text(node.get("badge", node.get("partition_badge", "")))
    marker_x = x + 18
    dash = ' stroke-dasharray="5 3"' if role == "dlq" else ""
    lines = [
        f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{height / 2}" fill="{fill}" stroke="{color}" stroke-width="1.6"{dash}/>',
        f'  <circle cx="{marker_x}" cy="{y + height / 2}" r="8" fill="{style_value(style, "background")}" stroke="{color}" stroke-width="2.4"/>',
        f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" x="{x + 36}" y="{y + 38}" text-anchor="start" class="node-title" font-size="{title_size}">{title}</text>',
        f'  <text data-text-role="subtitle" data-full-text="{normalize_attribute(subtitle_raw)}" x="{x + 36}" y="{y + 58}" text-anchor="start" class="node-sub" font-size="{subtitle_size}">{subtitle}</text>',
    ]
    if role == "junction":
        lines.append(f'  <circle cx="{marker_x}" cy="{y + height / 2}" r="3" fill="{color}"/>')
    elif role == "dlq":
        lines.append(
            f'  <path data-graph-role="decoration" d="M {marker_x - 3} {y + height / 2 - 3} '
            f'L {marker_x + 3} {y + height / 2 + 3} M {marker_x + 3} {y + height / 2 - 3} '
            f'L {marker_x - 3} {y + height / 2 + 3}" stroke="{color}" stroke-width="1.7" stroke-linecap="round"/>'
        )
    elif role == "state_store":
        lines.append(
            f'  <rect data-graph-role="decoration" x="{marker_x - 3.5}" y="{y + height / 2 - 3.5}" '
            f'width="7" height="7" rx="1.2" fill="none" stroke="{color}" stroke-width="1.5"/>'
        )
    elif isinstance(node.get("station_order"), int):
        station_number = int(node["station_order"]) + 1
        lines.append(
            f'  <text data-graph-role="decoration" x="{marker_x}" y="{y + height / 2 + 2.5}" '
            f'text-anchor="middle" font-size="7" font-weight="800" fill="{color}">{station_number:02d}</text>'
        )
    if badge:
        badge_width = max(34.0, geometry.estimate_text_width(str(node.get("badge", node.get("partition_badge", ""))), 9) + 12)
        lines.extend(
            [
                f'  <rect x="{x + width - badge_width - 10}" y="{y + 6}" width="{badge_width}" height="15" rx="7.5" fill="{color}" opacity="0.13"/>',
                f'  <text x="{x + width - badge_width / 2 - 10}" y="{y + 16.5}" text-anchor="middle" font-size="8.2" font-weight="800" fill="{color}">{badge}</text>',
            ]
        )
    return "\n".join(lines)


def render_ops_service(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 180))
    height = to_float(node.get("height", 108))
    status = str(node.get("status", "ok"))
    status_colors = {"ok": "#22c55e", "warn": "#f59e0b", "critical": "#f43f5e", "unknown": "#64748b"}
    status_color = status_colors.get(status, status_colors["unknown"])
    title_raw = str(node.get("label", ""))
    status_raw = str(node.get("status_label", status.upper()))
    status_preferred = 8.5
    status_needed = geometry.estimate_text_width(status_raw, status_preferred, weight=1.08) + 4
    status_budget = min(width * 0.38, max(36.0, status_needed))
    title_budget = max(28.0, width - 46.0 - status_budget)
    title_text, title_size = fit_single_line_text(title_raw, title_budget, preferred=13.5, minimum=9.5)
    status_text, status_size = fit_single_line_text(status_raw, status_budget, preferred=status_preferred, minimum=6.8)
    title = normalize_text(title_text)
    status_label = normalize_text(status_text)
    lines = [
        f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="12" fill="{node.get("fill", style_value(style, "node_fill"))}" stroke="{node.get("stroke", style_value(style, "node_stroke"))}" stroke-width="1.4"/>',
        f'  <rect data-graph-role="decoration" x="{x}" y="{y + 12}" width="4" height="{height - 24}" rx="2" fill="{status_color}"/>',
        f'  <circle cx="{x + 16}" cy="{y + 19}" r="5" fill="{status_color}"/>',
        f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" '
        f'data-text-max-width="{title_budget}" x="{x + 28}" y="{y + 24}" text-anchor="start" '
        f'class="node-title" font-size="{title_size}">{title}</text>',
        f'  <text data-text-role="status" data-full-text="{normalize_attribute(status_raw)}" '
        f'data-text-max-width="{status_budget}" x="{x + width - 10}" y="{y + 21}" text-anchor="end" '
        f'font-size="{status_size}" font-weight="800" fill="{status_color}">{status_label}</text>',
    ]
    metrics = list(node.get("metric_badges", []))[:4]
    chip_gap = 6.0
    chip_width = (width - 24 - chip_gap) / 2
    chip_height = 27.0
    for index, metric in enumerate(metrics):
        column = index % 2
        row = index // 2
        chip_x = x + 10 + column * (chip_width + chip_gap)
        chip_y = y + 38 + row * (chip_height + 5)
        metric_status = status_colors.get(str(metric.get("status", "unknown")), status_colors["unknown"])
        metric_name = normalize_text(str(metric.get("name", ""))[:3].upper())
        metric_value_raw = f'{metric.get("value", "")}{metric.get("unit", "")}'
        metric_window_raw = f'@{metric.get("window", "")}'
        metric_value_budget = max(20.0, chip_width - 16.0)
        metric_window_budget = max(18.0, chip_width - 44.0)
        metric_value_text, metric_value_size = fit_single_line_text(
            metric_value_raw, metric_value_budget, preferred=9.5, minimum=7.0
        )
        metric_window_text, metric_window_size = fit_single_line_text(
            metric_window_raw, metric_window_budget, preferred=6.8, minimum=5.8
        )
        metric_value = normalize_text(metric_value_text)
        metric_window = normalize_text(metric_window_text)
        lines.extend(
            [
                f'  <rect x="{chip_x}" y="{chip_y}" width="{chip_width}" height="{chip_height}" rx="6" fill="#13263a" stroke="#29435d" stroke-width="0.8"/>',
                f'  <circle cx="{chip_x + 8}" cy="{chip_y + 9}" r="2.5" fill="{metric_status}"/>',
                f'  <text x="{chip_x + 14}" y="{chip_y + 11.5}" class="metric-label">{metric_name}</text>',
                f'  <text data-text-role="metric-window" data-full-text="{normalize_attribute(metric_window_raw)}" '
                f'data-text-max-width="{metric_window_budget}" x="{chip_x + chip_width - 6}" y="{chip_y + 11.5}" '
                f'text-anchor="end" font-size="{metric_window_size}" font-weight="700" '
                f'fill="{style_value(style, "text_muted")}">{metric_window}</text>',
                f'  <text data-text-role="metric-value" data-full-text="{normalize_attribute(metric_value_raw)}" '
                f'data-text-max-width="{metric_value_budget}" x="{chip_x + 8}" y="{chip_y + 23}" '
                f'class="metric-value" font-size="{metric_value_size}">{metric_value}</text>',
            ]
        )
    return "\n".join(lines)


def render_trace_span(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 300))
    height = to_float(node.get("height", 28))
    status = str(node.get("status", "ok"))
    color = {"ok": "#38bdf8", "warn": "#f59e0b", "critical": "#f43f5e"}.get(status, "#64748b")
    title_raw = str(node.get("label", node.get("span_id", "span")))
    duration_raw = f'{node.get("duration_ms", "")} ms'
    duration_needed = geometry.estimate_text_width(duration_raw, 10, weight=1.08) + 4
    duration_budget = min(width * 0.3, max(34.0, duration_needed))
    title_budget = max(30.0, width - 34.0 - duration_budget)
    title_text, title_size = fit_single_line_text(title_raw, title_budget, preferred=11.5, minimum=8.0)
    duration_text, duration_size = fit_single_line_text(duration_raw, duration_budget, preferred=10, minimum=7.0)
    title = normalize_text(title_text)
    duration = normalize_text(duration_text)
    return "\n".join(
        [
            f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="6" fill="{color}" fill-opacity="0.12" stroke="{color}" stroke-width="1.2"/>',
            f'  <rect x="{x}" y="{y}" width="5" height="{height}" rx="2.5" fill="{color}"/>',
            f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" '
            f'data-text-max-width="{title_budget}" x="{x + 14}" y="{y + 18.5}" text-anchor="start" '
            f'class="node-title" font-size="{title_size}">{title}</text>',
            f'  <text data-text-role="duration" data-full-text="{normalize_attribute(duration_raw)}" '
            f'data-text-max-width="{duration_budget}" x="{x + width - 10}" y="{y + 18.5}" text-anchor="end" '
            f'font-size="{duration_size}" font-weight="700" fill="{style_value(style, "text_secondary")}">{duration}</text>',
        ]
    )


def render_otel_collector(node: Dict[str, object], style: Dict[str, object]) -> str:
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 180))
    height = to_float(node.get("height", 60))
    title_raw = str(node.get("label", "OTel Collector"))
    title_budget = max(24.0, width - 24.0)
    title_text, title_size = fit_single_line_text(title_raw, title_budget, preferred=13, minimum=8.5)
    title = normalize_text(title_text)
    return "\n".join(
        [
            f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="10" fill="#10263a" stroke="#22d3ee" stroke-width="1.5"/>',
            f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_raw)}" '
            f'data-text-max-width="{title_budget}" x="{x + 12}" y="{y + 24}" text-anchor="start" '
            f'class="node-title" font-size="{title_size}">{title}</text>',
            f'  <text x="{x + 12}" y="{y + 44}" text-anchor="start" font-size="8.8" font-weight="700" fill="#67e8f9">RECEIVE → PROCESS → EXPORT</text>',
        ]
    )


def render_special_node(node: Dict[str, object], style: Dict[str, object], kind: str) -> Optional[str]:
    if kind == "review_card":
        return render_review_node(node, style)
    if kind == "cloud_service":
        return render_cloud_node(node, style)
    if kind in {"transit_station", "transit_junction", "transit_terminal"}:
        return render_transit_node(node, style)
    if kind == "ops_service":
        return render_ops_service(node, style)
    if kind == "trace_span":
        return render_trace_span(node, style)
    if kind == "otel_collector":
        return render_otel_collector(node, style)
    return None


def render_rect_node(node: Dict[str, object], style: Dict[str, object], kind: str) -> str:
    special = render_special_node(node, style, kind)
    if special is not None:
        return special
    x = to_float(node["x"])
    y = to_float(node["y"])
    width = to_float(node.get("width", 180))
    height = to_float(node.get("height", 76))
    rx = to_float(node.get("rx", style_value(style, "node_radius")))
    fill = str(node.get("fill", style_value(style, "node_fill")))
    stroke = str(node.get("stroke", style_value(style, "node_stroke")))
    stroke_width = to_float(node.get("stroke_width", 2.0 if kind != "rect" else 1.8))
    filter_attr = ""
    node_shadow = node.get("filter")
    if node_shadow:
        filter_attr = f' filter="url(#{node_shadow})"'
    elif node.get("glow"):
        glow_name = str(node.get("glow"))
        glow_map = {
            "blue": "glowBlue",
            "purple": "glowPurple",
            "green": "glowGreen",
            "orange": "glowOrange",
        }
        if glow_name in glow_map:
            filter_attr = f' filter="url(#{glow_map[glow_name]})"'
    elif style_value(style, "node_shadow"):
        if not node.get("flat", False):
            filter_attr = f' filter="{style_value(style, "node_shadow")}"'
    title_text = str(node.get("label", ""))
    title = normalize_text(title_text)
    subtitle = normalize_text(node.get("sublabel", ""))
    type_label = normalize_text(node.get("type_label", ""))
    accent_fill = node.get("accent_fill")
    lines = []

    if kind == "double_rect":
        lines.append(
            f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>'
        )
        lines.append(
            f'  <rect x="{x + 6}" y="{y + 6}" width="{width - 12}" height="{height - 12}" rx="{max(rx - 3, 4)}" fill="none" stroke="{stroke}" stroke-width="1.2" opacity="0.65"/>'
        )
    elif kind == "terminal":
        lines.append(
            f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>'
        )
        lines.append(
            f'  <rect x="{x}" y="{y}" width="{width}" height="18" rx="{rx}" fill="{node.get("header_fill", "#1f2937")}" opacity="0.95"/>'
        )
        header_colors = node.get("header_dots", ["#ef4444", "#f59e0b", "#10b981"])
        for idx, color in enumerate(header_colors):
            lines.append(f'  <circle cx="{x + 16 + idx * 14}" cy="{y + 9}" r="4" fill="{color}"/>')
        lines.append(
            f'  <text x="{x + 18}" y="{y + 44}" font-size="28" font-weight="700" fill="{node.get("prompt_fill", "#10b981")}">$</text>'
        )
        lines.append(
            f'  <text x="{x + 38}" y="{y + 44}" font-size="22" font-weight="500" fill="{style_value(style, "text_secondary")}">_</text>'
        )
    elif kind == "document":
        fold = min(18, width * 0.18, height * 0.22)
        path = (
            f"M {x} {y} L {x + width - fold} {y} L {x + width} {y + fold} "
            f"L {x + width} {y + height} L {x} {y + height} Z"
        )
        lines.append(
            f'  <path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>'
        )
        lines.append(
            f'  <path d="M {x + width - fold} {y} L {x + width - fold} {y + fold} L {x + width} {y + fold}" fill="none" stroke="{stroke}" stroke-width="{stroke_width}"/>'
        )
        for idx in range(4):
            line_y = y + 26 + idx * 14
            lines.append(
                f'  <line x1="{x + 18}" y1="{line_y}" x2="{x + width - 28}" y2="{line_y}" stroke="{node.get("line_stroke", "#c4b5fd")}" stroke-width="1.2"/>'
            )
    elif kind == "folder":
        tab_w = min(54, width * 0.34)
        tab_h = 18
        path = (
            f"M {x} {y + tab_h} L {x + tab_w * 0.4} {y + tab_h} L {x + tab_w * 0.58} {y} "
            f"L {x + tab_w} {y} L {x + width} {y} L {x + width} {y + height} L {x} {y + height} Z"
        )
        lines.append(
            f'  <path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>'
        )
        for idx in range(3):
            line_y = y + 42 + idx * 14
            lines.append(
                f'  <line x1="{x + 22}" y1="{line_y}" x2="{x + width - 22}" y2="{line_y}" stroke="{node.get("line_stroke", stroke)}" stroke-opacity="0.35" stroke-width="1.2"/>'
            )
    elif kind == "hexagon":
        inset = 22
        path = (
            f"M {x + inset} {y} L {x + width - inset} {y} L {x + width} {y + height / 2} "
            f"L {x + width - inset} {y + height} L {x + inset} {y + height} L {x} {y + height / 2} Z"
        )
        lines.append(f'  <path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>')
    elif kind == "speech":
        tail = 18
        path = (
            f"M {x + rx} {y} L {x + width - rx} {y} Q {x + width} {y} {x + width} {y + rx} "
            f"L {x + width} {y + height - rx} Q {x + width} {y + height} {x + width - rx} {y + height} "
            f"L {x + 26} {y + height} L {x + 12} {y + height + tail} L {x + 16} {y + height} "
            f"L {x + rx} {y + height} Q {x} {y + height} {x} {y + height - rx} "
            f"L {x} {y + rx} Q {x} {y} {x + rx} {y} Z"
        )
        lines.append(f'  <path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>')
    else:
        lines.append(
            f'  <rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"{filter_attr}/>'
        )

    if accent_fill and kind == "icon_box":
        lines.append(
            f'  <rect x="{x + 12}" y="{y + 12}" width="{width - 24}" height="{height - 24}" rx="{max(rx - 4, 4)}" fill="{accent_fill}" opacity="0.9"/>'
        )

    if kind == "user_avatar":
        circle_fill = node.get("icon_fill", "#dbeafe")
        icon_stroke = node.get("icon_stroke", stroke)
        cx = x + 26
        cy = y + height / 2
        lines.append(f'  <circle cx="{cx}" cy="{cy}" r="18" fill="{circle_fill}" stroke="{icon_stroke}" stroke-width="1.6"/>')
        lines.append(f'  <circle cx="{cx}" cy="{cy - 6}" r="5" fill="{icon_stroke}"/>')
        lines.append(f'  <path d="M {cx - 10} {cy + 11} Q {cx} {cy + 2} {cx + 10} {cy + 11}" fill="none" stroke="{icon_stroke}" stroke-width="2"/>')

    if kind == "bot":
        cx = x + width / 2
        cy = y + height / 2 + 2
        body_fill = node.get("body_fill", "#1e293b")
        accent = node.get("accent_fill", "#34d399")
        lines.append(f'  <rect x="{cx - 42}" y="{cy - 32}" width="84" height="84" rx="18" fill="{body_fill}" stroke="#334155" stroke-width="1.8"{filter_attr}/>')
        lines.append(f'  <rect x="{cx - 26}" y="{cy - 16}" width="52" height="22" rx="6" fill="#0f172a" stroke="#475569" stroke-width="1.2"/>')
        lines.append(f'  <circle cx="{cx - 12}" cy="{cy - 5}" r="5" fill="{accent}"/>')
        lines.append(f'  <circle cx="{cx + 12}" cy="{cy - 5}" r="5" fill="{accent}"/>')
        lines.append(f'  <rect x="{cx - 14}" y="{cy + 14}" width="28" height="6" rx="3" fill="#334155"/>')
        lines.append(f'  <line x1="{cx}" y1="{cy - 36}" x2="{cx}" y2="{cy - 50}" stroke="{accent}" stroke-width="3"/>')
        lines.append(f'  <circle cx="{cx}" cy="{cy - 54}" r="5" fill="{accent}"/>')

    if kind == "circle_cluster":
        r = min(width, height) / 4.0
        centers = [(x + width * 0.36, y + height * 0.56), (x + width * 0.58, y + height * 0.45), (x + width * 0.74, y + height * 0.58)]
        for cx, cy in centers:
            lines.append(f'  <circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"/>')

    type_offset = y + 18 if kind not in {"terminal", "bot"} else y + 18
    title_y = y + height / 2 - (4 if type_label and kind not in {"terminal", "bot"} else 0)
    if kind in {"document", "folder"}:
        title_y = y + height + 26
    elif kind == "circle_cluster":
        title_y = y + height / 2 + 8
    elif kind == "bot":
        title_y = y + height + 22
    elif kind == "user_avatar":
        title_y = y + height / 2 + 6

    if type_label:
        lines.append(f'  <text x="{x + (54 if kind == "user_avatar" else width / 2)}" y="{type_offset}" text-anchor="middle" class="node-type">{type_label}</text>')
        title_y += 10 if kind not in {"document", "folder", "circle_cluster", "bot"} else 0

    title_x = x + width / 2
    text_anchor = "middle"
    if kind == "user_avatar":
        title_x = x + 64
        text_anchor = "start"
    if kind == "terminal":
        title_y = y + height - 14
    if kind == "bot":
        title_x = x + width / 2
        text_anchor = "middle"
    title_budget = width - (76 if kind == "user_avatar" else 52 if kind == "hexagon" else 32 if kind == "double_rect" else 24)
    fitted_title, title_size = fit_single_line_text(
        title_text, title_budget, preferred=to_float(node.get("title_size"), 18), minimum=12,
    )
    lines.append(
        f'  <text data-text-role="title" data-full-text="{normalize_attribute(title_text)}" '
        f'data-text-max-width="{title_budget}" x="{title_x}" y="{title_y}" text-anchor="{text_anchor}" class="node-title" '
        f'font-size="{title_size}">{normalize_text(fitted_title)}</text>'
    )

    if subtitle:
        sub_y = title_y + 22
        if kind == "document":
            sub_y = y + height + 44
            title_y = y + height + 24
        if kind == "folder":
            sub_y = y + height + 44
        if kind == "circle_cluster":
            sub_y = y + height / 2 + 28
        if kind == "bot":
            sub_y = y + height + 42
        if kind == "terminal":
            sub_y = y + height + 20
        if kind == "user_avatar":
            sub_y = title_y + 22
        subtitle_raw = str(node.get("sublabel", ""))
        subtitle_visible, subtitle_size = fit_single_line_text(subtitle_raw, title_budget, preferred=12, minimum=10.5)
        lines.append(f'  <text data-text-role="subtitle" data-full-text="{normalize_attribute(subtitle_raw)}" '
                     f'data-text-max-width="{title_budget}" x="{title_x}" y="{sub_y}" text-anchor="{text_anchor}" '
                     f'class="node-sub" font-size="{subtitle_size}">{normalize_text(subtitle_visible)}</text>')

    tag_lines = []
    if node.get("tags"):
        tag_x = x + 18
        tag_y = y + height - 20
        if kind in {"document", "folder", "circle_cluster", "bot", "terminal"}:
            tag_y = y + height + 52
        tag_lines = render_tags(node, tag_x, tag_y, style)
    lines.extend(tag_lines)

    return "\n".join(lines)


def render_node(node: Dict[str, object], style: Dict[str, object]) -> str:
    kind = str(node.get("kind", node.get("shape", "rect")))
    if kind == "cylinder":
        x = to_float(node["x"])
        y = to_float(node["y"])
        width = to_float(node.get("width", 160))
        height = to_float(node.get("height", 120))
        rx = width / 2
        ry = min(18, height / 8)
        fill = str(node.get("fill", "#ecfdf5"))
        stroke = str(node.get("stroke", "#10b981"))
        stroke_width = to_float(node.get("stroke_width", 2.2))
        label_text = str(node.get("label", ""))
        label_visible, label_size = fit_single_line_text(label_text, width - 24, preferred=to_float(node.get("title_size"), 18), minimum=12)
        label = normalize_text(label_visible)
        subtitle_raw = str(node.get("sublabel", ""))
        subtitle_visible, subtitle_size = fit_single_line_text(subtitle_raw, width - 24, preferred=12, minimum=10.5)
        subtitle = normalize_text(subtitle_visible)
        lines = [
            f'  <ellipse cx="{x + width / 2}" cy="{y + ry}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"/>',
            f'  <rect x="{x}" y="{y + ry}" width="{width}" height="{height - 2 * ry}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"/>',
            f'  <ellipse cx="{x + width / 2}" cy="{y + height - ry}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}"/>',
            f'  <ellipse cx="{x + width / 2}" cy="{y + height * 0.38}" rx="{rx}" ry="{ry}" fill="none" stroke="{stroke}" stroke-opacity="0.45" stroke-width="1.2"/>',
            f'  <ellipse cx="{x + width / 2}" cy="{y + height * 0.6}" rx="{rx}" ry="{ry}" fill="none" stroke="{stroke}" stroke-opacity="0.25" stroke-width="1.2"/>',
            f'  <text data-text-role="title" data-full-text="{normalize_attribute(label_text)}" data-text-max-width="{width - 24}" '
            f'x="{x + width / 2}" y="{y + height / 2 - 6}" text-anchor="middle" class="node-title" '
            f'font-size="{label_size}">{label}</text>',
        ]
        if subtitle:
            lines.append(f'  <text data-text-role="subtitle" data-full-text="{normalize_attribute(subtitle_raw)}" data-text-max-width="{width - 24}" '
                         f'x="{x + width / 2}" y="{y + height / 2 + 18}" text-anchor="middle" class="node-sub" font-size="{subtitle_size}">{subtitle}</text>')
        return "\n".join(lines)
    return render_rect_node(node, style, kind)


def inferred_port(node: Node, toward: Point) -> str:
    left, top, right, bottom = node.bounds
    dx = toward[0] - node.cx
    dy = toward[1] - node.cy
    width = right - left
    height = bottom - top
    if abs(dx) * height >= abs(dy) * width:
        return "right" if dx >= 0 else "left"
    return "bottom" if dy >= 0 else "top"


def prepare_arrows(arrows: Sequence[Dict[str, object]], node_map: Dict[str, Node]) -> List[Dict[str, object]]:
    prepared = [copy.deepcopy(arrow) for arrow in arrows]
    endpoint_groups: Dict[Tuple[str, str], List[Tuple[int, str, str]]] = {}

    for index, arrow in enumerate(prepared):
        edge_id = str(arrow.get("id") or f"edge-{index:03d}")
        arrow["_edge_id"] = edge_id
        arrow["_edge_dom_id"] = str(arrow.get("_dom_id") or safe_identifier(edge_id, f"edge-{index:03d}"))
        source = node_map.get(str(arrow.get("source"))) if arrow.get("source") else None
        target = node_map.get(str(arrow.get("target"))) if arrow.get("target") else None
        start_hint = (to_float(arrow.get("x1")), to_float(arrow.get("y1")))
        end_hint = (to_float(arrow.get("x2")), to_float(arrow.get("y2")))

        if source is not None:
            toward = end_hint if target is None else (target.cx, target.cy)
            source_port = str(arrow.get("source_port") or inferred_port(source, toward)).lower()
            arrow["_resolved_source_port"] = source_port
            endpoint_groups.setdefault((source.node_id, source_port), []).append((index, "source", edge_id))
        if target is not None:
            toward = start_hint if source is None else (source.cx, source.cy)
            target_port = str(arrow.get("target_port") or inferred_port(target, toward)).lower()
            arrow["_resolved_target_port"] = target_port
            endpoint_groups.setdefault((target.node_id, target_port), []).append((index, "target", edge_id))

    for (node_id, port), endpoints in sorted(endpoint_groups.items()):
        node = node_map[node_id]
        span = (node.bounds[3] - node.bounds[1]) if port in {"left", "right"} else (node.bounds[2] - node.bounds[0])
        ordered = sorted(endpoints, key=lambda item: item[2])
        count = len(ordered)
        usable_span = max(0.0, span - 24.0)
        if count > 1 and usable_span / (count - 1) < 6.0:
            raise ValueError(f"PORT_CAPACITY: {node_id}.{port} cannot fit {count} distinct endpoints")
        spacing = 0.0 if count <= 1 else min(18.0, usable_span / (count - 1))
        for position, (arrow_index, endpoint, _) in enumerate(ordered):
            offset = (position - (count - 1) / 2.0) * spacing
            prepared[arrow_index][f"_{endpoint}_port_offset"] = round(offset, 2)
    return prepared


def render_arrow(
    arrow: Dict[str, object],
    style: Dict[str, object],
    node_map: Dict[str, Node],
    route_obstacles: Sequence[Bounds],
    label_obstacles: Sequence[Bounds],
    *,
    existing_routes: Sequence[Sequence[Point]],
    canvas_bounds: Bounds,
) -> ArrowRender:
    edge_id = str(arrow.get("_edge_id") or "edge")
    edge_dom_id = str(arrow.get("_edge_dom_id") or safe_identifier(edge_id, "edge"))
    start_hint = (to_float(arrow.get("x1")), to_float(arrow.get("y1")))
    end_hint = (to_float(arrow.get("x2")), to_float(arrow.get("y2")))
    source_node = node_map.get(str(arrow.get("source"))) if arrow.get("source") else None
    target_node = node_map.get(str(arrow.get("target"))) if arrow.get("target") else None
    source_port = arrow.get("_resolved_source_port") or arrow.get("source_port")
    target_port = arrow.get("_resolved_target_port") or arrow.get("target_port")

    if source_node is not None:
        toward = end_hint if target_node is None else (target_node.cx, target_node.cy)
        start = anchor_point(
            source_node,
            toward,
            str(source_port) if source_port else None,
            to_float(arrow.get("_source_port_offset")),
        )
    else:
        start = start_hint

    if target_node is not None:
        toward = start_hint if source_node is None else (source_node.cx, source_node.cy)
        end = anchor_point(
            target_node,
            toward,
            str(target_port) if target_port else None,
            to_float(arrow.get("_target_port_offset")),
        )
    else:
        end = end_hint

    # Keep source and target bounds in the graph. Port endpoints lie on their
    # boundaries, so valid leads remain possible while routes cannot cut
    # through either node and re-enter from the wrong side.
    obstacles = list(route_obstacles)

    routing_data = dict(arrow)
    if source_port:
        routing_data["source_port"] = source_port
    if target_port:
        routing_data["target_port"] = target_port
    route = build_orthogonal_route(
        start,
        end,
        obstacles,
        routing_data,
        canvas_bounds=canvas_bounds,
        existing_routes=existing_routes,
    )
    interactions = geometry.route_interactions(route, existing_routes)
    if interactions.overlap_count:
        raise ValueError(f"edge {edge_id} has an unresolved collinear overlap")
    bridges = list(interactions.crossings)
    bends = geometry.bend_count(route)
    stretch = quality.route_stretch(route)
    path_d = geometry.path_with_bridges(route, bridges)
    color = color_for_flow(style, arrow)
    width = to_float(arrow.get("stroke_width", style_value(style, "arrow_width")))
    dash = arrow.get("stroke_dasharray")
    if dash is None and arrow.get("dashed"):
        dash = "6,4"
    marker = marker_for_color(style, color, arrow)
    source_id = normalize_attribute(arrow.get("source", ""))
    target_id = normalize_attribute(arrow.get("target", ""))
    bridge_attr = ";".join(f"{geometry.format_number(x)},{geometry.format_number(y)}" for x, y in bridges)
    edge_kind = str(arrow.get("edge_kind", arrow.get("transit_type", "flow")))
    topic_id = str(arrow.get("topic_id", ""))
    protocol = str(arrow.get("protocol", ""))
    via = str(arrow.get("via", ""))
    critical_path_id = str(arrow.get("critical_path_id", ""))
    critical = "true" if arrow.get("critical") else "false"
    flow = str(arrow.get("flow", ""))
    motion_role = str(arrow.get("motion_role", ""))
    motion_stage = str(arrow.get("motion_stage", ""))
    motion_order = str(arrow.get("motion_order", ""))
    critical_hop = str(arrow.get("critical_hop", ""))
    critical_hops = str(arrow.get("critical_hops", ""))
    shared_attributes = (
        f'data-edge-id="{normalize_attribute(edge_id)}" data-source="{source_id}" data-target="{target_id}" '
        f'data-edge-kind="{normalize_attribute(edge_kind)}" data-topic-id="{normalize_attribute(topic_id)}" '
        f'data-flow="{normalize_attribute(flow)}" '
        f'data-motion-role="{normalize_attribute(motion_role)}" '
        f'data-motion-stage="{normalize_attribute(motion_stage)}" '
        f'data-motion-order="{normalize_attribute(motion_order)}" '
        f'data-protocol="{normalize_attribute(protocol)}" data-via="{normalize_attribute(via)}" '
        f'data-critical-path-id="{normalize_attribute(critical_path_id)}" '
        f'data-critical-hop="{normalize_attribute(critical_hop)}" '
        f'data-critical-hops="{normalize_attribute(critical_hops)}" '
        f'data-critical="{critical}" data-bends="{bends}" data-route-stretch="{round(stretch, 3)}"'
    )
    rendered_paths: List[str] = []
    if bridges:
        background = str(style_value(style, "background"))
        rendered_paths.append(
            f'  <path id="{normalize_attribute(edge_dom_id)}-bridge-mask" data-graph-role="bridge-mask" '
            f'data-owner="{normalize_attribute(edge_id)}" d="{path_d}" fill="none" stroke="{background}" '
            f'stroke-width="{round(width + 4.5, 2)}" stroke-linecap="round" stroke-linejoin="round"/>'
        )
    style_index = int(style.get("_style_index", 0))
    if style_index == 9:
        # A second, deliberately imperfect pencil stroke is decorative only;
        # the routable edge remains the single semantic connector below.
        rough_offset = deterministic_jitter(arrow.get("_rough_seed", 0), edge_id, 7, amplitude=1.2)
        rendered_paths.append(
            f'  <path id="{normalize_attribute(edge_dom_id)}-review-stroke" data-graph-role="decoration" '
            f'data-owner="{normalize_attribute(edge_id)}" d="{path_d}" fill="none" stroke="{color}" '
            f'stroke-width="0.9" stroke-dasharray="2.5,2" opacity="0.30" '
            f'stroke-dashoffset="{round(rough_offset, 2)}"/>'
        )
    elif style_index == 11 and str(arrow.get("transit_type", "")) == "rail":
        rendered_paths.append(
            f'  <path id="{normalize_attribute(edge_dom_id)}-rail-casing" data-graph-role="decoration" '
            f'data-owner="{normalize_attribute(edge_id)}" d="{path_d}" fill="none" '
            f'stroke="{style_value(style, "rail_casing")}" stroke-width="{round(width + 3.2, 2)}" '
            f'stroke-linecap="round" stroke-linejoin="round" opacity="0.28"/>'
        )
    elif style_index == 12 and arrow.get("critical"):
        rendered_paths.append(
            f'  <path id="{normalize_attribute(edge_dom_id)}-critical-glow" data-graph-role="decoration" '
            f'data-owner="{normalize_attribute(edge_id)}" d="{path_d}" fill="none" stroke="{color}" '
            f'stroke-width="{round(width + 5, 2)}" stroke-linecap="round" stroke-linejoin="round" '
            f'opacity="0.22" filter="url(#pulseGlow)"/>'
        )
    path = (
        f'  <path id="{normalize_attribute(edge_dom_id)}" data-graph-role="edge" {shared_attributes} '
        f'data-bridges="{bridge_attr}" d="{path_d}" fill="none" stroke="{color}" '
        f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" marker-end="{marker}"'
    )
    if dash:
        path += f' stroke-dasharray="{dash}"'
    if arrow.get("opacity") is not None:
        path += f' opacity="{arrow["opacity"]}"'
    path += "/>"
    rendered_paths.append(path)
    if style_index == 11 and str(arrow.get("transit_type", "")) == "rail" and len(route) >= 2:
        direction_x = (route[0][0] + route[-1][0]) / 2
        direction_y = (route[0][1] + route[-1][1]) / 2
        rendered_paths.append(
            f'  <path id="{normalize_attribute(edge_dom_id)}-direction" data-graph-role="decoration" '
            f'data-owner="{normalize_attribute(edge_id)}" d="M {direction_x - 3.5} {direction_y - 3.5} '
            f'L {direction_x + 1.5} {direction_y} L {direction_x - 3.5} {direction_y + 3.5}" '
            f'fill="none" stroke="{style_value(style, "background")}" stroke-width="1.4" '
            f'stroke-linecap="round" stroke-linejoin="round"/>'
        )
    if style_index == 12 and arrow.get("critical") and len(route) >= 2:
        hop_x = (route[0][0] + route[-1][0]) / 2
        hop_y = (route[0][1] + route[-1][1]) / 2
        hop = int(arrow.get("critical_hop", 1))
        total_hops = int(arrow.get("critical_hops", 1))
        rendered_paths.extend(
            [
                f'  <circle id="{normalize_attribute(edge_dom_id)}-hop" data-graph-role="decoration" '
                f'data-owner="{normalize_attribute(edge_id)}" cx="{hop_x}" cy="{hop_y}" r="9" '
                f'fill="{style_value(style, "background")}" stroke="{color}" stroke-width="1.2"/>',
                f'  <text data-graph-role="decoration" data-owner="{normalize_attribute(edge_id)}" '
                f'x="{hop_x}" y="{hop_y + 2.7}" text-anchor="middle" font-size="7" font-weight="800" '
                f'fill="{color}">{hop}/{total_hops}</text>',
            ]
        )
    label_svg = ""
    label_bounds = None

    label = str(arrow.get("label", "")).strip()
    secondary_label = protocol.strip() if style_index == 9 else ""
    if style_index == 10 and not label and via.strip():
        label = via.strip()
    if label:
        label_proxy = label
        if secondary_label and geometry.estimate_text_width(secondary_label, 12) > geometry.estimate_text_width(label, 12):
            label_proxy = secondary_label
        label_x, label_y = choose_label_position_avoiding(
            route,
            label_proxy,
            label_obstacles,
            routes=existing_routes,
            canvas_bounds=canvas_bounds,
            dx=to_float(arrow.get("label_dx", 0)),
            dy=to_float(arrow.get("label_dy", -4)),
        )
        if secondary_label:
            label_content = render_dual_label_badge(label_x, label_y, label, secondary_label, style)
            label_bounds = estimate_dual_label_bounds(label_x, label_y, label, secondary_label)
        else:
            label_content = render_label_badge(label_x, label_y, label, style, label_style=str(arrow.get("label_style", "badge")))
            label_bounds = estimate_label_bounds(label_x, label_y, label)
        label_svg = (
            f'  <g id="{normalize_attribute(edge_dom_id)}-label" data-graph-role="label" '
            f'data-owner="{normalize_attribute(edge_id)}" data-graph-bounds="'
            f'{geometry.format_number(label_bounds[0])},{geometry.format_number(label_bounds[1])},'
            f'{geometry.format_number(label_bounds[2])},{geometry.format_number(label_bounds[3])}">\n'
            f'{label_content}\n  </g>'
        )

    report: Dict[str, object] = {
        "id": edge_id,
        "source": str(arrow.get("source", "")),
        "target": str(arrow.get("target", "")),
        "source_port": [round(start[0], 2), round(start[1], 2)],
        "target_port": [round(end[0], 2), round(end[1], 2)],
        "waypoints": [[to_float(point[0]), to_float(point[1])] for point in (arrow.get("route_points") or [])],
        "route": [[round(x, 2), round(y, 2)] for x, y in route],
        "length": round(geometry.route_length(route), 2),
        "bends": bends,
        "route_stretch": round(stretch, 3),
        "crossings": [[round(x, 2), round(y, 2)] for x, y in interactions.crossings],
        "bridges": [[round(x, 2), round(y, 2)] for x, y in bridges],
    }
    return ArrowRender(edge_id, "\n".join(rendered_paths), label_svg, label_bounds, route, report)


def render_legend(
    legend: Sequence[Dict[str, object]],
    style: Dict[str, object],
    width: float,
    height: float,
    data: Dict[str, object],
) -> str:
    layout = legend_layout(data, legend, width, height)
    if not layout:
        return ""
    legend_x, legend_y, bounds = layout
    lines = [
        '  <g id="legend" data-graph-role="legend">',
        f'    <rect id="legend-zone" data-graph-role="reserved" data-reserved-kind="legend" '
        f'x="{geometry.format_number(bounds[0])}" y="{geometry.format_number(bounds[1])}" '
        f'width="{geometry.format_number(bounds[2] - bounds[0])}" height="{geometry.format_number(bounds[3] - bounds[1])}" '
        f'rx="10" fill="none" stroke="none"/>',
    ]
    orientation = str(data.get("legend_orientation", "vertical")).strip().lower()
    cursor_x = legend_x
    for idx, item in enumerate(legend):
        y = legend_y if orientation == "horizontal" else legend_y + idx * 22
        color = item.get("color")
        if not color:
            color = style_value(style, "arrow_colors")[FLOW_ALIASES.get(str(item.get("flow", "control")).lower(), "control")]
        marker = marker_for_color(style, str(color), {"flow": item.get("flow", "control")})
        item_x = cursor_x if orientation == "horizontal" else legend_x
        lines.append(f'    <line data-graph-role="decoration" x1="{item_x}" y1="{y}" x2="{item_x + 30}" y2="{y}" stroke="{color}" stroke-width="{style_value(style, "arrow_width")}" marker-end="{marker}"/>')
        lines.append(f'    <text data-graph-role="decoration" x="{item_x + 40}" y="{y + 4}" class="legend">{normalize_text(item.get("label", ""))}</text>')
        if orientation == "horizontal":
            cursor_x += 40 + geometry.estimate_text_width(str(item.get("label", "")), 12) + 28
    if data.get("legend_box"):
        bg = data.get("legend_box_fill", style_value(style, "arrow_label_bg"))
        opacity = data.get("legend_box_opacity", 0.88)
        lines.insert(
            2,
            f'    <rect data-graph-role="decoration" x="{geometry.format_number(bounds[0])}" '
            f'y="{geometry.format_number(bounds[1])}" width="{geometry.format_number(bounds[2] - bounds[0])}" '
            f'height="{geometry.format_number(bounds[3] - bounds[1])}" rx="10" fill="{bg}" opacity="{opacity}"/>',
        )
    lines.append("  </g>")
    return "\n".join(lines)


def render_footer(data: Dict[str, object], style: Dict[str, object], width: float, height: float) -> str:
    layout = footer_layout(data, width, height)
    if not layout:
        return ""
    x, y, _ = layout
    text = str(data.get("footer", "")).strip()
    return f'  <text x="{x}" y="{y}" class="footnote">{normalize_text(text)}</text>'


def bounds_metadata(bounds: Bounds) -> str:
    return ",".join(geometry.format_number(value) for value in bounds)


def build_svg_with_report(template_type: str, data: Dict[str, object]) -> Tuple[str, Dict[str, object]]:
    diagram = normalize_diagram(data, template_type)
    source_data = diagram.as_dict()
    mode = diagram.mode

    # ``normalize_diagram`` resolves both the legacy ``style`` selector and
    # the v1 ``visual_theme`` selector.  Reuse that single decision here so a
    # conflicting or misspelled selector can never silently fall back to a
    # different renderer.
    style_index, style = parse_style(diagram.style_index)
    style["_style_index"] = style_index
    composition_contract = quality.resolve_contract(
        source_data.get("composition", source_data.get("quality_profile", "standard"))
    )
    if source_data.get("style_overrides"):
        style.update(source_data["style_overrides"])
    width, height = parse_template_viewbox(template_type)
    width = to_float(source_data.get("width", width))
    height = to_float(source_data.get("height", height))
    if source_data.get("viewBox"):
        _, _, width, height = parse_viewbox(source_data["viewBox"])
    if not math.isfinite(width) or not math.isfinite(height) or width <= 0 or height <= 0:
        raise ValueError("canvas width and height must be finite positive numbers")

    containers = list(source_data.get("containers", []))
    nodes_data = list(source_data.get("nodes", []))
    arrows_data = list(source_data.get("arrows", []))
    legend = list(source_data.get("legend", []))

    if style_index == 9:
        rough_seed = source_data.get("rough_seed", 0)
        for node_data in nodes_data:
            node_data.setdefault("_rough_seed", rough_seed)
        for container in containers:
            container.setdefault("_rough_seed", rough_seed)
        for arrow_data in arrows_data:
            arrow_data.setdefault("_rough_seed", rough_seed)

    defs = render_defs(style_index, style)
    canvas = render_canvas(style_index, style, width, height)
    title_block, content_start_y = render_title_block(style, source_data, width)
    window_controls = render_window_controls(source_data, style_index, width)
    header_meta = render_header_meta(source_data, style, width)
    style_signature = render_style_signature(style_index, source_data, width)

    # Assign auto_place y before building node maps so arrows route correctly
    for node_data in nodes_data:
        if "y" not in node_data and node_data.get("auto_place"):
            node_data["y"] = content_start_y + to_float(node_data.get("offset_y", 0))

    normalized_nodes = [normalize_node(node, f"node-{idx}") for idx, node in enumerate(nodes_data)]
    if len({node.node_id for node in normalized_nodes}) != len(normalized_nodes):
        raise ValueError("node ids must be unique")
    node_map = {node.node_id: node for node in normalized_nodes}

    # Raw semantic IDs stay intact in data attributes and reports. SVG DOM IDs
    # are allocated separately so normalization collisions (for example
    # ``a b`` vs ``a-b`` or multiple CJK-only IDs) cannot create duplicate IDs.
    used_dom_ids = set(_RESERVED_DOM_IDS)
    for index, container in enumerate(containers):
        raw_id = str(container.get("id") or f"container-{index:03d}")
        container["_dom_id"] = allocate_dom_identifier(
            safe_identifier(raw_id, f"container-{index:03d}"), used_dom_ids, ("-header",)
        )
    for index, arrow in enumerate(arrows_data):
        raw_id = str(arrow.get("id") or f"edge-{index:03d}")
        arrow["_dom_id"] = allocate_dom_identifier(
            safe_identifier(raw_id, f"edge-{index:03d}"), used_dom_ids, _EDGE_DOM_SUFFIXES
        )
    for node, node_data in zip(normalized_nodes, nodes_data):
        node_data["_dom_id"] = allocate_dom_identifier(
            f"node-{safe_identifier(node.node_id, 'node')}", used_dom_ids
        )

    section_obstacles = [bounds for container in containers if (bounds := container_header_bounds(container, style)) is not None]
    footer_reserved = footer_layout(source_data, width, height)
    blueprint_block_svg, blueprint_block_bounds = render_blueprint_title_block(source_data, style, style_index, width, height)
    node_obstacles = [node.bounds for node in normalized_nodes]
    placement_obstacles = list(node_obstacles) + list(section_obstacles)
    if footer_reserved:
        placement_obstacles.append(footer_reserved[2])
    if blueprint_block_bounds:
        placement_obstacles.append(blueprint_block_bounds)
    legend_placement = resolve_legend_layout(
        source_data,
        legend,
        width,
        height,
        placement_obstacles,
        arrows_data,
        node_map,
    )
    legend_reserved = legend_layout(source_data, legend, width, height)

    reserved_bounds = list(section_obstacles)
    if legend_reserved:
        reserved_bounds.append(legend_reserved[2])
    if footer_reserved:
        reserved_bounds.append(footer_reserved[2])
    if blueprint_block_bounds:
        reserved_bounds.append(blueprint_block_bounds)

    route_obstacles = node_obstacles + reserved_bounds
    label_obstacles = node_obstacles + reserved_bounds
    prepared_arrows = prepare_arrows(arrows_data, node_map)
    rendered_by_index: Dict[int, ArrowRender] = {}
    existing_routes: List[Sequence[Point]] = []
    routing_order = sorted(
        range(len(prepared_arrows)),
        key=lambda index: (0 if prepared_arrows[index].get("route_points") else 1, index),
    )
    issues: List[Dict[str, object]] = []
    for index in routing_order:
        rendered = render_arrow(
            prepared_arrows[index],
            style,
            node_map,
            route_obstacles,
            label_obstacles,
            existing_routes=existing_routes,
            canvas_bounds=(0.0, 0.0, width, height),
        )
        rendered_by_index[index] = rendered
        existing_routes.append(rendered.route)
        if rendered.label_bounds:
            label_obstacles.append(rendered.label_bounds)
            route_obstacles.append(rendered.label_bounds)
        if rendered.report["bridges"]:
            issues.append(
                {
                    "severity": "info",
                    "code": "EDGE_CROSSING_BRIDGED",
                    "element": rendered.edge_id,
                    "coordinates": rendered.report["bridges"],
                }
            )

    contract_data = composition_contract.as_dict()
    visual_theme = STYLE_NAMES[style_index]
    semantic_profile = str(diagram.semantic_report.get("profile", "generic"))
    diagram_type = str(source_data.get("diagram_type", mode))
    motion_scene = str(source_data.get("motion_scene", ""))
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {int(width)} {int(height)}" '
        f'width="{int(width)}" height="{int(height)}" data-generator="fireworks-tech-graph" '
        f'data-schema-version="1" data-text-metrics="heuristic-v1" '
        f'data-style-id="{style_index}" data-visual-theme="{normalize_attribute(visual_theme)}" '
        f'data-diagram-type="{normalize_attribute(diagram_type)}" '
        f'data-motion-scene="{normalize_attribute(motion_scene)}" '
        f'data-semantic-profile="{normalize_attribute(semantic_profile)}" data-semantic-valid="true" '
        f'data-quality-profile="{normalize_attribute(composition_contract.profile)}" '
        f'data-max-bends-per-edge="{contract_data["max_bends_per_edge"]}" '
        f'data-max-total-bends="{contract_data["max_total_bends"]}" '
        f'data-max-route-stretch="{contract_data["max_route_stretch"]}" '
        f'data-max-bridged-crossings="{contract_data["max_bridged_crossings"]}" '
        f'data-min-node-gap="{contract_data["min_node_gap"]}" '
        f'data-min-container-gutter="{contract_data["min_container_gutter"]}" '
        f'data-min-label-clearance="{contract_data["min_label_clearance"]}" '
        f'data-min-segment-length="{contract_data["min_segment_length"]}">'
    ]
    lines.append(defs)
    lines.append(canvas)
    if window_controls:
        lines.append(window_controls)
    if header_meta:
        lines.append(header_meta)
    lines.append(title_block)
    if style_signature:
        lines.append(style_signature)

    for index, container in enumerate(containers):
        container_id = str(container.get("_dom_id") or safe_identifier(container.get("id"), f"container-{index:03d}"))
        container_bounds = rectangle_bounds(
            to_float(container["x"]),
            to_float(container["y"]),
            to_float(container["width"]),
            to_float(container["height"]),
        )
        lines.append(
            f'  <g id="{normalize_attribute(container_id)}" data-graph-role="container" '
            f'data-container-id="{normalize_attribute(container.get("id", ""))}" '
            f'data-semantic-role="{normalize_attribute(container.get("deployment_kind", container.get("c4_type", "boundary")))}" '
            f'data-graph-bounds="{bounds_metadata(container_bounds)}">'
        )
        lines.append(render_section(container, style))
        header_bounds = container_header_bounds(container, style)
        if header_bounds:
            lines.append(
                f'    <rect id="{normalize_attribute(container_id)}-header" data-graph-role="reserved" '
                f'data-reserved-kind="container-header" x="{geometry.format_number(header_bounds[0])}" '
                f'y="{geometry.format_number(header_bounds[1])}" width="{geometry.format_number(header_bounds[2] - header_bounds[0])}" '
                f'height="{geometry.format_number(header_bounds[3] - header_bounds[1])}" fill="none" stroke="none"/>'
            )
        lines.append("  </g>")

    # A bridge is assigned to the edge routed after an existing edge. Preserve
    # that order in the SVG paint stack so the bridge mask erases the lower
    # edge before the bridge owner is painted on top.
    lines.extend(rendered_by_index[index].path_svg for index in routing_order)

    for node, node_data in zip(normalized_nodes, nodes_data):
        node_id = str(node_data.get("_dom_id") or f"node-{safe_identifier(node.node_id, 'node')}")
        semantic_role = node_data.get(
            "c4_type",
            node_data.get("deployment_kind", node_data.get("transit_role", node_data.get("ops_role", node_data.get("kind", "node")))),
        )
        lines.append(
            f'  <g id="{normalize_attribute(node_id)}" data-graph-role="node" '
            f'data-node-id="{normalize_attribute(node.node_id)}" '
            f'data-semantic-role="{normalize_attribute(semantic_role)}" '
            f'data-motion-role="{normalize_attribute(node_data.get("motion_role", ""))}" '
            f'data-motion-stage="{normalize_attribute(node_data.get("motion_stage", ""))}" '
            f'data-motion-order="{normalize_attribute(node_data.get("motion_order", ""))}" '
            f'data-parent="{normalize_attribute(node_data.get("parent", ""))}" '
            f'data-deployment-id="{normalize_attribute(node_data.get("deployment_id", ""))}" '
            f'data-topic-id="{normalize_attribute(node_data.get("topic_id", ""))}" '
            f'data-span-id="{normalize_attribute(node_data.get("span_id", ""))}" '
            f'data-station-order="{normalize_attribute(node_data.get("station_order", ""))}" '
            f'data-status="{normalize_attribute(node_data.get("status", ""))}" '
            f'data-start-ms="{normalize_attribute(node_data.get("start_ms", ""))}" '
            f'data-duration-ms="{normalize_attribute(node_data.get("duration_ms", ""))}" '
            f'data-parent-span="{normalize_attribute(node_data.get("parent_span", ""))}" '
            f'data-graph-bounds="{bounds_metadata(node.bounds)}">'
        )
        lines.append(render_node(node_data, style))
        lines.append("  </g>")

    lines.extend(
        rendered_by_index[index].label_svg
        for index in range(len(prepared_arrows))
        if rendered_by_index[index].label_svg
    )

    legend_svg = render_legend(legend, style, width, height, source_data)
    if legend_svg:
        lines.append(legend_svg)

    if blueprint_block_svg:
        if blueprint_block_bounds:
            lines.append(
                f'  <g id="blueprint-title-block" data-graph-role="reserved" '
                f'data-graph-bounds="{bounds_metadata(blueprint_block_bounds)}">'
            )
            lines.append(blueprint_block_svg)
            lines.append("  </g>")
        else:
            lines.append(blueprint_block_svg)

    footer_svg = render_footer(source_data, style, width, height)
    if footer_svg:
        if footer_reserved:
            lines.append(
                f'  <g id="footer" data-graph-role="reserved" data-graph-bounds="{bounds_metadata(footer_reserved[2])}">'
            )
            lines.append(footer_svg)
            lines.append("  </g>")
        else:
            lines.append(footer_svg)

    lines.append("</svg>")
    composition = quality.assess_composition(
        nodes=[(node.node_id, node.bounds) for node in normalized_nodes],
        containers=[
            (
                str(container.get("id") or f"container-{index:03d}"),
                rectangle_bounds(
                    to_float(container["x"]),
                    to_float(container["y"]),
                    to_float(container["width"]),
                    to_float(container["height"]),
                ),
            )
            for index, container in enumerate(containers)
        ],
        edges=[rendered_by_index[index].report for index in range(len(prepared_arrows))],
        contract=composition_contract,
    )
    if not composition["ok"]:
        summary = "; ".join(
            f'{item["code"]}:{item["element"]}={item["actual"]}>{item["limit"]}'
            for item in composition["violations"]
        )
        raise ValueError(f"COMPOSITION_QUALITY: {summary}")

    svg = "\n".join(line for line in lines if line)
    typography = text_quality_report(svg)
    text_policy = source_data.get("text_policy", "report")
    if text_policy not in {"report", "strict"}:
        raise ValueError("text_policy must be report or strict")
    if text_policy == "strict" and not typography["complete_text"]:
        raise ValueError("TEXT_FIT: text would be truncated; widen the card or split the view")
    report: Dict[str, object] = {
        "schema_version": 1,
        "input_schema": diagram.input_schema,
        "mode": mode,
        "style": {"id": style_index, "name": visual_theme},
        "semantics": dict(diagram.semantic_report),
        "ok": True,
        "canvas": {"width": round(width, 2), "height": round(height, 2)},
        "text_metrics": "heuristic-v1",
        "typography": typography,
        "palette": palette_report(style),
        "placements": {
            "legend": {
                key: ([round(item, 2) for item in value] if key == "bounds" else value)
                for key, value in legend_placement.items()
            }
            if legend_placement
            else None
        },
        "edges": [rendered_by_index[index].report for index in range(len(prepared_arrows))],
        "composition": composition,
        "issues": issues,
        "summary": {
            "nodes": len(nodes_data),
            "edges": len(prepared_arrows),
            "bridged_crossings": sum(len(rendered.report["bridges"]) for rendered in rendered_by_index.values()),
        },
    }
    return svg, report


def build_svg(template_type: str, data: Dict[str, object]) -> str:
    return build_svg_with_report(template_type, data)[0]


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("template_type")
    parser.add_argument("output_path")
    parser.add_argument("data_json", nargs="?")
    parser.add_argument("--layout-report", "--report", dest="layout_report")
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> None:
    args = parse_args(argv)
    try:
        if args.data_json is not None:
            data = json.loads(args.data_json)
        else:
            data = json.load(sys.stdin)
        svg_content, report = build_svg_with_report(args.template_type, data)
        os.makedirs(os.path.dirname(os.path.abspath(args.output_path)), exist_ok=True)
        with open(args.output_path, "w", encoding="utf-8") as handle:
            handle.write(svg_content)
        if args.layout_report:
            os.makedirs(os.path.dirname(os.path.abspath(args.layout_report)), exist_ok=True)
            with open(args.layout_report, "w", encoding="utf-8") as handle:
                json.dump(report, handle, ensure_ascii=False, indent=2, sort_keys=True)
                handle.write("\n")
        print(f"✓ SVG generated: {args.output_path}")
        if args.layout_report:
            print(f"✓ Layout report: {args.layout_report}")
    except FileNotFoundError as exc:
        print(f"Error: {exc}")
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Error: Invalid JSON: {exc}")
        sys.exit(1)
    except ValueError as exc:
        if args.layout_report:
            os.makedirs(os.path.dirname(os.path.abspath(args.layout_report)), exist_ok=True)
            failure_report = {
                "schema_version": 1,
                "ok": False,
                "issues": [{"severity": "error", "code": "LAYOUT_ERROR", "message": str(exc)}],
            }
            with open(args.layout_report, "w", encoding="utf-8") as handle:
                json.dump(failure_report, handle, ensure_ascii=False, indent=2, sort_keys=True)
                handle.write("\n")
        print(f"Error: {exc}")
        sys.exit(1)
    except Exception as exc:  # pragma: no cover
        print(f"Unexpected error: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
