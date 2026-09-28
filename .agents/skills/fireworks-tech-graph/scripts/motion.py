#!/usr/bin/env python3
"""Validated SVG-to-GIF motion planning for semantic technical diagrams."""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import tempfile
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional

from interactive_html import sanitize_svg
from validate_svg import run_check


SCRIPT_DIR = Path(__file__).resolve().parent
MOTION_WORKER = SCRIPT_DIR / "svg2gif.js"
STYLE_PRESETS = {
    1: "memory-weave",
    2: "tool-grounding",
    3: "service-blueprint",
    4: "memory-lifecycle",
    5: "agent-orchestration",
    6: "governed-runtime",
    7: "token-stream",
    8: "golden-circuit",
    9: "review-trace",
    10: "cloud-flow",
    11: "event-transit",
    12: "ops-pulse",
}
PRESET_STYLES = {preset: style for style, preset in STYLE_PRESETS.items()}
MOTION_PRESETS = tuple(STYLE_PRESETS.values())
REVIEWED_STYLE_IDS = frozenset(range(1, 13))
STYLE_MOTION_ROLES = {
    1: {"ingress", "reason", "extract", "transform", "resolve", "memory-write", "memory-read", "response-context"},
    2: {"ingress", "delegate", "tool-call", "inspect", "index", "grounding", "answer"},
    3: {"ingress", "policy", "fanout", "data-write", "event", "telemetry"},
    4: {"sample", "attend", "invoke", "remember", "consolidate", "recall"},
    5: {"ingress", "delegate", "evidence", "artifact", "context", "deliver", "approval"},
    6: {"ingress", "dispatch", "runtime-branch", "foundation", "promote"},
    7: {"connect", "prepare", "invoke", "tool-call", "token-stream", "govern", "measure", "promote"},
    8: {"primary", "memory-read", "tool-call", "data", "trace", "feedback"},
    9: {"review-entry", "review-request", "review-async", "review-state", "review-external"},
    10: {"global-route", "regional-write", "cross-region"},
    11: {"topic-rail", "dead-letter", "state-project"},
    12: {"critical-request", "telemetry-export"},
}
CHECKS = ("xml", "markers", "geometry", "composition")
MAX_INPUT_BYTES = 20 * 1024 * 1024
MAX_RENDERED_PIXELS = 600_000_000
MOTION_FORMAT = {"suffix": ".gif", "name": "gif", "mime": "image/gif", "loop_playback": "embedded-infinite"}
MOTION_TIMEOUTS = {"runtime_probe": 15, "render": 120, "encode": 120, "media_probe": 30}
MOTION_SIZE_TARGET_BYTES = 500_000
DEFAULT_MOTION_DURATION = 5.75
DEFAULT_MOTION_FPS = 20
DEFAULT_MOTION_FRAME_COUNT = 115
MINIMUM_MOTION_FRAME_COUNT = 55
MOTION_GRAMMAR_VERSION = "3.4"
APPROVED_BASELINE_DURATION = 3.75
APPROVED_BASELINE_FRAME_COUNT = 75
TIMING_REVISION_ID = "+2s-settled-flow"
TIMING_REVISION_APPROVED_AT = "2026-07-17"
MOTION_CURVES = {
    "draw": "linear",
    "persistent-data-flow": "linear",
    "reset": "linear",
}
SCENE_SIGNATURES = {
    1: {
        "name": "memory-weave-draw-on-persistent-data-flow",
        "distinctive_primitives": [
            "semantic-route-build",
            "settled-marker-arrival",
            "eight-route-persistent-data-flow",
        ],
    },
    2: {
        "name": "tool-grounding-terminal-evidence-trace",
        "distinctive_primitives": [
            "semantic-route-build",
            "settled-marker-arrival",
            "eight-route-terminal-evidence-stream",
            "terminal-prompt-cursor",
        ],
    },
    3: {
        "name": "service-blueprint-distribution-wave",
        "distinctive_primitives": [
            "semantic-route-build",
            "settled-marker-arrival",
            "ten-route-blueprint-distribution-wave",
            "blueprint-registration-bead",
        ],
    },
    4: {
        "name": "memory-lifecycle-notion-card-handoff",
        "distinctive_primitives": [
            "semantic-route-build",
            "settled-marker-arrival",
            "six-route-notion-memory-rail",
            "notion-memory-card",
        ],
    },
    5: {
        "name": "glassmorphism-multi-agent-task-capsules",
        "distinctive_primitives": ["semantic-route-build", "glass-handoff-rail", "glass-task-capsule", "coordinator-halo"],
    },
    6: {
        "name": "claude-official-governed-runtime-policy-seals",
        "distinctive_primitives": ["semantic-route-build", "governance-thread", "policy-seal"],
    },
    7: {
        "name": "openai-official-api-token-train",
        "distinctive_primitives": ["semantic-route-build", "api-token-rail", "token-train"],
    },
    8: {
        "name": "dark-luxury-golden-gem-circuit",
        "distinctive_primitives": ["semantic-route-build", "luxury-circuit-rail", "gem-tracer"],
    },
    9: {
        "name": "c4-review-canvas-moving-review-cursors",
        "distinctive_primitives": ["semantic-route-build", "review-trace-rail", "review-cursor"],
    },
    10: {
        "name": "cloud-fabric-active-active-synchronized-regions",
        "distinctive_primitives": ["semantic-route-build", "cloud-flow-rail", "region-chevron-pair", "replication-capsule", "availability-pulse"],
    },
    11: {
        "name": "event-transit-three-car-event-trains",
        "distinctive_primitives": ["semantic-route-build", "event-transit-rail", "event-train", "exception-car", "projection-car", "station-dwell-ring"],
    },
    12: {
        "name": "ops-pulse-incident-path-waterfall-scanner",
        "distinctive_primitives": ["semantic-route-build", "incident-pulse-rail", "ecg-head", "telemetry-export-packet", "trace-span-reveal", "waterfall-scanner"],
    },
}
STYLE_1_DRAW_SCHEDULE = [
    {"role": "ingress", "frames": [1, 8]},
    {"role": "reason", "frames": [5, 12]},
    {"role": "extract", "frames": [9, 16]},
    {"role": "transform", "frames": [13, 20]},
    {"role": "resolve", "frames": [17, 24]},
    {"role": "memory-write", "frames": [21, 28]},
    {"role": "memory-read", "frames": [25, 32]},
    {"role": "response-context", "frames": [29, 36]},
]
STYLE_2_DRAW_SCHEDULE = [
    {"role": "ingress", "stage": 1, "order": 0, "frames": [1, 8]},
    {"role": "delegate", "stage": 2, "order": 0, "frames": [5, 12]},
    {"role": "tool-call", "stage": 3, "order": 0, "frames": [9, 16]},
    {"role": "inspect", "stage": 4, "order": 0, "frames": [13, 20]},
    {"role": "index", "stage": 5, "order": 0, "frames": [17, 24]},
    {"role": "grounding", "stage": 6, "order": 0, "frames": [21, 28]},
    {"role": "grounding", "stage": 6, "order": 1, "frames": [25, 32]},
    {"role": "answer", "stage": 7, "order": 0, "frames": [29, 36]},
]
STYLE_3_DRAW_SCHEDULE = [
    {"role": "ingress", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "policy", "stage": 2, "order": 0, "frames": [4, 9]},
    {"role": "fanout", "stage": 3, "order": 0, "frames": [8, 13]},
    {"role": "fanout", "stage": 3, "order": 1, "frames": [11, 16]},
    {"role": "fanout", "stage": 3, "order": 2, "frames": [14, 19]},
    {"role": "data-write", "stage": 4, "order": 0, "frames": [18, 23]},
    {"role": "data-write", "stage": 4, "order": 1, "frames": [21, 26]},
    {"role": "data-write", "stage": 4, "order": 2, "frames": [24, 29]},
    {"role": "event", "stage": 5, "order": 0, "frames": [28, 33]},
    {"role": "telemetry", "stage": 6, "order": 0, "frames": [31, 36]},
]
STYLE_4_DRAW_SCHEDULE = [
    {"role": "sample", "stage": 1, "order": 0, "frames": [1, 4]},
    {"role": "attend", "stage": 2, "order": 0, "frames": [5, 8]},
    {"role": "invoke", "stage": 3, "order": 0, "frames": [9, 12]},
    {"role": "remember", "stage": 4, "order": 0, "frames": [13, 22]},
    {"role": "consolidate", "stage": 5, "order": 0, "frames": [23, 26]},
    {"role": "recall", "stage": 6, "order": 0, "frames": [27, 36]},
]
STYLE_5_DRAW_SCHEDULE = [
    {"role": "ingress", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "delegate", "stage": 2, "order": 0, "frames": [5, 12]},
    {"role": "delegate", "stage": 2, "order": 1, "frames": [8, 15]},
    {"role": "delegate", "stage": 2, "order": 2, "frames": [11, 18]},
    {"role": "evidence", "stage": 3, "order": 0, "frames": [17, 24]},
    {"role": "artifact", "stage": 3, "order": 1, "frames": [20, 27]},
    {"role": "context", "stage": 4, "order": 0, "frames": [25, 30]},
    {"role": "deliver", "stage": 5, "order": 0, "frames": [29, 36]},
    {"role": "approval", "stage": 5, "order": 1, "frames": [29, 36]},
]
STYLE_6_DRAW_SCHEDULE = [
    {"role": "ingress", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "dispatch", "stage": 2, "order": 0, "frames": [5, 12]},
    {"role": "runtime-branch", "stage": 3, "order": 0, "frames": [10, 17]},
    {"role": "runtime-branch", "stage": 3, "order": 1, "frames": [13, 20]},
    {"role": "runtime-branch", "stage": 3, "order": 2, "frames": [16, 23]},
    {"role": "foundation", "stage": 4, "order": 0, "frames": [21, 28]},
    {"role": "foundation", "stage": 4, "order": 1, "frames": [24, 31]},
    {"role": "foundation", "stage": 4, "order": 2, "frames": [27, 34]},
    {"role": "promote", "stage": 5, "order": 0, "frames": [31, 36]},
]
STYLE_7_DRAW_SCHEDULE = [
    {"role": "connect", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "prepare", "stage": 2, "order": 0, "frames": [5, 12]},
    {"role": "invoke", "stage": 3, "order": 0, "frames": [10, 17]},
    {"role": "tool-call", "stage": 4, "order": 0, "frames": [15, 22]},
    {"role": "token-stream", "stage": 4, "order": 1, "frames": [18, 27]},
    {"role": "govern", "stage": 5, "order": 0, "frames": [25, 32]},
    {"role": "measure", "stage": 5, "order": 1, "frames": [25, 32]},
    {"role": "promote", "stage": 6, "order": 0, "frames": [31, 36]},
]
STYLE_8_DRAW_SCHEDULE = [
    {"role": "primary", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "primary", "stage": 2, "order": 0, "frames": [5, 10]},
    {"role": "memory-read", "stage": 3, "order": 0, "frames": [9, 18]},
    {"role": "tool-call", "stage": 3, "order": 1, "frames": [12, 21]},
    {"role": "data", "stage": 4, "order": 0, "frames": [20, 25]},
    {"role": "trace", "stage": 5, "order": 0, "frames": [24, 29]},
    {"role": "feedback", "stage": 6, "order": 0, "frames": [28, 36]},
]
STYLE_9_DRAW_SCHEDULE = [
    {"role": "review-entry", "stage": 1, "order": 0, "frames": [1, 7]},
    {"role": "review-request", "stage": 2, "order": 0, "frames": [7, 13]},
    {"role": "review-async", "stage": 3, "order": 0, "frames": [13, 22]},
    {"role": "review-state", "stage": 4, "order": 0, "frames": [22, 30]},
    {"role": "review-external", "stage": 4, "order": 1, "frames": [28, 36]},
]
STYLE_10_DRAW_SCHEDULE = [
    {"role": "global-route", "stage": 1, "order": 0, "frames": [1, 12]},
    {"role": "global-route", "stage": 1, "order": 1, "frames": [1, 12]},
    {"role": "regional-write", "stage": 2, "order": 0, "frames": [13, 22]},
    {"role": "regional-write", "stage": 2, "order": 1, "frames": [13, 22]},
    {"role": "cross-region", "stage": 3, "order": 0, "frames": [23, 36]},
]
STYLE_11_DRAW_SCHEDULE = [
    {"role": "topic-rail", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "topic-rail", "stage": 2, "order": 0, "frames": [7, 12]},
    {"role": "topic-rail", "stage": 3, "order": 0, "frames": [13, 18]},
    {"role": "topic-rail", "stage": 4, "order": 0, "frames": [19, 24]},
    {"role": "dead-letter", "stage": 5, "order": 0, "frames": [25, 32]},
    {"role": "state-project", "stage": 5, "order": 1, "frames": [29, 36]},
]
STYLE_12_DRAW_SCHEDULE = [
    {"role": "critical-request", "stage": 1, "order": 0, "frames": [1, 6]},
    {"role": "critical-request", "stage": 2, "order": 0, "frames": [7, 12]},
    {"role": "critical-request", "stage": 3, "order": 0, "frames": [13, 18]},
    {"role": "telemetry-export", "stage": 4, "order": 0, "frames": [19, 26]},
]
# Backwards-compatible public name for the approved Style 1 report contract.
DRAW_SCHEDULE = STYLE_1_DRAW_SCHEDULE
RESET_OPACITY_SAMPLES = [1.0, 0.7575, 0.515, 0.2725, 0.03]

