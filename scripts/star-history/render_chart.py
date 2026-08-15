#!/usr/bin/env python3
"""Render repository-owned Star History SVGs and a static viewer."""

from __future__ import annotations

import argparse
import html
import json
from datetime import date
from pathlib import Path
from typing import Any

from history import validate_history


WIDTH = 800
HEIGHT = 533.333
PLOT_WIDTH = 700
PLOT_HEIGHT = 423.333
FONT_FAMILY = "xkcd, 'Comic Sans MS', 'Chalkboard SE', cursive"


def _svg_text(value: str) -> str:
    return html.escape(value, quote=True)


def _avatar_markup(history: dict[str, Any], dark: bool) -> str:
    avatar = history.get("avatar")
    if isinstance(avatar, dict) and avatar.get("data") and avatar.get("mimeType"):
        data_uri = f"data:{avatar['mimeType']};base64,{avatar['data']}"
        return (
            '<clipPath id="clip-circle-title"><circle cx="333" cy="23" r="11" />'
            "</clipPath>"
            f'<image x="322" y="12" width="22" height="22" href="{data_uri}" '
            'preserveAspectRatio="xMidYMid slice" clip-path="url(#clip-circle-title)" />'
        )

    fallback = "#4b5563" if dark else "#d1d5db"
    return '<circle cx="333" cy="23" r="11" fill="{}" />'.format(fallback)


def _date_positions(dates: list[str], plot_width: float) -> list[float]:
    """Place Date-mode points according to elapsed calendar days."""

    if not dates:
        return []
    parsed = [date.fromisoformat(value) for value in dates]
    first = parsed[0]
    span = max((parsed[-1] - first).days, 1)
    return [((value - first).days / span) * plot_width for value in parsed]


def _tick_values(max_count: int) -> list[int]:
    """Choose hand-written-friendly y-axis ticks without forcing a large ceiling."""

    if max_count <= 0:
        return [0]
    raw_step = max_count / 7
    magnitude = 10 ** (len(str(int(raw_step))) - 1)
    error = raw_step / magnitude
    if error >= 7:
        step = magnitude * 10
    elif error >= 3:
        step = magnitude * 5
    elif error >= 1.5:
        step = magnitude * 2
    else:
        step = magnitude
    return list(range(0, max_count + 1, step))


def _format_count(value: int) -> str:
    if value == 0:
        return ""
    if value >= 1000:
        return f"{value / 1000:g}k"
    return str(value)


