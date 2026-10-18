#!/usr/bin/env python3
"""Validate public GitHub Release HTTP and Sparkle feed contracts."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"


def fail(message: str) -> None:
    raise ValueError(message)


def read_headers(path: Path) -> dict[str, object]:
    content = path.read_text(encoding="utf-8", errors="replace")
    blocks = [block for block in re.split(r"\r?\n\r?\n", content) if block.strip()]
    if not blocks:
        fail(f"HTTP response did not include headers: {path}")
    lines = blocks[-1].splitlines()
    status = lines[0] if lines else ""
    values: dict[str, str] = {}
    for line in lines[1:]:
        if ":" not in line:
            continue
        name, value = line.split(":", 1)
        values[name.strip().lower()] = value.strip()
    return {"status": status, "headers": values}


def require_header(headers: dict[str, str], name: str, expected: str, label: str) -> None:
    actual = headers.get(name.lower(), "")
    if actual != expected:
        fail(f"{label} mismatch: expected={expected}, actual={actual}")


def validate_headers(args: argparse.Namespace) -> None:
    response = read_headers(Path(args.headers))
    status = str(response["status"])
    values = response["headers"]
    status_code = args.status
    if not re.search(rf"\s{re.escape(status_code)}(?:\s|$)", status):
        fail(f"expected HTTP {status_code}, got {status or 'empty status'}")
    require_header(values, "content-length", args.length, args.label)
    require_header(values, "content-type", args.content_type, args.label)
    if args.range_total is not None:
        require_header(values, "content-length", "1", "Range Content-Length")
        require_header(
            values,
            "content-range",
            f"bytes 0-0/{args.range_total}",
            "Range Content-Range",
        )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_assets(args: argparse.Namespace) -> None:
    release = json.loads(Path(args.release_json).read_text(encoding="utf-8"))
    assets = release.get("assets")
    if not isinstance(assets, list):
        fail("GitHub release response has no assets array")
    by_name: dict[str, list[dict[str, object]]] = {}
    for asset in assets:
        if isinstance(asset, dict) and isinstance(asset.get("name"), str):
            by_name.setdefault(asset["name"], []).append(asset)

    expected = {
        "Easydict.zip": ("application/zip", Path(args.artifact_dir) / "Easydict.zip"),
        "Easydict.dmg": (
            "application/x-apple-diskimage",
            Path(args.artifact_dir) / "Easydict.dmg",
        ),
        "SHA256SUMS.txt": (
            "text/plain; charset=utf-8",
            Path(args.artifact_dir) / "SHA256SUMS.txt",
        ),
    }
    for name, (content_type, local_path) in expected.items():
        matches = by_name.get(name, [])
        if len(matches) != 1:
            fail(f"GitHub release must contain exactly one uploaded asset: {name}")
        asset = matches[0]
        if asset.get("state") != "uploaded":
            fail(f"GitHub asset is not uploaded: {name}")
        local_size = local_path.stat().st_size
        if asset.get("size") != local_size:
            fail(
                f"GitHub asset size mismatch for {name}: "
                f"expected={local_size}, actual={asset.get('size', '')}"
            )
        if asset.get("contentType") != content_type:
            fail(
                f"GitHub asset Content-Type mismatch for {name}: "
                f"expected={content_type}, actual={asset.get('contentType', '')}"
            )
        digest = asset.get("digest", "")
        expected_digest = f"sha256:{sha256(local_path)}"
        if digest != expected_digest:
            fail(
                f"GitHub asset digest mismatch for {name}: "
                f"expected={expected_digest}, actual={digest}"
            )


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def normalized_element(element: ET.Element) -> tuple[object, ...]:
    text = element.text or ""
    if local_name(element.tag) != "description":
        text = text.strip()
    return (
        element.tag,
        text,
        tuple(sorted(element.attrib.items())),
        tuple(normalized_element(child) for child in element),
    )


def target_item(path: Path, version: str, build: str) -> tuple[object, ...]:
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError) as error:
        fail(f"failed to parse appcast {path}: {error}")
    matches = []
    for item in root.findall("./channel/item"):
        values = {
            local_name(child.tag): (child.text or "").strip() for child in item
        }
        if values.get("shortVersionString") == version and values.get("version") == build:
            if item.find("enclosure") is None:
                continue
            matches.append(normalized_element(item))
    if len(matches) != 1:
        fail(
            f"appcast must contain exactly one complete release item for "
            f"{version} ({build}): found {len(matches)} in {path}"
        )
    return matches[0]


def compare_appcast(args: argparse.Namespace) -> None:
    expected = target_item(Path(args.expected), args.version, args.build)
    actual = target_item(Path(args.actual), args.version, args.build)
    if actual != expected:
        fail(f"public appcast entry mismatch: expected={expected}, actual={actual}")


def compare_file(args: argparse.Namespace) -> None:
    expected = Path(args.expected).read_bytes()
    actual = Path(args.actual).read_bytes()
    if actual != expected:
        fail(f"public checksum content mismatch: expected={args.expected}, actual={args.actual}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    headers = subparsers.add_parser("validate-headers")
    headers.add_argument("--headers", required=True)
    headers.add_argument("--status", default="200")
    headers.add_argument("--length", required=True)
    headers.add_argument("--content-type", required=True)
    headers.add_argument("--label", default="public response")
    headers.add_argument("--range-total")
    headers.set_defaults(handler=validate_headers)

    assets = subparsers.add_parser("validate-assets")
    assets.add_argument("--release-json", required=True)
    assets.add_argument("--artifact-dir", required=True)
    assets.set_defaults(handler=validate_assets)

    appcast = subparsers.add_parser("compare-appcast")
    appcast.add_argument("--expected", required=True)
    appcast.add_argument("--actual", required=True)
    appcast.add_argument("--version", required=True)
    appcast.add_argument("--build", required=True)
    appcast.set_defaults(handler=compare_appcast)

    checksum = subparsers.add_parser("compare-file")
    checksum.add_argument("--expected", required=True)
    checksum.add_argument("--actual", required=True)
    checksum.set_defaults(handler=compare_file)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        args.handler(args)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