STYLE_SCENE_CONTRACTS = {
    1: {
        "preset": "memory-weave",
        "draw_schedule": STYLE_1_DRAW_SCHEDULE,
        "schedule_keys": [
            ("ingress", 0),
            ("reason", 0),
            ("extract", 0),
            ("transform", 0),
            ("resolve", 1),
            ("memory-write", 0),
            ("memory-read", 0),
            ("response-context", 0),
        ],
        "expected_stages": [1, 2, 3, 4, 4, 5, 6, 7],
        "stream_primitive": "persistent-data-flow-stream",
        "packet_head_primitive": "persistent-data-flow-head",
        "signature_primitive": None,
        "route_label_count": 8,
    },
    2: {
        "preset": "tool-grounding",
        "draw_schedule": STYLE_2_DRAW_SCHEDULE,
        "schedule_keys": [
            ("ingress", 0),
            ("delegate", 0),
            ("tool-call", 0),
            ("inspect", 0),
            ("index", 0),
            ("grounding", 0),
            ("grounding", 1),
            ("answer", 0),
        ],
        "expected_stages": [1, 2, 3, 4, 5, 6, 6, 7],
        "stream_primitive": "terminal-evidence-stream",
        "packet_head_primitive": "terminal-command-head",
        "signature_primitive": "terminal-prompt-cursor",
        "route_label_count": 8,
    },
    3: {
        "preset": "service-blueprint",
        "draw_schedule": STYLE_3_DRAW_SCHEDULE,
        "schedule_keys": [
            ("ingress", 0),
            ("policy", 0),
            ("fanout", 0),
            ("fanout", 1),
            ("fanout", 2),
            ("data-write", 0),
            ("data-write", 1),
            ("data-write", 2),
            ("event", 0),
            ("telemetry", 0),
        ],
        "expected_stages": [1, 2, 3, 3, 3, 4, 4, 4, 5, 6],
        "stream_primitive": "blueprint-distribution-wave",
        "packet_head_primitive": None,
        "registration_bead_primitive": "blueprint-registration-bead",
        "signature_primitive": None,
        "route_label_count": 7,
        "source_sha256": "b8f55d9ea0c6111176d8ff50d2e844b2001ee5087a3940621e635e1b875d470d",
    },
    4: {
        "preset": "memory-lifecycle",
        "draw_schedule": STYLE_4_DRAW_SCHEDULE,
        "schedule_keys": [
            ("sample", 0),
            ("attend", 0),
            ("invoke", 0),
            ("remember", 0),
            ("consolidate", 0),
            ("recall", 0),
        ],
        "expected_stages": [1, 2, 3, 4, 5, 6],
        "stream_primitive": "notion-memory-rail",
        "packet_head_primitive": None,
        "memory_card_primitive": "notion-memory-card",
        "signature_primitive": None,
        "route_label_count": 2,
        "source_sha256": "04cf833659e82c3e1743db4042cacf839a6d784a99c32d076e36fd4776e70c1b",
    },
    5: {
        "preset": "agent-orchestration",
        "draw_schedule": STYLE_5_DRAW_SCHEDULE,
        "schedule_keys": [("ingress", 0), ("delegate", 0), ("delegate", 1), ("delegate", 2), ("evidence", 0), ("artifact", 1), ("context", 0), ("deliver", 0), ("approval", 1)],
        "expected_stages": [1, 2, 2, 2, 3, 3, 4, 5, 5],
        "stream_primitive": "glass-handoff-rail",
        "signature_primitive": "glass-task-capsule",
        "route_label_count": 9,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "f4664045331c73179c312482b4d68d474513a059ede426891e097e615722b6a9",
        "source_sha256": "52bf52e8ac0b129fcfad8dcd06e93468b3b79e29e9e0f919be80cb58046c0991",
    },
    6: {
        "preset": "governed-runtime",
        "draw_schedule": STYLE_6_DRAW_SCHEDULE,
        "schedule_keys": [("ingress", 0), ("dispatch", 0), ("runtime-branch", 0), ("runtime-branch", 1), ("runtime-branch", 2), ("foundation", 0), ("foundation", 1), ("foundation", 2), ("promote", 0)],
        "expected_stages": [1, 2, 3, 3, 3, 4, 4, 4, 5],
        "stream_primitive": "governance-thread",
        "signature_primitive": "policy-seal",
        "route_label_count": 9,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "427127297757d7672ab365e37983a2a09bc55b26a420be9b44dc67e7ac5b9553",
        "source_sha256": "25847c17def77f9b9da1b9320504e31841c28cbcf35f56602d2f4dd76a40c772",
    },
    7: {
        "preset": "token-stream",
        "draw_schedule": STYLE_7_DRAW_SCHEDULE,
        "schedule_keys": [("connect", 0), ("prepare", 0), ("invoke", 0), ("tool-call", 0), ("token-stream", 1), ("govern", 0), ("measure", 1), ("promote", 0)],
        "expected_stages": [1, 2, 3, 4, 4, 5, 5, 6],
        "stream_primitive": "api-token-rail",
        "signature_primitive": "token-train",
        "route_label_count": 8,
        "maximum_concurrent_draws": 3,
        "fixture_sha256": "4d03096787cceb3e2be61567cf12996291dd46d2289bd5394cb30360b48a4473",
        "source_sha256": "ce07fd5279c5709b4546c59007068ca678b92122ed740d43270ecd22f7bbf82b",
    },
    8: {
        "preset": "golden-circuit",
        "draw_schedule": STYLE_8_DRAW_SCHEDULE,
        "schedule_keys": [("primary", 1, 0), ("primary", 2, 0), ("memory-read", 3, 0), ("tool-call", 3, 1), ("data", 4, 0), ("trace", 5, 0), ("feedback", 6, 0)],
        "expected_stages": [1, 2, 3, 3, 4, 5, 6],
        "stage_aware_schedule_key": True,
        "stream_primitive": "luxury-circuit-rail",
        "signature_primitive": "gem-tracer",
        "route_label_count": 7,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "6ade2db83f0fa772c4791e1a09a2c128373125da3bcfa2624434daff72316122",
        "source_sha256": "6ade2db83f0fa772c4791e1a09a2c128373125da3bcfa2624434daff72316122",
    },
    9: {
        "preset": "review-trace",
        "draw_schedule": STYLE_9_DRAW_SCHEDULE,
        "schedule_keys": [("review-entry", 0), ("review-request", 0), ("review-async", 0), ("review-state", 0), ("review-external", 1)],
        "expected_stages": [1, 2, 3, 4, 4],
        "stream_primitive": "review-trace-rail",
        "signature_primitive": "review-cursor",
        "route_label_count": 5,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "a8a0bccddc4b9b762286f3a7f21a5c1fdb98ea32f436d573bb7d3c14d7be27a9",
        "source_sha256": "b45264d17910fda296a7b52e7a338f361d8272ff14da55d2cad8c6e8dabe2717",
    },
    10: {
        "preset": "cloud-flow",
        "draw_schedule": STYLE_10_DRAW_SCHEDULE,
        "schedule_keys": [("global-route", 0), ("global-route", 1), ("regional-write", 0), ("regional-write", 1), ("cross-region", 0)],
        "expected_stages": [1, 1, 2, 2, 3],
        "stream_primitive": "cloud-flow-rail",
        "signature_primitive": "region-chevron-pair-or-replication-capsule",
        "route_label_count": 3,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "8c180ef8cecdc2419c79912245329ac9fffcc9ff08f8faeeb65541d21c747d4e",
        "source_sha256": "a739db50e30e0669dcfc926f4ce141c655f0b8f2e4e71c6a45444c9b3e61074a",
    },
    11: {
        "preset": "event-transit",
        "draw_schedule": STYLE_11_DRAW_SCHEDULE,
        "schedule_keys": [("topic-rail", 1, 0), ("topic-rail", 2, 0), ("topic-rail", 3, 0), ("topic-rail", 4, 0), ("dead-letter", 5, 0), ("state-project", 5, 1)],
        "expected_stages": [1, 2, 3, 4, 5, 5],
        "stage_aware_schedule_key": True,
        "stream_primitive": "event-transit-rail",
        "signature_primitive": "event-train-or-branch-car",
        "route_label_count": 0,
        "maximum_concurrent_draws": 2,
        "fixture_sha256": "a9fbd96129c9fc54b97b80024cb954d03d471d4c2963f99e71eff276d15d6140",
        "source_sha256": "e4ca3aa987b2495868765a0b66d11763a67890f13079c513f58451a40d5432e4",
    },
    12: {
        "preset": "ops-pulse",
        "draw_schedule": STYLE_12_DRAW_SCHEDULE,
        "schedule_keys": [("critical-request", 1, 0), ("critical-request", 2, 0), ("critical-request", 3, 0), ("telemetry-export", 4, 0)],
        "expected_stages": [1, 2, 3, 4],
        "stage_aware_schedule_key": True,
        "stream_primitive": "incident-pulse-rail-or-telemetry-export-rail",
        "signature_primitive": "ecg-head-or-telemetry-export-packet",
        "route_label_count": 0,
        "maximum_concurrent_draws": 1,
        "fixture_sha256": "2ea1d7a153ca8a39c37e9f5c5fd18a47c98a59f35694cd2bd68919d6b86b132c",
        "source_sha256": "f6170771acdd376fd78fa103214ff3125155754b6e19b87971d11c0afbab5a21",
    },
}

