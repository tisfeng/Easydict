"""Bounded, atomic PNG export with authoritative PNG dimension readback."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

from svg_canvas import canvas_dimensions
from interactive_html import sanitize_svg


def export_png(source_path: Path, output_path: Path, width: int = 1920) -> dict:
    if source_path.resolve() == output_path.resolve() or output_path.suffix.lower() != ".png":
        raise ValueError("PNG output must be a distinct .png file")
    source = source_path.read_text(encoding="utf-8")
    source_width, source_height = canvas_dimensions(source)
    if not isinstance(width, int) or width <= 0 or width > 32768:
        raise ValueError("PNG width must be an integer between 1 and 32768")
    height = max(1, round(width * source_height / source_width))
    if width * height > 64_000_000 or height > 32768:
        raise ValueError("PNG output exceeds the 64 megapixel / 32768px export budget")
    # The same offline SVG subset is accepted by HTML and raster export.
    # This rejects external URLs, scripts and DTDs before any renderer sees them.
    sanitize_svg(source)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    errors = []
    renderer = None
    with tempfile.TemporaryDirectory(prefix=".fireworks-png-", dir=output_path.parent) as directory:
        temporary = Path(directory) / "render.png"
        if importlib.util.find_spec("cairosvg") is not None:
            try:
                import cairosvg
                cairosvg.svg2png(bytestring=source.encode("utf-8"), write_to=str(temporary),
                                output_width=width, output_height=height)
                renderer = "cairosvg"
            except Exception as error:
                errors.append("CairoSVG: " + str(error))
        if renderer is None and shutil.which("rsvg-convert"):
            result = subprocess.run(["rsvg-convert", "-w", str(width), "-h", str(height),
                                     str(source_path), "-o", str(temporary)],
                                    capture_output=True, text=True, timeout=60)
            if result.returncode == 0:
                renderer = "rsvg-convert"
            else:
                errors.append("rsvg-convert: " + result.stderr.strip())
        if renderer is None:
            raise RuntimeError("PNG_RENDERER: install CairoSVG or rsvg-convert; " + "; ".join(errors))
        data = temporary.read_bytes()
        if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
            raise RuntimeError("renderer did not produce a valid PNG header")
        actual = struct.unpack(">II", data[16:24])
        if actual != (width, height):
            raise RuntimeError(f"PNG dimensions {actual} differ from requested {(width, height)}")
        temporary.replace(output_path)
    return {"ok": True, "png": str(output_path), "width": width, "height": height,
            "renderer": renderer, "bytes": len(data), "fallback_notes": errors}
