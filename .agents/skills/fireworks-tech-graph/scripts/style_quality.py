"""Readability tokens and inspectable text-quality evidence for every theme."""
from __future__ import annotations

import re
import xml.etree.ElementTree as ET

# Keep each theme's hue, material, connectors and signatures. Only strengthen
# small supporting text that previously disappeared on its default surface.
READABILITY_TOKENS = {
    1: {"text_muted": "#64748b", "section_sub_fill": "#64748b", "type_label_fill": "#64748b"},
    2: {"text_muted": "#94a3b8", "section_sub_fill": "#94a3b8", "type_label_fill": "#94a3b8"},
    4: {"text_muted": "#6b7280", "section_label_fill": "#6b7280", "section_sub_fill": "#6b7280", "type_label_fill": "#6b7280"},
    6: {"text_muted": "#75695d", "section_sub_fill": "#75695d", "type_label_fill": "#75695d"},
    7: {"text_muted": "#64748b", "section_sub_fill": "#64748b", "type_label_fill": "#64748b", "section_label_fill": "#087f5b"},
    9: {"text_muted": "#656b61", "section_sub_fill": "#756753"},
    10: {"text_muted": "#4b6680", "section_sub_fill": "#4b6680", "type_label_fill": "#4b6680"},
    11: {"text_muted": "#6d665c", "section_sub_fill": "#6d665c"},
    12: {"text_muted": "#8fa8bf", "section_sub_fill": "#8fa8bf", "type_label_fill": "#8fa8bf"},
}


def contrast_ratio(foreground: str, background: str) -> float:
    def luminance(color):
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
            raise ValueError("contrast sampling requires opaque six-digit colors")
        values = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values]
        return sum(v * weight for v, weight in zip(linear, (.2126, .7152, .0722)))
    first, second = sorted((luminance(foreground), luminance(background)))
    return (second + .05) / (first + .05)


def palette_report(style: dict) -> dict:
    background = str(style["background"])
    pairs, unsupported = {}, []
    for key in ("text_primary", "text_secondary", "text_muted", "section_sub_fill"):
        try:
            pairs[key] = round(contrast_ratio(str(style[key]), background), 2)
        except ValueError:
            unsupported.append(key)
    return {"scope": "default opaque canvas text tokens; not a full rendered accessibility audit",
            "minimum_target": 4.5, "ratios": pairs, "unsupported_tokens": unsupported,
            "below_target": [key for key, ratio in pairs.items() if ratio < 4.5]}



def text_quality_report(svg: str) -> dict:
    root = ET.fromstring(svg)
    truncated = []
    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1] != "text":
            continue
        full = element.get("data-full-text")
        visible = "".join(element.itertext())
        if full and visible.endswith("…") and visible != full:
            truncated.append({"role": element.get("data-text-role", "text"),
                              "full_text": full, "visible_text": visible,
                              "font_size": element.get("font-size")})
    return {"complete_text": not truncated, "truncated": truncated,
            "metrics": "heuristic widths; inspect the actual rendered font",
            "hint": "Widen the card, shorten approved copy, or split the view; use text_policy=strict to reject truncation." if truncated else None}