def render_svg(history: dict[str, Any], dark: bool = False) -> str:
    """Render a deterministic hand-drawn Date-mode SVG."""

    validate_history(history)
    points = history["points"]
    foreground = "#f3f4f6" if dark else "#000000"
    background = "#17191f" if dark else "#ffffff"
    line = "#ff745d" if dark else "#dd4528"
    max_count = points[-1]["count"] if points else 1

    dates = [point["date"] for point in points]
    x_positions = _date_positions(dates, PLOT_WIDTH)
    path_commands = []
    for index, point in enumerate(points):
        x = x_positions[index]
        y = PLOT_HEIGHT * (1 - point["count"] / max_count)
        path_commands.append(f"{('M' if index == 0 else 'L')}{x:.3f} {y:.3f}")
    path_markup = " ".join(path_commands)

    year_labels = []
    seen_years: set[str] = set()
    for index, value in enumerate(dates):
        year = value[:4]
        if year in seen_years:
            continue
        seen_years.add(year)
        x = x_positions[index]
        year_labels.append(
            f'<text y="6" dy=".71em" text-anchor="middle" '
            f'style="font-family:{FONT_FAMILY};font-size:16px;fill:{foreground}" '
            f'transform="translate({x:.3f} 423.333)">{_svg_text(year)}</text>'
        )

    y_ticks = []
    for value in _tick_values(max_count):
        y = PLOT_HEIGHT * (1 - value / max_count)
        y_ticks.append(
            f'<g class="tick"><path d="M0 {y:.3f}h-1" stroke="{foreground}" />'
            f'<text x="-7" y="{y:.3f}" dy=".32em" '
            f'style="font-family:{FONT_FAMILY};font-size:16px;fill:{foreground}" '
            f'text-anchor="end">{_format_count(value)}</text></g>'
        )

    legend = (
        f'<rect width="149" height="32" x="8" y="5" fill-opacity=".85" '
        f'fill="{background}" stroke="{foreground}" stroke-width="2" '
        'filter="url(#xkcdify)" rx="5" ry="5" />'
        f'<rect width="8" height="8" x="15" y="17" fill="{line}" '
        'filter="url(#xkcdify)" rx="2" ry="2" />'
        f'<text x="29" y="25" style="font-family:{FONT_FAMILY};font-size:15px;'
        f'fill:{foreground}">{_svg_text(history["repository"].lower())}</text>'
    )

    line_markup = (
        f'<path fill="none" stroke="{line}" d="{path_markup}" '
        'class="xkcd-chart-xyline" filter="url(#xkcdify)" />'
        if path_markup
        else ""
    )

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}"
     viewBox="0 0 {WIDTH} {HEIGHT}" role="img"
     aria-label="Star history chart for {_svg_text(history["repository"])}"
     style="stroke-width:3;font-family:{FONT_FAMILY};background:{background}">
  <defs>
    <filter id="xkcdify" width="100%" height="100%" x="-5" y="-5"
            filterUnits="userSpaceOnUse">
      <feTurbulence baseFrequency=".05" result="noise" type="fractalNoise" />
      <feDisplacementMap in="SourceGraphic" in2="noise" scale="5"
                         xChannelSelector="R" yChannelSelector="G" />
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="{background}" />
  <g pointer-events="all" transform="translate(70 60)">
    <g fill="none" class="xaxis" font-family="sans-serif" font-size="10"
       text-anchor="middle">
      <path d="M.5.5h700" stroke="{foreground}" class="domain"
            filter="url(#xkcdify)" transform="translate(0 423.333)" />
      {''.join(year_labels)}
    </g>
    <g fill="none" class="yaxis" font-family="sans-serif" font-size="10"
       text-anchor="end">
      <path d="M-1 423.833H.5V.5H-1" stroke="{foreground}" class="domain"
            filter="url(#xkcdify)" />
    {''.join(y_ticks)}
    </g>
    {line_markup}
    {legend}
  </g>
  {_avatar_markup(history, dark)}
  <text x="352" y="30" style="font-family:{FONT_FAMILY};font-size:20px;font-weight:700;fill:{foreground}"
        text-anchor="start">Star History</text>
  <text x="50%" y="523.333" style="font-family:{FONT_FAMILY};font-size:17px;fill:{foreground}"
        text-anchor="middle">Date</text>
  <text x="-217" y="8" dy=".75em" style="font-family:{FONT_FAMILY};font-size:17px;fill:{foreground}"
        text-anchor="end" transform="rotate(-90)">GitHub Stars</text>