STYLE_SPECIALIZED_LIVE_SPECS: dict[int, dict[str, object]] = {
    5: {
        "body_primitive": "glass-handoff-rail", "signature_primitive": "glass-task-capsule",
        "dash_pattern": [13, 30], "dash_period": 43, "step": 6, "body_opacity": 0.88,
        "maximum_live_width": 2.2, "endpoint_clearance": 8,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 43",
        "expected_initial_phases": [7, 14, 17, 20, 21, 24, 28, 35, 38],
        "resolved_widths": [2.2] * 9,
        "geometry": {
            "shape": "rounded-translucent-plate", "width": 14, "height": 9, "rx": 3,
            "highlight_stroke_width": 1, "work_item_dot_radius": 2, "work_item_dot_count": 2,
            "tangent_aware_rotation": True,
        },
        "auxiliary": {"primitive": "coordinator-halo", "node_id": "coordinator", "period_frames": 16, "opacity_range": [0.12, 0.32], "movement": "opacity-only"},
        "direction_sentinels": [
            {"key": "ingress/0", "directions": ["right"]},
            {"key": "delegate/0", "directions": ["down", "left", "down"]},
            {"key": "delegate/2", "directions": ["down", "right", "down"]},
            {"key": "evidence/0", "directions": ["down"]},
            {"key": "context/0", "directions": ["right"]},
        ],
    },
    6: {
        "body_primitive": "governance-thread", "signature_primitive": "policy-seal",
        "dash_pattern": [11, 36], "dash_period": 47, "step": 6, "body_opacity": 0.82,
        "maximum_live_width": 2.8, "endpoint_clearance": 8,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 47",
        "expected_initial_phases": [7, 14, 21, 24, 27, 28, 31, 34, 35],
        "resolved_widths": [2.0] * 9,
        "geometry": {"shape": "warm-white-hexagonal-outline", "width": 12, "height": 12, "center_dot_diameter": 3, "approval_bar_width": 4, "shadow": False, "glow": False},
        "direction_sentinels": [
            {"key": "ingress/0", "directions": ["right"]}, {"key": "dispatch/0", "directions": ["down"]},
            {"key": "runtime-branch/0", "directions": ["left"]}, {"key": "runtime-branch/1", "directions": ["right"]},
            {"key": "foundation/0", "directions": ["down"]}, {"key": "promote/0", "directions": ["right"]},
        ],
    },
    7: {
        "body_primitive": "api-token-rail", "signature_primitive": "token-train",
        "dash_pattern": [10, 33], "dash_period": 43, "step": 6, "body_opacity": 0.86,
        "maximum_live_width": 2.5, "endpoint_clearance": 10,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 43",
        "expected_initial_phases": [7, 14, 21, 28, 31, 35, 38, 42],
        "resolved_widths": [2.0] * 8,
        "geometry": {"shape": "three-cell-token-train", "group_width": 18, "group_height": 8, "cell_width": 4, "cell_height": 4, "cell_gap": 2, "cell_opacities": [1.0, 0.72, 0.44], "tangent_aware_rotation": True},
        "direction_sentinels": [
            {"key": "connect/0", "directions": ["right"]}, {"key": "prepare/0", "directions": ["down", "left", "down"]},
            {"key": "tool-call/0", "directions": ["right"]}, {"key": "token-stream/1", "directions": ["down", "left", "down"]},
            {"key": "govern/0", "directions": ["down"]}, {"key": "promote/0", "directions": ["right"]},
        ],
    },
    8: {
        "body_primitive": "luxury-circuit-rail", "signature_primitive": "gem-tracer",
        "dash_pattern": [14, 33], "dash_period": 47, "step": 6, "body_opacity": 0.86,
        "maximum_live_width": 2.8, "endpoint_clearance": 8,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 47",
        "expected_initial_phases": [7, 14, 21, 24, 28, 35, 42],
        "resolved_widths": [2.0, 2.0, 1.7, 1.7, 1.7, 2.0, 1.7],
        "geometry": {"shape": "diamond-with-tapered-tail", "diamond_width": 7, "diamond_height": 7, "diamond_rotation": 45, "specular_diameter": 2, "tail_length": 12, "filtered_elements_per_tracer": 1},
        "direction_sentinels": [
            {"key": "primary/1/0", "directions": ["right"]}, {"key": "primary/2/0", "directions": ["right"]},
            {"key": "memory-read/3/0", "directions": ["down", "left", "down"]},
            {"key": "feedback/6/0", "directions": ["up", "left", "up"]},
        ],
    },
    9: {
        "body_primitive": "review-trace-rail", "signature_primitive": "review-cursor",
        "dash_pattern": [8, 33], "dash_period": 41, "step": 5, "body_opacity": 0.82,
        "maximum_live_width": 2.6, "endpoint_clearance": 9,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 41",
        "expected_initial_phases": [7, 14, 21, 28, 31],
        "resolved_widths": [2.0] * 5,
        "geometry": {"shape": "review-mark", "outline_circle_diameter": 11, "diagonal_handle_length": 5, "internal_check_extent": 3, "shadow": False, "glow": False},
        "direction_sentinels": [
            {"key": "review-entry/0", "directions": ["right"]}, {"key": "review-request/0", "directions": ["right"]},
            {"key": "review-async/0", "directions": ["down"]}, {"key": "review-state/0", "directions": ["left"]},
            {"key": "review-external/1", "directions": ["right"]},
        ],
    },
    10: {
        "body_primitive": "cloud-flow-rail", "signature_primitive": "region-chevron-pair-or-replication-capsule",
        "dash_pattern": [12, 31], "dash_period": 43, "step": 6, "body_opacity": 0.82,
        "maximum_live_width": 2.7, "endpoint_clearance": 8,
        "phase_policy": "motionStage * 7 mod 43; A/B orders are phase-locked",
        "expected_initial_phases": [7, 7, 14, 14, 21],
        "resolved_widths": [2.2] * 5,
        "geometry": {"routing_write": {"shape": "region-chevron-pair", "chevron_width": 6, "chevron_height": 5, "separation": 5}, "replication": {"shape": "replication-capsule", "width": 14, "height": 7, "data_cell_count": 2, "direction": "left-to-right"}},
        "auxiliary": {"primitive": "availability-pulse", "container_ids": ["region-a", "region-b"], "movement": "opacity-only", "phase_locked": True},
        "direction_sentinels": [
            {"key": "global-route/0", "directions": ["down"]}, {"key": "global-route/1", "directions": ["down"]},
            {"key": "regional-write/0", "directions": ["down"]}, {"key": "regional-write/1", "directions": ["down"]},
            {"key": "cross-region/0", "directions": ["right"]},
        ],
    },
    11: {
        "body_primitive": "event-transit-rail", "signature_primitive": "event-train-or-branch-car",
        "dash_pattern": [8, 33], "dash_period": 41, "step": 5, "body_opacity": 0.78,
        "maximum_live_width": 2.2, "endpoint_clearance": 7,
        "phase_policy": "(motionStage * 5 + motionOrder * 3) mod 41",
        "expected_initial_phases": [5, 10, 15, 20, 25, 28],
        "resolved_widths": [2.2] * 6,
        "geometry": {"main": {"shape": "three-car-event-train", "car_diameter": 5, "car_gap": 3, "car_count": 3}, "dead_letter": {"shape": "red-outlined-exception-car"}, "state_project": {"shape": "teal-two-cell-projection-car", "cell_count": 2}},
        "auxiliary": {"primitive": "station-dwell-ring", "period_frames": 10, "movement": "opacity-only", "geometry_expansion": 0, "count": 4},
        "direction_sentinels": [
            {"key": "topic-rail/1/0", "directions": ["right"]}, {"key": "topic-rail/2/0", "directions": ["right"]},
            {"key": "topic-rail/3/0", "directions": ["right"]}, {"key": "topic-rail/4/0", "directions": ["right"]},
            {"key": "dead-letter/5/0", "directions": ["down"]}, {"key": "state-project/5/1", "directions": ["down"]},
        ],
    },
    12: {
        "body_primitive": "incident-pulse-rail-or-telemetry-export-rail", "signature_primitive": "ecg-head-or-telemetry-export-packet",
        "dash_pattern": [12, 31], "dash_period": 43, "step": 5, "body_opacity": 0.84,
        "maximum_live_width": 2.2, "endpoint_clearance": 8,
        "phase_policy": "motionStage * 5 mod 43",
        "expected_initial_phases": [5, 10, 15, 20],
        "resolved_widths": [2.2] * 4,
        "geometry": {"critical": {"shape": "compact-ecg-head", "stroke_width": 1.6}, "telemetry": {"shape": "cyan-three-dot-export-packet", "dot_count": 3, "dot_diameter": 4}},
        "trace_reveal": {"primitive": "trace-span-reveal", "span_ids": ["span-root", "span-api", "span-checkout", "span-payment"], "rendered_frames": [[24, 27], [27, 30], [30, 33], [33, 36]], "source_geometry_mutated": False},
        "scanner": {"primitive": "waterfall-scanner", "width": 2, "tail_width": 12, "period_frames": 34, "movement": "horizontal-within-trace-plot"},
        "auxiliary": {"primitive": "checkout-degraded-halo", "node_id": "checkout-service", "period_frames": 18, "opacity_range": [0.10, 0.28], "movement": "opacity-only"},
        "direction_sentinels": [
            {"key": "critical-request/1/0", "directions": ["right"]}, {"key": "critical-request/2/0", "directions": ["right"]},
            {"key": "critical-request/3/0", "directions": ["right"]}, {"key": "telemetry-export/4/0", "directions": ["down"]},
        ],
    },
}


def _style_1_persistent_stream_contract(frame_count: int) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    dash_period = 41
    dash_step = 6
    stream_interval_frame_count = frame_count - 36
    return {
        "primitive": "persistent-data-flow-stream",
        "packet_head_primitive": "persistent-data-flow-head",
        "stream_count": 8,
        "packet_head_count": 8,
        "roles": [entry["role"] for entry in DRAW_SCHEDULE],
        "rendered_frames": [36, frame_count - 1],
        "fade_in_frames": [36, 38],
        "fade_in_factors": [0.30, 0.65, 1.0],
        "full_opacity_frames": [38, reset_start - 1],
        "body": {
            "primitive": "persistent-data-flow-stream",
            "stroke_width": "min(4.0, max(3.0, source_stroke * 1.60))",
            "resolved_style_1_source_stroke_width": 2.4,
            "resolved_style_1_stroke_width": 3.84,
            "color": "#06b6d4",
            "opacity": 0.90,
            "dash_pattern": [16, 25],
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
        },
        "packet_head": {
            "primitive": "persistent-data-flow-head",
            "stroke_width": 2.20,
            "color": "#e0f2fe",
            "opacity": 0.98,
            "dash_pattern": [6, 35],
            "dash_offset_from_body": -10,
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
            "appended_immediately_after_body": True,
        },
        "dash_period": dash_period,
        "dash_offset_per_rendered_frame": -6.0,
        "travel_user_units_per_rendered_frame": dash_step,
        "travel_pixels_per_frame_at_960px": 6,
        "travel_pixels_per_second_at_960px_20fps": 120,
        "travel_pixels_per_frame_at_50_percent": 3,
        "travel_pixels_per_second_at_50_percent_20fps": 60,
        "phase_policy": "(motionStage * 7 + motionOrder * 3) mod 41",
        "expected_initial_phases": [7, 14, 21, 28, 31, 35, 1, 8],
        "period_step_coprime": math.gcd(dash_period, dash_step) == 1,
        "stream_interval_frame_count": stream_interval_frame_count,
        "phase_repeat_within_stream_interval": stream_interval_frame_count > dash_period,
        "direction": "source-to-target",
        "direction_sentinels": {
            "ingress": ["right"],
            "resolve": ["left"],
            "memory-write": ["down", "left", "down"],
        },
        "travel_easing": "linear",
        "minimum_review_scale": "50%",
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "reset_behavior": "all eight body/head pairs keep advancing while topology, labels, and both flow layers fade together",
    }


def _style_2_persistent_stream_contract(frame_count: int) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    dash_period = 41
    dash_step = 6
    stream_interval_frame_count = frame_count - 36
    return {
        "primitive": "terminal-evidence-stream",
        "packet_head_primitive": "terminal-command-head",
        "stream_count": 8,
        "packet_head_count": 8,
        "route_keys": [
            {"role": role, "order": order}
            for role, order in STYLE_SCENE_CONTRACTS[2]["schedule_keys"]
        ],
        "roles": [entry["role"] for entry in STYLE_2_DRAW_SCHEDULE],
        "rendered_frames": [36, frame_count - 1],
        "fade_in_frames": [36, 38],
        "fade_in_factors": [0.30, 0.65, 1.0],
        "full_opacity_frames": [38, reset_start - 1],
        "body": {
            "primitive": "terminal-evidence-stream",
            "stroke_width": "min(3.8, max(3.0, source_stroke * 1.50))",
            "resolved_style_2_source_stroke_width": 2.3,
            "resolved_style_2_stroke_width": 3.45,
            "color": "inherit-source-stroke",
            "source_colors_in_schedule_order": [
                "#a855f7",
                "#a855f7",
                "#38bdf8",
                "#38bdf8",
                "#22c55e",
                "#fb7185",
                "#fb7185",
                "#f97316",
            ],
            "semantic_colors": {
                "control": "#a855f7",
                "tool_read": "#38bdf8",
                "index_write": "#22c55e",
                "grounding_data": "#fb7185",
                "answer": "#f97316",
            },
            "opacity": 0.94,
            "dash_pattern": [15, 26],
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
        },
        "packet_head": {
            "primitive": "terminal-command-head",
            "stroke_width": 2.00,
            "color": "#f8fafc",
            "opacity": 1.00,
            "dash_pattern": [5, 36],
            "dash_offset_from_body": -10,
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
            "appended_immediately_after_body": True,
        },
        "dash_period": dash_period,
        "dash_offset_per_rendered_frame": -6.0,
        "travel_user_units_per_rendered_frame": dash_step,
        "travel_pixels_per_frame_at_960px": 6,
        "travel_pixels_per_second_at_960px_20fps": 120,
        "travel_pixels_per_frame_at_50_percent": 3,
        "travel_pixels_per_second_at_50_percent_20fps": 60,
        "phase_policy": "(motionStage * 6 + motionOrder * 3) mod 41",
        "expected_initial_phases": [6, 12, 18, 24, 30, 36, 39, 1],
        "period_step_coprime": math.gcd(dash_period, dash_step) == 1,
        "stream_interval_frame_count": stream_interval_frame_count,
        "phase_repeat_within_stream_interval": stream_interval_frame_count > dash_period,
        "direction": "source-to-target",
        "direction_sentinels": {
            "ingress/0": ["right"],
            "delegate/0": ["down", "left", "down"],
            "tool-call/0": ["right"],
            "inspect/0": ["down"],
            "index/0": ["right", "up"],
            "grounding/0": ["up", "left", "up"],
            "grounding/1": ["right"],
            "answer/0": ["right"],
        },
        "travel_easing": "linear",
        "minimum_review_scale": "50%",
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "reset_behavior": "all eight body/head pairs keep advancing while topology, labels, cursor, and both flow layers fade together",
    }


