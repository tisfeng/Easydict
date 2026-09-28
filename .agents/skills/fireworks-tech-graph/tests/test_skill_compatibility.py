from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class SkillCompatibilityTest(unittest.TestCase):
    def test_shared_skill_entrypoint_stays_portable(self) -> None:
        skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("name: fireworks-tech-graph", skill)
        self.assertIn("${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}", skill)
        self.assertNotIn("./scripts/", skill)
        self.assertLessEqual(len(skill.splitlines()), 500)

    def test_runtime_metadata_and_bundled_resources_exist(self) -> None:
        for relative_path in (
            "agents/openai.yaml",
            "references/png-export.md",
            "references/motion-effects.md",
            "scripts/generate-diagram.sh",
            "scripts/svg2png.js",
            "scripts/svg2gif.js",
            "scripts/motion.py",
        ):
            self.assertTrue((ROOT / relative_path).is_file(), relative_path)

        openai_yaml = (ROOT / "agents/openai.yaml").read_text(encoding="utf-8")
        self.assertIn("$fireworks-tech-graph", openai_yaml)

    def test_motion_trigger_and_twelve_style_contracts_ship_together(self) -> None:
        skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
        reference = (ROOT / "references" / "motion-effects.md").read_text(encoding="utf-8")
        scripts_readme = (ROOT / "scripts" / "README.md").read_text(encoding="utf-8")
        self.assertIn("让这张图动起来", skill)
        self.assertIn("Animate this diagram", skill)
        self.assertIn("生成 GIF", skill)
        self.assertIn("制作 GIF", skill)
        self.assertIn("Generate a GIF", skill)
        self.assertIn("Styles 1–12 are enabled", skill)
        self.assertIn("Styles 1–12 are enabled", reference)
        self.assertIn("terminal-evidence-stream", reference)
        self.assertIn("terminal-prompt-cursor", reference)
        self.assertIn("Style 1–12", scripts_readme)
        self.assertIn("blueprint-distribution-wave", reference)
        self.assertIn("token-train", scripts_readme)
        self.assertIn("notion-memory-rail", reference)
        self.assertIn("notion-memory-card", scripts_readme)
        self.assertIn("Styles 5–12", reference)
        self.assertIn("user-approved", reference)
        self.assertNotIn("awaiting_user_review", reference)
        self.assertIn("5.75-second", reference)
        self.assertIn("+2s-settled-flow", skill)
        self.assertIn("38–109", scripts_readme)
        self.assertIn("Exact source bytes are not pinned", " ".join(reference.split()))
        self.assertIn("<output>.motion.json", reference)
        self.assertNotIn("`+2s` awaiting", reference)

    def test_motion_runtime_install_targets_the_skill_root(self) -> None:
        documents = (
            (ROOT / "README.md").read_text(encoding="utf-8"),
            (ROOT / "README.zh.md").read_text(encoding="utf-8"),
            (ROOT / "references" / "motion-effects.md").read_text(encoding="utf-8"),
            (ROOT / "scripts" / "README.md").read_text(encoding="utf-8"),
        )
        expected = (
            'npm install --prefix "$SKILL_ROOT" --ignore-scripts --no-save '
            '--package-lock=false puppeteer-core@25.3.0'
        )
        for document in documents:
            self.assertIn(expected, document)
            self.assertNotIn("npm install --save-dev puppeteer-core", document)

    def test_distribution_includes_codex_metadata(self) -> None:
        package = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
        self.assertRegex(package["version"], r"^\d+\.\d+\.\d+$")
        self.assertIn("agents/", package["files"])
        self.assertIn("schemas/", package["files"])
        self.assertEqual(package["bin"]["fireworks-tech-graph"], "scripts/fireworks.py")
        self.assertNotIn("main", package)

    def test_install_docs_cover_both_discovery_paths(self) -> None:
        for readme in ("README.md", "README.zh.md"):
            content = (ROOT / readme).read_text(encoding="utf-8")
            self.assertIn("~/.agents/skills/fireworks-tech-graph", content)
            self.assertIn("~/.claude/skills/fireworks-tech-graph", content)

    def test_style_regression_exports_a_fixed_1920px_width(self) -> None:
        script = (ROOT / "scripts" / "test-all-styles.sh").read_text(encoding="utf-8")
        self.assertIn("PNG_WIDTH=1920", script)
        self.assertIn('export-png "$svg_file" "$png_file" --width "$PNG_WIDTH"', script)
        self.assertNotIn("scale=2", script)

    def test_workflows_pin_actions_and_never_persist_checkout_credentials(self) -> None:
        workflow_dir = ROOT / ".github" / "workflows"
        if not workflow_dir.is_dir():
            self.skipTest("repository-only workflow files are not part of the Skill payload")
        for workflow in ("ci.yml", "release.yml"):
            content = (workflow_dir / workflow).read_text(encoding="utf-8")
            checkouts = content.count("actions/checkout@")
            self.assertGreater(checkouts, 0)
            self.assertEqual(checkouts, content.count("persist-credentials: false"))
            action_refs = re.findall(r"uses:\s+actions/[\w-]+@([^\s#]+)", content)
            self.assertTrue(action_refs)
            self.assertTrue(all(re.fullmatch(r"[0-9a-f]{40}", ref) for ref in action_refs))

    def test_ci_and_release_gate_all_installed_motion_styles(self) -> None:
        workflow_dir = ROOT / ".github" / "workflows"
        if not workflow_dir.is_dir():
            self.skipTest("repository-only workflow files are not part of the Skill payload")
        for workflow in ("ci.yml", "release.yml"):
            content = (workflow_dir / workflow).read_text(encoding="utf-8")
            self.assertIn("ffmpeg imagemagick", content)
            self.assertIn("puppeteer-core@25.3.0", content)
            self.assertIn('FIREWORKS_INSTALL_CANARY_MOTION: "1"', content)
            self.assertIn('FIREWORKS_INSTALL_CANARY_ALL_STYLES: "1"', content)
            self.assertIn("tools/install-canary.sh", content)

    def test_current_release_notes_are_in_the_distribution(self) -> None:
        package = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
        notes = ROOT / "docs" / "releases" / f'v{package["version"]}.md'
        self.assertTrue(notes.is_file(), notes)
        self.assertIn("Node.js 18", notes.read_text(encoding="utf-8"))

    def test_readme_showcase_uses_approved_gifs(self) -> None:
        samples = ROOT / "assets" / "samples"
        manifest = json.loads((samples / "showcase-gif-manifest.json").read_text(encoding="utf-8"))
        entries = manifest["assets"]
        self.assertEqual(manifest["schema_version"], 1)
        self.assertEqual(manifest["source_contract"], "user-approved +2s-settled-flow")
        self.assertEqual(manifest["approval"]["status"], "user-approved")
        self.assertEqual(manifest["approval"]["style_count"], 12)
        self.assertEqual(
            manifest["approval"]["compatibility_frames_accepted"],
            manifest["approval"]["compatibility_frames_total"],
        )
        self.assertEqual(len(entries), 13)

        expected = {"showcase-12-styles.gif"}
        expected.update(
            {
                "sample-style1-flat.gif",
                "sample-style2-dark.gif",
                "sample-style3-blueprint.gif",
                "sample-style4-notion.gif",
                "sample-style5-glass.gif",
                "sample-style6-claude.gif",
                "sample-style7-openai.gif",
                "sample-style8-dark-luxury.gif",
                "sample-style9-c4-review-canvas.gif",
                "sample-style10-cloud-fabric.gif",
                "sample-style11-event-transit.gif",
                "sample-style12-ops-pulse.gif",
            }
        )
        self.assertEqual({entry["file"] for entry in entries}, expected)
        overview = next(entry for entry in entries if entry["file"] == "showcase-12-styles.gif")
        self.assertEqual(
            (overview["width"], overview["height"], overview["fps"], overview["frames"]),
            (1200, 1280, "12/1", 69),
        )

        for entry in entries:
            path = samples / entry["file"]
            content = path.read_bytes()
            self.assertIn(content[:6], (b"GIF87a", b"GIF89a"), path)
            self.assertEqual(len(content), entry["bytes"], path)
            self.assertEqual(hashlib.sha256(content).hexdigest(), entry["sha256"], path)
        self.assertLessEqual((samples / "showcase-12-styles.gif").stat().st_size, 2 * 1024 * 1024)

        for readme in ("README.md", "README.zh.md"):
            content = (ROOT / readme).read_text(encoding="utf-8")
            self.assertNotRegex(content, r"!\[[^]]*\]\(assets/samples/[^)]+\.png\)")
            for name in expected:
                self.assertIn(f"assets/samples/{name}", content)


if __name__ == "__main__":
    unittest.main()