</svg>
'''


def render_viewer(history: dict[str, Any]) -> str:
    """Create a self-contained static Date/Timeline viewer."""

    validate_history(history)
    payload = json.dumps(history, separators=(",", ":")).replace("<", "\\u003c")
    repository = _svg_text(history["repository"])
    return f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Star History — {repository}</title>
  <style>
    :root {{
      color-scheme: light dark;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      --chart-background: #ffffff;
      --chart-foreground: #202124;
      --chart-line: #e24d32;
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{
        --chart-background: #17191f;
        --chart-foreground: #f3f4f6;
        --chart-line: #ff745d;
      }}
    }}
    body {{ margin: 0; padding: 24px; background: Canvas; color: CanvasText; }}
    main {{ max-width: 960px; margin: auto; }}
    .toolbar {{ display: flex; gap: 8px; align-items: center; margin-bottom: 16px; }}
    button {{ padding: 6px 12px; cursor: pointer; }}
    button[aria-pressed="true"] {{ font-weight: 700; }}
    #chart svg {{ width: 100%; height: auto; display: block; }}
    .note {{ color: GrayText; font-size: 13px; }}
  </style>
</head>
<body>
  <main>
    <div class="toolbar" role="group" aria-label="Chart mode">
      <button id="date" type="button">Date</button>
      <button id="timeline" type="button">Timeline</button>
      <span class="note">{repository}</span>
    </div>
    <div id="chart"></div>
  </main>
  <script>
    const historyData = {payload};
    const chart = document.getElementById("chart");
    const buttons = {{
      Date: document.getElementById("date"),
      Timeline: document.getElementById("timeline")
    }};

    function modeFromHash() {{
      return location.hash.toLowerCase().includes("timeline") ? "Timeline" : "Date";
    }}

    function render(mode) {{
      const points = historyData.points;
      const width = 900;
      const height = 560;
      const left = 78;
      const top = 44;
      const right = 28;
      const bottom = 78;
      const plotWidth = width - left - right;
      const plotHeight = height - top - bottom;
      const values = points.map((point) => point.count);
      const maxValue = Math.max(...values, 1);
      const xValues = points.map((point, index) => mode === "Timeline"
        ? index
        : Date.parse(point.date));
      const minX = xValues.length ? xValues[0] : 0;
      const maxX = xValues.length ? xValues[xValues.length - 1] || 1 : 1;
      const xSpan = maxX - minX || 1;
      const pointsMarkup = points.map((point, index) => {{
        const x = left + ((xValues[index] - minX) / xSpan) * plotWidth;
        const y = top + (1 - point.count / maxValue) * plotHeight;
        return `${{x.toFixed(2)}},${{y.toFixed(2)}}`;
      }}).join(" ");
      const labels = mode === "Timeline" ? "Timeline" : "Date";
      const line = pointsMarkup
        ? `<polyline points="${{pointsMarkup}}" fill="none" stroke="var(--chart-line)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />`
        : "";
      chart.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${{width}} ${{height}}" role="img" aria-label="Star history chart">
        <rect width="100%" height="100%" fill="var(--chart-background)" />
        <text x="${{left}}" y="28" fill="var(--chart-foreground)" font-size="22">Star History</text>
        <line x1="${{left}}" y1="${{top + plotHeight}}" x2="${{width - right}}" y2="${{top + plotHeight}}" stroke="var(--chart-foreground)" />
        <line x1="${{left}}" y1="${{top}}" x2="${{left}}" y2="${{top + plotHeight}}" stroke="var(--chart-foreground)" />
        ${{line}}
        <text x="${{left + plotWidth / 2}}" y="${{height - 24}}" text-anchor="middle" fill="var(--chart-foreground)" font-size="15">${{labels}}</text>
        <text x="20" y="${{top + plotHeight / 2}}" text-anchor="middle" transform="rotate(-90 20 ${{top + plotHeight / 2}})" fill="var(--chart-foreground)" font-size="15">GitHub Stars</text>
      </svg>`;
      Object.entries(buttons).forEach(([name, button]) => button.setAttribute("aria-pressed", String(name === mode)));
    }}

    function setMode(mode) {{
      const repo = historyData.repository.toLowerCase();
      history.replaceState(null, "", `#${{repo}}&${{mode}}`);
      render(mode);
    }}

    buttons.Date.addEventListener("click", () => setMode("Date"));
    buttons.Timeline.addEventListener("click", () => setMode("Timeline"));
    render(modeFromHash());
  </script>
</body>
</html>
'''


def write_outputs(history: dict[str, Any], data_dir: Path, site_dir: Path) -> None:
    """Write both README images and the static viewer site."""

    validate_history(history)
    data_dir.mkdir(parents=True, exist_ok=True)
    site_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "star-history-light.svg").write_text(render_svg(history), encoding="utf-8")
    (data_dir / "star-history-dark.svg").write_text(render_svg(history, dark=True), encoding="utf-8")
    viewer_dir = site_dir / "star-history"
    viewer_dir.mkdir(parents=True, exist_ok=True)
    (viewer_dir / "index.html").write_text(render_viewer(history), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--data-dir", type=Path, required=True)
    parser.add_argument("--site-dir", type=Path, required=True)
    args = parser.parse_args()

    history = json.loads(args.input.read_text(encoding="utf-8"))
    write_outputs(history, args.data_dir, args.site_dir)


if __name__ == "__main__":
    main()
