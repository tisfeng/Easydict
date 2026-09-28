from __future__ import annotations

import copy
import importlib.util
import math
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("diagram_ir", ROOT / "scripts" / "diagram_ir.py")
assert SPEC and SPEC.loader
diagram_ir = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = diagram_ir
SPEC.loader.exec_module(diagram_ir)


class DiagramIRTest(unittest.TestCase):
    def base(self) -> dict[str, object]:
        return {
            "style": 1,
            "nodes": [
                {"id": "a", "x": 10, "y": 20, "width": 100, "height": 50},
                {"id": "b", "x": 220, "y": 20, "width": 100, "height": 50},
            ],
            "arrows": [{"source": "a", "target": "b", "route_points": [[160, 45]]}],
        }

    def test_legacy_and_v1_normalize_to_equivalent_payloads(self) -> None:
        legacy = self.base()
        versioned = copy.deepcopy(legacy)
        versioned.update({"schema_version": 1, "mode": "architecture"})
        legacy_ir = diagram_ir.normalize_diagram(legacy, "architecture")
        versioned_ir = diagram_ir.normalize_diagram(versioned, "architecture")
        self.assertEqual(legacy_ir.as_dict(), versioned_ir.as_dict())
        self.assertEqual(legacy_ir.input_schema, "legacy")
        self.assertEqual(versioned_ir.input_schema, "v1")

    def test_normalization_never_mutates_the_caller(self) -> None:
        data = self.base()
        before = copy.deepcopy(data)
        diagram_ir.normalize_diagram(data, "architecture")
        self.assertEqual(data, before)

    def test_duplicate_and_dangling_ids_are_rejected(self) -> None:
        duplicate = self.base()
        duplicate["nodes"][1]["id"] = "a"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "duplicate node id"):
            diagram_ir.normalize_diagram(duplicate, "architecture")
        dangling = self.base()
        dangling["arrows"][0]["target"] = "missing"  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, "unknown node"):
            diagram_ir.normalize_diagram(dangling, "architecture")

    def test_container_ids_are_non_empty_and_globally_unique(self) -> None:
        empty = self.base()
        empty["containers"] = [{"id": "", "x": 0, "y": 0, "width": 400, "height": 200}]
        with self.assertRaisesRegex(ValueError, r"containers\[0\]\.id.*non-empty"):
            diagram_ir.normalize_diagram(empty, "architecture")

        duplicate = self.base()
        duplicate["containers"] = [
            {"id": "scope", "x": 0, "y": 0, "width": 400, "height": 200},
            {"id": "scope", "x": 10, "y": 10, "width": 380, "height": 180},
        ]
        with self.assertRaisesRegex(ValueError, "duplicate container id: scope"):
            diagram_ir.normalize_diagram(duplicate, "architecture")

        cross_kind = self.base()
        cross_kind["containers"] = [{"id": "a", "x": 0, "y": 0, "width": 400, "height": 200}]
        with self.assertRaisesRegex(ValueError, "duplicate diagram id: a"):
            diagram_ir.normalize_diagram(cross_kind, "architecture")

    def test_schema_mode_and_non_finite_values_are_rejected(self) -> None:
        for update, message in (
            ({"schema_version": 2}, "unsupported schema_version"),
            ({"schema_version": 1, "mode": "sequence"}, "conflicts"),
            ({"width": math.inf}, "finite"),
        ):
            data = self.base()
            data.update(update)
            with self.assertRaisesRegex(ValueError, message):
                diagram_ir.normalize_diagram(data, "architecture")

    def test_malformed_waypoint_is_rejected(self) -> None:
        data = self.base()
        data["arrows"][0]["route_points"] = [[10]]  # type: ignore[index]
        with self.assertRaisesRegex(ValueError, r"must be \[x, y\]"):
            diagram_ir.normalize_diagram(data, "architecture")


if __name__ == "__main__":
    unittest.main()
