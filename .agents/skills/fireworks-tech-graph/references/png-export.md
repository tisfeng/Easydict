# PNG Export

Load this reference when exporting PNG or choosing between native and Chromium rendering. The unified command validates the SVG root/canvas, limits output to 64 megapixels and 32768px per side, writes atomically, and reads PNG dimensions back.

## Renderer Choice

| Tool | Install | Use when |
| --- | --- | --- |
| CairoSVG | `python3 -m pip install cairosvg` | Default; good CSS support |
| `rsvg-convert` | `brew install librsvg` or `apt install librsvg2-bin` | Simple SVGs without complex CSS |
| Puppeteer | Node.js plus Chromium | Browser-generated SVG, CJK/emoji fallback, or pixel fidelity |

Prefer the bundled validation/export entry point:

```bash
SKILL_ROOT="${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}"
python3 "$SKILL_ROOT/scripts/fireworks.py" export-png ./diagram.svg ./diagram.png --width 1920
```

## Manual CairoSVG

```bash
python3 -c "import cairosvg; cairosvg.svg2png(url='input.svg', write_to='output.png', output_width=1920)"
```

## Manual librsvg

```bash
rsvg-convert -w 1920 input.svg -o output.png
```

## Puppeteer

Use Node.js 22.12+ and Puppeteer with Chrome/Chromium. The bundled converter exports intrinsic root-canvas dimensions at 2×; a viewBox-only SVG uses the root viewBox, never an inner shape. It blocks external network requests and uses an isolated headless browser. Sandbox disabling is explicit via `FIREWORKS_CHROME_NO_SANDBOX=1` only for a runtime that requires it.

Install Puppeteer outside the user's project and run the converter:

```bash
SKILL_ROOT="${CLAUDE_SKILL_DIR:-/absolute/path/from-codex-skill-metadata}"
npm install --prefix /tmp/fireworks-tech-graph-puppeteer puppeteer
NODE_PATH=/tmp/fireworks-tech-graph-puppeteer/node_modules node "$SKILL_ROOT/scripts/svg2png.js" ./output
```

## Known Limits

- `rsvg-convert` can omit complex CSS, filters, and `<foreignObject>` content.
- CairoSVG can miss CJK or emoji glyphs when the selected system font lacks them.
- Use Puppeteer when browser rendering is required; its viewport path preserves the SVG dimensions more reliably than a raw Chrome `--window-size` screenshot.