def _style_3_persistent_stream_contract(frame_count: int) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    dash_period = 43
    dash_step = 6
    stream_interval_frame_count = frame_count - 36
    return {
        "primitive": "blueprint-distribution-wave",
        "registration_bead_primitive": "blueprint-registration-bead",
        "stream_count": 10,
        "registration_bead_count": 10,
        "route_keys": [
            {"role": role, "order": order}
            for role, order in STYLE_SCENE_CONTRACTS[3]["schedule_keys"]
        ],
        "roles": [entry["role"] for entry in STYLE_3_DRAW_SCHEDULE],
        "rendered_frames": [36, frame_count - 1],
        "fade_in_frames": [36, 38],
        "fade_in_factors": [0.30, 0.65, 1.0],
        "full_opacity_frames": [38, reset_start - 1],
        "body": {
            "primitive": "blueprint-distribution-wave",
            "stroke_width": "min(3.4, max(2.8, source_stroke * 1.40))",
            "resolved_style_3_source_stroke_width": 2.1,
            "resolved_style_3_stroke_width": 2.94,
            "resolved_style_3_stroke_width_at_50_percent": 1.47,
            "color": "inherit-source-stroke",
            "source_colors_in_schedule_order": [
                "#38bdf8",
                "#67e8f9",
                "#38bdf8",
                "#38bdf8",
                "#38bdf8",
                "#fde047",
                "#fde047",
                "#fde047",
                "#fb7185",
                "#fb7185",
            ],
            "opacity": 0.92,
            "dash_pattern": [12, 31],
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
        },
        "registration_bead": {
            "primitive": "blueprint-registration-bead",
            "shape": "circle",
            "radius": 3.0,
            "diameter_at_960px": 6,
            "diameter_at_50_percent": 3,
            "fill": "#e0f2fe",
            "stroke": "inherit-source-stroke",
            "stroke_width": 1.2,
            "opacity": 0.98,
            "initial_path_distance": "stage-locked-phase",
            "path_advance_per_rendered_frame": 6.0,
            "direction": "source-to-target",
            "wrap": "target-end-to-source-start",
            "animated_attributes": ["cx", "cy", "opacity"],
            "marker_free": True,
            "filter_free": True,
        },
        "dash_period": dash_period,
        "dash_offset_per_rendered_frame": -6.0,
        "bead_advance_per_rendered_frame": 6.0,
        "travel_user_units_per_rendered_frame": dash_step,
        "travel_pixels_per_frame_at_960px": 6,
        "travel_pixels_per_second_at_960px_20fps": 120,
        "travel_pixels_per_frame_at_50_percent": 3,
        "travel_pixels_per_second_at_50_percent_20fps": 60,
        "phase_policy": "(motionStage * 7 + motionOrder * 0) mod 43",
        "expected_initial_phases": [7, 14, 21, 21, 21, 28, 28, 28, 35, 42],
        "stage_locks": {
            "fanout": {"orders": [0, 1, 2], "phase": 21},
            "data-write": {"orders": [0, 1, 2], "phase": 28, "equal_length_paths": True},
        },
        "period_step_coprime": math.gcd(dash_period, dash_step) == 1,
        "stream_interval_frame_count": stream_interval_frame_count,
        "phase_repeat_within_stream_interval": stream_interval_frame_count > dash_period,
        "direction": "source-to-target",
        "direction_sentinels": {
            "ingress/0": ["right"],
            "policy/0": ["right"],
            "fanout/0": ["down", "left", "down"],
            "fanout/1": ["down"],
            "fanout/2": ["down", "right", "down"],
            "data-write/0": ["down"],
            "data-write/1": ["down"],
            "data-write/2": ["down"],
            "event/0": ["right"],
            "telemetry/0": ["down"],
        },
        "travel_easing": "linear",
        "minimum_review_scale": "50%",
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "reset_behavior": (
            "all ten bodies and registration beads keep advancing while topology, labels, "
            "and both Blueprint flow layers fade together"
        ),
    }


def _style_4_persistent_stream_contract(frame_count: int) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    dash_period = 47
    dash_step = 6
    stream_interval_frame_count = frame_count - 36
    semantic_colors = [
        "#3b82f6",
        "#3b82f6",
        "#7c3aed",
        "#059669",
        "#ea580c",
        "#ea580c",
    ]
    progress_vector = [0.08, 0.22, 0.36, 0.50, 0.64, 0.78]
    return {
        "primitive": "notion-memory-rail",
        "memory_card_primitive": "notion-memory-card",
        "stream_count": 6,
        "memory_card_count": 6,
        "route_keys": [
            {"role": role, "order": order}
            for role, order in STYLE_SCENE_CONTRACTS[4]["schedule_keys"]
        ],
        "roles": [entry["role"] for entry in STYLE_4_DRAW_SCHEDULE],
        "rendered_frames": [36, frame_count - 1],
        "fade_in_frames": [36, 38],
        "fade_in_factors": [0.30, 0.65, 1.0],
        "full_opacity_frames": [38, reset_start - 1],
        "body": {
            "primitive": "notion-memory-rail",
            "stroke_width": "min(3.0, max(2.4, source_stroke * 1.50))",
            "resolved_style_4_source_stroke_width": 1.8,
            "resolved_style_4_stroke_width": 2.70,
            "resolved_style_4_stroke_width_at_50_percent": 1.35,
            "color": "semantic-memory-destination",
            "source_colors_in_schedule_order": ["#3b82f6"] * 6,
            "semantic_colors_in_schedule_order": semantic_colors,
            "semantic_color_meanings": {
                "active_context": "#3b82f6",
                "procedural_memory": "#7c3aed",
                "episodic_memory": "#059669",
                "semantic_memory": "#ea580c",
            },
            "opacity": 0.88,
            "dash_pattern": [12, 35],
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
            "appended_below_labels_and_nodes": True,
        },
        "memory_card": {
            "primitive": "notion-memory-card",
            "shape": "group",
            "outer_rect": {
                "x": -7,
                "y": -5,
                "width": 14,
                "height": 10,
                "rx": 2,
                "fill": "#ffffff",
                "stroke": "semantic-memory-destination",
                "stroke_width": 1.4,
            },
            "ink_lines": [
                {"x1": -4.5, "y1": -2, "x2": 4, "y2": -2},
                {"x1": -4.5, "y1": 2, "x2": 0.5, "y2": 2},
            ],
            "ink_stroke": "semantic-memory-destination",
            "ink_stroke_width": 2.0,
            "ink_linecap": "butt",
            "ink_shape_rendering": "crispEdges",
            "opacity": 0.98,
            "semantic_colors_in_schedule_order": semantic_colors,
            "initial_normalized_progress_by_stage": progress_vector,
            "initial_path_distance": "8 + progress * (pathLength - 16)",
            "endpoint_clearance": 8,
            "path_advance_per_rendered_frame": 6.0,
            "direction": "source-to-target",
            "wrap": "target-clearance-to-source-clearance",
            "tangent_rotations_in_schedule_order": [0, 0, 0, 90, 0, -90],
            "animated_attributes": ["transform", "opacity"],
            "marker_free": True,
            "filter_free": True,
            "shadow_free": True,
            "appended_below_labels_and_nodes": True,
        },
        "dash_period": dash_period,
        "dash_offset_per_rendered_frame": -6.0,
        "card_advance_per_rendered_frame": 6.0,
        "travel_user_units_per_rendered_frame": dash_step,
        "travel_pixels_per_frame_at_960px": 6,
        "travel_pixels_per_second_at_960px_20fps": 120,
        "travel_pixels_per_frame_at_50_percent": 3,
        "travel_pixels_per_second_at_50_percent_20fps": 60,
        "phase_policy": "(motionStage * 7 + motionOrder * 0) mod 47",
        "expected_initial_phases": [7, 14, 21, 28, 35, 42],
        "initial_normalized_progress_by_stage": progress_vector,
        "period_step_coprime": math.gcd(dash_period, dash_step) == 1,
        "stream_interval_frame_count": stream_interval_frame_count,
        "phase_repeat_within_stream_interval": stream_interval_frame_count > dash_period,
        "direction": "source-to-target",
        "direction_sentinels": {
            "sample/0": {"directions": ["right"], "tangent_rotation": 0},
            "attend/0": {"directions": ["right"], "tangent_rotation": 0},
            "invoke/0": {"directions": ["right"], "tangent_rotation": 0},
            "remember/0": {"directions": ["down"], "tangent_rotation": 90},
            "consolidate/0": {"directions": ["right"], "tangent_rotation": 0},
            "recall/0": {"directions": ["up"], "tangent_rotation": -90},
        },
        "travel_easing": "linear",
        "minimum_review_scale": "50%",
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "reset_behavior": (
            "all six rails and six memory cards keep advancing while topology, labels, "
            "rails, and cards fade together"
        ),
    }


def _terminal_signature_contract(frame_count: int) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    return {
        "primitive": "terminal-prompt-cursor",
        "count": 1,
        "node_id": "terminal",
        "source_text": "_",
        "source_text_hidden": False,
        "source_text_mutated": False,
        "geometry": "2.2px-high rectangle derived from underscore getBBox",
        "height": 2.2,
        "fill": "#a7f3d0",
        "marker_free": True,
        "filter_free": True,
        "movement": "opacity-only",
        "visible_after_route": {"role": "tool-call", "order": 0, "settled_frame": 16},
        "cadence_frames": [16, reset_start - 1],
        "period_frames": 16,
        "bright_frames_per_period": 8,
        "absent_frames_per_period": 8,
        "bright_opacity": 0.95,
        "reset_range": [reset_start, frame_count - 1],
        "reset_behavior": "bright opacity multiplied by shared reset opacity",
    }


def _specialized_persistent_stream_contract(frame_count: int, style_id: int) -> dict[str, object]:
    spec = STYLE_SPECIALIZED_LIVE_SPECS[style_id]
    scene = STYLE_SCENE_CONTRACTS[style_id]
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    step = int(spec["step"])
    stage_aware = bool(scene.get("stage_aware_schedule_key"))
    route_keys = []
    for key in scene["schedule_keys"]:
        if stage_aware:
            role, stage, order = key
            route_keys.append({"role": role, "stage": stage, "order": order})
        else:
            role, order = key
            route_keys.append({"role": role, "order": order})
    contract: dict[str, object] = {
        "primitive": spec["body_primitive"],
        "signature_primitive": spec["signature_primitive"],
        "stream_count": len(scene["schedule_keys"]),
        "signature_count": len(scene["schedule_keys"]),
        "route_keys": route_keys,
        "rendered_frames": [36, frame_count - 1],
        "fade_in_frames": [36, 38],
        "fade_in_factors": [0.30, 0.65, 1.0],
        "full_opacity_frames": [38, reset_start - 1],
        "body": {
            "primitive": spec["body_primitive"],
            "stroke_width": "min(maximum_live_width, source_stroke)",
            "maximum_live_width": spec["maximum_live_width"],
            "resolved_widths_in_schedule_order": spec["resolved_widths"],
            "color": "inherit-source-stroke",
            "opacity": spec["body_opacity"],
            "dash_pattern": spec["dash_pattern"],
            "linecap": "round",
            "linejoin": "round",
            "marker_free": True,
            "filter_free": True,
            "appended_below_labels_and_nodes": True,
        },
        "signature": {
            "primitive": spec["signature_primitive"],
            "geometry": spec["geometry"],
            "endpoint_clearance": spec["endpoint_clearance"],
            "path_advance_per_rendered_frame": step,
            "direction": "source-to-target",
            "wrap": "target-clearance-to-source-clearance",
            "tangent_aware_rotation": True,
            "animated_attributes": ["transform", "opacity"],
            "appended_below_labels_and_nodes": True,
        },
        "dash_period": spec["dash_period"],
        "dash_offset_per_rendered_frame": -step,
        "signature_advance_per_rendered_frame": step,
        "travel_user_units_per_rendered_frame": step,
        "travel_pixels_per_frame_at_100_percent": step,
        "travel_pixels_per_frame_at_50_percent": step / 2,
        "phase_policy": spec["phase_policy"],
        "expected_initial_phases": spec["expected_initial_phases"],
        "period_step_coprime": math.gcd(int(spec["dash_period"]), step) == 1,
        "direction": "source-to-target",
        "direction_sentinels": spec["direction_sentinels"],
        "travel_easing": "linear",
        "minimum_review_scale": "50%",
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "reset_behavior": "live rails, signatures, and scene auxiliaries keep advancing while the shared reset opacity fades to 0.03",
    }
    for optional in ("auxiliary", "trace_reveal", "scanner"):
        if optional in spec:
            contract[optional] = spec[optional]
    return contract


def _persistent_stream_contract(frame_count: int, style_id: int = 1) -> dict[str, object]:
    if style_id == 1:
        return _style_1_persistent_stream_contract(frame_count)
    if style_id == 2:
        return _style_2_persistent_stream_contract(frame_count)
    if style_id == 3:
        return _style_3_persistent_stream_contract(frame_count)
    if style_id == 4:
        return _style_4_persistent_stream_contract(frame_count)
    if style_id in STYLE_SPECIALIZED_LIVE_SPECS:
        return _specialized_persistent_stream_contract(frame_count, style_id)
    raise ValueError(f"MOTION_STYLE_REVIEW: Style {style_id} has no reviewed stream contract")


