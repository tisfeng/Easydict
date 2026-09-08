from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("interactive_html", ROOT / "scripts" / "interactive_html.py")
assert SPEC and SPEC.loader
interactive = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = interactive
SPEC.loader.exec_module(interactive)


SAFE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80"><rect width="100" height="80"/></svg>'


class InteractiveHTMLTest(unittest.TestCase):
    def test_builds_offline_viewer_with_complete_controls(self) -> None:
        output = interactive.build_interactive_html(SAFE_SVG, "Architecture <v1>", {"slug": "sample"})
        self.assertIn("Architecture &lt;v1&gt;", output)
        self.assertIn('data-action="zoom-in"', output)
        self.assertIn('data-action="reset"', output)
        self.assertIn('data-action="theme"', output)
        self.assertIn('data-action="copy"', output)
        for image_format in ("SVG", "PNG", "JPEG", "WebP"):
            self.assertIn(f"<option>{image_format}</option>", output)
        self.assertIn("Content-Security-Policy", output)
        self.assertNotIn("https://", output)

    def test_sanitizer_rejects_active_and_external_content(self) -> None:
        unsafe = (
            '<svg xmlns="http://www.w3.org/2000/svg">'
            '<script>alert(1)</script><image href="https://example.com/a.png" onload="x()"/>'
            '</svg>'
        )
        with self.assertRaisesRegex(ValueError, "unsupported SVG element"):
            interactive.sanitize_svg(unsafe)
        with self.assertRaisesRegex(ValueError, "external reference"):
            interactive.sanitize_svg(
                '<svg xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="url(https://example.com/a.svg#paint)"/></svg>'
            )
        with self.assertRaisesRegex(ValueError, "event handler"):
            interactive.sanitize_svg(
                '<svg xmlns="http://www.w3.org/2000/svg"><rect onclick="x()"/></svg>'
            )

    def test_sanitizer_rejects_foreign_object_and_external_css(self) -> None:
        with self.assertRaisesRegex(ValueError, "foreignobject"):
            interactive.sanitize_svg(
                '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject/></svg>'
            )
        with self.assertRaisesRegex(ValueError, "external or active CSS"):
            interactive.sanitize_svg(
                '<svg xmlns="http://www.w3.org/2000/svg"><style>@import url(https://example.com/x.css)</style></svg>'
            )
        with self.assertRaisesRegex(ValueError, "DTD"):
            interactive.sanitize_svg(
                '<!DOCTYPE svg [<!ENTITY x "boom">]><svg xmlns="http://www.w3.org/2000/svg"><text>&x;</text></svg>'
            )

    def test_sanitizer_rejects_smil_navigation_and_external_paint(self) -> None:
        unsafe_samples = (
            '<svg xmlns="http://www.w3.org/2000/svg"><set href="#go" attributeName="href" to="javascript:alert(1)" begin="0s"/></svg>',
            '<svg xmlns="http://www.w3.org/2000/svg"><a href="data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;">go</a></svg>',
            '<svg xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" filter="url(https://attacker.invalid/f.svg#x)"/></svg>',
        )
        for sample in unsafe_samples:
            with self.subTest(sample=sample):
                with self.assertRaises(ValueError):
                    interactive.sanitize_svg(sample)

    def test_sanitizer_accepts_static_local_paint_servers(self) -> None:
        safe = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">'
            '<defs><filter id="shadow"><feDropShadow dx="1" dy="2" stdDeviation="2"/></filter>'
            '<linearGradient id="gradient"><stop offset="0" stop-color="#fff"/></linearGradient>'
            '<marker id="arrow" markerWidth="8" markerHeight="8" refX="8" refY="4" orient="auto">'
            '<path d="M0 0 L8 4 L0 8 Z" fill="#111"/></marker></defs>'
            '<rect width="80" height="40" fill="url(#gradient)" filter="url(#shadow)"/>'
            '<path d="M10 60 H90" marker-end="url(#arrow)"/></svg>'
        )
        sanitized = interactive.sanitize_svg(safe)
        self.assertIn("url(#gradient)", sanitized)
        self.assertIn("url(#arrow)", sanitized)


if __name__ == "__main__":
    unittest.main()
