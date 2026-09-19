"""Public input boundaries and typography regressions (independent of showcase art)."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))


class QualityUpgradeTest(unittest.TestCase):
    def cli(self, *args):
        return subprocess.run([sys.executable, str(ROOT / "scripts/fireworks.py"), *args],
                              capture_output=True, text=True)

    def test_non_svg_and_foreign_namespace_are_rejected_by_default_check(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.svg"
            for source in ('<document/>', '<svg xmlns="urn:not-svg"/>'):
                with self.subTest(source=source):
                    path.write_text(source)
                    result = self.cli("check", str(path))
                    self.assertNotEqual(result.returncode, 0, result.stdout)
                    self.assertFalse(json.loads(result.stdout)["ok"])

    def test_default_check_rejects_unannotated_arrow_crossing_node(self):
        source = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200">
          <defs><marker id="a"><path d="M 0 0 L 10 5 L 0 10 Z"/></marker></defs>
          <rect id="node" x="150" y="50" width="100" height="100"/>
          <path id="edge" d="M 50 100 L 350 100" stroke="black" marker-end="url(#a)"/>
        </svg>'''
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.svg"
            path.write_text(source)
            result = self.cli("check", str(path))
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("intersects", result.stdout)

    def test_invalid_viewbox_is_rejected_before_render(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.json"
            for box in ("0 0 0 0", "0 0 -20 10", "0 0 NaN 10", "0 0 100", "junk"):
                with self.subTest(viewBox=box):
                    path.write_text(json.dumps({"schema_version": 1, "mode": "architecture",
                                                "viewBox": box, "nodes": [], "arrows": []}))
                    result = self.cli("validate", "architecture", str(path))
                    self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_cjk_description_uses_available_second_line_without_losing_text(self):
        spec = importlib.util.spec_from_file_location("quality_generator", ROOT / "scripts/generate-from-template.py")
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        text = "协调跨区域订单处理与库存一致性验证"
        lines = module.wrap_text_lines(text, 120, font_size=11.5, max_lines=2)
        self.assertEqual("".join(lines), text)
        self.assertEqual(len(lines), 2)

    def test_canvas_dimensions_use_root_and_handle_physical_units(self):
        from svg_canvas import canvas_dimensions
        cases = (
            ('<svg viewBox="-10 -20 400 200"><rect width="8" height="9"/></svg>', (400, 200)),
            ('<svg width="2in" height="72pt"/>', (192, 96)),
            ('<svg width="800" viewBox="0 0 400 200"/>', (800, 400)),
            ('<svg width="100%" height="100%" viewBox="0 0 500 250"/>', (500, 250)),
        )
        for source, expected in cases:
            with self.subTest(source=source):
                self.assertEqual(canvas_dimensions(source), expected)
        for source in ('<svg width="0" height="100"/>', '<svg width="40000" height="100"/>', '<svg width="bad%" viewBox="0 0 400 200"/>'):
            with self.assertRaises(ValueError):
                canvas_dimensions(source)

    def test_palette_tokens_reach_target_on_default_canvas(self):
        from style_quality import palette_report
        from test_motion import generator
        for style in range(1, 13):
            if style == 8:
                continue  # Authored SVG has no generator-owned palette.
            with self.subTest(style=style):
                report = palette_report(generator.parse_style(style)[1])
                self.assertEqual(report["below_target"], [])
        custom = dict(generator.parse_style(1)[1], background="rgba(255,255,255,.5)")
        self.assertTrue(palette_report(custom)["unsupported_tokens"])

    def test_strict_text_policy_rejects_loss_before_writing_output(self):
        data = {"style": 1, "nodes": [{"id": "n", "x": 80, "y": 120,
                "width": 100, "height": 60, "label": "必须完整显示的跨区域订单一致性校验服务标题"}], "arrows": []}
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory)/"input.json", Path(directory)/"output.svg"
            source.write_text(json.dumps(data))
            result = self.cli("render", "architecture", str(source), str(output))
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertFalse(json.loads(result.stdout)["typography"]["complete_text"])
            original = output.read_bytes()
            data["text_policy"] = "strict"
            source.write_text(json.dumps(data))
            result = self.cli("render", "architecture", str(source), str(output))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("TEXT_FIT", result.stdout + result.stderr)
            self.assertEqual(output.read_bytes(), original)

    def test_png_rejects_unsafe_or_oversize_input_without_overwriting(self):
        from png_export import export_png
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory)/"input.svg", Path(directory)/"output.png"
            output.write_bytes(b"keep-existing")
            for content, width in (('<svg viewBox="0 0 100 100"><script>alert(1)</script></svg>', 100),
                                   ('<svg viewBox="0 0 100 100"/>', 32000)):
                source.write_text(content)
                with self.assertRaises(ValueError):
                    export_png(source, output, width)
                self.assertEqual(output.read_bytes(), b"keep-existing")

    @unittest.skipUnless(__import__("shutil").which("rsvg-convert") or importlib.util.find_spec("cairosvg"),
                         "A PNG renderer is required for real export readback")
    def test_png_and_legacy_batch_read_back_root_dimensions(self):
        import struct
        from png_export import export_png
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory)/"input.svg", Path(directory)/"input.png"
            source.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><rect width="10" height="20"/></svg>')
            report = export_png(source, output, 320)
            self.assertEqual((report["width"], report["height"]), (320, 160))
            self.assertEqual(struct.unpack(">II", output.read_bytes()[16:24]), (320, 160))
            if __import__("os").environ.get("FIREWORKS_RUN_RENDER_REGRESSION") == "1" and __import__("shutil").which("node"):
                result = subprocess.run(["node", str(ROOT/"scripts/svg2png.js"), directory], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(struct.unpack(">II", output.read_bytes()[16:24]), (800, 400))
                # CSS must honor fitted presentation attributes in an actual browser.
                from test_motion import generator
                data = json.loads((ROOT/"fixtures/c4-review-canvas-style9.json").read_text())
                data["nodes"][1]["description"] = "协调跨区域订单处理与库存一致性验证"
                source.write_text(generator.build_svg_with_report("architecture", data)[0])
                probe = r"""
const fs = require('fs');
const {loadRenderer, chromeExecutable} = require(process.argv[1]);
(async () => {
 const renderer = loadRenderer();
 const browser = await renderer.api.launch({headless:true, executablePath:chromeExecutable(renderer.api),
  args:process.env.FIREWORKS_CHROME_NO_SANDBOX==='1'?['--no-sandbox','--disable-setuid-sandbox']:[]});
 try {
  const page = await browser.newPage();
  await page.setContent(fs.readFileSync(process.argv[2],'utf8'));
  const mismatches = await page.evaluate(()=>[...document.querySelectorAll('.node-sub')]
   .filter(e=>parseFloat(getComputedStyle(e).fontSize)!==parseFloat(e.getAttribute('font-size'))).length);
  if(mismatches)throw new Error('Fitted font sizes overridden by CSS: '+mismatches);
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
"""
                result = subprocess.run(["node", "-e", probe, str(ROOT/"scripts/renderer_runtime.js"), str(source)], capture_output=True, text=True, timeout=60)
                self.assertEqual(result.returncode, 0, result.stderr)



if __name__ == "__main__":
    unittest.main()