def _draw_on_contract(frame_count: int, style_id: int = 1) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    contract: dict[str, object] = {
        "primitive": "connector-draw-on-with-persistent-data-flow",
        "empty_opening_frame": 0,
        "draw_schedule": STYLE_SCENE_CONTRACTS[style_id]["draw_schedule"],
        "reset_range": [reset_start, frame_count - 1],
        "reset_opacity_samples": RESET_OPACITY_SAMPLES,
        "connectors_visible_at_opening": False,
        "nodes_visible_every_frame": True,
        "topology_draw_on": True,
        "settled_topology_dynamic": True,
        "source_edges_hidden_by_transient_css": True,
        "draw_easing": "linear",
        "settled_markers": "original marker appears only after route arrival",
        "persistent_data_flow": _persistent_stream_contract(frame_count, style_id),
        "route_label_opacity_states": STYLE_SCENE_CONTRACTS[style_id]["route_label_count"],
        "text_geometry_motion": 0,
        "maximum_concurrent_draws": STYLE_SCENE_CONTRACTS[style_id].get("maximum_concurrent_draws", 2),
        "forbidden": ["node-motion", "text-motion", "halo", "ripple", "zoom", "breathing"],
    }
    if style_id == 2:
        contract["schedule_key"] = "(data-motion-role, data-motion-order)"
        contract["terminal_signature"] = _terminal_signature_contract(frame_count)
        contract["forbidden"] = [
            "node-motion",
            "text-motion",
            "terminal-text-typing",
            "scan-line",
            "halo",
            "ripple",
            "zoom",
            "camera-motion",
            "animated-background",
            "breathing",
        ]
    elif style_id == 3:
        contract["schedule_key"] = "(data-motion-role, data-motion-order)"
        contract["maximum_concurrent_draws"] = 2
        contract["forbidden"] = [
            "node-motion",
            "text-motion",
            "glow",
            "blur",
            "shadow",
            "scan-line",
            "halo",
            "ripple",
            "terminal-cursor",
            "camera-motion",
            "animated-background",
            "breathing",
        ]
    elif style_id == 4:
        contract["schedule_key"] = "(data-motion-role, data-motion-order)"
        contract["maximum_concurrent_draws"] = 1
        contract["forbidden"] = [
            "node-motion",
            "text-motion",
            "glow",
            "blur",
            "shadow",
            "scan-line",
            "halo",
            "ripple",
            "terminal-cursor",
            "circular-bead",
            "camera-motion",
            "animated-background",
            "breathing",
        ]
    elif style_id >= 5:
        contract["schedule_key"] = (
            "(data-motion-role, data-motion-stage, data-motion-order)"
            if STYLE_SCENE_CONTRACTS[style_id].get("stage_aware_schedule_key")
            else "(data-motion-role, data-motion-order)"
        )
        contract["forbidden"] = [
            "source-node-motion",
            "source-text-motion",
            "source-geometry-mutation",
            "source-marker-mutation",
            "camera-motion",
            "animated-background",
        ]
    return contract


PERSISTENT_STREAM_CONTRACT = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT)
DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT)
STYLE_2_PERSISTENT_STREAM_CONTRACT = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT, 2)
STYLE_2_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 2)
STYLE_3_PERSISTENT_STREAM_CONTRACT = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT, 3)
STYLE_3_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 3)
STYLE_4_PERSISTENT_STREAM_CONTRACT = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT, 4)
STYLE_4_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 4)
STYLE_5_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 5)
STYLE_6_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 6)
STYLE_7_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 7)
STYLE_8_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 8)
STYLE_9_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 9)
STYLE_10_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 10)
STYLE_11_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 11)
STYLE_12_DRAW_ON_CONTRACT = _draw_on_contract(DEFAULT_MOTION_FRAME_COUNT, 12)
TERMINAL_SIGNATURE_CONTRACT = _terminal_signature_contract(DEFAULT_MOTION_FRAME_COUNT)


def _motion_grammar(duration: float, fps: int, frame_count: int, style_id: int = 1) -> dict[str, object]:
    reset_start = frame_count - len(RESET_OPACITY_SAMPLES)
    phase_ranges = {
        "empty": (0, 0),
        "draw": (1, 36),
        "stream": (36, frame_count - 1),
        "full_opacity": (38, reset_start - 1),
        "reset": (reset_start, frame_count - 1),
    }
    phases: dict[str, object] = {}
    for name, (start_frame, end_frame) in phase_ranges.items():
        phases[name] = {
            "frames": [start_frame, end_frame],
            "seconds": [
                round((start_frame + 0.5) / fps, 6),
                round((end_frame + 0.5) / fps, 6),
            ],
        }
    return {
        "version": MOTION_GRAMMAR_VERSION,
        "phases": phases,
        "curves": MOTION_CURVES,
        "draw_on": _draw_on_contract(frame_count, style_id),
        "frame_duration_ms": round(1000 / fps, 6),
        "sampling": "uniform-frame-centers",
        "sample_index_expression": "time * fps - 0.5",
        "duration_seconds": duration,
    }


def _timing_revision(duration: float, fps: int, frame_count: int) -> dict[str, object]:
    if (
        fps == DEFAULT_MOTION_FPS
        and frame_count == DEFAULT_MOTION_FRAME_COUNT
        and math.isclose(duration, DEFAULT_MOTION_DURATION, rel_tol=0, abs_tol=1e-9)
    ):
        return {
            "id": TIMING_REVISION_ID,
            "status": "user-approved",
            "approved_at": TIMING_REVISION_APPROVED_AT,
            "only_pending_item": False,
            "baseline": {
                "duration_seconds": APPROVED_BASELINE_DURATION,
                "frame_count": APPROVED_BASELINE_FRAME_COUNT,
            },
            "candidate": {
                "duration_seconds": DEFAULT_MOTION_DURATION,
                "frame_count": DEFAULT_MOTION_FRAME_COUNT,
                "added_full_opacity_frames": [70, 109],
            },
        }
    if (
        fps == DEFAULT_MOTION_FPS
        and frame_count == APPROVED_BASELINE_FRAME_COUNT
        and math.isclose(duration, APPROVED_BASELINE_DURATION, rel_tol=0, abs_tol=1e-9)
    ):
        return {
            "id": "approved-3.75s-baseline",
            "status": "user-approved",
            "only_pending_item": False,
        }
    return {
        "id": "explicit-custom-timing",
        "status": "custom_timing",
        "only_pending_item": False,
    }


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _elements(root: ET.Element, role: str) -> list[ET.Element]:
    return [element for element in root.iter() if element.get("data-graph-role") == role]


def _parse_viewbox(root: ET.Element) -> tuple[float, float, float, float]:
    raw = root.get("viewBox") or root.get("viewbox")
    if not raw:
        raise ValueError("MOTION_VIEWBOX: generated SVG must define a viewBox")
    try:
        values = tuple(float(value) for value in raw.replace(",", " ").split())
    except ValueError as error:
        raise ValueError("MOTION_VIEWBOX: viewBox values must be numeric") from error
    if len(values) != 4 or values[2] <= 0 or values[3] <= 0:
        raise ValueError("MOTION_VIEWBOX: viewBox must contain four positive dimensions")
    return values  # type: ignore[return-value]


def _validate_settings(duration: float, fps: int, width: int) -> int:
    if isinstance(duration, bool) or not isinstance(duration, (int, float)) or not math.isfinite(duration):
        raise ValueError("MOTION_DURATION: duration must be a finite number")
    if duration < 0.5 or duration > 20:
        raise ValueError("MOTION_DURATION: duration must be between 0.5 and 20 seconds")
    if isinstance(fps, bool) or not isinstance(fps, int):
        raise ValueError("MOTION_FPS: fps must be a whole number")
    if fps < 1 or fps > 25:
        raise ValueError("MOTION_FPS: fps must be between 1 and 25")
    if isinstance(width, bool) or not isinstance(width, int):
        raise ValueError("MOTION_WIDTH: width must be a whole number")
    if width < 320 or width > 4096:
        raise ValueError("MOTION_WIDTH: width must be between 320 and 4096 pixels")
    requested_frames = duration * fps
    frame_count = round(requested_frames)
    if abs(requested_frames - frame_count) > 1e-9:
        raise ValueError("MOTION_TIMELINE: duration multiplied by fps must be a whole number of frames")
    if frame_count < MINIMUM_MOTION_FRAME_COUNT:
        raise ValueError(
            f"MOTION_TIMELINE: semantic GIF motion requires at least {MINIMUM_MOTION_FRAME_COUNT} rendered frames"
        )
    if frame_count > 500:
        raise ValueError("MOTION_FRAME_BUDGET: animation may not exceed 500 frames")
    return frame_count


def _validate_render_budget(width: int, height: int, frame_count: int) -> int:
    rendered_pixels = width * height * frame_count
    if rendered_pixels > MAX_RENDERED_PIXELS:
        raise ValueError(
            "MOTION_TOTAL_PIXEL_BUDGET: output dimensions multiplied by frame count may not exceed 600 million pixels"
        )
    return rendered_pixels


def _read_input(path: Path) -> bytes:
    if not path.is_file():
        raise ValueError(f"MOTION_INPUT: input does not exist: {path}")
    size = path.stat().st_size
    if size <= 0:
        raise ValueError("MOTION_INPUT: input is empty")
    if size > MAX_INPUT_BYTES:
        raise ValueError("MOTION_INPUT_SIZE: input may not exceed 20 MiB")
    return path.read_bytes()


def _input_kind(path: Path, source: bytes) -> str:
    if path.suffix.lower() == ".svg" and b"<svg" in source[:4096].lower():
        return "svg"
    raise ValueError("MOTION_INPUT_TYPE: input must be a generated .svg file")


def _validate_semantics(style_id: int, edges: list[ET.Element], nodes: list[ET.Element]) -> dict[str, object]:
    if style_id not in REVIEWED_STYLE_IDS:
        raise ValueError(f"MOTION_STYLE: Style {style_id} does not have a motion preset yet")
    if not edges or not nodes:
        raise ValueError(f"MOTION_METADATA: Style {style_id} requires semantic nodes and edges")
    incomplete = [
        edge.get("data-edge-id", "unknown")
        for edge in edges
        if not edge.get("data-source") or not edge.get("data-target")
    ]
    if incomplete:
        raise ValueError(
            "MOTION_METADATA: semantic edges require source and target metadata: "
            + ", ".join(incomplete)
        )
    explicit: list[ET.Element] = []
    partial: list[str] = []
    unknown_roles: set[str] = set()
    supported_roles = STYLE_MOTION_ROLES[style_id]
    for edge in edges:
        values = (
            edge.get("data-motion-role", ""),
            edge.get("data-motion-stage", ""),
            edge.get("data-motion-order", ""),
        )
        populated = sum(bool(value) for value in values)
        if 0 < populated < 3:
            partial.append(edge.get("data-edge-id", "unknown"))
        elif populated == 3:
            explicit.append(edge)
            if values[0] not in supported_roles:
                unknown_roles.add(values[0])
    if partial:
        raise ValueError(
            "MOTION_METADATA: motion role, stage, and order must be provided together: " + ", ".join(partial)
        )
    if unknown_roles:
        raise ValueError(
            f"MOTION_METADATA: Style {style_id} has unsupported motion roles: "
            + ", ".join(sorted(unknown_roles))
        )
    if not explicit:
        metadata_mode = "topology-fallback"
    elif len(explicit) == len(edges):
        metadata_mode = "explicit"
    else:
        metadata_mode = "hybrid"
    result: dict[str, object] = {
        "edges": len(edges),
        "nodes": len(nodes),
        "motion_metadata": metadata_mode,
        "staged_edges": len(explicit),
        "edges_without_flow": sum(not edge.get("data-flow") for edge in edges),
    }
    if style_id == 10:
        flows = [edge.get("data-flow", "") for edge in edges]
        missing = sorted({"read", "write", "async"} - set(flows))
        if missing:
            raise ValueError(f'MOTION_METADATA: Style 10 is missing flow metadata: {", ".join(missing)}')
        result["flows"] = {flow: flows.count(flow) for flow in sorted(set(flows))}
    elif style_id == 11:
        stations = [node for node in nodes if node.get("data-station-order", "")]
        rails = [edge for edge in edges if edge.get("data-edge-kind") == "rail"]
        branch_kinds = {edge.get("data-edge-kind") for edge in edges}
        if len(stations) < 2 or not rails:
            raise ValueError("MOTION_METADATA: Style 11 requires ordered stations and rail edges")
        if not {"dead_letter", "state"}.issubset(branch_kinds):
            raise ValueError("MOTION_METADATA: Style 11 requires dead-letter and state branches")
        orders = sorted(int(node.get("data-station-order", "-1")) for node in stations)
        if orders != list(range(len(orders))):
            raise ValueError("MOTION_METADATA: Style 11 station order must be contiguous from zero")
        result.update({"stations": len(stations), "rails": len(rails), "branches": 2})
    elif style_id == 12:
        critical = [edge for edge in edges if edge.get("data-critical") == "true"]
        spans = [node for node in nodes if node.get("data-span-id")]
        if not critical or any(not edge.get("data-critical-hop") for edge in critical):
            raise ValueError("MOTION_METADATA: Style 12 critical edges require hop metadata")
        if not spans or any(not node.get("data-duration-ms") for node in spans):
            raise ValueError("MOTION_METADATA: Style 12 trace spans require timing metadata")
        result.update({"critical_hops": len(critical), "trace_spans": len(spans)})
    return result


