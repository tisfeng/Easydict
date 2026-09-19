from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts" / "fireworks.py"

class UnifiedCLITest(unittest.TestCase):
    def run_cli(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CLI), *arguments],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_examples_and_validate_are_machine_readable(self) -> None:
        examples = self.run_cli("examples")
        self.assertEqual(examples.returncode, 0, examples.stderr)
        self.assertIn("fixtures/mem0-style1.json", json.loads(examples.stdout)["examples"])
        validated = self.run_cli("validate", "memory", "fixtures/mem0-style1.json")
        self.assertEqual(validated.returncode, 0, validated.stderr)
        validation = json.loads(validated.stdout)
        self.assertTrue(validation["ok"])
        self.assertEqual(validation["style"]["id"], 1)
        self.assertEqual(validation["semantics"]["profile"], "generic")

    def test_render_check_inspect_and_export_html(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "diagram.svg"
            report = root / "layout.json"
            page = root / "diagram.html"
            rendered = self.run_cli(
                "render", "architecture", "fixtures/api-flow-style7.json", str(svg), "--report", str(report)
            )
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            self.assertTrue(svg.is_file())
            self.assertTrue(json.loads(report.read_text(encoding="utf-8"))["ok"])
            checked = self.run_cli("check", str(svg))
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
            inspected = self.run_cli("inspect", str(svg))
            inspection = json.loads(inspected.stdout)
            self.assertEqual(inspection["generator"], "fireworks-tech-graph")
            self.assertEqual(inspection["style_id"], "7")
            self.assertEqual(inspection["semantic_profile"], "generic")
            exported = self.run_cli("export-html", str(svg), str(page))
            self.assertEqual(exported.returncode, 0, exported.stderr)
            self.assertIn('data-action="zoom-in"', page.read_text(encoding="utf-8"))

    def test_checked_in_interactive_example_matches_current_cli_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "api-flow.svg"
            page = root / "interactive-architecture.html"
            rendered = self.run_cli("render", "architecture", "fixtures/api-flow-style7.json", str(svg))
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            exported = self.run_cli(
                "export-html",
                str(svg),
                str(page),
                "--title",
                "API Integration Flow",
                "--slug",
                "api-integration-flow",
            )
            self.assertEqual(exported.returncode, 0, exported.stderr)
            expected = ROOT / "examples" / "interactive-architecture.html"
            self.assertEqual(page.read_bytes(), expected.read_bytes())

    def test_animate_dry_run_resolves_semantic_preset_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "memory-weave.svg"
            gif = root / "memory-weave.gif"
            rendered = self.run_cli("render", "memory", "fixtures/mem0-style1.json", str(svg))
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            animated = self.run_cli("animate", str(svg), str(gif), "--dry-run")
            self.assertEqual(animated.returncode, 0, animated.stderr)
            plan = json.loads(animated.stdout)
            self.assertTrue(plan["dry_run"])
            self.assertEqual(plan["style_id"], 1)
            self.assertEqual(plan["preset"], "memory-weave")
            self.assertEqual(plan["duration_seconds"], 5.75)
            self.assertEqual(plan["fps"], 20)
            self.assertEqual(plan["frame_count"], 115)
            self.assertEqual(plan["width"], 960)
            self.assertEqual(plan["output_format"], "gif")
            self.assertEqual(plan["motion_grammar_version"], "3.4")
            self.assertEqual(plan["review_status"], "user-approved")
            self.assertEqual(plan["style_contract_status"], "user-approved")
            self.assertEqual(plan["timing_revision"]["id"], "+2s-settled-flow")
            self.assertEqual(plan["timing_revision"]["status"], "user-approved")
            self.assertFalse(plan["timing_revision"]["only_pending_item"])
            self.assertEqual(plan["timing_revision"]["approved_at"], "2026-07-17")
            self.assertEqual(
                plan["animation_contract"]["primitive"],
                "connector-draw-on-with-persistent-data-flow",
            )
            self.assertEqual(plan["animation_contract"]["empty_opening_frame"], 0)
            self.assertEqual(plan["animation_contract"]["draw_schedule"][0]["frames"], [1, 8])
            stream = plan["animation_contract"]["persistent_data_flow"]
            self.assertEqual(stream["stream_count"], 8)
            self.assertEqual(stream["packet_head_count"], 8)
            self.assertEqual(stream["rendered_frames"], [36, 114])
            self.assertEqual(stream["full_opacity_frames"], [38, 109])
            self.assertEqual(stream["body"]["dash_pattern"], [16, 25])
            self.assertEqual(stream["body"]["resolved_style_1_stroke_width"], 3.84)
            self.assertEqual(stream["packet_head"]["dash_pattern"], [6, 35])
            self.assertEqual(stream["packet_head"]["stroke_width"], 2.20)
            self.assertEqual(stream["packet_head"]["dash_offset_from_body"], -10)
            self.assertEqual(stream["dash_offset_per_rendered_frame"], -6.0)
            self.assertEqual(stream["expected_initial_phases"], [7, 14, 21, 28, 31, 35, 1, 8])
            self.assertEqual(plan["animation_contract"]["reset_range"], [110, 114])
            self.assertEqual(
                plan["animation_contract"]["reset_opacity_samples"],
                [1.0, 0.7575, 0.515, 0.2725, 0.03],
            )
            self.assertFalse(gif.exists())
            self.assertFalse(gif.with_suffix(".motion.json").exists())

    def test_animate_rejects_raster_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for suffix, payload in ((".png", b"\x89PNG\r\n\x1a\n"), (".jpg", b"\xff\xd8\xff\xd9")):
                with self.subTest(suffix=suffix):
                    image = root / f"diagram{suffix}"
                    image.write_bytes(payload)
                    animated = self.run_cli("animate", str(image), str(root / "diagram.gif"), "--dry-run")
                    self.assertNotEqual(animated.returncode, 0)
                    self.assertIn("generated .svg", animated.stderr)

    def test_animate_rejects_non_gif_outputs_and_removed_options(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "memory.svg"
            rendered = self.run_cli("render", "memory", "fixtures/mem0-style1.json", str(svg))
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            for suffix in (".webp", ".mp4", ".webm", ".png"):
                with self.subTest(suffix=suffix):
                    animated = self.run_cli("animate", str(svg), str(root / f"memory{suffix}"), "--dry-run")
                    self.assertNotEqual(animated.returncode, 0)
                    self.assertIn("must end in .gif", animated.stderr)
            removed_option = self.run_cli(
                "animate", str(svg), str(root / "memory.gif"), "--poster", str(root / "poster.png"), "--dry-run"
            )
            self.assertNotEqual(removed_option.returncode, 0)
            self.assertIn("unrecognized arguments: --poster", removed_option.stderr)

    def test_animate_enables_styles_two_through_five(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "style2.svg"
            rendered = self.run_cli("render", "agent", "fixtures/tool-call-style2.json", str(svg))
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            animated = self.run_cli("animate", str(svg), str(root / "style2.gif"), "--dry-run")
            self.assertEqual(animated.returncode, 0, animated.stderr)
            plan = json.loads(animated.stdout)
            self.assertEqual(plan["style_id"], 2)
            self.assertEqual(plan["preset"], "tool-grounding")
            self.assertEqual(plan["height"], 720)
            self.assertEqual(plan["animation_contract"]["draw_schedule"][5]["role"], "grounding")
            self.assertEqual(plan["animation_contract"]["draw_schedule"][6]["order"], 1)
            stream = plan["animation_contract"]["persistent_data_flow"]
            self.assertEqual(stream["primitive"], "terminal-evidence-stream")
            self.assertEqual(stream["packet_head_primitive"], "terminal-command-head")
            self.assertEqual(stream["body"]["resolved_style_2_stroke_width"], 3.45)
            self.assertEqual(stream["packet_head"]["stroke_width"], 2.0)
            self.assertEqual(stream["expected_initial_phases"], [6, 12, 18, 24, 30, 36, 39, 1])
            self.assertEqual(
                plan["animation_contract"]["terminal_signature"]["primitive"],
                "terminal-prompt-cursor",
            )

            style_three = root / "style3.svg"
            rendered = self.run_cli(
                "render",
                "architecture",
                "fixtures/microservices-style3.json",
                str(style_three),
            )
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            style_three_animation = self.run_cli(
                "animate", str(style_three), str(root / "style3.gif"), "--dry-run"
            )
            self.assertEqual(style_three_animation.returncode, 0, style_three_animation.stderr)
            style_three_plan = json.loads(style_three_animation.stdout)
            self.assertEqual(style_three_plan["style_id"], 3)
            self.assertEqual(style_three_plan["preset"], "service-blueprint")
            style_three_stream = style_three_plan["animation_contract"]["persistent_data_flow"]
            self.assertEqual(style_three_stream["primitive"], "blueprint-distribution-wave")
            self.assertEqual(style_three_stream["registration_bead_count"], 10)
            self.assertEqual(style_three_stream["expected_initial_phases"], [7, 14, 21, 21, 21, 28, 28, 28, 35, 42])

            style_four = root / "style4.svg"
            rendered = self.run_cli(
                "render",
                "memory",
                "fixtures/agent-memory-types-style4.json",
                str(style_four),
            )
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            style_four_animation = self.run_cli(
                "animate", str(style_four), str(root / "style4.gif"), "--dry-run"
            )
            self.assertEqual(style_four_animation.returncode, 0, style_four_animation.stderr)
            style_four_plan = json.loads(style_four_animation.stdout)
            self.assertEqual(style_four_plan["style_id"], 4)
            self.assertEqual(style_four_plan["preset"], "memory-lifecycle")
            self.assertEqual(style_four_plan["height"], 620)
            style_four_stream = style_four_plan["animation_contract"]["persistent_data_flow"]
            self.assertEqual(style_four_stream["primitive"], "notion-memory-rail")
            self.assertEqual(style_four_stream["memory_card_count"], 6)
            self.assertEqual(style_four_stream["expected_initial_phases"], [7, 14, 21, 28, 35, 42])
            self.assertEqual(
                style_four_stream["memory_card"]["initial_normalized_progress_by_stage"],
                [0.08, 0.22, 0.36, 0.50, 0.64, 0.78],
            )

            style_five = root / "style5.svg"
            rendered = self.run_cli(
                "render",
                "agent",
                "fixtures/multi-agent-style5.json",
                str(style_five),
            )
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            style_five_animation = self.run_cli(
                "animate", str(style_five), str(root / "style5.gif"), "--dry-run"
            )
            self.assertEqual(style_five_animation.returncode, 0, style_five_animation.stderr)
            style_five_plan = json.loads(style_five_animation.stdout)
            self.assertEqual(style_five_plan["style_id"], 5)
            self.assertEqual(style_five_plan["preset"], "agent-orchestration")
            self.assertEqual(style_five_plan["review_status"], "user-approved")
            style_five_stream = style_five_plan["animation_contract"]["persistent_data_flow"]
            self.assertEqual(style_five_stream["primitive"], "glass-handoff-rail")
            self.assertEqual(style_five_stream["signature_primitive"], "glass-task-capsule")

    def test_motion_review_command_is_removed(self) -> None:
        removed = self.run_cli("motion-review", "review.json", "review.html")
        self.assertNotEqual(removed.returncode, 0)
        self.assertIn("invalid choice", removed.stderr)

    def test_legacy_generator_writes_a_failure_report_without_svg(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            svg = root / "unsafe.svg"
            report = root / "layout.json"
            invalid = json.dumps({"schema_version": 2, "nodes": [], "arrows": []})
            process = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "scripts" / "generate-from-template.py"),
                    "architecture",
                    str(svg),
                    invalid,
                    "--layout-report",
                    str(report),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(process.returncode, 0)
            self.assertFalse(svg.exists())
            failure = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(failure["ok"])
            self.assertEqual(failure["issues"][0]["code"], "LAYOUT_ERROR")


if __name__ == "__main__":
    unittest.main()
