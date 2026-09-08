from __future__ import annotations

import copy
import importlib.util
import json
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from diagram_ir import normalize_diagram  # noqa: E402
from semantic_contracts import resolve_style_index  # noqa: E402


def load_generator():
    spec = importlib.util.spec_from_file_location("semantic_contract_generator", SCRIPTS / "generate-from-template.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


generator = load_generator()


class StyleCatalogContractTest(unittest.TestCase):
    def test_style_names_aliases_and_visual_theme_are_canonical(self) -> None:
        self.assertEqual(resolve_style_index({"style": "C4 Review Canvas"}), 9)
        self.assertEqual(resolve_style_index({"style": "cloud deployment"}), 10)
        self.assertEqual(resolve_style_index({"visual_theme": "event metro"}), 11)
        self.assertEqual(resolve_style_index({"visual_theme": "ops pulse"}), 12)
        prompt_fingerprints = {
            "风格9": 9,
            "C4 评审画布": 9,
            "cloud landing zone map": 10,
            "事件地铁图": 11,
            "黄金信号追踪图": 12,
        }
        for selector, expected in prompt_fingerprints.items():
            with self.subTest(selector=selector):
                self.assertEqual(resolve_style_index({"style": selector}), expected)

    def test_unknown_and_conflicting_style_selectors_fail_closed(self) -> None:
        with self.assertRaisesRegex(ValueError, "STYLE_SELECTOR"):
            resolve_style_index({"style": "almost-cloud"})
        with self.assertRaisesRegex(ValueError, "STYLE_SELECTOR_CONFLICT"):
            resolve_style_index({"style": 9, "visual_theme": 10})

    def test_style_8_stays_ai_authored_and_outside_the_json_renderer(self) -> None:
        with self.assertRaisesRegex(ValueError, "AI-authored"):
            generator.parse_style(8)


class EngineeringSemanticContractTest(unittest.TestCase):
    def fixture(self, name: str) -> dict[str, object]:
        return json.loads((ROOT / "fixtures" / name).read_text(encoding="utf-8"))

    def test_c4_requires_technology_at_the_selected_abstraction_level(self) -> None:
        data = self.fixture("c4-review-canvas-style9.json")
        del data["nodes"][1]["technology"]  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "SEMANTIC_REQUIRED.*technology"):
            normalize_diagram(data, "architecture")

        empty_boundary = self.fixture("c4-review-canvas-style9.json")
        empty_boundary["containers"][0]["id"] = ""  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, r"containers\[0\]\.id.*non-empty"):
            normalize_diagram(empty_boundary, "architecture")

        undersized = self.fixture("c4-review-canvas-style9.json")
        undersized["nodes"][1]["height"] = 95  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "C4_CARD_SIZE"):
            normalize_diagram(undersized, "architecture")

    def test_cloud_rejects_unknown_icons_and_boundary_cycles(self) -> None:
        data = self.fixture("cloud-fabric-style10.json")
        data["nodes"][0]["icon_id"] = "vendor:magic"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "CLOUD_ICON_UNKNOWN"):
            normalize_diagram(data, "architecture")

        cycle = self.fixture("cloud-fabric-style10.json")
        cycle["containers"][1]["parent"] = "vpc-a"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "CLOUD_BOUNDARY_CYCLE"):
            normalize_diagram(cycle, "architecture")

        overlap = self.fixture("cloud-fabric-style10.json")
        overlap["containers"][2]["x"] = 400  # type: ignore[index]
        overlap["containers"][4]["x"] = 425  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "CLOUD_BOUNDARY_GAP"):
            normalize_diagram(overlap, "architecture")

        duplicate = self.fixture("cloud-fabric-style10.json")
        duplicate["containers"].append(copy.deepcopy(duplicate["containers"][1]))  # type: ignore[union-attr,index]
        with self.assertRaisesRegex(ValueError, "duplicate container id: region-a"):
            normalize_diagram(duplicate, "architecture")

    def test_event_rails_require_adjacent_stations_and_real_dlq_targets(self) -> None:
        data = self.fixture("event-transit-style11.json")
        data["nodes"][4]["station_order"] = 5  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "EVENT_RAIL_ORDER"):
            normalize_diagram(data, "flow")

        dlq = self.fixture("event-transit-style11.json")
        dlq["arrows"][4]["target"] = "order-state"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "EVENT_DLQ_TARGET"):
            normalize_diagram(dlq, "flow")

        too_close = self.fixture("event-transit-style11.json")
        too_close["nodes"][1]["x"] = 270  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "EVENT_RAIL_LENGTH"):
            normalize_diagram(too_close, "flow")

    def test_ops_requires_all_golden_signals_and_a_contiguous_critical_path(self) -> None:
        data = self.fixture("ops-pulse-style12.json")
        del data["nodes"][0]["signals"]["latency"]  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "OPS_GOLDEN_SIGNALS"):
            normalize_diagram(data, "architecture")

        discontinuous = self.fixture("ops-pulse-style12.json")
        discontinuous["critical_path"] = ["edge-api-checkout", "edge-gateway-api"]
        with self.assertRaisesRegex(ValueError, "OPS_CRITICAL_PATH.*discontinuous"):
            normalize_diagram(discontinuous, "architecture")

        non_business = self.fixture("ops-pulse-style12.json")
        non_business["arrows"][1]["edge_kind"] = "other"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "OPS_CRITICAL_PATH.*business edge"):
            normalize_diagram(non_business, "architecture")

        distorted = self.fixture("ops-pulse-style12.json")
        distorted["nodes"][6]["width"] = 500  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "OPS_SPAN_SCALE"):
            normalize_diagram(distorted, "architecture")

    def test_engineering_profiles_reject_coordinate_only_edges(self) -> None:
        cases = (
            ("architecture", "c4-review-canvas-style9.json", 0),
            ("architecture", "cloud-fabric-style10.json", 0),
            ("flow", "event-transit-style11.json", 0),
            ("architecture", "ops-pulse-style12.json", 3),
        )
        for mode, fixture_name, edge_index in cases:
            with self.subTest(fixture=fixture_name):
                data = self.fixture(fixture_name)
                edge = data["arrows"][edge_index]  # type: ignore[index]
                edge.pop("source")
                edge.pop("target")
                edge.update({"x1": 40, "y1": 40, "x2": 200, "y2": 40})
                with self.assertRaisesRegex(ValueError, "SEMANTIC_EDGE_ENDPOINT"):
                    normalize_diagram(data, mode)

    def test_ops_observation_window_is_required_and_consistent(self) -> None:
        missing = self.fixture("ops-pulse-style12.json")
        del missing["observation_window"]
        with self.assertRaisesRegex(ValueError, "SEMANTIC_REQUIRED.*observation_window"):
            normalize_diagram(missing, "architecture")

        mismatch = self.fixture("ops-pulse-style12.json")
        mismatch["nodes"][0]["signals"]["latency"]["window"] = "15m"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "OPS_OBSERVATION_WINDOW"):
            normalize_diagram(mismatch, "architecture")

    def test_styles_9_to_12_render_with_semantics_and_showcase_quality(self) -> None:
        cases = (
            (9, "architecture", "c4-review-canvas-style9.json", "c4-review"),
            (10, "architecture", "cloud-fabric-style10.json", "cloud-fabric"),
            (11, "flow", "event-transit-style11.json", "event-transit"),
            (12, "architecture", "ops-pulse-style12.json", "ops-pulse"),
        )
        for style_id, mode, fixture_name, profile in cases:
            with self.subTest(style=style_id):
                data = self.fixture(fixture_name)
                svg, report = generator.build_svg_with_report(mode, data)
                root = ET.fromstring(svg)
                semantic_edges = [item for item in root if item.get("data-graph-role") == "edge"]
                self.assertEqual(root.get("data-style-id"), str(style_id))
                self.assertEqual(root.get("data-semantic-profile"), profile)
                self.assertEqual(root.get("data-semantic-valid"), "true")
                self.assertEqual(report["semantics"]["profile"], profile)
                self.assertEqual(report["composition"]["score"], 100)
                self.assertEqual(report["composition"]["metrics"]["bridged_crossings"], 0)
                self.assertEqual(len(semantic_edges), len(data["arrows"]))
                signature = next(item for item in root if item.get("id") == "style-signature")
                expected_signatures = {
                    9: "c4-review-board",
                    10: "cloud-ownership-map",
                    11: "event-metro-map",
                    12: "ops-live-investigation",
                }
                self.assertEqual(signature.get("data-style-signature"), expected_signatures[style_id])
                if style_id == 9:
                    self.assertTrue(all(item.get("data-protocol") for item in semantic_edges))
                    wrapped = False
                    for node_group in (item for item in root if item.get("data-graph-role") == "node"):
                        bounds = [float(value) for value in node_group.get("data-graph-bounds", "").split(",")]
                        available = bounds[2] - bounds[0] - 28
                        descriptions = [item for item in node_group if item.get("data-text-role") == "description"]
                        wrapped = wrapped or len(descriptions) > 1
                        for text_node in descriptions:
                            rendered_width = generator.geometry.estimate_text_width(
                                text_node.text or "", float(text_node.get("font-size", "11.5"))
                            )
                            self.assertLessEqual(rendered_width, available + 0.01)
                    self.assertTrue(wrapped)
                if style_id == 10:
                    self.assertEqual(
                        {item.get("data-flow") for item in semantic_edges},
                        {"read", "write", "async"},
                    )
                    for node_group in (item for item in root if item.get("data-graph-role") == "node"):
                        bounds = [float(value) for value in node_group.get("data-graph-bounds", "").split(",")]
                        available = bounds[2] - bounds[0] - 78
                        for text_node in (item for item in node_group if item.get("data-text-role") in {"title", "subtitle"}):
                            rendered_width = generator.geometry.estimate_text_width(
                                text_node.text or "", float(text_node.get("font-size", "12")), weight=1.08
                            )
                            self.assertLessEqual(rendered_width, available + 0.01)
                            self.assertEqual(text_node.text, text_node.get("data-full-text"))
                if style_id == 11:
                    rail_edges = [item for item in semantic_edges if item.get("data-edge-kind") == "rail"]
                    self.assertTrue(rail_edges)
                    self.assertTrue(all(float(item.get("stroke-width", "99")) <= 2.8 for item in rail_edges))
                    self.assertGreaterEqual(report["composition"]["metrics"]["minimum_node_gap"], 64)
                    markers = [item for item in root.iter() if item.tag.endswith("marker")]
                    self.assertTrue(markers)
                    self.assertTrue(all(item.get("markerUnits") == "userSpaceOnUse" for item in markers))
                    transit_copy = [
                        item
                        for node_group in (item for item in root if item.get("data-graph-role") == "node")
                        for item in node_group
                        if item.get("data-text-role") in {"title", "subtitle"}
                    ]
                    self.assertTrue(transit_copy)
                    self.assertTrue(all(item.text == item.get("data-full-text") for item in transit_copy))
                    station_orders = sorted(
                        int(item.get("data-station-order", "-1"))
                        for item in root
                        if item.get("data-graph-role") == "node" and item.get("data-station-order")
                    )
                    self.assertEqual(station_orders, list(range(5)))
                if style_id == 12:
                    self.assertEqual(sum(item.get("data-critical") == "true" for item in semantic_edges), 3)
                    critical_edges = [item for item in semantic_edges if item.get("data-critical") == "true"]
                    self.assertEqual(
                        sorted(int(item.get("data-critical-hop", "0")) for item in critical_edges),
                        [1, 2, 3],
                    )
                    self.assertTrue(all(item.get("data-critical-hops") == "3" for item in critical_edges))
                    hop_markers = [item for item in root if item.get("id", "").endswith("-hop")]
                    metric_windows = [item for item in root.iter() if (item.text or "").startswith("@5m")]
                    self.assertEqual(len(hop_markers), 3)
                    self.assertGreaterEqual(len(metric_windows), 16)
                    span_nodes = [
                        item
                        for item in root
                        if item.get("data-graph-role") == "node" and item.get("data-span-id")
                    ]
                    self.assertEqual(len(span_nodes), 4)
                    self.assertTrue(all(item.get("data-duration-ms") for item in span_nodes))

    def test_engineering_style_signatures_fit_long_dynamic_values(self) -> None:
        cases = (
            ("architecture", "c4-review-canvas-style9.json", "review_state", "ARCHITECTURE DECISION RECORD APPROVED WITH CONDITIONS"),
            ("architecture", "cloud-fabric-style10.json", "deployment_mode", "ACTIVE ACTIVE MULTI REGION DISASTER RECOVERY MODE"),
            ("flow", "event-transit-style11.json", "line_code", "CHECKOUT EVENT PROCESSING METROPOLITAN EXPRESS LINE"),
            ("architecture", "ops-pulse-style12.json", "observation_window", "ROLLING THIRTY MINUTE INCIDENT WINDOW"),
        )
        for mode, fixture_name, field, value in cases:
            with self.subTest(fixture=fixture_name):
                data = self.fixture(fixture_name)
                data[field] = value
                if field == "observation_window":
                    for node in data["nodes"]:  # type: ignore[union-attr]
                        for signal in node.get("signals", {}).values():
                            signal["window"] = value
                svg, _ = generator.build_svg_with_report(mode, data)
                root = ET.fromstring(svg)
                signature = next(item for item in root if item.get("id") == "style-signature")
                background = next(item for item in signature if item.tag.endswith("rect"))
                right = float(background.get("x", "0")) + float(background.get("width", "0")) - 10
                for text_node in (item for item in signature if item.tag.endswith("text")):
                    used = generator.geometry.estimate_text_width(
                        text_node.text or "", float(text_node.get("font-size", "8")), weight=1.08
                    )
                    self.assertLessEqual(float(text_node.get("x", "0")) + used, right + 0.01)

    def test_engineering_node_copy_fails_visually_closed_inside_declared_budgets(self) -> None:
        cases = []

        c4 = self.fixture("c4-review-canvas-style9.json")
        c4["nodes"][1]["label"] = "Checkout Web Application With International Merchant Controls"  # type: ignore[index]
        c4["nodes"][1]["technology"] = "Next.js TypeScript OpenTelemetry Runtime"  # type: ignore[index]
        cases.append(("architecture", c4))

        ops = self.fixture("ops-pulse-style12.json")
        long_window = "rolling-thirty-minute-incident-investigation-window"
        ops["observation_window"] = long_window
        for node in ops["nodes"]:  # type: ignore[union-attr]
            if node.get("ops_role") == "service":
                node["label"] = f'{node["label"]} International Checkout Reliability Control Plane'
                node["status_label"] = "CRITICAL DEGRADATION UNDER INVESTIGATION"
                for signal in node["signals"].values():
                    signal["value"] = "123456789.987654321"
                    signal["unit"] = "requests-per-second"
                    signal["window"] = long_window
            elif node.get("ops_role") in {"trace_span", "collector"}:
                node["label"] = f'{node["label"]} with an intentionally very long diagnostic label'
        cases.append(("architecture", ops))

        for mode, data in cases:
            with self.subTest(style=data["style"]):
                svg, _ = generator.build_svg_with_report(mode, data)
                root = ET.fromstring(svg)
                budgeted = [item for item in root.iter() if item.get("data-text-max-width")]
                self.assertTrue(budgeted)
                self.assertTrue(any((item.text or "") != item.get("data-full-text") for item in budgeted))
                for text_node in budgeted:
                    rendered_width = generator.geometry.estimate_text_width(
                        text_node.text or "",
                        float(text_node.get("font-size", "12")),
                        weight=1.08,
                    )
                    self.assertLessEqual(
                        rendered_width,
                        float(text_node.get("data-text-max-width", "0")) + 0.01,
                    )

    def test_c4_rough_marks_are_deterministic_and_decorative_only(self) -> None:
        data = self.fixture("c4-review-canvas-style9.json")
        first, _ = generator.build_svg_with_report("architecture", copy.deepcopy(data))
        second, _ = generator.build_svg_with_report("architecture", copy.deepcopy(data))
        self.assertEqual(first, second)
        root = ET.fromstring(first)
        self.assertTrue(any(item.get("id", "").endswith("-review-stroke") for item in root))
        changed = copy.deepcopy(data)
        changed["rough_seed"] = 20260716
        changed_svg, _ = generator.build_svg_with_report("architecture", changed)
        changed_root = ET.fromstring(changed_svg)
        first_edges = {item.get("id"): item.get("d") for item in root if item.get("data-graph-role") == "edge"}
        changed_edges = {item.get("id"): item.get("d") for item in changed_root if item.get("data-graph-role") == "edge"}
        self.assertEqual(first_edges, changed_edges)
        first_rough = [item.get("stroke-dashoffset") for item in root if item.get("id", "").endswith("-review-stroke")]
        changed_rough = [item.get("stroke-dashoffset") for item in changed_root if item.get("id", "").endswith("-review-stroke")]
        self.assertNotEqual(first_rough, changed_rough)


if __name__ == "__main__":
    unittest.main()