def _validate_scene_schedule(style_id: int, edges: list[ET.Element]) -> list[dict[str, object]]:
    scene_contract = STYLE_SCENE_CONTRACTS[style_id]
    expected_keys = list(scene_contract["schedule_keys"])
    expected_stages = list(scene_contract["expected_stages"])
    stage_aware = bool(scene_contract.get("stage_aware_schedule_key"))
    keyed_edges: dict[tuple[object, ...], list[ET.Element]] = {}
    for edge in edges:
        role = edge.get("data-motion-role", "")
        try:
            stage = int(edge.get("data-motion-stage", ""))
            order = int(edge.get("data-motion-order", ""))
        except ValueError as error:
            raise ValueError(
                f'MOTION_METADATA: edge {edge.get("data-edge-id", "unknown")} has a non-integer motion stage or order'
            ) from error
        key: tuple[object, ...] = (role, stage, order) if stage_aware else (role, order)
        keyed_edges.setdefault(key, []).append(edge)

    actual_keys = set(keyed_edges)
    expected_key_set = set(expected_keys)
    duplicate_keys = [key for key, values in keyed_edges.items() if len(values) != 1]
    if len(edges) != len(expected_keys) or actual_keys != expected_key_set or duplicate_keys:
        missing = sorted(expected_key_set - actual_keys)
        unexpected = sorted(actual_keys - expected_key_set)
        raise ValueError(
            f"MOTION_METADATA: Style {style_id} schedule must resolve exactly one edge per "
            f"{'(role, stage, order)' if stage_aware else '(role, order)'}; "
            f"missing={missing}, unexpected={unexpected}, duplicate={sorted(duplicate_keys)}"
        )

    resolved: list[dict[str, object]] = []
    for expected_key, expected_stage in zip(expected_keys, expected_stages):
        if stage_aware:
            role, key_stage, order = expected_key
            if key_stage != expected_stage:
                raise ValueError(f"MOTION_CONTRACT: Style {style_id} stage-aware schedule is internally inconsistent")
        else:
            role, order = expected_key
        edge = keyed_edges[expected_key][0]
        actual_stage = int(edge.get("data-motion-stage", ""))
        if actual_stage != expected_stage:
            raise ValueError(
                f"MOTION_METADATA: Style {style_id} route {role}/{order} must use motion stage {expected_stage}"
            )
        resolved.append(
            {
                "edge_id": edge.get("data-edge-id", ""),
                "role": role,
                "stage": actual_stage,
                "order": order,
                "source_stroke": edge.get("stroke", ""),
            }
        )

    if style_id in {2, 3, 4}:
        expected_colors = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT, style_id)["body"][
            "source_colors_in_schedule_order"
        ]
        actual_colors = [entry["source_stroke"] for entry in resolved]
        if actual_colors != expected_colors:
            raise ValueError(
                f"MOTION_METADATA: Style {style_id} semantic route colors changed: "
                f"expected {expected_colors}, got {actual_colors}"
            )
    if style_id == 4:
        semantic_colors = _persistent_stream_contract(DEFAULT_MOTION_FRAME_COUNT, 4)["body"][
            "semantic_colors_in_schedule_order"
        ]
        for entry, semantic_color in zip(resolved, semantic_colors):
            entry["semantic_color"] = semantic_color
    return resolved


def build_motion_plan(
    svg_path: Path,
    preset: str = "auto",
    duration: float = DEFAULT_MOTION_DURATION,
    fps: int = DEFAULT_MOTION_FPS,
    width: Optional[int] = None,
) -> tuple[dict[str, object], object]:
    """Validate a semantic SVG and return its focused GIF motion plan."""

    source_bytes = _read_input(svg_path)
    _input_kind(svg_path, source_bytes)
    resolved_width = 960 if width is None else width
    frame_count = _validate_settings(duration, fps, resolved_width)
    try:
        source_text = source_bytes.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError("MOTION_INPUT: SVG must be UTF-8 encoded") from error
    safe_svg = sanitize_svg(source_text)
    root = ET.fromstring(safe_svg)
    if root.get("data-generator") != "fireworks-tech-graph":
        raise ValueError("MOTION_INPUT: only fireworks-tech-graph generated SVGs are supported")
    if root.get("data-semantic-valid") != "true":
        raise ValueError("MOTION_INPUT: SVG must carry a valid semantic contract")
    try:
        style_id = int(root.get("data-style-id", "0"))
    except ValueError as error:
        raise ValueError("MOTION_STYLE: SVG has an invalid style id") from error
    if style_id not in REVIEWED_STYLE_IDS:
        raise ValueError(
            f"MOTION_STYLE_REVIEW: Style {style_id} is unsupported; enabled styles are 1-12"
        )
    scene_contract = STYLE_SCENE_CONTRACTS[style_id]
    resolved_preset = STYLE_PRESETS.get(style_id) if preset == "auto" else preset
    if not resolved_preset or resolved_preset not in PRESET_STYLES:
        raise ValueError(f"MOTION_PRESET: unsupported preset: {preset}")
    expected_style = PRESET_STYLES[resolved_preset]
    if style_id != expected_style:
        raise ValueError(
            f"MOTION_PRESET: {resolved_preset} belongs to Style {expected_style}, input is Style {style_id}"
        )

    edges = _elements(root, "edge")
    nodes = _elements(root, "node")
    semantics = _validate_semantics(style_id, edges, nodes)
    if semantics.get("motion_metadata") != "explicit":
        raise ValueError("MOTION_METADATA: reviewed styles require explicit motion metadata on every edge")
    resolved_schedule = _validate_scene_schedule(style_id, edges)
    if style_id in set(range(2, 13)):
        semantics["schedule_key"] = "(data-motion-role, data-motion-order)"
        if scene_contract.get("stage_aware_schedule_key"):
            semantics["schedule_key"] = "(data-motion-role, data-motion-stage, data-motion-order)"
        semantics["resolved_schedule"] = resolved_schedule
    check_results: dict[str, object] = {}
    for check in CHECKS:
        passed, details = run_check(svg_path, check)
        check_results[check] = {"ok": passed, "details": details}
        if not passed:
            raise ValueError(f"MOTION_SOURCE_CHECK: {check} failed: {details}")

    viewbox = _parse_viewbox(root)
    height = max(1, round(resolved_width * viewbox[3] / viewbox[2]))
    if height > 4096 or resolved_width * height > 16_777_216:
        raise ValueError("MOTION_DIMENSIONS: output must stay within 4096px per side and 16 megapixels")
    rendered_pixels = _validate_render_budget(resolved_width, height, frame_count)
    timing_revision = _timing_revision(duration, fps, frame_count)
    style_contract: dict[str, object] = {
        "status": "user-approved",
        "scope": "signature-speed-path-geometry-and-construction-schedule",
        "source_policy": "semantic-schedule-and-geometry-not-exact-byte-hash",
    }
    if style_id >= 5:
        style_contract["approval_recorded_on"] = "2026-07-16"
    plan: dict[str, object] = {
        "ok": True,
        "dry_run": True,
        "source": str(svg_path),
        "source_sha256": _sha256_bytes(source_bytes),
        "review_reference_source_sha256": scene_contract.get("source_sha256"),
        "fixture_sha256": scene_contract.get("fixture_sha256"),
        "input_kind": "svg",
        "style_id": style_id,
        "visual_theme": root.get("data-visual-theme"),
        "semantic_profile": root.get("data-semantic-profile"),
        "motion_scene": root.get("data-motion-scene") or resolved_preset,
        "motion_class": "semantic",
        "preset": resolved_preset,
        "motion_grammar_version": MOTION_GRAMMAR_VERSION,
        "motion_grammar": _motion_grammar(duration, fps, frame_count, style_id),
        "scene_signature": SCENE_SIGNATURES[style_id],
        "review_status": timing_revision["status"],
        "style_contract_status": "user-approved",
        "style_contract": style_contract,
        "timing_revision": timing_revision,
        "animation_contract": _draw_on_contract(frame_count, style_id),
        "duration_seconds": duration,
        "fps": fps,
        "frame_count": frame_count,
        "width": resolved_width,
        "height": height,
        "rendered_pixels": rendered_pixels,
        "seamless_loop_contract": (
            "75 frames or fewer: every raster is unique; more than 75 frames: non-adjacent "
            "repeats are allowed within the full-opacity interval, plus the sole intentional "
            "reset-boundary exception at reset_start with opacity 1.00, with at least 75 unique "
            "rasters; seam MAD must not exceed p95 adjacent-frame MAD"
        ),
        "frame_uniqueness_contract": {
            "strict_all_unique_through_frame_count": APPROVED_BASELINE_FRAME_COUNT,
            "minimum_unique_rasters_for_long_timeline": APPROVED_BASELINE_FRAME_COUNT,
            "long_timeline_repeat_scope": [38, frame_count - len(RESET_OPACITY_SAMPLES) - 1],
            "intentional_reset_boundary_repeat_frame": (
                frame_count - len(RESET_OPACITY_SAMPLES)
            ),
            "intentional_reset_boundary_opacity": RESET_OPACITY_SAMPLES[0],
            "adjacent_duplicates_allowed": False,
            "opening_construction_and_reset_tail_globally_distinct": True,
        },
        "semantics": semantics,
        "source_checks": check_results,
    }
    return plan, safe_svg


def probe_motion_runtime() -> dict[str, object]:
    node = shutil.which("node")
    ffmpeg = shutil.which("ffmpeg")
    ffprobe = shutil.which("ffprobe")
    result: dict[str, object] = {
        "ok": False,
        "node": node,
        "ffmpeg": ffmpeg,
        "ffprobe": ffprobe,
        "worker": str(MOTION_WORKER),
    }
    if not node or not MOTION_WORKER.is_file():
        result["error"] = "Node.js or scripts/svg2gif.js is unavailable"
        return result
    try:
        version_process = subprocess.run([node, "--version"], capture_output=True, text=True, timeout=5)
        version_text = version_process.stdout.strip().lstrip("v")
        result["node_version"] = version_text
        if version_process.returncode or tuple(int(part) for part in version_text.split(".")[:3]) < (22, 12, 0):
            result["error"] = "MOTION_NODE_VERSION: puppeteer-core 25.3.0 requires Node.js >=22.12.0"
            return result
    except (OSError, ValueError, subprocess.TimeoutExpired):
        result["error"] = "MOTION_NODE_VERSION: could not determine a supported Node.js version"
        return result
    try:
        process = subprocess.run(
            [node, str(MOTION_WORKER), "--probe"],
            text=True,
            capture_output=True,
            check=False,
            timeout=MOTION_TIMEOUTS["runtime_probe"],
        )
    except subprocess.TimeoutExpired:
        result["error"] = "MOTION_RUNTIME_TIMEOUT: renderer probe exceeded 15 seconds"
        return result
    try:
        worker = json.loads(process.stdout.strip().splitlines()[-1]) if process.stdout.strip() else {}
    except (IndexError, json.JSONDecodeError):
        worker = {"ok": False, "error": process.stderr.strip() or "motion runtime probe returned invalid JSON"}
    encoders: set[str] = set()
    encoder_error: Optional[str] = None
    if ffmpeg:
        try:
            encoder_process = subprocess.run(
                [ffmpeg, "-nostdin", "-hide_banner", "-encoders"],
                text=True,
                capture_output=True,
                check=False,
                timeout=MOTION_TIMEOUTS["runtime_probe"],
            )
            if encoder_process.returncode == 0:
                for line in encoder_process.stdout.splitlines():
                    match = re.match(r"^\s*[VASFXBD\.]{6}\s+([A-Za-z0-9_][^\s]*)", line)
                    if match:
                        encoders.add(match.group(1))
            else:
                encoder_error = encoder_process.stderr.strip() or "FFmpeg encoder discovery failed"
        except subprocess.TimeoutExpired:
            encoder_error = "MOTION_RUNTIME_TIMEOUT: FFmpeg encoder probe exceeded 15 seconds"
    result["renderer"] = worker
    result["encoders"] = sorted(encoders.intersection({"gif"}))
    result["format"] = {"gif": bool(ffmpeg and "gif" in encoders)}
    if encoder_error:
        result["encoder_probe_error"] = encoder_error
    result["ok"] = bool(
        ffmpeg
        and ffprobe
        and "gif" in encoders
        and process.returncode == 0
        and worker.get("ok")
    )
    if not result["ok"] and "error" not in result:
        result["error"] = (
            worker.get("error")
            or process.stderr.strip()
            or ("FFprobe is unavailable" if not ffprobe else "motion dependencies are incomplete")
        )
    return result


