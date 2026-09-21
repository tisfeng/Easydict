#!/usr/bin/env python3
"""Unified command line for rendering, validating, inspecting, and exporting diagrams."""

from __future__ import annotations

import argparse
import importlib.util
import json
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from diagram_ir import normalize_diagram  # noqa: E402
from interactive_html import build_interactive_html  # noqa: E402
from motion import DEFAULT_MOTION_DURATION, MOTION_PRESETS, probe_motion_runtime, render_motion_gif  # noqa: E402
from validate_svg import run_check  # noqa: E402
from png_export import export_png  # noqa: E402
from semantic_contracts import STYLE_NAMES  # noqa: E402


def _load_generator():
    spec = importlib.util.spec_from_file_location("fireworks_template_generator", SCRIPT_DIR / "generate-from-template.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load diagram generator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def command_doctor(_: argparse.Namespace) -> int:
    motion_runtime = probe_motion_runtime()
    probes = {
        "python": {"ok": sys.version_info >= (3, 9), "value": sys.version.split()[0]},
        "cairosvg": {"ok": importlib.util.find_spec("cairosvg") is not None},
        "rsvg-convert": {"ok": shutil.which("rsvg-convert") is not None},
        "node": {"ok": shutil.which("node") is not None},
        "ffmpeg": {"ok": shutil.which("ffmpeg") is not None},
        "motion_renderer": motion_runtime,
    }
    probes["raster_export"] = {"ok": probes["cairosvg"]["ok"] or probes["rsvg-convert"]["ok"]}
    probes["animation_export"] = {"ok": motion_runtime["ok"], "optional": True}
    probes["version"] = version_info()
    probes["capabilities"] = {"svg": probes["python"]["ok"], "html": probes["python"]["ok"],
                              "png": probes["raster_export"]["ok"], "gif": motion_runtime["ok"]}
    print(json.dumps(probes, indent=2, sort_keys=True))
    return 0 if probes["python"]["ok"] and probes["raster_export"]["ok"] else 1


def version_info() -> dict:
    package = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
    result = {"version": package["version"], "schema_version": 1, "skill_root": str(ROOT),
              "source": "installed-package", "styles": dict(STYLE_NAMES),
              "node_for_motion": ">=22.12.0"}
    if (ROOT / ".git").exists() and shutil.which("git"):
        commit = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "HEAD"], capture_output=True, text=True, timeout=5)
        dirty = subprocess.run(["git", "-C", str(ROOT), "diff", "--quiet", "HEAD"], timeout=5)
        result.update(source="git-checkout", commit=commit.stdout.strip(), modified=dirty.returncode != 0)
    return result


def command_version(_: argparse.Namespace) -> int:
    print(json.dumps(version_info(), ensure_ascii=False, indent=2, sort_keys=True))
    return 0


def command_export_png(args: argparse.Namespace) -> int:
    print(json.dumps(export_png(args.svg, args.output, args.width), indent=2, sort_keys=True))
    return 0


def _read_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def command_validate(args: argparse.Namespace) -> int:
    diagram = normalize_diagram(_read_json(args.input), args.mode)
    # Validation covers the same renderer boundary as ``render``. Style 8 is
    # intentionally AI-authored/static, so accepting JSON for it here would
    # promise a render path that does not exist.
    _load_generator().parse_style(diagram.style_index)
    print(json.dumps({
        "ok": True,
        "schema_version": diagram.schema_version,
        "input_schema": diagram.input_schema,
        "mode": diagram.mode,
        "style": {
            "id": diagram.style_index,
            "name": diagram.semantic_report["visual_theme"],
        },
        "semantics": dict(diagram.semantic_report),
        "nodes": len(diagram.nodes),
        "edges": len(diagram.edges),
    }, indent=2, sort_keys=True))
    return 0


def command_render(args: argparse.Namespace) -> int:
    generator = _load_generator()
    data = _read_json(args.input)
    svg, report = generator.build_svg_with_report(args.mode, data)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(svg, encoding="utf-8")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "svg": str(args.output), "report": str(args.report) if args.report else None,
                      "typography": report["typography"], "palette": report["palette"]}, sort_keys=True))
    return 0


