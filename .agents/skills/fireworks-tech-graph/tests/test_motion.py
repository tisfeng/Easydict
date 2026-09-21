from __future__ import annotations

import importlib.util
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_DIR = ROOT / "scripts"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from motion import (  # noqa: E402
    DEFAULT_MOTION_DURATION,
    DEFAULT_MOTION_FRAME_COUNT,
    DEFAULT_MOTION_FPS,
    DRAW_ON_CONTRACT,
    DRAW_SCHEDULE,
    MINIMUM_MOTION_FRAME_COUNT,
    MOTION_FORMAT,
    MOTION_GRAMMAR_VERSION,
    PERSISTENT_STREAM_CONTRACT,
    RESET_OPACITY_SAMPLES,
    REVIEWED_STYLE_IDS,
    STYLE_2_DRAW_ON_CONTRACT,
    STYLE_2_DRAW_SCHEDULE,
    STYLE_2_PERSISTENT_STREAM_CONTRACT,
    STYLE_3_DRAW_ON_CONTRACT,
    STYLE_3_DRAW_SCHEDULE,
    STYLE_3_PERSISTENT_STREAM_CONTRACT,
    STYLE_4_DRAW_ON_CONTRACT,
    STYLE_4_DRAW_SCHEDULE,
    STYLE_4_PERSISTENT_STREAM_CONTRACT,
    STYLE_SCENE_CONTRACTS,
    TERMINAL_SIGNATURE_CONTRACT,
    _commit_artifacts,
    _read_gif_loop_count,
    _size_guidance,
    _summarize_frame_hashes,
    _summarize_delta_quality,
    _validate_encoded_gif,
    _validate_gif_loop,
    build_motion_plan,
    render_motion_gif,
)


def load_generator():
    spec = importlib.util.spec_from_file_location("motion_test_generator", SCRIPT_DIR / "generate-from-template.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("generator loader is unavailable")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


generator = load_generator()
QUALITY_SNAPSHOTS = json.loads((ROOT / "tests/snapshots/quality-upgrade.json").read_text())["styles"]


def _imagemagick_command(*arguments: str) -> list[str]:
    magick = shutil.which("magick")
    if magick:
        return [magick, *arguments]
    if arguments and arguments[0] in {"compare", "identify", "montage"}:
        executable = shutil.which(arguments[0])
        if executable:
            return [executable, *arguments[1:]]
    convert = shutil.which("convert")
    if convert:
        return [convert, *arguments]
    raise RuntimeError("ImageMagick is unavailable")


def _imagemagick_available() -> bool:
    return bool(shutil.which("magick") or (shutil.which("compare") and shutil.which("convert")))


def _image_compare_metric(left: Path, right: Path, metric: str) -> str:
    process = subprocess.run(
        _imagemagick_command("compare", "-metric", metric, str(left), str(right), "null:"),
        text=True,
        capture_output=True,
        check=False,
    )
    if process.returncode not in (0, 1):
        raise RuntimeError(process.stderr or process.stdout or f"ImageMagick {metric} failed")
    return (process.stderr or process.stdout).strip()


def _orthogonal_edge_segments(svg: Path) -> list[tuple[float, float, float, float]]:
    root = ET.parse(svg).getroot()
    segments: list[tuple[float, float, float, float]] = []
    token_pattern = re.compile(r"[MLHVZ]|-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?")
    for element in root.iter():
        if element.get("data-graph-role") != "edge":
            continue
        tokens = token_pattern.findall(element.get("d") or "")
        index = 0
        command = ""
        current: tuple[float, float] | None = None
        while index < len(tokens):
            token = tokens[index]
            if token in {"M", "L", "H", "V", "Z"}:
                command = token
                index += 1
                if command == "Z":
                    continue
            if command in {"M", "L"} and index + 1 < len(tokens):
                point = (float(tokens[index]), float(tokens[index + 1]))
                index += 2
            elif command == "H" and current is not None:
                point = (float(tokens[index]), current[1])
                index += 1
            elif command == "V" and current is not None:
                point = (current[0], float(tokens[index]))
                index += 1
            else:
                break
            if current is not None and command != "M":
                segments.append((*current, *point))
            current = point
            if command == "M":
                command = "L"
    return segments


def _node_bounds(svg: Path) -> list[tuple[float, float, float, float]]:
    root = ET.parse(svg).getroot()
    bounds = []
    for element in root.iter():
        if element.get("data-graph-role") != "node":
            continue
        raw = element.get("data-graph-bounds")
        if not raw:
            continue
        values = [float(value) for value in raw.split(",")]
        if len(values) == 4:
            bounds.append((values[0], values[1], values[2], values[3]))
    return bounds


def _point_to_segment_distance(
    x: float,
    y: float,
    segment: tuple[float, float, float, float],
) -> float:
    x1, y1, x2, y2 = segment
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(x - x1, y - y1)
    projection = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - (x1 + projection * dx), y - (y1 + projection * dy))


def _component_is_on_edge_or_node_border(
    component: dict[str, int],
    segments: list[tuple[float, float, float, float]],
    nodes: list[tuple[float, float, float, float]],
) -> bool:
    x = component["x"] + (component["width"] - 1) / 2
    y = component["y"] + (component["height"] - 1) / 2
    for left, top, right, bottom in nodes:
        near_vertical = min(abs(x - left), abs(x - right)) <= 3 and top - 3 <= y <= bottom + 3
        near_horizontal = min(abs(y - top), abs(y - bottom)) <= 3 and left - 3 <= x <= right + 3
        if near_vertical or near_horizontal:
            return True
    return any(_point_to_segment_distance(x, y, segment) <= 8 for segment in segments)


def _decoded_rgba_compatibility(left: Path, right: Path, svg: Path) -> dict[str, object]:
    ae_output = _image_compare_metric(left, right, "AE")
    ae_match = re.match(r"^[0-9.eE+-]+", ae_output)
    if ae_match is None:
        raise RuntimeError(f"Could not parse absolute error pixels from {ae_output!r}")
    ae = int(float(ae_match.group(0)))
    if ae == 0:
        return {
            "classification": "decoded_rgba_exact",
            "absolute_error_pixels": 0,
            "normalized_rmse": 0.0,
            "components": [],
        }
    rmse_output = _image_compare_metric(left, right, "RMSE")
    normalized_match = re.search(r"\(([^)]+)\)", rmse_output)
    if normalized_match is None:
        raise RuntimeError(f"Could not parse normalized RMSE from {rmse_output!r}")
    normalized_rmse = float(normalized_match.group(1))
    process = subprocess.run(
        _imagemagick_command(
            str(left), str(right), "-compose", "difference", "-composite",
            "-alpha", "off", "-threshold", "0",
            "-define", "connected-components:verbose=true", "-connected-components", "4", "null:",
        ),
        text=True,
        capture_output=True,
        check=False,
    )
    if process.returncode != 0:
        raise RuntimeError(process.stderr or process.stdout or "ImageMagick component probe failed")
    component_pattern = re.compile(
        r"^\s*\d+:\s+(\d+)x(\d+)\+(-?\d+)\+(-?\d+).*?\s(\d+)\s+srgb\(255,255,255\)\s*$",
        re.MULTILINE,
    )
    components = [
        {
            "width": int(match.group(1)),
            "height": int(match.group(2)),
            "x": int(match.group(3)),
            "y": int(match.group(4)),
            "area": int(match.group(5)),
        }
        for match in component_pattern.finditer(process.stdout + process.stderr)
    ]
    segments = _orthogonal_edge_segments(svg)
    nodes = _node_bounds(svg)
    thin_components = all(min(component["width"], component["height"]) <= 2 for component in components)
    border_components = all(
        _component_is_on_edge_or_node_border(component, segments, nodes)
        for component in components
    )
    if ae > 128 or normalized_rmse > 0.001 or not components or not thin_components or not border_components:
        raise AssertionError(
            "Decoded RGBA compatibility guard failed: "
            f"AE={ae}, normalized_rmse={normalized_rmse}, components={components}, "
            f"thin={thin_components}, border_only={border_components}"
        )
    return {
        "classification": "guarded_antialias_equivalent",
        "absolute_error_pixels": ae,
        "normalized_rmse": normalized_rmse,
        "components": components,
        "components_thin": thin_components,
        "components_on_edge_or_node_border": border_components,
    }