def _last_json_line(output: str, label: str) -> dict[str, object]:
    for line in reversed(output.splitlines()):
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    raise RuntimeError(f"{label} did not return a JSON result")


def _stage_json(path: Path, value: dict[str, object]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    if os.path.lexists(path) and path.is_dir():
        raise ValueError("MOTION_REPORT: report target must be a file path")
    temporary = path.with_name(f".{path.name}.{uuid.uuid4().hex}.tmp")
    try:
        temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        return temporary
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def _commit_artifacts(staged_targets: list[tuple[Path, Path]]) -> None:
    """Install related artifacts together and restore every previous target on failure."""

    for staged, target in staged_targets:
        if not staged.is_file():
            raise RuntimeError(f"MOTION_COMMIT: staged artifact is unavailable: {staged}")
        target.parent.mkdir(parents=True, exist_ok=True)
        if os.path.lexists(target) and target.is_dir():
            raise ValueError(f"MOTION_COMMIT: artifact target must be a file path: {target}")

    backups: dict[Path, Optional[Path]] = {}
    installed: set[Path] = set()
    try:
        for staged, target in staged_targets:
            backup: Optional[Path] = None
            if os.path.lexists(target):
                backup = target.with_name(f".{target.name}.{uuid.uuid4().hex}.rollback")
                backups[target] = backup
                os.replace(target, backup)
            else:
                backups[target] = None
            os.replace(staged, target)
            installed.add(target)
    except Exception as error:
        rollback_errors: list[str] = []
        for _staged, target in reversed(staged_targets):
            backup = backups.get(target)
            try:
                if target in installed and os.path.lexists(target):
                    target.unlink()
                if backup is not None and os.path.lexists(backup):
                    os.replace(backup, target)
            except OSError as rollback_error:
                rollback_errors.append(f"{target}: {rollback_error}")
        if rollback_errors:
            raise RuntimeError(
                "MOTION_COMMIT_ROLLBACK: artifact commit failed and rollback was incomplete: "
                + "; ".join(rollback_errors)
            ) from error
        raise
    else:
        for backup in backups.values():
            if backup is not None:
                backup.unlink(missing_ok=True)
    finally:
        for staged, _target in staged_targets:
            staged.unlink(missing_ok=True)


def _probe_media(path: Path) -> dict[str, object]:
    ffprobe = shutil.which("ffprobe")
    if not ffprobe:
        raise RuntimeError("MOTION_MEDIA_PROBE: FFprobe is required to validate encoded motion")
    try:
        process = subprocess.run(
            [
                ffprobe,
                "-v",
                "error",
                "-count_frames",
                "-select_streams",
                "v:0",
                "-show_entries",
                "stream=codec_name,width,height,duration,nb_frames,nb_read_frames,r_frame_rate,pix_fmt:format=format_name,duration",
                "-of",
                "json",
                "-protocol_whitelist",
                "file,pipe",
                str(path.resolve()),
            ],
            text=True,
            capture_output=True,
            check=False,
            timeout=MOTION_TIMEOUTS["media_probe"],
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError("MOTION_MEDIA_PROBE_TIMEOUT: FFprobe exceeded 30 seconds") from error
    if process.returncode != 0:
        return {"error": process.stderr.strip()}
    try:
        payload = json.loads(process.stdout)
        streams = payload.get("streams", [])
    except (AttributeError, json.JSONDecodeError):
        return {"error": "ffprobe returned invalid JSON"}
    if not streams:
        return {"error": "ffprobe found no video stream"}
    result = dict(streams[0])
    if isinstance(payload.get("format"), dict):
        result["container"] = payload["format"]
        if not result.get("duration") and payload["format"].get("duration"):
            result["duration"] = payload["format"]["duration"]
    return result


def _validate_encoded_gif(
    media_probe: dict[str, object],
    expected_width: int,
    expected_height: int,
    expected_frames: int,
    expected_duration: float,
) -> None:
    if media_probe.get("error"):
        raise RuntimeError(f'MOTION_MEDIA_PROBE: {media_probe["error"]}')
    if media_probe.get("codec_name") != "gif":
        raise RuntimeError(
            f'MOTION_CODEC: expected gif, encoded {media_probe.get("codec_name", "unknown")}'
        )
    if int(str(media_probe.get("width", -1))) != expected_width:
        raise RuntimeError("MOTION_DIMENSIONS: encoded media width differs from the motion plan")
    if int(str(media_probe.get("height", -1))) != expected_height:
        raise RuntimeError("MOTION_DIMENSIONS: encoded media height differs from the motion plan")
    encoded_frames = media_probe.get("nb_read_frames") or media_probe.get("nb_frames")
    if encoded_frames is None:
        raise RuntimeError("MOTION_FRAMES: media probe did not report an encoded frame count")
    encoded_frame_count = int(str(encoded_frames))
    if encoded_frame_count != expected_frames:
        raise RuntimeError("MOTION_FRAMES: encoded media frame count differs from the motion plan")
    if media_probe.get("duration") is None:
        raise RuntimeError("MOTION_DURATION: media probe did not report encoded duration")
    encoded_duration = float(str(media_probe["duration"]))
    if abs(encoded_duration - expected_duration) > 0.03:
        raise RuntimeError(
            f"MOTION_DURATION: requested {expected_duration}s, encoder produced {encoded_duration}s"
        )


def _read_gif_loop_count(path: Path) -> Optional[int]:
    """Return the Netscape/ANIMEXTS repeat count embedded in a GIF."""

    data = path.read_bytes()
    if data[:6] not in (b"GIF87a", b"GIF89a"):
        return None
    for application in (b"NETSCAPE2.0", b"ANIMEXTS1.0"):
        marker = b"\x21\xff\x0b" + application + b"\x03\x01"
        offset = data.find(marker)
        if offset < 0:
            continue
        value_offset = offset + len(marker)
        if value_offset + 3 > len(data) or data[value_offset + 2] != 0:
            return None
        return int.from_bytes(data[value_offset : value_offset + 2], "little")
    return None


def _validate_gif_loop(path: Path) -> int:
    loop_count = _read_gif_loop_count(path)
    if loop_count is None:
        raise RuntimeError("MOTION_LOOP: encoded GIF has no readable loop extension")
    if loop_count != 0:
        raise RuntimeError(
            f"MOTION_LOOP: encoded GIF repeats {loop_count} time(s), expected infinite looping"
        )
    return loop_count


def _run_encoder(command: list[str], label: str) -> subprocess.CompletedProcess[str]:
    try:
        process = subprocess.run(
            command,
            text=True,
            capture_output=True,
            check=False,
            timeout=MOTION_TIMEOUTS["encode"],
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"MOTION_ENCODE_TIMEOUT: {label} exceeded 120 seconds") from error
    if process.returncode != 0:
        raise RuntimeError(f"MOTION_ENCODE: {process.stderr.strip() or process.stdout.strip()}")
    return process


def _signalstats_values(output: str) -> list[float]:
    return [float(value) for value in re.findall(r"lavfi\.signalstats\.YAVG=([0-9.eE+-]+)", output)]


def _summarize_delta_quality(
    adjacent_yavg: list[float],
    seam_yavg: float,
    changed_area_yavg: float,
) -> dict[str, object]:
    values = sorted(adjacent_yavg)
    if not values or any(not math.isfinite(value) or value < 0 for value in (*values, seam_yavg, changed_area_yavg)):
        raise RuntimeError("MOTION_DELTA: frame-delta metrics are missing or invalid")
    p95 = values[max(0, math.ceil(len(values) * 0.95) - 1)]
    median = values[len(values) // 2]
    seam_within_p95 = seam_yavg <= p95
    result: dict[str, object] = {
        "metric": "normalized-luma-mean-absolute-difference",
        "adjacent_min": values[0] / 255,
        "adjacent_median": median / 255,
        "adjacent_p95": p95 / 255,
        "adjacent_max": values[-1] / 255,
        "seam": seam_yavg / 255,
        "seam_within_adjacent_p95": seam_within_p95,
        "changed_area_ratio": min(1.0, changed_area_yavg / 255),
        "changed_area_method": "accumulated adjacent luma delta greater than 2 percent",
    }
    if not seam_within_p95:
        raise RuntimeError("MOTION_LOOP: loop seam exceeds the p95 adjacent-frame delta")
    return result


def _probe_frame_deltas(ffmpeg: str, frames: Path, fps: int, frame_count: int) -> dict[str, object]:
    pattern = str(frames / "frame-%06d.png")
    adjacent = _run_encoder(
        [
            ffmpeg,
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-framerate",
            str(fps),
            "-start_number",
            "0",
            "-i",
            pattern,
            "-vf",
            "tblend=all_mode=difference,signalstats,metadata=print:file=-",
            "-f",
            "null",
            "-",
        ],
        "adjacent frame-delta probe",
    )
    adjacent_values = _signalstats_values(adjacent.stdout)
    if len(adjacent_values) != frame_count - 1:
        raise RuntimeError("MOTION_DELTA: adjacent frame-delta probe returned an unexpected sample count")

    seam = _run_encoder(
        [
            ffmpeg,
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(frames / f"frame-{frame_count - 1:06d}.png"),
            "-i",
            str(frames / "frame-000000.png"),
            "-filter_complex",
            "[0:v][1:v]blend=all_mode=difference,signalstats,metadata=print:file=-",
            "-frames:v",
            "1",
            "-f",
            "null",
            "-",
        ],
        "loop-seam frame-delta probe",
    )
    seam_values = _signalstats_values(seam.stdout)
    if len(seam_values) != 1:
        raise RuntimeError("MOTION_DELTA: loop-seam probe returned an unexpected sample count")

    delta_frames = frame_count - 1
    weights = " ".join("1" for _ in range(delta_frames))
    coverage_filter = (
        "tblend=all_mode=difference,format=gray,"
        f"tmix=frames={delta_frames}:weights='{weights}':scale=1,"
        "lut=y='if(gt(val,5.1),255,0)',signalstats,metadata=print:file=-"
    )
    coverage = _run_encoder(
        [
            ffmpeg,
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-framerate",
            str(fps),
            "-start_number",
            "0",
            "-i",
            pattern,
            "-vf",
            coverage_filter,
            "-f",
            "null",
            "-",
        ],
        "changed-area probe",
    )
    coverage_values = _signalstats_values(coverage.stdout)
    if len(coverage_values) != delta_frames:
        raise RuntimeError("MOTION_DELTA: changed-area probe returned an unexpected sample count")
    return _summarize_delta_quality(adjacent_values, seam_values[0], coverage_values[-1])


def _summarize_frame_hashes(
    hashes: list[str],
    full_opacity_frames: tuple[int, int],
    *,
    algorithm: str,
    raster_kind: str,
) -> dict[str, object]:
    groups: dict[str, list[int]] = {}
    for index, frame_hash in enumerate(hashes):
        groups.setdefault(frame_hash, []).append(index)
    repeated = [
        {"hash": frame_hash, "frame_indices": indices}
        for frame_hash, indices in groups.items()
        if len(indices) > 1
    ]
    adjacent_duplicates = [
        [index, index + 1]
        for index in range(len(hashes) - 1)
        if hashes[index] == hashes[index + 1]
    ]
    if adjacent_duplicates:
        raise RuntimeError(
            f"MOTION_LOOP: {raster_kind} contains adjacent duplicate frames: {adjacent_duplicates}"
        )

    unique_count = len(groups)
    strict_all_unique = len(hashes) <= APPROVED_BASELINE_FRAME_COUNT
    minimum_unique = len(hashes) if strict_all_unique else APPROVED_BASELINE_FRAME_COUNT
    if strict_all_unique and repeated:
        raise RuntimeError(
            f"MOTION_LOOP: every {raster_kind} frame must be unique for timelines of "
            f"{APPROVED_BASELINE_FRAME_COUNT} frames or fewer"
        )
    if unique_count < minimum_unique:
        raise RuntimeError(
            f"MOTION_LOOP: {raster_kind} requires at least {minimum_unique} unique frames; "
            f"found {unique_count}"
        )

    repeat_scope_start, repeat_scope_end = full_opacity_frames
    reset_boundary_frame = repeat_scope_end + 1
    classified_repeats = []
    for evidence in repeated:
        indices = evidence["frame_indices"]
        if all(repeat_scope_start <= index <= repeat_scope_end for index in indices):
            classification = "steady_state_periodic_repeat"
        elif (
            reset_boundary_frame in indices
            and all(repeat_scope_start <= index <= reset_boundary_frame for index in indices)
        ):
            classification = "intentional_reset_boundary_repeat"
        else:
            classification = "outside_permitted_repeat_scope"
        classified_repeats.append({**evidence, "classification": classification})
    outside_scope = [
        evidence
        for evidence in classified_repeats
        if evidence["classification"] == "outside_permitted_repeat_scope"
    ]
    if outside_scope:
        raise RuntimeError(
            f"MOTION_LOOP: repeated {raster_kind} frames must stay inside full-opacity frames "
            f"{repeat_scope_start}-{repeat_scope_end}, except reset boundary frame "
            f"{reset_boundary_frame} at opacity 1.00: {outside_scope}"
        )

    intentional_reset_boundary_repeats = [
        evidence
        for evidence in classified_repeats
        if evidence["classification"] == "intentional_reset_boundary_repeat"
    ]
    repeats_confined_to_full_opacity = not intentional_reset_boundary_repeats

    return {
        "algorithm": algorithm,
        "frame_count": len(hashes),
        "unique_frame_count": unique_count,
        "minimum_unique_frame_count": minimum_unique,
        "all_frames_unique": not repeated,
        "adjacent_duplicate_count": 0,
        "adjacent_duplicate_pairs": [],
        "repeat_scope": [repeat_scope_start, repeat_scope_end],
        "intentional_reset_boundary_repeat_frame": reset_boundary_frame,
        "intentional_reset_boundary_opacity": RESET_OPACITY_SAMPLES[0],
        "repeat_scope_policy": (
            "all-frames-unique"
            if strict_all_unique
            else "non-adjacent-repeats-inside-full-opacity-plus-reset-start-boundary"
        ),
        "repeated_frame_group_count": len(classified_repeats),
        "repeated_frame_index_evidence": classified_repeats,
        "intentional_reset_boundary_repeat_count": len(intentional_reset_boundary_repeats),
        "intentional_reset_boundary_repeat_evidence": intentional_reset_boundary_repeats,
        "repeats_confined_to_full_opacity": repeats_confined_to_full_opacity,
        "repeats_confined_to_permitted_scope": True,
        "opening_construction_and_reset_tail_globally_distinct": True,
        "first_frame_hash": hashes[0],
        "last_frame_hash": hashes[-1],
    }


def _probe_encoded_frame_hashes(
    ffmpeg: str,
    gif: Path,
    expected_frames: int,
    full_opacity_frames: tuple[int, int],
) -> dict[str, object]:
    process = _run_encoder(
        [
            ffmpeg,
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(gif),
            "-map",
            "0:v:0",
            "-f",
            "framemd5",
            "-",
        ],
        "encoded GIF frame-hash probe",
    )
    hashes = re.findall(r",\s*([0-9a-f]{32})\s*$", process.stdout, flags=re.MULTILINE)
    if len(hashes) != expected_frames:
        raise RuntimeError("MOTION_FRAMES: encoded frame-hash probe returned an unexpected frame count")
    return _summarize_frame_hashes(
        hashes,
        full_opacity_frames,
        algorithm="framemd5",
        raster_kind="encoded GIF",
    )


def _gif_command(ffmpeg: str, frames: Path, fps: int, output: Path) -> list[str]:
    return [
        ffmpeg,
        "-nostdin",
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-framerate",
        str(fps),
        "-i",
        str(frames / "frame-%06d.png"),
        "-filter_complex",
        "[0:v]split[a][b];[a]palettegen=stats_mode=full:max_colors=256[p];"
        "[b][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle",
        "-loop",
        "0",
        "-map_metadata",
        "-1",
        str(output.resolve()),
    ]


def _encode_gif(
    frames: Path,
    fps: int,
    output: Path,
    runtime: dict[str, object],
) -> str:
    ffmpeg = str(runtime["ffmpeg"])
    _run_encoder(_gif_command(ffmpeg, frames, fps, output), "GIF encoder")
    return "ffmpeg/gif-palette"


def _size_guidance(
    artifact_bytes: int,
) -> dict[str, object]:
    warnings: list[str] = []
    if artifact_bytes > MOTION_SIZE_TARGET_BYTES:
        warnings.append("GIF exceeds 500 KB; reduce width, duration, or frame rate before distribution.")
    return {
        "artifact_target_bytes": MOTION_SIZE_TARGET_BYTES,
        "artifact_within_target": artifact_bytes <= MOTION_SIZE_TARGET_BYTES,
        "warnings": warnings,
    }


def render_motion_gif(
    svg_path: Path,
    output_path: Path,
    report_path: Optional[Path] = None,
    preset: str = "auto",
    duration: float = DEFAULT_MOTION_DURATION,
    fps: int = DEFAULT_MOTION_FPS,
    width: Optional[int] = None,
    dry_run: bool = False,
) -> dict[str, object]:
    """Render one generated semantic SVG to one validated, atomic GIF artifact."""

    source_target = svg_path.resolve()
    gif_target = output_path.resolve()
    if source_target == gif_target:
        raise ValueError("MOTION_OUTPUT: output path must differ from the input path")
    if output_path.suffix.lower() != MOTION_FORMAT["suffix"]:
        raise ValueError("MOTION_OUTPUT: output path must end in .gif")
    if report_path and report_path.resolve() in {source_target, gif_target}:
        raise ValueError("MOTION_REPORT: report path must differ from the input and GIF paths")

    plan, prepared_source = build_motion_plan(
        svg_path,
        preset=preset,
        duration=duration,
        fps=fps,
        width=width,
    )
    encoded_width = int(plan["width"])
    encoded_height = int(plan["height"])
    plan.update(
        {
            "output": str(output_path),
            "report": str(report_path) if report_path else None,
            "output_format": MOTION_FORMAT["name"],
            "mime_type": MOTION_FORMAT["mime"],
            "loop_playback": MOTION_FORMAT["loop_playback"],
            "encoded_dimensions": {"width": encoded_width, "height": encoded_height},
            "required_encoder": "ffmpeg/gif",
        }
    )
    if dry_run:
        return plan

    runtime = probe_motion_runtime()
    if not runtime.get("ok"):
        raise RuntimeError(f'MOTION_RUNTIME: {runtime.get("error", "motion dependencies are unavailable")}')
    available = runtime.get("format")
    if not isinstance(available, dict) or not available.get("gif"):
        raise RuntimeError("MOTION_FORMAT_UNAVAILABLE: GIF encoder is unavailable")

    node = str(runtime["node"])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_gif = output_path.with_name(f".{output_path.stem}.{uuid.uuid4().hex}.tmp.gif")
    temporary_report: Optional[Path] = None
    source_hash = str(plan["source_sha256"])

    try:
        with tempfile.TemporaryDirectory(prefix="fireworks-motion-") as directory:
            work = Path(directory)
            source = work / "source.svg"
            frames = work / "frames"
            source.write_text(str(prepared_source), encoding="utf-8")
            frames.mkdir()
            try:
                render_process = subprocess.run(
                    [
                        node,
                        str(MOTION_WORKER),
                        "--input",
                        str(source),
                        "--frames-dir",
                        str(frames),
                        "--preset",
                        str(plan["preset"]),
                        "--duration",
                        str(duration),
                        "--fps",
                        str(fps),
                        "--width",
                        str(plan["width"]),
                        "--height",
                        str(plan["height"]),
                    ],
                    text=True,
                    capture_output=True,
                    check=False,
                    timeout=MOTION_TIMEOUTS["render"],
                )
            except subprocess.TimeoutExpired as error:
                raise RuntimeError("MOTION_RENDER_TIMEOUT: frame rendering exceeded 120 seconds") from error
            if render_process.returncode != 0:
                raise RuntimeError(f"MOTION_RENDER: {render_process.stderr.strip() or render_process.stdout.strip()}")
            worker = _last_json_line(render_process.stdout, "motion renderer")
            frame_files = sorted(frames.glob("frame-*.png"))
            if len(frame_files) != plan["frame_count"]:
                raise RuntimeError(f'MOTION_FRAMES: expected {plan["frame_count"]} frames, rendered {len(frame_files)}')
            frame_hashes = [_sha256(frame) for frame in frame_files]
            first_hash = frame_hashes[0]
            last_hash = frame_hashes[-1]
            stream_contract = plan["animation_contract"]["persistent_data_flow"]
            full_opacity_values = stream_contract["full_opacity_frames"]
            full_opacity_frames = (int(full_opacity_values[0]), int(full_opacity_values[1]))
            raw_frame_hashes = _summarize_frame_hashes(
                frame_hashes,
                full_opacity_frames,
                algorithm="sha256",
                raster_kind="raw Chromium raster",
            )
            delta_quality = _probe_frame_deltas(
                str(runtime["ffmpeg"]),
                frames,
                fps,
                int(plan["frame_count"]),
            )

            encoder = _encode_gif(frames, fps, temporary_gif, runtime)
            if not temporary_gif.is_file() or temporary_gif.stat().st_size == 0:
                raise RuntimeError("MOTION_ENCODE: encoder produced an empty GIF artifact")
            media_probe = _probe_media(temporary_gif)
            _validate_encoded_gif(
                media_probe,
                encoded_width,
                encoded_height,
                int(plan["frame_count"]),
                duration,
            )
            loop_count = _validate_gif_loop(temporary_gif)
            encoded_frame_hashes = _probe_encoded_frame_hashes(
                str(runtime["ffmpeg"]),
                temporary_gif,
                int(plan["frame_count"]),
                full_opacity_frames,
            )

        source_hash_after = _sha256(svg_path)
        if source_hash_after != source_hash:
            raise RuntimeError("MOTION_SOURCE_MUTATED: source SVG changed during GIF rendering")
        artifact_bytes = temporary_gif.stat().st_size
        result = dict(plan)
        result.update(
            {
                "dry_run": False,
                "runtime": runtime,
                "renderer": worker,
                "source_integrity": {
                    "sha256": source_hash,
                    "sha256_before": source_hash,
                    "sha256_after": source_hash_after,
                    "unchanged": True,
                },
                "loop": {
                    "first_frame_sha256": first_hash,
                    "last_frame_sha256": last_hash,
                    "unique_frame_count": raw_frame_hashes["unique_frame_count"],
                    "minimum_unique_frame_count": raw_frame_hashes["minimum_unique_frame_count"],
                    "all_frames_unique": raw_frame_hashes["all_frames_unique"],
                    "adjacent_duplicate_count": raw_frame_hashes["adjacent_duplicate_count"],
                    "repeat_scope": raw_frame_hashes["repeat_scope"],
                    "repeat_scope_policy": raw_frame_hashes["repeat_scope_policy"],
                    "repeated_frame_index_evidence": raw_frame_hashes[
                        "repeated_frame_index_evidence"
                    ],
                    "intentional_reset_boundary_repeat_count": raw_frame_hashes[
                        "intentional_reset_boundary_repeat_count"
                    ],
                    "intentional_reset_boundary_repeat_evidence": raw_frame_hashes[
                        "intentional_reset_boundary_repeat_evidence"
                    ],
                    "repeats_confined_to_full_opacity": raw_frame_hashes[
                        "repeats_confined_to_full_opacity"
                    ],
                    "repeats_confined_to_permitted_scope": raw_frame_hashes[
                        "repeats_confined_to_permitted_scope"
                    ],
                    "opening_construction_and_reset_tail_globally_distinct": raw_frame_hashes[
                        "opening_construction_and_reset_tail_globally_distinct"
                    ],
                    "sampling": "uniform-frame-centers",
                    "delta_quality": delta_quality,
                    "raw_frames": raw_frame_hashes,
                    "encoded_frames": encoded_frame_hashes,
                    "playback": MOTION_FORMAT["loop_playback"],
                    "embedded_loop_count": loop_count,
                },
                "artifact": {
                    "path": str(output_path),
                    "format": MOTION_FORMAT["name"],
                    "mime_type": MOTION_FORMAT["mime"],
                    "encoder": encoder,
                    "bytes": artifact_bytes,
                    "sha256": _sha256(temporary_gif),
                    "probe": media_probe,
                    "source_frame_count": plan["frame_count"],
                },
                "size_guidance": _size_guidance(artifact_bytes),
            }
        )
        if report_path:
            temporary_report = _stage_json(report_path, result)
        staged_targets = [(temporary_gif, output_path)]
        if report_path and temporary_report:
            staged_targets.append((temporary_report, report_path))
        _commit_artifacts(staged_targets)
        return result
    finally:
        temporary_gif.unlink(missing_ok=True)
        if temporary_report:
            temporary_report.unlink(missing_ok=True)