def command_check(args: argparse.Namespace) -> int:
    checks = args.check or ["xml", "markers", "collisions", "geometry", "composition"]
    results: dict[str, object] = {}
    ok = True
    for check in checks:
        passed, details = run_check(args.svg, check)
        results[check] = {"ok": passed, "details": details}
        ok = ok and passed
    print(json.dumps({"ok": ok, "checks": results}, indent=2, sort_keys=True))
    return 0 if ok else 1


def command_inspect(args: argparse.Namespace) -> int:
    root = ET.parse(args.svg).getroot()
    roles: dict[str, int] = {}
    for element in root.iter():
        role = element.get("data-graph-role")
        if role:
            roles[role] = roles.get(role, 0) + 1
    print(json.dumps({
        "generator": root.get("data-generator"),
        "schema_version": root.get("data-schema-version"),
        "style_id": root.get("data-style-id"),
        "visual_theme": root.get("data-visual-theme"),
        "diagram_type": root.get("data-diagram-type"),
        "semantic_profile": root.get("data-semantic-profile"),
        "semantic_valid": root.get("data-semantic-valid"),
        "viewBox": root.get("viewBox"),
        "roles": roles,
    }, indent=2, sort_keys=True))
    return 0


def command_export_html(args: argparse.Namespace) -> int:
    output = build_interactive_html(
        args.svg.read_text(encoding="utf-8"),
        args.title or args.svg.stem,
        {"slug": args.slug or args.svg.stem},
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    print(json.dumps({"ok": True, "html": str(args.output)}, sort_keys=True))
    return 0


def command_animate(args: argparse.Namespace) -> int:
    report = args.report or args.output.with_suffix(".motion.json")
    result = render_motion_gif(
        args.input,
        args.output,
        report_path=report,
        preset=args.preset,
        duration=args.duration,
        fps=args.fps,
        width=args.width,
        dry_run=args.dry_run,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


def command_examples(_: argparse.Namespace) -> int:
    examples = [str(path.relative_to(ROOT)) for path in sorted((ROOT / "fixtures").glob("*")) if path.suffix in {".json", ".svg"}]
    print(json.dumps({"examples": examples}, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("doctor").set_defaults(func=command_doctor)
    subparsers.add_parser("version", help="report installed version, source and style catalog").set_defaults(func=command_version)
    png = subparsers.add_parser("export-png", help="export PNG with bounded dimensions and pixel-size readback")
    png.add_argument("svg", type=Path)
    png.add_argument("output", type=Path)
    png.add_argument("--width", type=int, default=1920)
    png.set_defaults(func=command_export_png)

    validate = subparsers.add_parser("validate", help="validate and normalize diagram JSON")
    validate.add_argument("mode")
    validate.add_argument("input", type=Path)
    validate.set_defaults(func=command_validate)

    render = subparsers.add_parser("render", help="render diagram JSON to SVG")
    render.add_argument("mode")
    render.add_argument("input", type=Path)
    render.add_argument("output", type=Path)
    render.add_argument("--report", type=Path)
    render.set_defaults(func=command_render)

    check = subparsers.add_parser("check", help="check an SVG artifact")
    check.add_argument("svg", type=Path)
    check.add_argument("--check", action="append", choices=("xml", "markers", "collisions", "geometry", "composition"))
    check.set_defaults(func=command_check)

    inspect = subparsers.add_parser("inspect", help="print semantic SVG metadata")
    inspect.add_argument("svg", type=Path)
    inspect.set_defaults(func=command_inspect)

    export = subparsers.add_parser("export-html", help="create an offline interactive HTML viewer")
    export.add_argument("svg", type=Path)
    export.add_argument("output", type=Path)
    export.add_argument("--title")
    export.add_argument("--slug")
    export.set_defaults(func=command_export_html)

    animate = subparsers.add_parser(
        "animate",
        help="create a validated animated GIF from a generated semantic SVG",
    )
    animate.add_argument("input", type=Path)
    animate.add_argument("output", type=Path)
    animate.add_argument("--preset", choices=("auto", *MOTION_PRESETS), default="auto")
    animate.add_argument("--duration", type=float, default=DEFAULT_MOTION_DURATION)
    animate.add_argument("--fps", type=int, default=20)
    animate.add_argument("--width", type=int, default=960)
    animate.add_argument("--report", type=Path)
    animate.add_argument("--dry-run", action="store_true")
    animate.set_defaults(func=command_animate)

    subparsers.add_parser("examples").set_defaults(func=command_examples)
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return int(args.func(args))
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError, ET.ParseError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"ok": False, "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