class MotionPlanTest(unittest.TestCase):
    def render_fixture(self, fixture: str, mode: str, output: Path) -> None:
        data = json.loads((ROOT / "fixtures" / fixture).read_text(encoding="utf-8"))
        svg, _ = generator.build_svg_with_report(mode, data)
        output.write_text(svg, encoding="utf-8")

    def specialized_style_plan(
        self,
        style_id: int,
        fixture: str,
        mode: str | None,
    ) -> tuple[dict[str, object], str]:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / f"style-{style_id}.svg"
            if mode is None:
                svg.write_bytes((ROOT / "fixtures" / fixture).read_bytes())
            else:
                self.render_fixture(fixture, mode, svg)
            return build_motion_plan(svg)

    def assert_specialized_style_contract(
        self,
        *,
        style_id: int,
        fixture: str,
        mode: str | None,
        preset: str,
        source_sha256: str,
        fixture_sha256: str,
        height: int,
        routes: list[tuple[str, int, int, tuple[int, int]]],
        rail: str,
        signature: str,
        signature_geometry: dict[str, object],
        phases: list[int],
        period: int,
        advance: int,
        maximum_width: float,
        endpoint_clearance: int,
        maximum_concurrent_draws: int,
    ) -> tuple[dict[str, object], dict[str, object]]:
        plan, safe_svg = self.specialized_style_plan(style_id, fixture, mode)
        expected_schedule = [
            {"role": role, "stage": stage, "order": order, "frames": list(frames)}
            for role, stage, order, frames in routes
        ]
        contract = plan["animation_contract"]
        stream = contract["persistent_data_flow"]
        self.assertEqual(plan["style_id"], style_id)
        self.assertEqual(plan["preset"], preset)
        self.assertEqual(plan["source_sha256"], QUALITY_SNAPSHOTS[str(style_id)]["sha256"])
        self.assertEqual(plan["review_reference_source_sha256"], source_sha256)
        self.assertEqual(plan["fixture_sha256"], fixture_sha256)
        self.assertEqual(plan["review_status"], "user-approved")
        self.assertEqual(plan["style_contract_status"], "user-approved")
        self.assertEqual(plan["style_contract"]["approval_recorded_on"], "2026-07-16")
        self.assertEqual(plan["timing_revision"]["id"], "+2s-settled-flow")
        self.assertEqual(plan["timing_revision"]["status"], "user-approved")
        self.assertFalse(plan["timing_revision"]["only_pending_item"])
        self.assertEqual(plan["timing_revision"]["approved_at"], "2026-07-17")
        self.assertEqual(plan["duration_seconds"], 5.75)
        self.assertEqual(plan["fps"], 20)
        self.assertEqual(plan["frame_count"], 115)
        self.assertEqual((plan["width"], plan["height"]), (960, height))
        self.assertEqual(contract["draw_schedule"], expected_schedule)
        self.assertEqual(contract["maximum_concurrent_draws"], maximum_concurrent_draws)
        self.assertEqual(
            [
                (entry["role"], entry["stage"], entry["order"])
                for entry in plan["semantics"]["resolved_schedule"]
            ],
            [(role, stage, order) for role, stage, order, _ in routes],
        )
        self.assertEqual(stream["primitive"], rail)
        self.assertEqual(stream["signature_primitive"], signature)
        self.assertEqual(stream["stream_count"], len(routes))
        self.assertEqual(stream["signature_count"], len(routes))
        self.assertEqual(stream["rendered_frames"], [36, 114])
        self.assertEqual(stream["fade_in_frames"], [36, 38])
        self.assertEqual(stream["full_opacity_frames"], [38, 109])
        self.assertEqual(stream["body"]["maximum_live_width"], maximum_width)
        self.assertTrue(
            all(width <= maximum_width for width in stream["body"]["resolved_widths_in_schedule_order"])
        )
        self.assertEqual(stream["signature"]["geometry"], signature_geometry)
        self.assertEqual(stream["signature"]["endpoint_clearance"], endpoint_clearance)
        self.assertEqual(stream["signature_advance_per_rendered_frame"], advance)
        self.assertEqual(stream["travel_pixels_per_frame_at_100_percent"], advance)
        self.assertEqual(stream["travel_pixels_per_frame_at_50_percent"], advance / 2)
        self.assertEqual(stream["dash_period"], period)
        self.assertEqual(stream["expected_initial_phases"], phases)
        self.assertTrue(stream["period_step_coprime"])
        self.assertEqual(stream["reset_range"], [110, 114])
        self.assertEqual(stream["reset_opacity_samples"], RESET_OPACITY_SAMPLES)
        self.assertIn(f'data-style-id="{style_id}"', safe_svg)
        self.assertTrue(all(check["ok"] for check in plan["source_checks"].values()))
        return plan, stream

    def test_style_five_glass_task_capsule_contract_is_exact(self) -> None:
        _, stream = self.assert_specialized_style_contract(
            style_id=5,
            fixture="multi-agent-style5.json",
            mode="agent",
            preset="agent-orchestration",
            source_sha256="52bf52e8ac0b129fcfad8dcd06e93468b3b79e29e9e0f919be80cb58046c0991",
            fixture_sha256="f4664045331c73179c312482b4d68d474513a059ede426891e097e615722b6a9",
            height=700,
            routes=[
                ("ingress", 1, 0, (1, 6)), ("delegate", 2, 0, (5, 12)),
                ("delegate", 2, 1, (8, 15)), ("delegate", 2, 2, (11, 18)),
                ("evidence", 3, 0, (17, 24)), ("artifact", 3, 1, (20, 27)),
                ("context", 4, 0, (25, 30)), ("deliver", 5, 0, (29, 36)),
                ("approval", 5, 1, (29, 36)),
            ],
            rail="glass-handoff-rail",
            signature="glass-task-capsule",
            signature_geometry={
                "shape": "rounded-translucent-plate", "width": 14, "height": 9, "rx": 3,
                "highlight_stroke_width": 1, "work_item_dot_radius": 2,
                "work_item_dot_count": 2, "tangent_aware_rotation": True,
            },
            phases=[7, 14, 17, 20, 21, 24, 28, 35, 38],
            period=43, advance=6, maximum_width=2.2, endpoint_clearance=8,
            maximum_concurrent_draws=2,
        )
        self.assertEqual(
            stream["auxiliary"],
            {"primitive": "coordinator-halo", "node_id": "coordinator", "period_frames": 16,
             "opacity_range": [0.12, 0.32], "movement": "opacity-only"},
        )

    def test_style_six_governance_policy_seal_contract_is_exact(self) -> None:
        self.assert_specialized_style_contract(
            style_id=6, fixture="system-architecture-style6.json", mode="architecture",
            preset="governed-runtime",
            source_sha256="25847c17def77f9b9da1b9320504e31841c28cbcf35f56602d2f4dd76a40c772",
            fixture_sha256="427127297757d7672ab365e37983a2a09bc55b26a420be9b44dc67e7ac5b9553",
            height=700,
            routes=[
                ("ingress", 1, 0, (1, 6)), ("dispatch", 2, 0, (5, 12)),
                ("runtime-branch", 3, 0, (10, 17)), ("runtime-branch", 3, 1, (13, 20)),
                ("runtime-branch", 3, 2, (16, 23)), ("foundation", 4, 0, (21, 28)),
                ("foundation", 4, 1, (24, 31)), ("foundation", 4, 2, (27, 34)),
                ("promote", 5, 0, (31, 36)),
            ],
            rail="governance-thread", signature="policy-seal",
            signature_geometry={
                "shape": "warm-white-hexagonal-outline", "width": 12, "height": 12,
                "center_dot_diameter": 3, "approval_bar_width": 4, "shadow": False, "glow": False,
            },
            phases=[7, 14, 21, 24, 27, 28, 31, 34, 35], period=47, advance=6,
            maximum_width=2.8, endpoint_clearance=8, maximum_concurrent_draws=2,
        )

    def test_style_seven_api_token_train_contract_is_exact(self) -> None:
        self.assert_specialized_style_contract(
            style_id=7, fixture="api-flow-style7.json", mode="architecture", preset="token-stream",
            source_sha256="ce07fd5279c5709b4546c59007068ca678b92122ed740d43270ecd22f7bbf82b",
            fixture_sha256="4d03096787cceb3e2be61567cf12996291dd46d2289bd5394cb30360b48a4473",
            height=700,
            routes=[
                ("connect", 1, 0, (1, 6)), ("prepare", 2, 0, (5, 12)),
                ("invoke", 3, 0, (10, 17)), ("tool-call", 4, 0, (15, 22)),
                ("token-stream", 4, 1, (18, 27)), ("govern", 5, 0, (25, 32)),
                ("measure", 5, 1, (25, 32)), ("promote", 6, 0, (31, 36)),
            ],
            rail="api-token-rail", signature="token-train",
            signature_geometry={
                "shape": "three-cell-token-train", "group_width": 18, "group_height": 8,
                "cell_width": 4, "cell_height": 4, "cell_gap": 2,
                "cell_opacities": [1.0, 0.72, 0.44], "tangent_aware_rotation": True,
            },
            phases=[7, 14, 21, 28, 31, 35, 38, 42], period=43, advance=6,
            maximum_width=2.5, endpoint_clearance=10, maximum_concurrent_draws=3,
        )

    def test_style_six_and_seven_feedback_legends_use_distinct_semantic_encodings(self) -> None:
        cases = (
            (
                "system-architecture-style6.json",
                "orchestration",
                "operations",
                "#d97757",
                "#7c5c96",
            ),
            (
                "api-flow-style7.json",
                "primary API path",
                "governance",
                "#10a37f",
                "#475569",
            ),
        )
        for fixture, primary_label, feedback_label, primary_color, feedback_color in cases:
            with self.subTest(fixture=fixture):
                with tempfile.TemporaryDirectory() as directory:
                    svg = Path(directory) / "scene.svg"
                    self.render_fixture(fixture, "architecture", svg)
                    root = ET.parse(svg).getroot()
                    legend = next(item for item in root if item.get("id") == "legend")
                    entries: dict[str, ET.Element] = {}
                    previous_line: ET.Element | None = None
                    for item in legend:
                        if item.tag.endswith("line"):
                            previous_line = item
                        elif item.tag.endswith("text") and previous_line is not None:
                            entries[item.text or ""] = previous_line
                    primary = entries[primary_label]
                    feedback = entries[feedback_label]
                    self.assertEqual(primary.get("stroke"), primary_color)
                    self.assertEqual(feedback.get("stroke"), feedback_color)
                    self.assertNotEqual(primary.get("stroke"), feedback.get("stroke"))
                    self.assertNotEqual(primary.get("marker-end"), feedback.get("marker-end"))
                    feedback_edges = [
                        item
                        for item in root.iter()
                        if item.get("data-graph-role") == "edge" and item.get("data-flow") == "feedback"
                    ]
                    self.assertTrue(feedback_edges)
                    self.assertTrue(all(item.get("stroke") == feedback_color for item in feedback_edges))

    def test_style_eight_gem_circuit_contract_is_exact(self) -> None:
        plan, stream = self.assert_specialized_style_contract(
            style_id=8, fixture="dark-luxury-style8.svg", mode=None, preset="golden-circuit",
            source_sha256="6ade2db83f0fa772c4791e1a09a2c128373125da3bcfa2624434daff72316122",
            fixture_sha256="6ade2db83f0fa772c4791e1a09a2c128373125da3bcfa2624434daff72316122",
            height=600,
            routes=[
                ("primary", 1, 0, (1, 6)), ("primary", 2, 0, (5, 10)),
                ("memory-read", 3, 0, (9, 18)), ("tool-call", 3, 1, (12, 21)),
                ("data", 4, 0, (20, 25)), ("trace", 5, 0, (24, 29)),
                ("feedback", 6, 0, (28, 36)),
            ],
            rail="luxury-circuit-rail", signature="gem-tracer",
            signature_geometry={
                "shape": "diamond-with-tapered-tail", "diamond_width": 7, "diamond_height": 7,
                "diamond_rotation": 45, "specular_diameter": 2, "tail_length": 12,
                "filtered_elements_per_tracer": 1,
            },
            phases=[7, 14, 21, 24, 28, 35, 42], period=47, advance=6,
            maximum_width=2.8, endpoint_clearance=8, maximum_concurrent_draws=2,
        )
        self.assertEqual(
            plan["semantics"]["schedule_key"],
            "(data-motion-role, data-motion-stage, data-motion-order)",
        )
        self.assertEqual(stream["signature"]["geometry"]["filtered_elements_per_tracer"], 1)

    def test_style_nine_review_cursor_contract_is_exact(self) -> None:
        self.assert_specialized_style_contract(
            style_id=9, fixture="c4-review-canvas-style9.json", mode="architecture",
            preset="review-trace",
            source_sha256="b45264d17910fda296a7b52e7a338f361d8272ff14da55d2cad8c6e8dabe2717",
            fixture_sha256="a8a0bccddc4b9b762286f3a7f21a5c1fdb98ea32f436d573bb7d3c14d7be27a9",
            height=611,
            routes=[
                ("review-entry", 1, 0, (1, 7)), ("review-request", 2, 0, (7, 13)),
                ("review-async", 3, 0, (13, 22)), ("review-state", 4, 0, (22, 30)),
                ("review-external", 4, 1, (28, 36)),
            ],
            rail="review-trace-rail", signature="review-cursor",
            signature_geometry={
                "shape": "review-mark", "outline_circle_diameter": 11,
                "diagonal_handle_length": 5, "internal_check_extent": 3,
                "shadow": False, "glow": False,
            },
            phases=[7, 14, 21, 28, 31], period=41, advance=5,
            maximum_width=2.6, endpoint_clearance=9, maximum_concurrent_draws=2,
        )

    def test_style_ten_active_active_cloud_flow_contract_is_exact(self) -> None:
        plan, stream = self.assert_specialized_style_contract(
            style_id=10, fixture="cloud-fabric-style10.json", mode="architecture",
            preset="cloud-flow",
            source_sha256="a739db50e30e0669dcfc926f4ce141c655f0b8f2e4e71c6a45444c9b3e61074a",
            fixture_sha256="8c180ef8cecdc2419c79912245329ac9fffcc9ff08f8faeeb65541d21c747d4e",
            height=760,
            routes=[
                ("global-route", 1, 0, (1, 12)), ("global-route", 1, 1, (1, 12)),
                ("regional-write", 2, 0, (13, 22)), ("regional-write", 2, 1, (13, 22)),
                ("cross-region", 3, 0, (23, 36)),
            ],
            rail="cloud-flow-rail", signature="region-chevron-pair-or-replication-capsule",
            signature_geometry={
                "routing_write": {"shape": "region-chevron-pair", "chevron_width": 6,
                                  "chevron_height": 5, "separation": 5},
                "replication": {"shape": "replication-capsule", "width": 14, "height": 7,
                                "data_cell_count": 2, "direction": "left-to-right"},
            },
            phases=[7, 7, 14, 14, 21], period=43, advance=6,
            maximum_width=2.7, endpoint_clearance=8, maximum_concurrent_draws=2,
        )
        self.assertEqual(plan["semantics"]["flows"], {"async": 1, "read": 2, "write": 2})
        self.assertEqual(stream["auxiliary"]["container_ids"], ["region-a", "region-b"])

    def test_style_eleven_event_transit_train_contract_is_exact(self) -> None:
        plan, stream = self.assert_specialized_style_contract(
            style_id=11, fixture="event-transit-style11.json", mode="flow", preset="event-transit",
            source_sha256="e4ca3aa987b2495868765a0b66d11763a67890f13079c513f58451a40d5432e4",
            fixture_sha256="a9fbd96129c9fc54b97b80024cb954d03d471d4c2963f99e71eff276d15d6140",
            height=590,
            routes=[
                ("topic-rail", 1, 0, (1, 6)), ("topic-rail", 2, 0, (7, 12)),
                ("topic-rail", 3, 0, (13, 18)), ("topic-rail", 4, 0, (19, 24)),
                ("dead-letter", 5, 0, (25, 32)), ("state-project", 5, 1, (29, 36)),
            ],
            rail="event-transit-rail", signature="event-train-or-branch-car",
            signature_geometry={
                "main": {"shape": "three-car-event-train", "car_diameter": 5,
                         "car_gap": 3, "car_count": 3},
                "dead_letter": {"shape": "red-outlined-exception-car"},
                "state_project": {"shape": "teal-two-cell-projection-car", "cell_count": 2},
            },
            phases=[5, 10, 15, 20, 25, 28], period=41, advance=5,
            maximum_width=2.2, endpoint_clearance=7, maximum_concurrent_draws=2,
        )
        self.assertEqual(plan["semantics"]["stations"], 5)
        self.assertEqual(plan["semantics"]["rails"], 4)
        self.assertEqual(plan["semantics"]["branches"], 2)
        self.assertEqual(stream["auxiliary"]["count"], 4)

    def test_style_twelve_ops_pulse_waterfall_contract_is_exact(self) -> None:
        plan, stream = self.assert_specialized_style_contract(
            style_id=12, fixture="ops-pulse-style12.json", mode="architecture", preset="ops-pulse",
            source_sha256="f6170771acdd376fd78fa103214ff3125155754b6e19b87971d11c0afbab5a21",
            fixture_sha256="2ea1d7a153ca8a39c37e9f5c5fd18a47c98a59f35694cd2bd68919d6b86b132c",
            height=860,
            routes=[
                ("critical-request", 1, 0, (1, 6)), ("critical-request", 2, 0, (7, 12)),
                ("critical-request", 3, 0, (13, 18)), ("telemetry-export", 4, 0, (19, 26)),
            ],
            rail="incident-pulse-rail-or-telemetry-export-rail",
            signature="ecg-head-or-telemetry-export-packet",
            signature_geometry={
                "critical": {"shape": "compact-ecg-head", "stroke_width": 1.6},
                "telemetry": {"shape": "cyan-three-dot-export-packet", "dot_count": 3,
                              "dot_diameter": 4},
            },
            phases=[5, 10, 15, 20], period=43, advance=5,
            maximum_width=2.2, endpoint_clearance=8, maximum_concurrent_draws=1,
        )
        self.assertEqual(plan["semantics"]["critical_hops"], 3)
        self.assertEqual(plan["semantics"]["trace_spans"], 4)
        self.assertEqual(stream["trace_reveal"]["rendered_frames"], [[24, 27], [27, 30], [30, 33], [33, 36]])
        self.assertEqual(
            stream["scanner"],
            {"primitive": "waterfall-scanner", "width": 2, "tail_width": 12,
             "period_frames": 34, "movement": "horizontal-within-trace-plot"},
        )

    def test_styles_ten_to_twelve_motion_metadata_preserves_static_geometry(self) -> None:
        cases = (
            ("cloud-fabric-style10.json", "architecture", "db23661b915c0ededf9017ae70e8bcd5c81225d09c91c94a341119e8dd78e3f0"),
            ("event-transit-style11.json", "flow", "5242b071e98c20157c52838b618e14b5012bf9ff84467b4d73d7e814804f3980"),
            ("ops-pulse-style12.json", "architecture", "f19ed8555f0d98f977d25b32067d812c6db1e3b22c587852f4c7d3ef8905272b"),
        )
        for fixture, mode, expected_hash in cases:
            with self.subTest(fixture=fixture):
                data = json.loads((ROOT / "fixtures" / fixture).read_text(encoding="utf-8"))
                svg, _ = generator.build_svg_with_report(mode, data)
                root = ET.fromstring(svg)
                motion_edges = [
                    element for element in root.iter()
                    if element.get("data-graph-role") == "edge" and element.get("data-motion-role")
                ]
                self.assertTrue(motion_edges)
                self.assertTrue(
                    all(
                        edge.get("data-motion-stage") is not None
                        and edge.get("data-motion-order") is not None
                        for edge in motion_edges
                    )
                )
                for element in root.iter():
                    for attribute in ("data-motion-role", "data-motion-stage", "data-motion-order"):
                        element.attrib.pop(attribute, None)
                normalized = ET.tostring(root, encoding="utf-8")
                self.assertEqual(hashlib.sha256(normalized).hexdigest(),
                                 QUALITY_SNAPSHOTS[str(data["style"])]["without_motion_metadata_sha256"])

    def test_style_one_default_plan_matches_focused_gif_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            plan, safe_svg = build_motion_plan(svg)
            self.assertEqual(REVIEWED_STYLE_IDS, frozenset(range(1, 13)))
            self.assertEqual(plan["style_id"], 1)
            self.assertEqual(plan["preset"], "memory-weave")
            self.assertEqual(plan["input_kind"], "svg")
            self.assertEqual(plan["duration_seconds"], DEFAULT_MOTION_DURATION)
            self.assertEqual(plan["fps"], DEFAULT_MOTION_FPS)
            self.assertEqual(plan["frame_count"], DEFAULT_MOTION_FRAME_COUNT)
            self.assertEqual(plan["width"], 960)
            self.assertEqual(plan["review_status"], "user-approved")
            self.assertEqual(plan["timing_revision"]["status"], "user-approved")
            self.assertFalse(plan["timing_revision"]["only_pending_item"])
            self.assertEqual(plan["timing_revision"]["approved_at"], "2026-07-17")
            self.assertEqual(plan["motion_grammar_version"], "3.4")
            self.assertEqual(plan["animation_contract"], DRAW_ON_CONTRACT)
            self.assertEqual(plan["scene_signature"]["name"], "memory-weave-draw-on-persistent-data-flow")
            self.assertEqual(plan["semantics"]["motion_metadata"], "explicit")
            self.assertIn('data-semantic-valid="true"', safe_svg)
            self.assertTrue(all(check["ok"] for check in plan["source_checks"].values()))

    def test_unsupported_style_reports_the_current_enabled_range(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-13.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            svg.write_text(
                svg.read_text(encoding="utf-8").replace('data-style-id="1"', 'data-style-id="13"', 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, r"enabled styles are 1-12"):
                build_motion_plan(svg)

    def test_style_two_default_plan_matches_terminal_evidence_trace_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-2.svg"
            self.render_fixture("tool-call-style2.json", "agent", svg)
            self.assertEqual(
                hashlib.sha256(svg.read_bytes()).hexdigest(),
                QUALITY_SNAPSHOTS["2"]["sha256"],
            )
            plan, safe_svg = build_motion_plan(svg)

        self.assertEqual(plan["style_id"], 2)
        self.assertEqual(plan["preset"], "tool-grounding")
        self.assertEqual(plan["visual_theme"], "Dark Terminal")
        self.assertEqual(plan["duration_seconds"], 5.75)
        self.assertEqual(plan["fps"], 20)
        self.assertEqual(plan["frame_count"], 115)
        self.assertEqual(plan["width"], 960)
        self.assertEqual(plan["height"], 720)
        self.assertEqual(plan["motion_grammar_version"], "3.4")
        self.assertEqual(plan["animation_contract"], STYLE_2_DRAW_ON_CONTRACT)
        self.assertEqual(plan["scene_signature"]["name"], "tool-grounding-terminal-evidence-trace")
        self.assertIn("terminal-prompt-cursor", plan["scene_signature"]["distinctive_primitives"])
        self.assertEqual(plan["semantics"]["motion_metadata"], "explicit")
        self.assertEqual(plan["semantics"]["schedule_key"], "(data-motion-role, data-motion-order)")
        self.assertEqual(
            [(entry["role"], entry["order"]) for entry in plan["semantics"]["resolved_schedule"]],
            STYLE_SCENE_CONTRACTS[2]["schedule_keys"],
        )
        self.assertEqual(
            [entry["edge_id"] for entry in plan["semantics"]["resolved_schedule"]],
            ["request", "delegate", "tool-call", "inspect", "index", "ground", "draft", "answer"],
        )
        self.assertIn('data-node-id="terminal"', safe_svg)
        self.assertTrue(all(check["ok"] for check in plan["source_checks"].values()))

    def test_style_two_schedule_stream_colors_phases_directions_and_cursor_are_pinned(self) -> None:
        self.assertEqual(
            STYLE_2_DRAW_SCHEDULE,
            [
                {"role": "ingress", "stage": 1, "order": 0, "frames": [1, 8]},
                {"role": "delegate", "stage": 2, "order": 0, "frames": [5, 12]},
                {"role": "tool-call", "stage": 3, "order": 0, "frames": [9, 16]},
                {"role": "inspect", "stage": 4, "order": 0, "frames": [13, 20]},
                {"role": "index", "stage": 5, "order": 0, "frames": [17, 24]},
                {"role": "grounding", "stage": 6, "order": 0, "frames": [21, 28]},
                {"role": "grounding", "stage": 6, "order": 1, "frames": [25, 32]},
                {"role": "answer", "stage": 7, "order": 0, "frames": [29, 36]},
            ],
        )
        stream = STYLE_2_PERSISTENT_STREAM_CONTRACT
        self.assertEqual(stream["primitive"], "terminal-evidence-stream")
        self.assertEqual(stream["packet_head_primitive"], "terminal-command-head")
        self.assertEqual(stream["stream_count"], 8)
        self.assertEqual(stream["packet_head_count"], 8)
        self.assertEqual(stream["rendered_frames"], [36, 114])
        self.assertEqual(stream["fade_in_frames"], [36, 38])
        self.assertEqual(stream["fade_in_factors"], [0.30, 0.65, 1.0])
        self.assertEqual(stream["full_opacity_frames"], [38, 109])
        body = stream["body"]
        head = stream["packet_head"]
        self.assertEqual(body["stroke_width"], "min(3.8, max(3.0, source_stroke * 1.50))")
        self.assertEqual(body["resolved_style_2_source_stroke_width"], 2.3)
        self.assertEqual(body["resolved_style_2_stroke_width"], 3.45)
        self.assertEqual(body["color"], "inherit-source-stroke")
        self.assertEqual(
            body["source_colors_in_schedule_order"],
            ["#a855f7", "#a855f7", "#38bdf8", "#38bdf8", "#22c55e", "#fb7185", "#fb7185", "#f97316"],
        )
        self.assertEqual(
            body["semantic_colors"],
            {
                "control": "#a855f7",
                "tool_read": "#38bdf8",
                "index_write": "#22c55e",
                "grounding_data": "#fb7185",
                "answer": "#f97316",
            },
        )
        self.assertEqual(body["opacity"], 0.94)
        self.assertEqual(body["dash_pattern"], [15, 26])
        self.assertTrue(body["marker_free"])
        self.assertTrue(body["filter_free"])
        self.assertEqual(head["primitive"], "terminal-command-head")
        self.assertEqual(head["stroke_width"], 2.00)
        self.assertEqual(head["color"], "#f8fafc")
        self.assertEqual(head["opacity"], 1.00)
        self.assertEqual(head["dash_pattern"], [5, 36])
        self.assertEqual(head["dash_offset_from_body"], -10)
        self.assertTrue(head["marker_free"])
        self.assertTrue(head["filter_free"])
        self.assertTrue(head["appended_immediately_after_body"])
        self.assertEqual(stream["dash_period"], 41)
        self.assertEqual(stream["dash_offset_per_rendered_frame"], -6.0)
        self.assertEqual(stream["travel_pixels_per_frame_at_960px"], 6)
        self.assertEqual(stream["travel_pixels_per_frame_at_50_percent"], 3)
        self.assertEqual(stream["phase_policy"], "(motionStage * 6 + motionOrder * 3) mod 41")
        self.assertEqual(stream["expected_initial_phases"], [6, 12, 18, 24, 30, 36, 39, 1])
        self.assertTrue(stream["period_step_coprime"])
        self.assertEqual(stream["stream_interval_frame_count"], 79)
        self.assertTrue(stream["phase_repeat_within_stream_interval"])
        self.assertEqual(
            stream["direction_sentinels"],
            {
                "ingress/0": ["right"],
                "delegate/0": ["down", "left", "down"],
                "tool-call/0": ["right"],
                "inspect/0": ["down"],
                "index/0": ["right", "up"],
                "grounding/0": ["up", "left", "up"],
                "grounding/1": ["right"],
                "answer/0": ["right"],
            },
        )
        cursor = TERMINAL_SIGNATURE_CONTRACT
        self.assertEqual(cursor["primitive"], "terminal-prompt-cursor")
        self.assertEqual(cursor["count"], 1)
        self.assertEqual(cursor["node_id"], "terminal")
        self.assertEqual(cursor["source_text"], "_")
        self.assertFalse(cursor["source_text_hidden"])
        self.assertFalse(cursor["source_text_mutated"])
        self.assertEqual(cursor["height"], 2.2)
        self.assertEqual(cursor["fill"], "#a7f3d0")
        self.assertEqual(cursor["movement"], "opacity-only")
        self.assertEqual(cursor["visible_after_route"], {"role": "tool-call", "order": 0, "settled_frame": 16})
        self.assertEqual(cursor["cadence_frames"], [16, 109])
        self.assertEqual(cursor["period_frames"], 16)
        self.assertEqual(cursor["bright_frames_per_period"], 8)
        self.assertEqual(cursor["absent_frames_per_period"], 8)
        self.assertEqual(cursor["bright_opacity"], 0.95)
        self.assertEqual(cursor["reset_range"], [110, 114])
        self.assertTrue(cursor["marker_free"])
        self.assertTrue(cursor["filter_free"])

    def test_style_three_blueprint_distribution_contract_is_pinned(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-3.svg"
            self.render_fixture("microservices-style3.json", "architecture", svg)
            self.assertEqual(
                hashlib.sha256(svg.read_bytes()).hexdigest(),
                QUALITY_SNAPSHOTS["3"]["sha256"],
            )
            plan, safe_svg = build_motion_plan(svg)

        self.assertEqual(plan["style_id"], 3)
        self.assertEqual(plan["preset"], "service-blueprint")
        self.assertEqual(plan["visual_theme"], "Blueprint")
        self.assertEqual((plan["width"], plan["height"]), (960, 720))
        self.assertEqual((plan["duration_seconds"], plan["fps"], plan["frame_count"]), (5.75, 20, 115))
        self.assertEqual(plan["scene_signature"]["name"], "service-blueprint-distribution-wave")
        self.assertIn("blueprint-registration-bead", plan["scene_signature"]["distinctive_primitives"])
        self.assertEqual(plan["animation_contract"], STYLE_3_DRAW_ON_CONTRACT)
        self.assertEqual(plan["semantics"]["schedule_key"], "(data-motion-role, data-motion-order)")
        self.assertEqual(
            [entry["edge_id"] for entry in plan["semantics"]["resolved_schedule"]],
            [
                "client-request", "policy-check", "a-route-order", "b-route-catalog", "c-route-billing",
                "order-store", "catalog-cache", "billing-store", "publish-event", "observe",
            ],
        )
        self.assertIn('data-motion-scene="service-blueprint"', safe_svg)

        self.assertEqual(
            STYLE_3_DRAW_SCHEDULE,
            [
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
            ],
        )
        concurrency = [
            sum(start <= frame <= end for start, end in (entry["frames"] for entry in STYLE_3_DRAW_SCHEDULE))
            for frame in range(DEFAULT_MOTION_FRAME_COUNT)
        ]
        self.assertEqual(max(concurrency), 2)

        stream = STYLE_3_PERSISTENT_STREAM_CONTRACT
        self.assertEqual(stream["primitive"], "blueprint-distribution-wave")
        self.assertEqual(stream["registration_bead_primitive"], "blueprint-registration-bead")
        self.assertEqual((stream["stream_count"], stream["registration_bead_count"]), (10, 10))
        self.assertEqual(stream["rendered_frames"], [36, 114])
        self.assertEqual(stream["fade_in_factors"], [0.30, 0.65, 1.0])
        self.assertEqual(stream["full_opacity_frames"], [38, 109])
        body = stream["body"]
        self.assertEqual(body["resolved_style_3_source_stroke_width"], 2.1)
        self.assertEqual(body["resolved_style_3_stroke_width"], 2.94)
        self.assertEqual(body["resolved_style_3_stroke_width_at_50_percent"], 1.47)
        self.assertEqual(body["dash_pattern"], [12, 31])
        self.assertEqual(body["opacity"], 0.92)
        self.assertEqual(
            body["source_colors_in_schedule_order"],
            ["#38bdf8", "#67e8f9", "#38bdf8", "#38bdf8", "#38bdf8", "#fde047", "#fde047", "#fde047", "#fb7185", "#fb7185"],
        )
        bead = stream["registration_bead"]
        self.assertEqual((bead["shape"], bead["radius"], bead["stroke_width"]), ("circle", 3.0, 1.2))
        self.assertEqual((bead["fill"], bead["stroke"], bead["opacity"]), ("#e0f2fe", "inherit-source-stroke", 0.98))
        self.assertEqual(bead["path_advance_per_rendered_frame"], 6.0)
        self.assertEqual(bead["animated_attributes"], ["cx", "cy", "opacity"])
        self.assertTrue(bead["marker_free"] and bead["filter_free"])
        self.assertEqual((stream["dash_period"], stream["dash_offset_per_rendered_frame"]), (43, -6.0))
        self.assertEqual(stream["bead_advance_per_rendered_frame"], 6.0)
        self.assertEqual(stream["expected_initial_phases"], [7, 14, 21, 21, 21, 28, 28, 28, 35, 42])
        self.assertTrue(stream["period_step_coprime"])
        self.assertEqual(stream["stream_interval_frame_count"], 79)
        self.assertTrue(stream["phase_repeat_within_stream_interval"])
        self.assertEqual(stream["stage_locks"]["fanout"]["phase"], 21)
        self.assertEqual(stream["stage_locks"]["data-write"]["phase"], 28)
        self.assertEqual(
            stream["direction_sentinels"],
            {
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
        )
        self.assertEqual(stream["reset_range"], [110, 114])
        self.assertEqual(STYLE_3_DRAW_ON_CONTRACT["route_label_opacity_states"], 7)
        self.assertIn("terminal-cursor", STYLE_3_DRAW_ON_CONTRACT["forbidden"])

    def test_style_three_semantic_contract_is_not_byte_hash_locked(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-3.svg"
            self.render_fixture("microservices-style3.json", "architecture", svg)
            reviewed_hash = build_motion_plan(svg)[0]["review_reference_source_sha256"]
            svg.write_text(svg.read_text(encoding="utf-8") + "\n", encoding="utf-8")
            plan, _ = build_motion_plan(svg)
            self.assertNotEqual(plan["source_sha256"], reviewed_hash)
            self.assertEqual(plan["review_reference_source_sha256"], reviewed_hash)
            self.assertEqual(
                plan["style_contract"]["source_policy"],
                "semantic-schedule-and-geometry-not-exact-byte-hash",
            )

    def test_style_four_notion_memory_card_handoff_contract_is_pinned(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-4.svg"
            self.render_fixture("agent-memory-types-style4.json", "memory", svg)
            self.assertEqual(
                hashlib.sha256(svg.read_bytes()).hexdigest(),
                QUALITY_SNAPSHOTS["4"]["sha256"],
            )
            plan, safe_svg = build_motion_plan(svg)

        self.assertEqual(plan["style_id"], 4)
        self.assertEqual(plan["preset"], "memory-lifecycle")
        self.assertEqual(plan["visual_theme"], "Notion Clean")
        self.assertEqual((plan["width"], plan["height"]), (960, 620))
        self.assertEqual((plan["duration_seconds"], plan["fps"], plan["frame_count"]), (5.75, 20, 115))
        self.assertEqual(plan["scene_signature"]["name"], "memory-lifecycle-notion-card-handoff")
        self.assertIn("notion-memory-card", plan["scene_signature"]["distinctive_primitives"])
        self.assertEqual(plan["animation_contract"], STYLE_4_DRAW_ON_CONTRACT)
        self.assertEqual(plan["semantics"]["schedule_key"], "(data-motion-role, data-motion-order)")
        self.assertEqual(
            [entry["edge_id"] for entry in plan["semantics"]["resolved_schedule"]],
            ["sample", "attend", "invoke", "remember", "consolidate", "recall"],
        )
        self.assertEqual(
            [entry["semantic_color"] for entry in plan["semantics"]["resolved_schedule"]],
            ["#3b82f6", "#3b82f6", "#7c3aed", "#059669", "#ea580c", "#ea580c"],
        )
        self.assertIn('data-motion-scene="memory-lifecycle"', safe_svg)

        self.assertEqual(
            STYLE_4_DRAW_SCHEDULE,
            [
                {"role": "sample", "stage": 1, "order": 0, "frames": [1, 4]},
                {"role": "attend", "stage": 2, "order": 0, "frames": [5, 8]},
                {"role": "invoke", "stage": 3, "order": 0, "frames": [9, 12]},
                {"role": "remember", "stage": 4, "order": 0, "frames": [13, 22]},
                {"role": "consolidate", "stage": 5, "order": 0, "frames": [23, 26]},
                {"role": "recall", "stage": 6, "order": 0, "frames": [27, 36]},
            ],
        )
        concurrency = [
            sum(start <= frame <= end for start, end in (entry["frames"] for entry in STYLE_4_DRAW_SCHEDULE))
            for frame in range(DEFAULT_MOTION_FRAME_COUNT)
        ]
        self.assertEqual(max(concurrency), 1)
        self.assertEqual([index for index, count in enumerate(concurrency) if count], list(range(1, 37)))

        stream = STYLE_4_PERSISTENT_STREAM_CONTRACT
        self.assertEqual(stream["primitive"], "notion-memory-rail")
        self.assertEqual(stream["memory_card_primitive"], "notion-memory-card")
        self.assertEqual((stream["stream_count"], stream["memory_card_count"]), (6, 6))
        self.assertEqual(stream["rendered_frames"], [36, 114])
        self.assertEqual(stream["fade_in_frames"], [36, 38])
        self.assertEqual(stream["fade_in_factors"], [0.30, 0.65, 1.0])
        self.assertEqual(stream["full_opacity_frames"], [38, 109])
        body = stream["body"]
        self.assertEqual(body["stroke_width"], "min(3.0, max(2.4, source_stroke * 1.50))")
        self.assertEqual(body["resolved_style_4_source_stroke_width"], 1.8)
        self.assertEqual(body["resolved_style_4_stroke_width"], 2.70)
        self.assertEqual(body["resolved_style_4_stroke_width_at_50_percent"], 1.35)
        self.assertEqual(body["opacity"], 0.88)
        self.assertEqual(body["dash_pattern"], [12, 35])
        self.assertEqual(
            body["semantic_colors_in_schedule_order"],
            ["#3b82f6", "#3b82f6", "#7c3aed", "#059669", "#ea580c", "#ea580c"],
        )
        self.assertTrue(body["marker_free"] and body["filter_free"])
        self.assertTrue(body["appended_below_labels_and_nodes"])

        card = stream["memory_card"]
        self.assertEqual(card["primitive"], "notion-memory-card")
        self.assertEqual(
            card["outer_rect"],
            {
                "x": -7,
                "y": -5,
                "width": 14,
                "height": 10,
                "rx": 2,
                "fill": "#ffffff",
                "stroke": "semantic-memory-destination",
                "stroke_width": 1.4,
            },
        )
        self.assertEqual(
            card["ink_lines"],
            [
                {"x1": -4.5, "y1": -2, "x2": 4, "y2": -2},
                {"x1": -4.5, "y1": 2, "x2": 0.5, "y2": 2},
            ],
        )
        self.assertEqual(card["ink_stroke_width"], 2.0)
        self.assertEqual(card["ink_linecap"], "butt")
        self.assertEqual(card["ink_shape_rendering"], "crispEdges")
        self.assertEqual(card["opacity"], 0.98)
        self.assertEqual(card["initial_normalized_progress_by_stage"], [0.08, 0.22, 0.36, 0.50, 0.64, 0.78])
        self.assertEqual(card["initial_path_distance"], "8 + progress * (pathLength - 16)")
        self.assertEqual(card["endpoint_clearance"], 8)
        self.assertEqual(card["path_advance_per_rendered_frame"], 6.0)
        self.assertEqual(card["tangent_rotations_in_schedule_order"], [0, 0, 0, 90, 0, -90])
        self.assertEqual(card["animated_attributes"], ["transform", "opacity"])
        self.assertTrue(card["marker_free"] and card["filter_free"] and card["shadow_free"])
        self.assertEqual((stream["dash_period"], stream["dash_offset_per_rendered_frame"]), (47, -6.0))
        self.assertEqual(stream["card_advance_per_rendered_frame"], 6.0)
        self.assertEqual(stream["expected_initial_phases"], [7, 14, 21, 28, 35, 42])
        self.assertEqual(stream["initial_normalized_progress_by_stage"], [0.08, 0.22, 0.36, 0.50, 0.64, 0.78])
        self.assertTrue(stream["period_step_coprime"])
        self.assertEqual(stream["stream_interval_frame_count"], 79)
        self.assertTrue(stream["phase_repeat_within_stream_interval"])
        self.assertEqual(stream["reset_range"], [110, 114])
        self.assertEqual(STYLE_4_DRAW_ON_CONTRACT["maximum_concurrent_draws"], 1)
        self.assertIn("circular-bead", STYLE_4_DRAW_ON_CONTRACT["forbidden"])

    def test_style_four_semantic_contract_is_not_byte_hash_locked(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-4.svg"
            self.render_fixture("agent-memory-types-style4.json", "memory", svg)
            reviewed_hash = build_motion_plan(svg)[0]["review_reference_source_sha256"]
            svg.write_text(svg.read_text(encoding="utf-8") + "\n", encoding="utf-8")
            plan, _ = build_motion_plan(svg)
            self.assertNotEqual(plan["source_sha256"], reviewed_hash)
            self.assertEqual(plan["review_reference_source_sha256"], reviewed_hash)

    def test_motion_grammar_uses_empty_draw_live_and_reset_phases(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            plan, _ = build_motion_plan(svg)
            grammar = plan["motion_grammar"]
            self.assertEqual(MOTION_GRAMMAR_VERSION, "3.4")
            self.assertEqual(grammar["phases"]["empty"]["frames"], [0, 0])
            self.assertEqual(grammar["phases"]["draw"]["frames"], [1, 36])
            self.assertEqual(grammar["phases"]["stream"]["frames"], [36, 114])
            self.assertEqual(grammar["phases"]["full_opacity"]["frames"], [38, 109])
            self.assertEqual(grammar["phases"]["reset"]["frames"], [110, 114])
            self.assertEqual(grammar["curves"]["draw"], "linear")
            self.assertEqual(grammar["curves"]["persistent-data-flow"], "linear")
            self.assertEqual(grammar["curves"]["reset"], "linear")
            self.assertEqual(grammar["sampling"], "uniform-frame-centers")
            self.assertEqual(grammar["sample_index_expression"], "time * fps - 0.5")
            self.assertEqual(grammar["draw_on"]["empty_opening_frame"], 0)
            self.assertEqual(grammar["draw_on"]["maximum_concurrent_draws"], 2)
            self.assertFalse(grammar["draw_on"]["connectors_visible_at_opening"])
            self.assertTrue(grammar["draw_on"]["nodes_visible_every_frame"])
            self.assertTrue(grammar["draw_on"]["topology_draw_on"])
            self.assertTrue(grammar["draw_on"]["settled_topology_dynamic"])

    def test_style_one_schedule_is_pinned_to_the_review_contract(self) -> None:
        self.assertEqual(
            DRAW_SCHEDULE,
            [
                {"role": "ingress", "frames": [1, 8]},
                {"role": "reason", "frames": [5, 12]},
                {"role": "extract", "frames": [9, 16]},
                {"role": "transform", "frames": [13, 20]},
                {"role": "resolve", "frames": [17, 24]},
                {"role": "memory-write", "frames": [21, 28]},
                {"role": "memory-read", "frames": [25, 32]},
                {"role": "response-context", "frames": [29, 36]},
            ],
        )
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["stream_count"], 8)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["packet_head_count"], 8)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["roles"], [entry["role"] for entry in DRAW_SCHEDULE])
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["rendered_frames"], [36, 114])
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["fade_in_frames"], [36, 38])
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["fade_in_factors"], [0.30, 0.65, 1.0])
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["full_opacity_frames"], [38, 109])
        body = PERSISTENT_STREAM_CONTRACT["body"]
        head = PERSISTENT_STREAM_CONTRACT["packet_head"]
        self.assertEqual(body["primitive"], "persistent-data-flow-stream")
        self.assertEqual(body["stroke_width"], "min(4.0, max(3.0, source_stroke * 1.60))")
        self.assertEqual(body["resolved_style_1_source_stroke_width"], 2.4)
        self.assertEqual(body["resolved_style_1_stroke_width"], 3.84)
        self.assertEqual(body["color"], "#06b6d4")
        self.assertEqual(body["opacity"], 0.90)
        self.assertEqual(body["dash_pattern"], [16, 25])
        self.assertEqual(body["linecap"], "round")
        self.assertEqual(body["linejoin"], "round")
        self.assertTrue(body["marker_free"])
        self.assertTrue(body["filter_free"])
        self.assertEqual(head["primitive"], "persistent-data-flow-head")
        self.assertEqual(head["stroke_width"], 2.20)
        self.assertEqual(head["color"], "#e0f2fe")
        self.assertEqual(head["opacity"], 0.98)
        self.assertEqual(head["dash_pattern"], [6, 35])
        self.assertEqual(head["dash_offset_from_body"], -10)
        self.assertEqual(head["linecap"], "round")
        self.assertEqual(head["linejoin"], "round")
        self.assertTrue(head["marker_free"])
        self.assertTrue(head["filter_free"])
        self.assertTrue(head["appended_immediately_after_body"])
        self.assertAlmostEqual(body["dash_pattern"][0] / sum(body["dash_pattern"]), 0.3902439024)
        self.assertEqual(body["dash_pattern"][0] - head["dash_pattern"][0], 10)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["dash_period"], 41)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["dash_offset_per_rendered_frame"], -6.0)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["travel_user_units_per_rendered_frame"], 6)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["travel_pixels_per_frame_at_960px"], 6)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["travel_pixels_per_second_at_960px_20fps"], 120)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["travel_pixels_per_frame_at_50_percent"], 3)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["travel_pixels_per_second_at_50_percent_20fps"], 60)
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["phase_policy"], "(motionStage * 7 + motionOrder * 3) mod 41")
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["expected_initial_phases"], [7, 14, 21, 28, 31, 35, 1, 8])
        self.assertEqual(math.gcd(PERSISTENT_STREAM_CONTRACT["dash_period"], 6), 1)
        self.assertTrue(PERSISTENT_STREAM_CONTRACT["period_step_coprime"])
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["stream_interval_frame_count"], 79)
        self.assertTrue(PERSISTENT_STREAM_CONTRACT["phase_repeat_within_stream_interval"])
        self.assertEqual(
            [round(body["opacity"] * factor, 3) for factor in PERSISTENT_STREAM_CONTRACT["fade_in_factors"]],
            [0.27, 0.585, 0.9],
        )
        self.assertEqual(
            [round(head["opacity"] * factor, 3) for factor in PERSISTENT_STREAM_CONTRACT["fade_in_factors"]],
            [0.294, 0.637, 0.98],
        )
        self.assertEqual(PERSISTENT_STREAM_CONTRACT["direction"], "source-to-target")
        self.assertEqual(
            PERSISTENT_STREAM_CONTRACT["direction_sentinels"],
            {
                "ingress": ["right"],
                "resolve": ["left"],
                "memory-write": ["down", "left", "down"],
            },
        )
        self.assertEqual(DRAW_ON_CONTRACT["reset_range"], [110, 114])
        self.assertEqual(RESET_OPACITY_SAMPLES, [1.0, 0.7575, 0.515, 0.2725, 0.03])
        self.assertEqual(DRAW_ON_CONTRACT["reset_opacity_samples"], RESET_OPACITY_SAMPLES)
        self.assertEqual(DRAW_ON_CONTRACT["persistent_data_flow"], PERSISTENT_STREAM_CONTRACT)

    def test_fifty_five_frame_compatibility_timeline_keeps_the_approved_build_indices(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            plan, _ = build_motion_plan(svg, duration=2.75, fps=20)
        grammar = plan["motion_grammar"]
        stream = plan["animation_contract"]["persistent_data_flow"]
        self.assertEqual(plan["frame_count"], MINIMUM_MOTION_FRAME_COUNT)
        self.assertEqual(grammar["phases"]["draw"]["frames"], [1, 36])
        self.assertEqual(grammar["phases"]["stream"]["frames"], [36, 54])
        self.assertEqual(grammar["phases"]["reset"]["frames"], [50, 54])
        self.assertEqual(stream["rendered_frames"], [36, 54])
        self.assertEqual(stream["full_opacity_frames"], [38, 49])
        self.assertEqual(stream["reset_range"], [50, 54])
        self.assertEqual(stream["stream_count"], 8)
        self.assertEqual(stream["packet_head_count"], 8)
        self.assertEqual(stream["dash_period"], 41)
        self.assertEqual(stream["dash_offset_per_rendered_frame"], -6.0)

    def test_seventy_five_frame_compatibility_keeps_the_approved_timing_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-2.svg"
            self.render_fixture("tool-call-style2.json", "agent", svg)
            plan, _ = build_motion_plan(svg, duration=3.75, fps=20)
        grammar = plan["motion_grammar"]
        stream = plan["animation_contract"]["persistent_data_flow"]
        cursor = plan["animation_contract"]["terminal_signature"]
        self.assertEqual((plan["duration_seconds"], plan["fps"], plan["frame_count"]), (3.75, 20, 75))
        self.assertEqual(plan["style_contract_status"], "user-approved")
        self.assertEqual(plan["review_status"], "user-approved")
        self.assertEqual(plan["timing_revision"]["id"], "approved-3.75s-baseline")
        self.assertEqual(grammar["phases"]["draw"]["frames"], [1, 36])
        self.assertEqual(grammar["phases"]["stream"]["frames"], [36, 74])
        self.assertEqual(grammar["phases"]["full_opacity"]["frames"], [38, 69])
        self.assertEqual(grammar["phases"]["reset"]["frames"], [70, 74])
        self.assertEqual(stream["rendered_frames"], [36, 74])
        self.assertEqual(stream["full_opacity_frames"], [38, 69])
        self.assertEqual(stream["reset_range"], [70, 74])
        self.assertEqual(cursor["cadence_frames"], [16, 69])
        self.assertEqual(cursor["reset_range"], [70, 74])

    def test_periodic_frame_hash_contract_reports_repeat_indices_and_rejects_bad_scope(self) -> None:
        default_hashes = [f"frame-{index}" for index in range(115)]
        default_hashes[79] = default_hashes[38]
        summary = _summarize_frame_hashes(
            default_hashes,
            (38, 109),
            algorithm="sha256",
            raster_kind="test raster",
        )
        self.assertEqual(summary["frame_count"], 115)
        self.assertEqual(summary["unique_frame_count"], 114)
        self.assertEqual(summary["minimum_unique_frame_count"], 75)
        self.assertFalse(summary["all_frames_unique"])
        self.assertEqual(summary["adjacent_duplicate_count"], 0)
        self.assertEqual(
            summary["repeated_frame_index_evidence"],
            [{
                "hash": "frame-38",
                "frame_indices": [38, 79],
                "classification": "steady_state_periodic_repeat",
            }],
        )
        self.assertTrue(summary["repeats_confined_to_full_opacity"])
        self.assertTrue(summary["repeats_confined_to_permitted_scope"])
        self.assertTrue(summary["opening_construction_and_reset_tail_globally_distinct"])

        reset_boundary_hashes = [f"reset-boundary-{index}" for index in range(115)]
        reset_boundary_hashes[110] = reset_boundary_hashes[69]
        reset_boundary_summary = _summarize_frame_hashes(
            reset_boundary_hashes,
            (38, 109),
            algorithm="sha256",
            raster_kind="test raster",
        )
        self.assertFalse(reset_boundary_summary["repeats_confined_to_full_opacity"])
        self.assertTrue(reset_boundary_summary["repeats_confined_to_permitted_scope"])
        self.assertEqual(reset_boundary_summary["intentional_reset_boundary_repeat_count"], 1)
        self.assertEqual(
            reset_boundary_summary["intentional_reset_boundary_repeat_evidence"],
            [{
                "hash": "reset-boundary-69",
                "frame_indices": [69, 110],
                "classification": "intentional_reset_boundary_repeat",
            }],
        )

        strict_hashes = [f"strict-{index}" for index in range(75)]
        strict_hashes[60] = strict_hashes[38]
        with self.assertRaisesRegex(RuntimeError, "75 frames or fewer"):
            _summarize_frame_hashes(
                strict_hashes,
                (38, 69),
                algorithm="sha256",
                raster_kind="test raster",
            )

        outside_scope = [f"outside-{index}" for index in range(115)]
        outside_scope[79] = outside_scope[10]
        with self.assertRaisesRegex(RuntimeError, "except reset boundary frame 110"):
            _summarize_frame_hashes(
                outside_scope,
                (38, 109),
                algorithm="sha256",
                raster_kind="test raster",
            )

        reset_tail_repeat = [f"reset-tail-{index}" for index in range(115)]
        reset_tail_repeat[111] = reset_tail_repeat[69]
        with self.assertRaisesRegex(RuntimeError, "except reset boundary frame 110"):
            _summarize_frame_hashes(
                reset_tail_repeat,
                (38, 109),
                algorithm="sha256",
                raster_kind="test raster",
            )

        adjacent = [f"adjacent-{index}" for index in range(115)]
        adjacent[39] = adjacent[38]
        with self.assertRaisesRegex(RuntimeError, "adjacent duplicate"):
            _summarize_frame_hashes(
                adjacent,
                (38, 109),
                algorithm="sha256",
                raster_kind="test raster",
            )

        too_few_unique = [f"outside-unique-{index}" for index in range(115)]
        for index in range(38, 110):
            too_few_unique[index] = f"steady-{(index - 38) % 31}"
        with self.assertRaisesRegex(RuntimeError, "at least 75 unique"):
            _summarize_frame_hashes(
                too_few_unique,
                (38, 109),
                algorithm="sha256",
                raster_kind="test raster",
            )

    def test_worker_contains_all_twelve_per_style_scene_contracts(self) -> None:
        source = (SCRIPT_DIR / "svg2gif.js").read_text(encoding="utf-8")
        for token in (
            "const SCENE_CONTRACTS = Object.freeze({",
            '"memory-weave": Object.freeze({',
            '"tool-grounding": Object.freeze({',
            '"service-blueprint": Object.freeze({',
            '"memory-lifecycle": Object.freeze({',
            '"agent-orchestration": Object.freeze({',
            '"governed-runtime": Object.freeze({',
            '"token-stream": Object.freeze({',
            '"golden-circuit": Object.freeze({',
            '"review-trace": Object.freeze({',
            '"cloud-flow": Object.freeze({',
            '"event-transit": Object.freeze({',
            '"ops-pulse": Object.freeze({',
            "const PRESETS = new Set(Object.keys(SCENE_CONTRACTS))",
            'const MINIMUM_FRAME_COUNT = 55',
            'const EMPTY_OPENING_FRAME = 0',
            'const STYLE_1_DRAW_SCHEDULE = Object.freeze([',
            'Object.freeze({ role: "ingress", order: 0, start: 1, end: 8 })',
            'Object.freeze({ role: "resolve", order: 1, start: 17, end: 24 })',
            'Object.freeze({ role: "response-context", order: 0, start: 29, end: 36 })',
            'const STYLE_2_DRAW_SCHEDULE = Object.freeze([',
            'Object.freeze({ role: "grounding", stage: 6, order: 0, start: 21, end: 28 })',
            'Object.freeze({ role: "grounding", stage: 6, order: 1, start: 25, end: 32 })',
            'const STYLE_3_DRAW_SCHEDULE = Object.freeze([',
            'Object.freeze({ role: "fanout", stage: 3, order: 2, start: 14, end: 19 })',
            'Object.freeze({ role: "data-write", stage: 4, order: 2, start: 24, end: 29 })',
            'Object.freeze({ role: "telemetry", stage: 6, order: 0, start: 31, end: 36 })',
            'const STYLE_4_DRAW_SCHEDULE = Object.freeze([',
            'Object.freeze({ role: "sample", stage: 1, order: 0, start: 1, end: 4 })',
            'Object.freeze({ role: "remember", stage: 4, order: 0, start: 13, end: 22 })',
            'Object.freeze({ role: "recall", stage: 6, order: 0, start: 27, end: 36 })',
            'const STYLE_5_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_6_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_7_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_8_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_9_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_10_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_11_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_12_DRAW_SCHEDULE = Object.freeze([',
            'const STYLE_1_STREAM_CONTRACT = Object.freeze({',
            'const STYLE_2_STREAM_CONTRACT = Object.freeze({',
            'const STYLE_3_STREAM_CONTRACT = Object.freeze({',
            'const STYLE_4_STREAM_CONTRACT = Object.freeze({',
            'const SPECIALIZED_STREAM_CONTRACTS = Object.freeze({',
            'signaturePrimitive: "glass-task-capsule"',
            'signaturePrimitive: "policy-seal"',
            'signaturePrimitive: "token-train"',
            'signaturePrimitive: "gem-tracer"',
            'signaturePrimitive: "review-cursor"',
            'signaturePrimitive: "region-chevron-pair-or-replication-capsule"',
            'signaturePrimitive: "event-train-or-branch-car"',
            'signaturePrimitive: "ecg-head-or-telemetry-export-packet"',
            'fadeInFactors: Object.freeze([0.30, 0.65, 1.00])',
            'bodyDashPattern: Object.freeze([16, 25])',
            'headDashPattern: Object.freeze([6, 35])',
            'bodyDashPattern: Object.freeze([15, 26])',
            'headDashPattern: Object.freeze([5, 36])',
            'dashPeriod: 41',
            'dashOffsetPerFrame: -6.0',
            'headLeadOffset: -10',
            'bodyOpacity: 0.90',
            'bodyOpacity: 0.94',
            'headOpacity: 0.98',
            'headOpacity: 1.00',
            'headStrokeWidth: 2.20',
            'headStrokeWidth: 2.00',
            'bodyPrimitive: "terminal-evidence-stream"',
            'headPrimitive: "terminal-command-head"',
            'bodyPrimitive: "blueprint-distribution-wave"',
            'beadPrimitive: "blueprint-registration-bead"',
            'beadAdvancePerFrame: 6.0',
            'beadRadius: 3.0',
            'beadStrokeWidth: 1.2',
            'dashPeriod: 43',
            'phaseOrderMultiplier: 0',
            'expectedStreamPhases: Object.freeze([7, 14, 21, 21, 21, 28, 28, 28, 35, 42])',
            'expectedStreamPhases: Object.freeze([7, 14, 21, 28, 35, 42])',
            'bodyPrimitive: "notion-memory-rail"',
            'cardPrimitive: "notion-memory-card"',
            'bodyDashPattern: Object.freeze([12, 35])',
            'dashPeriod: 47',
            'endpointClearance: 8',
            'outerRect: Object.freeze({ x: -7, y: -5, width: 14, height: 10, rx: 2 })',
            'inkStrokeWidth: 2.0',
            'inkLinecap: "butt"',
            'inkShapeRendering: "crispEdges"',
            'initialNormalizedProgress: Object.freeze([0.08, 0.22, 0.36, 0.50, 0.64, 0.78])',
            'bodyColor: "inherit-source-stroke"',
            'headColor: "#f8fafc"',
            'bodyWidthDescription: "min(3.8, max(3.0, source_stroke * 1.50))"',
            'resolvedStrokeWidth: 3.45',
            'expectedStreamPhases: Object.freeze([6, 12, 18, 24, 30, 36, 39, 1])',
            '"#22c55e", "#fb7185", "#fb7185", "#f97316"',
            'const TERMINAL_CURSOR_CONTRACT = Object.freeze({',
            'primitive: "terminal-prompt-cursor"',
            'nodeId: "terminal"',
            'sourceText: "_"',
            'periodFrames: 16',
            'brightFrames: 8',
            'absentFrames: 8',
            'brightOpacity: 0.95',
            'height: 2.2',
            'fill: "#a7f3d0"',
            'data-motion-layer", "connector-draw-on-with-persistent-data-flow"',
            'prepareDecoration(edge, "connector-draw-on", false)',
            'prepareDecoration(edge, "settled-connector", true)',
            'prepareDecoration(edge, persistentStreamContract.bodyPrimitive, false)',
            'prepareDecoration(edge, persistentStreamContract.headPrimitive, false)',
            'function addBlueprintDistributionWave(edge, entry)',
            'function addNotionMemoryCardHandoff(edge, entry)',
            'edge.getPointAtLength(beadDistance)',
            'bead.setAttribute("cx", String(point.x))',
            'bead.setAttribute("cy", String(point.y))',
            'animated_attributes: ["cx", "cy", "opacity"]',
            'animated_attributes: ["transform", "opacity"]',
            "sourceHidingSelectors.join",
            '[data-graph-role="decoration"][data-owner]:not([data-motion-primitive])',
            'appendMotionAttributes(clone, "settled-owner-decoration", owner)',
            '[data-graph-role="node"][data-span-id]:not([data-span-id=""])',
            "ownerDecorationSourceOpeningVisibleCount",
            "traceSpanSourceOpeningVisibleCount",
            'data-motion-primitive", "route-label-arrival"',
            'const routeKey = (role, order, stage) => selectedSceneContract.stageAwareRouteKey',
            "requires exact (motion role, motion order) coverage",
            "const edgeForEntry = (entry) => edgeForKey(entry.role, entry.order, entry.stage)",
            'persistentStreamContract.bodyColor === "inherit-source-stroke"',
            "% persistentStreamContract.dashPeriod",
            "(frame - persistentStreamContract.start) * persistentStreamContract.dashOffsetPerFrame",
            "persistentStreamContract.bodyOpacity * fade",
            "persistentStreamContract.headOpacity * fade",
            "dashOffset + persistentStreamContract.headLeadOffset",
            "motionLayer.append(stream, packetHead)",
            'root.append(signatureLayer)',
            'cursor.setAttribute("opacity", String(opacity))',
            "time * selectedFps - 0.5",
            "selectedFrameCount - resetOpacitySamples.length",
            "maximumConcurrentDraws > selectedSceneContract.requiredMaximumConcurrentDraws",
            "const progress = raw",
            "const RESET_OPACITY_SAMPLES = Object.freeze([1.00, 0.7575, 0.515, 0.2725, 0.03])",
            "resetOpacitySamples[upperIndex] - resetOpacitySamples[lowerIndex]",
            "reset_opacity_samples: resetOpacitySamples",
            "travel_easing: \"linear\"",
            "assertStaticDomUnchanged",
            "source_edges_hidden_by_transient_css: true",
            "connectors_visible_at_opening: false",
            "nodes_visible_every_frame: true",
            "topology_draw_on: true",
            "settled_topology_dynamic: true",
            "draw_clones: drawReports.length",
            "settled_marker_clones: drawReports.length",
            "stream_count: persistentStreamReports.length",
            "packet_head_count: persistentPacketHeadReports.length",
            "persistent_streams: persistentStreamReports",
            "persistent_packet_heads: persistentPacketHeadReports",
            "full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd]",
            'direction: "source-to-target"',
            'role: "ingress", order: 0, expected: Object.freeze(["right"])',
            'role: "delegate", order: 0, expected: Object.freeze(["down", "left", "down"])',
            'role: "grounding", order: 0, expected: Object.freeze(["up", "left", "up"])',
            'role: "grounding", order: 1, expected: Object.freeze(["right"])',
            "direction_sentinels: directionSentinels",
            "route_label_clones: routeLabels.length",
            "text_geometry_motion: 0",
            "route_label_opacity_states: routeLabels.length",
            "integer-frame-index-centers-with-steady-state-plus-reset-boundary-repeat-scope",
            "fonts-ready-plus-two-animation-frames-before-capture",
        ):
            with self.subTest(token=token):
                self.assertIn(token, source)
        for removed in (
            "image-breathe",
            "installRasterRuntime",
            "addPacket",
            "addNodeHalo",
            "addEndpointRipple",
            "addPersistentTransit",
            "tintTowardWhite",
            'data-motion-primitive", "connector-tracer"',
            "thin-connector-tracer",
            "static_diagram_visible_every_frame",
            "LIVE_TAIL_SCHEDULE",
            "addLiveTail",
            "live-memory-tail",
            "live_tail_contract",
            "time / totalDuration",
            "Math.min(3.4, Math.max(2.4, sourceWidth * 1.30))",
            "dashPattern: Object.freeze([12, 28])",
            "dashOffsetPerFrame: -3.0",
            "persistentStreamContract.opacity",
            "mod 40",
            "addNodeGlowPulse",
            "addTerminalTextTyping",
            "addScanLine",
            "addCameraMotion",
            "addAnimatedBackground",
        ):
            with self.subTest(removed=removed):
                self.assertNotIn(removed, source)

    def test_public_docs_describe_draw_on_then_live_operation(self) -> None:
        english = (ROOT / "README.md").read_text(encoding="utf-8")
        chinese = (ROOT / "README.zh.md").read_text(encoding="utf-8")
        reference = (ROOT / "references" / "motion-effects.md").read_text(encoding="utf-8")
        self.assertIn("connectors begin absent", english)
        self.assertIn("连接线从无到有", chinese)
        self.assertIn("connector-draw-on-with-persistent-data-flow", reference)
        self.assertIn("glass task capsule", english)
        self.assertIn("三格 token train", chinese)
        self.assertIn("persistent-data-flow-head", reference)
        self.assertIn("Styles 1–12 are enabled", reference)
        self.assertIn("Style 2 — Dark Terminal evidence trace", reference)
        self.assertIn("(data-motion-role, data-motion-order)", reference)
        self.assertIn("terminal-evidence-stream", reference)
        self.assertIn("terminal-command-head", reference)
        self.assertIn("terminal-prompt-cursor", reference)
        self.assertIn("6px/frame", reference)
        self.assertIn("3px/frame", reference)
        self.assertIn("Styles 5–12", reference)
        self.assertIn("blueprint-distribution-wave", reference)
        self.assertIn("blueprint-registration-bead", reference)
        self.assertIn("Style 3 — Blueprint distribution wave", reference)
        self.assertIn("notion-memory-rail", reference)
        self.assertIn("notion-memory-card", reference)
        self.assertIn("14×10", english)
        self.assertIn("14×10", chinese)
        self.assertIn("Style 4 — Notion memory-card handoff", reference)
        self.assertIn('shape-rendering="crispEdges"', reference)
        self.assertIn("two non-touching unequal-length ink strokes", reference)
        self.assertIn("Styles 1–12 are enabled and their signature", reference)
        self.assertIn("`+2s-settled-flow`", reference)
        self.assertIn("5.75 seconds", english)
        self.assertIn("第 38–109 帧", chinese)
        self.assertIn("zero adjacent duplicates", reference)
        self.assertIn("glass-task-capsule", reference)
        self.assertIn("waterfall-scanner", reference)
        self.assertIn("All twelve style contracts are user-approved", english)
        self.assertIn("Style 1–12", chinese)
        self.assertIn("Generate a GIF", english)
        self.assertIn("生成 GIF", chinese)
        self.assertIn("制作 GIF", reference)
        self.assertNotIn("awaiting_user_review", reference)
        self.assertNotIn("complete diagram stays static", english)
        self.assertNotIn("完整静态图始终可读", chinese)

    @unittest.skipUnless(
        os.environ.get("FIREWORKS_RUN_RENDER_REGRESSION") == "1"
        and shutil.which("node")
        and _imagemagick_available(),
        "Set FIREWORKS_RUN_RENDER_REGRESSION=1 with Node.js and ImageMagick to run the raw Chromium frame gate",
    )
    def test_raw_worker_frames_preserve_styles_one_through_three_and_prove_style_four_notion_handoff(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            style_one_svg = root / "style-1.svg"
            style_two_svg = root / "style-2.svg"
            style_three_svg = root / "style-3.svg"
            style_four_svg = root / "style-4.svg"
            self.render_fixture("mem0-style1.json", "memory", style_one_svg)
            self.render_fixture("tool-call-style2.json", "agent", style_two_svg)
            self.render_fixture("microservices-style3.json", "architecture", style_three_svg)
            self.render_fixture("agent-memory-types-style4.json", "memory", style_four_svg)
            self.assertEqual(
                hashlib.sha256(style_four_svg.read_bytes()).hexdigest(),
                QUALITY_SNAPSHOTS["4"]["sha256"],
            )

            probe = subprocess.run(
                [str(shutil.which("node")), str(SCRIPT_DIR / "svg2gif.js"), "--probe"],
                text=True,
                capture_output=True,
                check=False,
                timeout=20,
            )
            if probe.returncode:
                self.skipTest(f"motion renderer unavailable: {probe.stderr.strip()}")

            def render_raw(
                svg: Path,
                preset: str,
                duration: float,
                frame_count: int,
                height: int,
                destination: Path,
            ) -> tuple[list[str], dict[str, object]]:
                destination.mkdir()
                process = subprocess.run(
                    [
                        str(shutil.which("node")),
                        str(SCRIPT_DIR / "svg2gif.js"),
                        "--input",
                        str(svg),
                        "--frames-dir",
                        str(destination),
                        "--preset",
                        preset,
                        "--duration",
                        str(duration),
                        "--fps",
                        "20",
                        "--width",
                        "960",
                        "--height",
                        str(height),
                    ],
                    text=True,
                    capture_output=True,
                    check=False,
                    timeout=120,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
                frames = sorted(destination.glob("frame-*.png"))
                self.assertEqual(len(frames), frame_count)
                report = json.loads(process.stdout)
                return [hashlib.sha256(frame.read_bytes()).hexdigest() for frame in frames], report

            hashes_55, report_55 = render_raw(
                style_one_svg,
                "memory-weave",
                2.75,
                55,
                680,
                root / "style-one-55",
            )
            hashes_75, report_75 = render_raw(
                style_one_svg,
                "memory-weave",
                3.75,
                75,
                680,
                root / "style-one-75",
            )
            style_two_hashes, style_two_report = render_raw(
                style_two_svg,
                "tool-grounding",
                3.75,
                75,
                720,
                root / "style-two-75",
            )
            style_three_hashes, style_three_report = render_raw(
                style_three_svg,
                "service-blueprint",
                3.75,
                75,
                720,
                root / "style-three-75",
            )
            style_four_hashes, style_four_report = render_raw(
                style_four_svg,
                "memory-lifecycle",
                3.75,
                75,
                620,
                root / "style-four-75",
            )

            baseline_root_value = os.environ.get("FIREWORKS_STYLE4_PRE_BASELINE_ROOT")
            if baseline_root_value:
                baseline_root = Path(baseline_root_value)
                for style, post_hashes in (
                    ("style01", hashes_75),
                    ("style02", style_two_hashes),
                    ("style03", style_three_hashes),
                ):
                    manifest_path = baseline_root / f"{style}-normalized-manifest.json"
                    self.assertTrue(manifest_path.is_file(), manifest_path)
                    baseline_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                    self.assertEqual(
                        post_hashes,
                        [frame["sha256"] for frame in baseline_manifest["frames"]],
                        f"{style} post-edit raw frames differ from the pre-edit baseline",
                    )

            style_four_v1_root_value = os.environ.get("FIREWORKS_STYLE4_V1_RAW_ROOT")
            if style_four_v1_root_value:
                style_four_v1_frames = sorted(Path(style_four_v1_root_value).glob("frame-*.png"))
                self.assertEqual(len(style_four_v1_frames), 75)
                style_four_v1_hashes = [
                    hashlib.sha256(frame.read_bytes()).hexdigest()
                    for frame in style_four_v1_frames
                ]
                self.assertEqual(
                    style_four_hashes[:36],
                    style_four_v1_hashes[:36],
                    "Style 4 V2 frames 0-35 must stay byte-identical to V1",
                )
                self.assertTrue(
                    any(
                        v2_hash != v1_hash
                        for v2_hash, v1_hash in zip(style_four_hashes[36:], style_four_v1_hashes[36:])
                    ),
                    "Style 4 V2 card frames must differ from the rejected V1 card geometry",
                )

            pixel_pattern = re.compile(
                r"^(\d+),(\d+): \(([0-9.]+),([0-9.]+),([0-9.]+)(?:,[0-9.]+)?\)",
                re.MULTILINE,
            )

            def crop_pixels(
                frame: Path,
                x: int,
                y: int,
                width: int,
                height: int,
                half_scale: bool = False,
            ) -> dict[tuple[int, int], tuple[int, int, int]]:
                command = [
                    *_imagemagick_command(),
                    str(frame),
                    "-crop",
                    f"{width}x{height}+{x}+{y}",
                    "+repage",
                ]
                if half_scale:
                    command.extend(["-filter", "point", "-resize", "50%"])
                command.append("txt:-")
                process = subprocess.run(
                    command,
                    text=True,
                    capture_output=True,
                    check=False,
                    timeout=20,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
                return {
                    (int(match.group(1)), int(match.group(2))): tuple(
                        round(float(match.group(index))) for index in (3, 4, 5)
                    )
                    for match in pixel_pattern.finditer(process.stdout)
                }

            def crop_half_frame_pixels(
                frame: Path,
                center_x: float,
                center_y: float,
            ) -> dict[tuple[int, int], tuple[int, int, int]]:
                crop_x = round(center_x / 2) - 6
                crop_y = round(center_y / 2) - 6
                process = subprocess.run(
                    _imagemagick_command(
                        str(frame),
                        "-filter",
                        "point",
                        "-resize",
                        "50%",
                        "-crop",
                        f"13x13+{crop_x}+{crop_y}",
                        "+repage",
                        "txt:-",
                    ),
                    text=True,
                    capture_output=True,
                    check=False,
                    timeout=20,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
                pixels = {
                    (int(match.group(1)), int(match.group(2))): tuple(
                        round(float(match.group(index))) for index in (3, 4, 5)
                    )
                    for match in pixel_pattern.finditer(process.stdout)
                }
                self.assertEqual(len(pixels), 13 * 13)
                return pixels

            def contiguous_runs(values: list[int]) -> list[list[int]]:
                runs: list[list[int]] = []
                for value in sorted(set(values)):
                    if not runs or value != runs[-1][-1] + 1:
                        runs.append([value])
                    else:
                        runs[-1].append(value)
                return runs

            def head_run(
                pixels: dict[tuple[int, int], tuple[int, int, int]],
                row: int,
                expected: tuple[int, int, int],
                lengths: set[int],
            ) -> list[int]:
                candidates = [
                    x
                    for (x, y), color in pixels.items()
                    if y == row and max(abs(color[index] - expected[index]) for index in range(3)) <= 8
                ]
                matches = [run for run in contiguous_runs(candidates) if len(run) in lengths]
                self.assertTrue(matches, (row, expected, contiguous_runs(candidates)))
                return matches[0]

            def bead_centroid(
                pixels: dict[tuple[int, int], tuple[int, int, int]],
            ) -> tuple[float, float]:
                candidates = [
                    (x, y)
                    for (x, y), color in pixels.items()
                    if color[0] >= 218 and color[1] >= 238 and color[2] >= 250
                ]
                self.assertGreaterEqual(len(candidates), 3, candidates)
                return (
                    sum(x for x, _ in candidates) / len(candidates),
                    sum(y for _, y in candidates) / len(candidates),
                )

            def assert_half_scale_card_signature(
                pixels: dict[tuple[int, int], tuple[int, int, int]],
                expected_ink: tuple[int, int, int],
                orientation: str,
            ) -> dict[str, object]:
                interior = range(3, 8)

                def is_ink(color: tuple[int, int, int]) -> bool:
                    return max(abs(color[index] - expected_ink[index]) for index in range(3)) <= 35

                def is_background(color: tuple[int, int, int]) -> bool:
                    return min(color) >= 245

                def longest_contiguous_run(values: list[int]) -> list[int]:
                    runs = contiguous_runs(values)
                    return max(runs, key=len, default=[])

                axis_candidates: list[tuple[int, list[int]]] = []
                for axis in range(2, 10):
                    colored = [
                        position
                        for position in interior
                        if is_ink(
                            pixels[(position, axis)]
                            if orientation == "horizontal"
                            else pixels[(axis, position)]
                        )
                    ]
                    run = longest_contiguous_run(colored)
                    if len(run) >= 2:
                        axis_candidates.append((axis, run))

                self.assertEqual(
                    len(axis_candidates),
                    2,
                    f"{orientation} card must rasterize as exactly two interior ink strokes",
                )
                (first_axis, first_run), (second_axis, second_run) = axis_candidates
                self.assertGreaterEqual(
                    second_axis - first_axis,
                    2,
                    f"{orientation} card ink strokes touch after 50% point downsampling",
                )
                self.assertNotEqual(
                    len(first_run),
                    len(second_run),
                    f"{orientation} card ink strokes lost their unequal-length signature",
                )
                separator_axes = [
                    axis
                    for axis in range(first_axis + 1, second_axis)
                    if all(
                        is_background(
                            pixels[(position, axis)]
                            if orientation == "horizontal"
                            else pixels[(axis, position)]
                        )
                        for position in interior
                    )
                ]
                self.assertTrue(
                    separator_axes,
                    f"{orientation} card lacks a full background separator axis at 50%",
                )
                return {
                    "orientation": orientation,
                    "stroke_axes": [first_axis, second_axis],
                    "stroke_lengths": [len(first_run), len(second_run)],
                    "separator_axes": separator_axes,
                }

            style_one_frame_38 = root / "style-one-75" / "frame-000038.png"
            style_one_frame_39 = root / "style-one-75" / "frame-000039.png"
            style_two_frame_38 = root / "style-two-75" / "frame-000038.png"
            style_two_frame_39 = root / "style-two-75" / "frame-000039.png"

            style_one_full_38 = crop_pixels(style_one_frame_38, 180, 168, 100, 8)
            style_one_full_39 = crop_pixels(style_one_frame_39, 180, 168, 100, 8)
            style_one_head_38 = head_run(style_one_full_38, 4, (220, 241, 253), {6})
            style_one_head_39 = head_run(style_one_full_39, 4, (220, 241, 253), {6})
            self.assertEqual(style_one_head_39[0] - style_one_head_38[0], 6)
            self.assertTrue(
                all(
                    style_one_full_38[(x, 2)][0] < 80
                    and style_one_full_38[(x, 2)][1] > 150
                    and style_one_full_38[(x, 2)][2] > 190
                    for x in style_one_head_38
                )
            )

            style_two_full_38 = crop_pixels(style_two_frame_38, 200, 179, 80, 8)
            style_two_full_39 = crop_pixels(style_two_frame_39, 200, 179, 80, 8)
            style_two_head_38 = head_run(style_two_full_38, 4, (248, 250, 252), {5})
            style_two_head_39 = head_run(style_two_full_39, 4, (248, 250, 252), {5})
            self.assertEqual(style_two_head_39[0] - style_two_head_38[0], 6)
            self.assertTrue(
                all(
                    style_two_full_38[(x, 2)][0] > 90
                    and style_two_full_38[(x, 2)][2] > style_two_full_38[(x, 2)][0]
                    for x in style_two_head_38
                )
            )

            style_one_half_38 = crop_pixels(style_one_frame_38, 180, 168, 100, 8, half_scale=True)
            style_one_half_39 = crop_pixels(style_one_frame_39, 180, 168, 100, 8, half_scale=True)
            style_one_half_head_38 = head_run(style_one_half_38, 1, (220, 241, 253), {3})
            style_one_half_head_39 = head_run(style_one_half_39, 1, (220, 241, 253), {3})
            self.assertEqual(style_one_half_head_39[0] - style_one_half_head_38[0], 3)

            style_two_half_38 = crop_pixels(style_two_frame_38, 200, 179, 80, 8, half_scale=True)
            style_two_half_39 = crop_pixels(style_two_frame_39, 200, 179, 80, 8, half_scale=True)
            style_two_half_head_38 = head_run(style_two_half_38, 1, (248, 250, 252), {2, 3})
            style_two_half_head_39 = head_run(style_two_half_39, 1, (248, 250, 252), {2, 3})
            self.assertEqual(style_two_half_head_39[0] - style_two_half_head_38[0], 3)

            style_three_frame_0 = root / "style-three-75" / "frame-000000.png"
            style_three_frame_38 = root / "style-three-75" / "frame-000038.png"
            style_three_frame_39 = root / "style-three-75" / "frame-000039.png"
            style_three_frame_42 = root / "style-three-75" / "frame-000042.png"
            style_three_frame_43 = root / "style-three-75" / "frame-000043.png"
            empty_ingress = crop_pixels(style_three_frame_0, 225, 168, 70, 10)
            live_ingress = crop_pixels(style_three_frame_38, 225, 168, 70, 10)
            def cyan(color):
                return color[0] < 100 and color[1] > 150 and color[2] > 190

            self.assertEqual(sum(cyan(color) for color in empty_ingress.values()), 0)
            self.assertGreater(sum(cyan(color) for color in live_ingress.values()), 0)

            style_three_ingress_38 = bead_centroid(crop_pixels(style_three_frame_38, 210, 163, 100, 20))
            style_three_ingress_39 = bead_centroid(crop_pixels(style_three_frame_39, 210, 163, 100, 20))
            self.assertEqual(style_three_ingress_39[0] - style_three_ingress_38[0], 6)
            self.assertEqual(style_three_ingress_39[1], style_three_ingress_38[1])
            style_three_half_38 = bead_centroid(
                crop_pixels(style_three_frame_38, 210, 163, 100, 20, half_scale=True)
            )
            style_three_half_39 = bead_centroid(
                crop_pixels(style_three_frame_39, 210, 163, 100, 20, half_scale=True)
            )
            self.assertAlmostEqual(style_three_half_39[0] - style_three_half_38[0], 3)

            data_write_centroids_42 = [
                bead_centroid(crop_pixels(style_three_frame_42, x, 440, 20, 10))
                for x in (140, 370, 600)
            ]
            data_write_centroids_43 = [
                bead_centroid(crop_pixels(style_three_frame_43, x, 446, 20, 10))
                for x in (140, 370, 600)
            ]
            self.assertEqual(len({centroid[1] for centroid in data_write_centroids_42}), 1)
            self.assertEqual(len({centroid[1] for centroid in data_write_centroids_43}), 1)
            self.assertTrue(
                all(
                    (446 + after[1]) - (440 + before[1]) == 6
                    for before, after in zip(data_write_centroids_42, data_write_centroids_43)
                )
            )

            cursor_colors = {
                frame: crop_pixels(
                    root / "style-two-75" / f"frame-{frame:06d}.png",
                    432,
                    407,
                    1,
                    1,
                )[(0, 0)]
                for frame in (15, 16, 23, 24, 31, 32, 39, 40, 69, 70, 71, 72, 73, 74)
            }
            for bright, absent in ((16, 15), (23, 24), (32, 31), (39, 40), (69, 24), (70, 24)):
                self.assertGreater(cursor_colors[bright][1], cursor_colors[absent][1] + 60)
            self.assertEqual(
                [cursor_colors[frame][1] for frame in (70, 71, 72, 73, 74)],
                sorted([cursor_colors[frame][1] for frame in (70, 71, 72, 73, 74)], reverse=True),
            )

            style_four_frame_0 = root / "style-four-75" / "frame-000000.png"
            style_four_frame_38 = root / "style-four-75" / "frame-000038.png"
            empty_sample = crop_pixels(style_four_frame_0, 223, 203, 44, 14)
            live_sample = crop_pixels(style_four_frame_38, 223, 203, 44, 14)
            def notion_blue(color):
                return color[2] > 180 and color[1] > 90 and color[0] < 120

            self.assertEqual(sum(notion_blue(color) for color in empty_sample.values()), 0)
            self.assertGreater(sum(notion_blue(color) for color in live_sample.values()), 0)

            card_reports = {
                card["role"]: card
                for card in style_four_report["scene_report"]["notion_memory_cards"]
            }
            live_frame_offset = 38 - 36
            card_centers = {
                "sample": (
                    card_reports["sample"]["initial_point"]["x"] + 6 * live_frame_offset,
                    card_reports["sample"]["initial_point"]["y"],
                ),
                "remember": (
                    card_reports["remember"]["initial_point"]["x"],
                    card_reports["remember"]["initial_point"]["y"] + 6 * live_frame_offset,
                ),
                "recall": (
                    card_reports["recall"]["initial_point"]["x"],
                    card_reports["recall"]["initial_point"]["y"] - 6 * live_frame_offset,
                ),
            }
            raster_signatures = {
                "sample": assert_half_scale_card_signature(
                    crop_half_frame_pixels(style_four_frame_38, *card_centers["sample"]),
                    (59, 130, 246),
                    "horizontal",
                ),
                "remember": assert_half_scale_card_signature(
                    crop_half_frame_pixels(style_four_frame_38, *card_centers["remember"]),
                    (5, 150, 105),
                    "vertical-down",
                ),
                "recall": assert_half_scale_card_signature(
                    crop_half_frame_pixels(style_four_frame_38, *card_centers["recall"]),
                    (234, 88, 12),
                    "vertical-up",
                ),
            }
            stroke_lengths = {
                role: signature["stroke_lengths"]
                for role, signature in raster_signatures.items()
            }
            self.assertTrue(
                all(2 <= length <= 5 for lengths in stroke_lengths.values() for length in lengths),
                stroke_lengths,
            )
            self.assertGreater(stroke_lengths["sample"][0], stroke_lengths["sample"][1])
            self.assertLess(stroke_lengths["remember"][0], stroke_lengths["remember"][1])
            self.assertGreater(stroke_lengths["recall"][0], stroke_lengths["recall"][1])

        self.assertEqual(hashes_75[:36], hashes_55[:36])
        self.assertTrue(any(left != right for left, right in zip(hashes_75[36:55], hashes_55[36:])))
        self.assertEqual(len(set(hashes_75)), 75)
        self.assertEqual(len(set(style_two_hashes)), 75)
        self.assertEqual(len(set(style_three_hashes)), 75)
        self.assertEqual(len(set(style_four_hashes)), 75)
        for report in (report_55, report_75):
            scene = report["scene_report"]
            self.assertEqual(scene["grammar_version"], "3.4")
            self.assertEqual(scene["stream_count"], 8)
            self.assertEqual(scene["packet_head_count"], 8)
            self.assertEqual(
                [stream["initial_phase"] for stream in scene["persistent_streams"]],
                [7, 14, 21, 28, 31, 35, 1, 8],
            )
            self.assertTrue(all(stream["stroke_width"] == 3.84 for stream in scene["persistent_streams"]))
            self.assertTrue(all(stream["marker_free"] for stream in scene["persistent_streams"]))
            self.assertTrue(all(stream["filter_free"] for stream in scene["persistent_streams"]))
            self.assertTrue(all(head["stroke_width"] == 2.20 for head in scene["persistent_packet_heads"]))
            self.assertTrue(all(head["dash_offset_from_body"] == -10 for head in scene["persistent_packet_heads"]))
            self.assertTrue(all(head["marker_free"] for head in scene["persistent_packet_heads"]))
            self.assertTrue(all(head["filter_free"] for head in scene["persistent_packet_heads"]))
            sentinels = scene["direction_sentinels"]
            self.assertEqual([sentinel["passed"] for sentinel in sentinels], [True, True, True])

        style_two_scene = style_two_report["scene_report"]
        self.assertEqual(style_two_scene["grammar_version"], "3.4")
        self.assertEqual(style_two_scene["preset"], "tool-grounding")
        self.assertEqual(style_two_scene["effects"] if "effects" in style_two_scene else style_two_report["effects"], 25)
        self.assertEqual(style_two_scene["stream_count"], 8)
        self.assertEqual(style_two_scene["packet_head_count"], 8)
        self.assertEqual(style_two_scene["maximum_concurrent_draws"], 2)
        self.assertEqual(
            [entry["schedule_key"] for entry in style_two_scene["draw_schedule"]],
            ["ingress/0", "delegate/0", "tool-call/0", "inspect/0", "index/0", "grounding/0", "grounding/1", "answer/0"],
        )
        self.assertEqual(
            [stream["initial_phase"] for stream in style_two_scene["persistent_streams"]],
            [6, 12, 18, 24, 30, 36, 39, 1],
        )
        self.assertEqual(
            [stream["color"] for stream in style_two_scene["persistent_streams"]],
            ["#a855f7", "#a855f7", "#38bdf8", "#38bdf8", "#22c55e", "#fb7185", "#fb7185", "#f97316"],
        )
        self.assertTrue(all(stream["stroke_width"] == 3.45 for stream in style_two_scene["persistent_streams"]))
        self.assertTrue(all(stream["marker_free"] and stream["filter_free"] for stream in style_two_scene["persistent_streams"]))
        self.assertTrue(all(head["stroke_width"] == 2 for head in style_two_scene["persistent_packet_heads"]))
        self.assertTrue(all(head["marker_free"] and head["filter_free"] for head in style_two_scene["persistent_packet_heads"]))
        self.assertEqual([sentinel["passed"] for sentinel in style_two_scene["direction_sentinels"]], [True] * 8)
        self.assertEqual(style_two_scene["cursor_count"], 1)
        cursor = style_two_scene["terminal_prompt_cursor"]
        self.assertEqual(cursor["primitive"], "terminal-prompt-cursor")
        self.assertEqual(cursor["movement"], "opacity-only")
        self.assertEqual(cursor["animated_attributes"], ["opacity"])
        self.assertEqual(cursor["period_frames"], 16)
        self.assertEqual((cursor["bright_frames_per_period"], cursor["absent_frames_per_period"]), (8, 8))
        self.assertFalse(cursor["source_text_hidden"])
        self.assertFalse(cursor["source_text_mutated"])
        self.assertEqual(cursor["rectangle"]["height"], 2.2)
        for phase in [stream["initial_phase"] for stream in style_two_scene["persistent_streams"]]:
            self.assertEqual(len({(phase - 6 * offset) % 41 for offset in range(39)}), 39)

        style_three_scene = style_three_report["scene_report"]
        self.assertEqual(style_three_scene["preset"], "service-blueprint")
        self.assertEqual((style_three_scene["source_edges"], style_three_scene["source_route_labels"]), (10, 7))
        self.assertEqual((style_three_scene["draw_clones"], style_three_scene["settled_marker_clones"]), (10, 10))
        self.assertEqual((style_three_scene["stream_count"], style_three_scene["registration_bead_count"]), (10, 10))
        self.assertEqual(style_three_scene["packet_head_count"], 0)
        self.assertEqual(style_three_scene["maximum_concurrent_draws"], 2)
        self.assertTrue(style_three_scene["static_dom_guard"])
        self.assertEqual(
            [entry["schedule_key"] for entry in style_three_scene["draw_schedule"]],
            ["ingress/0", "policy/0", "fanout/0", "fanout/1", "fanout/2", "data-write/0", "data-write/1", "data-write/2", "event/0", "telemetry/0"],
        )
        self.assertEqual(
            [stream["initial_phase"] for stream in style_three_scene["persistent_streams"]],
            [7, 14, 21, 21, 21, 28, 28, 28, 35, 42],
        )
        self.assertTrue(all(stream["stroke_width"] == 2.94 for stream in style_three_scene["persistent_streams"]))
        self.assertTrue(all(stream["marker_free"] and stream["filter_free"] for stream in style_three_scene["persistent_streams"]))
        self.assertEqual(len(style_three_scene["blueprint_registration_beads"]), 10)
        self.assertTrue(
            all(
                bead["radius"] == 3
                and bead["stroke_width"] == 1.2
                and bead["path_advance_per_rendered_frame"] == 6
                and bead["animated_attributes"] == ["cx", "cy", "opacity"]
                and bead["marker_free"]
                and bead["filter_free"]
                for bead in style_three_scene["blueprint_registration_beads"]
            )
        )
        data_write_beads = [bead for bead in style_three_scene["blueprint_registration_beads"] if bead["role"] == "data-write"]
        self.assertEqual([bead["path_length"] for bead in data_write_beads], [100, 100, 100])
        self.assertEqual(len({bead["initial_point"]["y"] for bead in data_write_beads}), 1)
        self.assertEqual([sentinel["passed"] for sentinel in style_three_scene["direction_sentinels"]], [True] * 10)
        self.assertTrue(all(sentinel["bead_advance_per_rendered_frame"] == 6 for sentinel in style_three_scene["direction_sentinels"]))
        self.assertEqual(style_three_scene["stage_locks"]["fanout"]["phase"], 21)
        self.assertEqual(style_three_scene["stage_locks"]["data_write"]["phase"], 28)
        for phase in [stream["initial_phase"] for stream in style_three_scene["persistent_streams"]]:
            self.assertEqual(len({(phase - 6 * offset) % 43 for offset in range(39)}), 39)

        style_four_scene = style_four_report["scene_report"]
        self.assertEqual(style_four_scene["preset"], "memory-lifecycle")
        self.assertEqual((style_four_scene["source_edges"], style_four_scene["source_route_labels"]), (6, 2))
        self.assertEqual((style_four_scene["draw_clones"], style_four_scene["settled_marker_clones"]), (6, 6))
        self.assertEqual((style_four_scene["stream_count"], style_four_scene["notion_memory_card_count"]), (6, 6))
        self.assertEqual(style_four_scene["packet_head_count"], 0)
        self.assertEqual(style_four_scene["maximum_concurrent_draws"], 1)
        self.assertTrue(style_four_scene["static_dom_guard"])
        self.assertEqual(
            [entry["schedule_key"] for entry in style_four_scene["draw_schedule"]],
            ["sample/0", "attend/0", "invoke/0", "remember/0", "consolidate/0", "recall/0"],
        )
        self.assertEqual(
            [entry["rendered_frames"] for entry in style_four_scene["draw_schedule"]],
            [[1, 4], [5, 8], [9, 12], [13, 22], [23, 26], [27, 36]],
        )
        self.assertEqual(
            [stream["initial_phase"] for stream in style_four_scene["persistent_streams"]],
            [7, 14, 21, 28, 35, 42],
        )
        self.assertEqual(
            [stream["color"] for stream in style_four_scene["persistent_streams"]],
            ["#3b82f6", "#3b82f6", "#7c3aed", "#059669", "#ea580c", "#ea580c"],
        )
        self.assertTrue(all(stream["stroke_width"] == 2.7 for stream in style_four_scene["persistent_streams"]))
        self.assertTrue(all(stream["marker_free"] and stream["filter_free"] for stream in style_four_scene["persistent_streams"]))
        cards = style_four_scene["notion_memory_cards"]
        self.assertEqual(len(cards), 6)
        self.assertEqual([card["initial_normalized_progress"] for card in cards], [0.08, 0.22, 0.36, 0.50, 0.64, 0.78])
        self.assertEqual([card["tangent_rotation"] for card in cards], [0, 0, 0, 90, 0, -90])
        self.assertEqual([card["path_length"] for card in cards], [50, 60, 50, 145, 60, 145])
        self.assertTrue(
            all(
                card["outer_rect"]["width"] == 14
                and card["outer_rect"]["height"] == 10
                and card["endpoint_clearance"] == 8
                and card["ink_stroke_width"] == 2
                and card["ink_linecap"] == "butt"
                and card["ink_shape_rendering"] == "crispEdges"
                and card["path_advance_per_rendered_frame"] == 6
                and card["animated_attributes"] == ["transform", "opacity"]
                and len(card["ink_lines"]) == 2
                and card["marker_free"]
                and card["filter_free"]
                and card["shadow_free"]
                and 8 <= card["initial_path_distance"] <= card["path_length"] - 8
                for card in cards
            )
        )
        self.assertEqual([sentinel["passed"] for sentinel in style_four_scene["direction_sentinels"]], [True] * 6)
        self.assertEqual(
            [sentinel["tangent_rotation"] for sentinel in style_four_scene["direction_sentinels"]],
            [0, 0, 0, 90, 0, -90],
        )
        self.assertTrue(all(sentinel["card_advance_per_rendered_frame"] == 6 for sentinel in style_four_scene["direction_sentinels"]))
        self.assertEqual(style_four_scene["initial_progress_vector"], [0.08, 0.22, 0.36, 0.50, 0.64, 0.78])
        self.assertEqual(style_four_scene["persistent_stream_contract"]["travel_pixels_per_frame_at_50_percent"], 3)
        self.assertEqual(style_four_scene["reset_range"], [70, 74])
        for phase in [stream["initial_phase"] for stream in style_four_scene["persistent_streams"]]:
            self.assertEqual(len({(phase - 6 * offset) % 47 for offset in range(39)}), 39)

    @unittest.skipUnless(shutil.which("node"), "Node.js is required for the renderer trust-boundary test")
    def test_worker_does_not_execute_a_renderer_module_from_the_current_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            module = root / "node_modules" / "puppeteer"
            module.mkdir(parents=True)
            canary = root / "cwd-module-executed"
            (root / "package.json").write_text('{"private":true}', encoding="utf-8")
            (module / "package.json").write_text(
                '{"name":"puppeteer","version":"0.0.0","main":"index.js"}',
                encoding="utf-8",
            )
            (module / "index.js").write_text(
                f'require("fs").writeFileSync({json.dumps(str(canary))}, "executed"); module.exports={{}};',
                encoding="utf-8",
            )
            environment = dict(os.environ)
            environment.pop("FIREWORKS_PUPPETEER_PATH", None)
            process = subprocess.run(
                [str(shutil.which("node")), str(SCRIPT_DIR / "svg2gif.js"), "--probe"],
                cwd=root,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
                timeout=20,
            )
            self.assertFalse(canary.exists(), process.stdout + process.stderr)
            self.assertNotIn("cwd:puppeteer", process.stdout + process.stderr)

    @unittest.skipUnless(
        os.environ.get("FIREWORKS_RUN_RENDER_REGRESSION") == "1" and shutil.which("node"),
        "Set FIREWORKS_RUN_RENDER_REGRESSION=1 with Node.js to run the Styles 5-12 Chromium gate",
    )
    def test_styles_five_through_twelve_real_chromium_contracts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cases = (
                (5, "agent", "multi-agent-style5.json", "agent-orchestration", 700, 9, 2),
                (6, "architecture", "system-architecture-style6.json", "governed-runtime", 700, 9, 2),
                (7, "architecture", "api-flow-style7.json", "token-stream", 700, 8, 3),
                (8, None, "dark-luxury-style8.svg", "golden-circuit", 600, 7, 2),
                (9, "architecture", "c4-review-canvas-style9.json", "review-trace", 611, 5, 2),
                (10, "architecture", "cloud-fabric-style10.json", "cloud-flow", 760, 5, 2),
                (11, "flow", "event-transit-style11.json", "event-transit", 590, 6, 2),
                (12, "architecture", "ops-pulse-style12.json", "ops-pulse", 860, 4, 1),
            )
            for style_id, mode, fixture, preset, height, edge_count, maximum_draws in cases:
                with self.subTest(style_id=style_id):
                    svg = root / f"style-{style_id}.svg"
                    if mode is None:
                        svg.write_bytes((ROOT / "fixtures" / fixture).read_bytes())
                    else:
                        self.render_fixture(fixture, mode, svg)
                    frames = root / f"style-{style_id}-frames"
                    frames.mkdir()
                    process = subprocess.run(
                        [
                            str(shutil.which("node")), str(SCRIPT_DIR / "svg2gif.js"),
                            "--input", str(svg), "--frames-dir", str(frames), "--preset", preset,
                            "--duration", "3.75", "--fps", "20", "--width", "960", "--height", str(height),
                        ],
                        text=True,
                        capture_output=True,
                        check=False,
                        timeout=120,
                    )
                    self.assertEqual(process.returncode, 0, process.stderr)
                    raw_frames = sorted(frames.glob("frame-*.png"))
                    self.assertEqual(len(raw_frames), 75)
                    self.assertEqual(len({hashlib.sha256(frame.read_bytes()).hexdigest() for frame in raw_frames}), 75)
                    report = json.loads(process.stdout)
                    scene = report["scene_report"]
                    self.assertEqual(report["frame_count"], 75)
                    self.assertEqual((report["width"], report["height"]), (960, height))
                    self.assertFalse(scene["connectors_visible_at_opening"])
                    self.assertTrue(scene["static_dom_guard"])
                    self.assertEqual(scene["stream_count"], edge_count)
                    self.assertEqual(scene["specialized_signature_count"], edge_count)
                    self.assertEqual(scene["maximum_concurrent_draws"], maximum_draws)
                    self.assertTrue(scene["live_rail_width_ceiling_passed"])
                    self.assertTrue(scene["dynamic_not_thicker_than_source"])
                    self.assertEqual(scene["source_geometry_mutation_count"], 0)
                    self.assertEqual(scene["source_text_mutation_count"], 0)
                    self.assertEqual(scene["source_marker_mutation_count"], 0)
                    self.assertTrue(all(item["passed"] for item in scene["direction_sentinels"]))
                    for signature in scene["specialized_signatures"]:
                        minimum, maximum = signature["center_travel_range"]
                        self.assertGreaterEqual(signature["initial_path_distance"], minimum)
                        self.assertLessEqual(signature["initial_path_distance"], maximum)
                        self.assertEqual(signature["path_advance_per_rendered_frame"], 6 if style_id in {5, 6, 7, 8, 10} else 5)
                        self.assertTrue(signature["marker_free"])
                        self.assertTrue(signature["filter_boundary_valid"])
                    if style_id == 8:
                        self.assertTrue(
                            all(signature["filtered_element_count"] == 1 for signature in scene["specialized_signatures"])
                        )
                    if style_id == 11:
                        self.assertEqual(scene["source_owner_decoration_count"], 8)
                        self.assertEqual(scene["settled_owner_decoration_clone_count"], 8)
                        self.assertEqual(scene["owner_decoration_source_opening_visible_count"], 0)
                        self.assertEqual(scene["owner_decoration_clone_opening_visible_count"], 0)
                        self.assertEqual(
                            [item["settle_frame"] for item in scene["owner_decorations"]],
                            [6, 12, 18, 24],
                        )
                        self.assertTrue(
                            all(item["hidden_before_settle"] for item in scene["owner_decorations"])
                        )
                    if style_id == 12:
                        self.assertEqual(scene["trace_span_reveal_count"], 4)
                        self.assertEqual(scene["trace_span_source_count"], 4)
                        self.assertEqual(scene["trace_span_source_opening_visible_count"], 0)
                        self.assertEqual(scene["non_trace_span_node_opening_hidden_count"], 0)
                        self.assertEqual(scene["source_owner_decoration_count"], 9)
                        self.assertEqual(scene["settled_owner_decoration_clone_count"], 9)
                        self.assertEqual(scene["owner_decoration_source_opening_visible_count"], 0)
                        self.assertEqual(scene["owner_decoration_clone_opening_visible_count"], 0)
                        self.assertEqual(
                            [item["settle_frame"] for item in scene["owner_decorations"]],
                            [6, 12, 18],
                        )
                        self.assertTrue(scene["scanner_contained"])
                        self.assertTrue(scene["scanner_below_span_labels"])

    @unittest.skipUnless(
        os.environ.get("FIREWORKS_RUN_RENDER_REGRESSION") == "1" and shutil.which("node"),
        "Set FIREWORKS_RUN_RENDER_REGRESSION=1 with Node.js to run the 12-style 75-vs-115 gate",
    )
    def test_all_twelve_styles_keep_frames_zero_through_seventy_byte_identical_at_115_frames(self) -> None:
        cases = (
            (1, "memory", "mem0-style1.json", "memory-weave", 680),
            (2, "agent", "tool-call-style2.json", "tool-grounding", 720),
            (3, "architecture", "microservices-style3.json", "service-blueprint", 720),
            (4, "memory", "agent-memory-types-style4.json", "memory-lifecycle", 620),
            (5, "agent", "multi-agent-style5.json", "agent-orchestration", 700),
            (6, "architecture", "system-architecture-style6.json", "governed-runtime", 700),
            (7, "architecture", "api-flow-style7.json", "token-stream", 700),
            (8, None, "dark-luxury-style8.svg", "golden-circuit", 600),
            (9, "architecture", "c4-review-canvas-style9.json", "review-trace", 611),
            (10, "architecture", "cloud-fabric-style10.json", "cloud-flow", 760),
            (11, "flow", "event-transit-style11.json", "event-transit", 590),
            (12, "architecture", "ops-pulse-style12.json", "ops-pulse", 860),
        )

        def signature_fingerprint(scene: dict[str, object]) -> dict[str, object]:
            def projected(name: str, fields: tuple[str, ...]) -> list[dict[str, object]]:
                rows = scene.get(name, [])
                return [
                    {field: row[field] for field in fields if field in row}
                    for row in rows
                ]

            cursor = scene.get("terminal_prompt_cursor")
            return {
                "streams": projected(
                    "persistent_streams",
                    ("role", "stage", "order", "primitive", "stroke_width", "dash_pattern"),
                ),
                "heads": projected(
                    "persistent_packet_heads",
                    ("role", "stage", "order", "primitive", "stroke_width", "dash_pattern"),
                ),
                "beads": projected(
                    "blueprint_registration_beads",
                    ("role", "stage", "order", "primitive", "radius", "stroke_width"),
                ),
                "cards": projected(
                    "notion_memory_cards",
                    ("role", "stage", "order", "primitive", "outer_rect", "ink_lines"),
                ),
                "signatures": projected(
                    "specialized_signatures",
                    ("schedule_key", "primitive", "geometry"),
                ),
                "terminal_cursor": (
                    {
                        key: cursor[key]
                        for key in ("primitive", "geometry", "rectangle", "fill")
                        if key in cursor
                    }
                    if isinstance(cursor, dict)
                    else None
                ),
            }

        requested_style_ids = {
            int(value)
            for value in os.environ.get("FIREWORKS_RENDER_STYLE_IDS", "").split(",")
            if value.strip()
        }
        if requested_style_ids:
            cases = tuple(case for case in cases if case[0] in requested_style_ids)
            self.assertEqual({case[0] for case in cases}, requested_style_ids)

        compared_frames = 0
        binary_exact_count = 0
        decoded_rgba_exact_count = 0
        guarded_antialias_equivalent_count = 0
        compatibility_evidence: list[dict[str, object]] = []
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for style_id, mode, fixture, preset, height in cases:
                with self.subTest(style_id=style_id):
                    svg = root / f"style-{style_id}.svg"
                    if mode is None:
                        svg.write_bytes((ROOT / "fixtures" / fixture).read_bytes())
                    else:
                        self.render_fixture(fixture, mode, svg)
                    source_hash = hashlib.sha256(svg.read_bytes()).hexdigest()

                    def render(
                        duration: float,
                        frame_count: int,
                    ) -> tuple[list[Path], list[str], dict[str, object]]:
                        frames = root / f"style-{style_id}-{frame_count}"
                        frames.mkdir()
                        process = subprocess.run(
                            [
                                str(shutil.which("node")),
                                str(SCRIPT_DIR / "svg2gif.js"),
                                "--input", str(svg),
                                "--frames-dir", str(frames),
                                "--preset", preset,
                                "--duration", str(duration),
                                "--fps", "20",
                                "--width", "960",
                                "--height", str(height),
                            ],
                            text=True,
                            capture_output=True,
                            check=False,
                            timeout=180,
                        )
                        self.assertEqual(process.returncode, 0, process.stderr)
                        frame_files = sorted(frames.glob("frame-*.png"))
                        self.assertEqual(len(frame_files), frame_count)
                        return (
                            frame_files,
                            [hashlib.sha256(frame.read_bytes()).hexdigest() for frame in frame_files],
                            json.loads(process.stdout),
                        )

                    frames_75, hashes_75, report_75 = render(3.75, 75)
                    frames_115, hashes_115, report_115 = render(5.75, 115)
                    for frame_index, (hash_75, hash_115) in enumerate(zip(hashes_75[:71], hashes_115[:71])):
                        if hash_75 == hash_115:
                            binary_exact_count += 1
                            classification = "binary_exact"
                            evidence: dict[str, object] = {
                                "classification": classification,
                                "absolute_error_pixels": 0,
                                "normalized_rmse": 0.0,
                                "components": [],
                            }
                        else:
                            evidence = _decoded_rgba_compatibility(
                                frames_75[frame_index],
                                frames_115[frame_index],
                                svg,
                            )
                            classification = str(evidence["classification"])
                            if classification == "decoded_rgba_exact":
                                decoded_rgba_exact_count += 1
                            else:
                                guarded_antialias_equivalent_count += 1
                        if classification != "binary_exact":
                            compatibility_evidence.append({
                                "style_id": style_id,
                                "frame_index": frame_index,
                                "baseline_sha256": hash_75,
                                "extended_sha256": hash_115,
                                **evidence,
                            })
                        compared_frames += 1
                    summary = _summarize_frame_hashes(
                        hashes_115,
                        (38, 109),
                        algorithm="sha256",
                        raster_kind=f"Style {style_id} raw Chromium raster",
                    )
                    self.assertGreaterEqual(summary["unique_frame_count"], 75)
                    self.assertEqual(summary["adjacent_duplicate_count"], 0)
                    self.assertTrue(summary["repeats_confined_to_permitted_scope"])
                    self.assertTrue(summary["opening_construction_and_reset_tail_globally_distinct"])

                    scene_75 = report_75["scene_report"]
                    scene_115 = report_115["scene_report"]
                    self.assertEqual(report_115["frame_count"], 115)
                    self.assertEqual(scene_115["grammar_version"], "3.4")
                    self.assertEqual(scene_115["reset_range"], [110, 114])
                    self.assertEqual(
                        scene_115["persistent_stream_contract"]["full_opacity_frames"],
                        [38, 109],
                    )
                    self.assertTrue(scene_115["static_dom_guard"])
                    self.assertTrue(all(item["passed"] for item in scene_115["direction_sentinels"]))
                    self.assertEqual(signature_fingerprint(scene_75), signature_fingerprint(scene_115))
                    self.assertEqual(hashlib.sha256(svg.read_bytes()).hexdigest(), source_hash)
                    if style_id >= 5:
                        self.assertEqual(scene_115["source_geometry_mutation_count"], 0)
                        self.assertEqual(scene_115["source_text_mutation_count"], 0)
                        self.assertEqual(scene_115["source_marker_mutation_count"], 0)
                    if os.environ.get("FIREWORKS_RENDER_PROGRESS") == "1":
                        print(
                            f"chromium-regression style-{style_id:02d} pass "
                            f"accepted={compared_frames} binary={binary_exact_count} "
                            f"decoded={decoded_rgba_exact_count} guarded={guarded_antialias_equivalent_count}",
                            flush=True,
                        )

        self.assertEqual(compared_frames, len(cases) * 71)
        self.assertEqual(
            binary_exact_count + decoded_rgba_exact_count + guarded_antialias_equivalent_count,
            compared_frames,
        )
        regression_report = {
            "ok": True,
            "contract": "75-vs-115-frame-compatibility",
            "style_ids": [case[0] for case in cases],
            "frames_per_style": 71,
            "accepted_count": compared_frames,
            "expected_accepted_count": len(cases) * 71,
            "binary_exact_count": binary_exact_count,
            "decoded_rgba_exact_count": decoded_rgba_exact_count,
            "guarded_antialias_equivalent_count": guarded_antialias_equivalent_count,
            "guard": {
                "maximum_absolute_error_pixels": 128,
                "maximum_normalized_rmse": 0.001,
                "maximum_component_width_or_height": 2,
                "component_scope": "edge-or-node-border-only",
                "dom_and_signature_contract": "strict-exact",
            },
            "non_binary_exact_evidence": compatibility_evidence,
        }
        report_path = os.environ.get("FIREWORKS_RENDER_REGRESSION_REPORT")
        if report_path:
            Path(report_path).write_text(
                json.dumps(regression_report, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
        if os.environ.get("FIREWORKS_RENDER_PROGRESS") == "1":
            print(
                "chromium-regression summary " + json.dumps(regression_report, sort_keys=True),
                flush=True,
            )

    def test_only_generated_svg_inputs_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for filename, data in (
                ("diagram.png", b"\x89PNG\r\n\x1a\n"),
                ("diagram.jpg", b"\xff\xd8\xff\xd9"),
                ("diagram.txt", b"<svg></svg>"),
            ):
                with self.subTest(filename=filename):
                    path = root / filename
                    path.write_bytes(data)
                    with self.assertRaisesRegex(ValueError, "generated \\.svg"):
                        build_motion_plan(path)
            plain = root / "plain.svg"
            plain.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"/>', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "only fireworks-tech-graph"):
                build_motion_plan(plain)

    def test_explicit_motion_metadata_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            source = svg.read_text(encoding="utf-8")
            source = source.replace(' data-motion-role="ingress"', "")
            source = source.replace(' data-motion-stage="1"', "", 1)
            source = source.replace(' data-motion-order="0"', "", 1)
            svg.write_text(source, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "explicit motion metadata"):
                build_motion_plan(svg)

    def test_unknown_motion_roles_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            svg.write_text(
                svg.read_text(encoding="utf-8").replace(
                    'data-motion-role="ingress"',
                    'data-motion-role="typo-role"',
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "unsupported motion roles.*typo-role"):
                build_motion_plan(svg)

    def test_preset_cannot_be_applied_to_a_different_style(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            with self.assertRaisesRegex(ValueError, "belongs to Style 2"):
                build_motion_plan(svg, preset="tool-grounding")

    def test_motion_budget_rejects_unsafe_settings(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            svg = Path(directory) / "style-1.svg"
            self.render_fixture("mem0-style1.json", "memory", svg)
            with self.assertRaisesRegex(ValueError, "MOTION_FPS"):
                build_motion_plan(svg, fps=26)
            with self.assertRaisesRegex(ValueError, "MOTION_DURATION"):
                build_motion_plan(svg, duration=21)
            with self.assertRaisesRegex(ValueError, "MOTION_WIDTH"):
                build_motion_plan(svg, width=200)
            with self.assertRaisesRegex(ValueError, "MOTION_TIMELINE"):
                build_motion_plan(svg, duration=1.1, fps=3)
            with self.assertRaisesRegex(ValueError, "at least 55 rendered frames"):
                build_motion_plan(svg, duration=2.7, fps=20)
            with self.assertRaisesRegex(ValueError, "finite"):
                build_motion_plan(svg, duration=float("nan"))
            with self.assertRaisesRegex(ValueError, "whole number"):
                build_motion_plan(svg, width=960.5)  # type: ignore[arg-type]
            with self.assertRaisesRegex(ValueError, "TOTAL_PIXEL_BUDGET"):
                build_motion_plan(svg, duration=20, fps=25, width=4096)

    def test_gif_output_and_report_paths_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "style-1.svg"
            gif = root / "style-1.gif"
            self.render_fixture("mem0-style1.json", "memory", svg)
            for suffix in (".webp", ".mp4", ".webm", ".png"):
                with self.subTest(suffix=suffix), self.assertRaisesRegex(ValueError, "must end in \\.gif"):
                    render_motion_gif(svg, root / f"style-1{suffix}", dry_run=True)
            with self.assertRaisesRegex(ValueError, "MOTION_REPORT"):
                render_motion_gif(svg, gif, report_path=gif, dry_run=True)
            with self.assertRaisesRegex(ValueError, "MOTION_REPORT"):
                render_motion_gif(svg, gif, report_path=svg, dry_run=True)
            with self.assertRaisesRegex(ValueError, "must differ from the input"):
                render_motion_gif(svg, svg, dry_run=True)

    def test_gif_dry_run_reports_single_delivery_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "style-1.svg"
            output = root / "style-1.gif"
            self.render_fixture("mem0-style1.json", "memory", svg)
            plan = render_motion_gif(svg, output, dry_run=True)
            self.assertEqual(plan["output_format"], MOTION_FORMAT["name"])
            self.assertEqual(plan["mime_type"], MOTION_FORMAT["mime"])
            self.assertEqual(plan["required_encoder"], "ffmpeg/gif")
            self.assertEqual(plan["encoded_dimensions"]["width"], 960)
            self.assertFalse(output.exists())

    def test_encoded_gif_probe_is_strict(self) -> None:
        valid = {
            "codec_name": "gif",
            "width": 960,
            "height": 680,
            "nb_read_frames": 55,
            "duration": "2.750000",
        }
        _validate_encoded_gif(valid, 960, 680, 55, 2.75)
        for key, value, error in (
            ("codec_name", "webp", "expected gif"),
            ("width", 959, "width differs"),
            ("height", 679, "height differs"),
            ("nb_read_frames", 54, "frame count differs"),
            ("duration", "2.000000", "requested 2.75s"),
        ):
            with self.subTest(key=key), self.assertRaisesRegex(RuntimeError, error):
                probe = dict(valid)
                probe[key] = value
                _validate_encoded_gif(probe, 960, 680, 55, 2.75)

    def test_gif_loop_extension_is_read_back_as_infinite(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "loop.gif"
            prefix = b"GIF89a" + (b"\x00" * 16)
            marker = b"\x21\xff\x0bNETSCAPE2.0\x03\x01"

            path.write_bytes(prefix + marker + b"\x00\x00\x00")
            self.assertEqual(_read_gif_loop_count(path), 0)
            self.assertEqual(_validate_gif_loop(path), 0)

            path.write_bytes(prefix + marker + b"\x01\x00\x00")
            self.assertEqual(_read_gif_loop_count(path), 1)
            with self.assertRaisesRegex(RuntimeError, "expected infinite looping"):
                _validate_gif_loop(path)

            path.write_bytes(prefix)
            self.assertIsNone(_read_gif_loop_count(path))
            with self.assertRaisesRegex(RuntimeError, "no readable loop extension"):
                _validate_gif_loop(path)

    def test_size_guidance_stays_within_gif_scope(self) -> None:
        guidance = _size_guidance(2_000_000)
        self.assertFalse(guidance["artifact_within_target"])
        self.assertIn("reduce width, duration, or frame rate", guidance["warnings"][0])
        self.assertNotIn("MP4", guidance["warnings"][0])
        self.assertNotIn("WebM", guidance["warnings"][0])

    def test_loop_delta_gate_uses_adjacent_p95_and_reports_coverage(self) -> None:
        quality = _summarize_delta_quality([1.0, 2.0, 3.0, 4.0], 3.0, 5.1)
        self.assertTrue(quality["seam_within_adjacent_p95"])
        self.assertAlmostEqual(quality["changed_area_ratio"], 0.02)
        with self.assertRaisesRegex(RuntimeError, "loop seam exceeds"):
            _summarize_delta_quality([1.0, 1.0, 1.0], 2.0, 5.1)

    def test_render_timeout_preserves_existing_gif(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "style-1.svg"
            output = root / "style-1.gif"
            self.render_fixture("mem0-style1.json", "memory", svg)
            output.write_bytes(b"existing")
            runtime = {
                "ok": True,
                "node": "node",
                "ffmpeg": "ffmpeg",
                "ffprobe": "ffprobe",
                "format": {"gif": True},
            }
            with mock.patch("motion.probe_motion_runtime", return_value=runtime), mock.patch(
                "motion.subprocess.run",
                side_effect=subprocess.TimeoutExpired(["node"], 120),
            ):
                with self.assertRaisesRegex(RuntimeError, "MOTION_RENDER_TIMEOUT"):
                    render_motion_gif(svg, output)
            self.assertEqual(output.read_bytes(), b"existing")
            self.assertEqual(list(root.glob(".*.tmp.gif")), [])

    def test_render_failure_preserves_existing_gif(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "style-1.svg"
            output = root / "style-1.gif"
            self.render_fixture("mem0-style1.json", "memory", svg)
            output.write_bytes(b"existing-gif")
            runtime = {
                "ok": True,
                "node": "node",
                "ffmpeg": "ffmpeg",
                "ffprobe": "ffprobe",
                "format": {"gif": True},
            }
            failed = subprocess.CompletedProcess([], 1, "", "renderer failed")
            with mock.patch("motion.probe_motion_runtime", return_value=runtime), mock.patch(
                "motion.subprocess.run",
                return_value=failed,
            ):
                with self.assertRaisesRegex(RuntimeError, "renderer failed"):
                    render_motion_gif(svg, output)
            self.assertEqual(output.read_bytes(), b"existing-gif")
            self.assertEqual(list(root.glob(".*.tmp.gif")), [])

    def test_artifact_commit_rolls_back_gif_and_report_together(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gif = root / "diagram.gif"
            report = root / "diagram.motion.json"
            staged_gif = root / ".diagram.tmp.gif"
            staged_report = root / ".diagram.motion.tmp"
            gif.write_bytes(b"existing-gif")
            report.write_text("existing-report", encoding="utf-8")
            staged_gif.write_bytes(b"new-gif")
            staged_report.write_text("new-report", encoding="utf-8")
            real_replace = os.replace

            def fail_report_install(source: object, target: object) -> None:
                if Path(source) == staged_report and Path(target) == report:
                    raise OSError("simulated report install failure")
                real_replace(source, target)

            with mock.patch("motion.os.replace", side_effect=fail_report_install):
                with self.assertRaisesRegex(OSError, "simulated report install failure"):
                    _commit_artifacts([(staged_gif, gif), (staged_report, report)])

            self.assertEqual(gif.read_bytes(), b"existing-gif")
            self.assertEqual(report.read_text(encoding="utf-8"), "existing-report")
            self.assertEqual(list(root.glob("*.rollback")), [])
            self.assertFalse(staged_gif.exists())
            self.assertFalse(staged_report.exists())


if __name__ == "__main__":
    unittest.main()
