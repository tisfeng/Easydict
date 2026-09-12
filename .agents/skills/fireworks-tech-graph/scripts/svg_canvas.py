"""Shared SVG root and canvas validation; no optional renderer dependencies."""
from __future__ import annotations

import json
import math
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

SVG_NAMESPACE = "http://www.w3.org/2000/svg"
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"


def parse_viewbox(value: str) -> tuple[float, float, float, float]:
    fields = re.split(r"[\s,]+", str(value).strip())
    if len(fields) != 4 or not all(re.fullmatch(NUMBER, field) for field in fields):
        raise ValueError("viewBox must contain exactly four finite numbers")
    numbers = tuple(float(field) for field in fields)
    if not all(math.isfinite(number) for number in numbers) or min(numbers[2:]) <= 0:
        raise ValueError("viewBox width and height must be finite positive numbers")
    return numbers


def parse_svg(source: str) -> ET.Element:
    if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", source, re.IGNORECASE):
        raise ValueError("SVG DTD and entity declarations are not supported")
    root = ET.fromstring(source)
    if root.tag not in {"svg", "{" + SVG_NAMESPACE + "}svg"}:
        raise ValueError("input root must be <svg> in the SVG namespace")
    if "viewBox" in root.attrib:
        parse_viewbox(root.attrib["viewBox"])
    return root


def _length(value: str, fallback: float) -> float:
    value = value.strip()
    if value.endswith("%"):
        if not re.fullmatch(NUMBER, value[:-1]) or not math.isfinite(float(value[:-1])) or float(value[:-1]) <= 0:
            raise ValueError("percentage dimensions must be finite positive numbers")
        # Percentages need a viewport; use the intrinsic viewBox aspect ratio.
        if fallback <= 0:
            raise ValueError("percentage dimensions require a viewBox")
        return fallback
    match = re.fullmatch(r"(" + NUMBER + r")\s*(px|pt|pc|mm|cm|in)?", value.strip())
    if not match:
        raise ValueError("unsupported SVG dimension: " + value)
    factors = {None: 1, "px": 1, "pt": 96 / 72, "pc": 16, "mm": 96 / 25.4,
               "cm": 96 / 2.54, "in": 96}
    result = float(match[1]) * factors[match[2]]
    if not math.isfinite(result) or result <= 0:
        raise ValueError("SVG dimensions must be finite positive numbers")
    return result


def canvas_dimensions(source: str) -> tuple[float, float]:
    root = parse_svg(source)
    box = parse_viewbox(root.get("viewBox")) if root.get("viewBox") else None
    width = _length(root.get("width", "100%"), box[2] if box else 0)
    height = _length(root.get("height", "100%"), box[3] if box else 0)
    if box and "width" in root.attrib and "height" not in root.attrib:
        height = width * box[3] / box[2]
    elif box and "height" in root.attrib and "width" not in root.attrib:
        width = height * box[2] / box[3]
    if width * height > 64_000_000 or max(width, height) > 32768:
        raise ValueError("SVG canvas exceeds the 64 megapixel / 32768px export budget")
    return width, height


if __name__ == "__main__":
    try:
        width, height = canvas_dimensions(Path(sys.argv[1]).read_text(encoding="utf-8"))
        print(json.dumps({"width": width, "height": height}))
    except (OSError, ValueError, ET.ParseError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
