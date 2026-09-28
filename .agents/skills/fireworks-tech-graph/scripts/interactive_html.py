#!/usr/bin/env python3
"""Build a safe, self-contained interactive HTML viewer for an SVG diagram."""

from __future__ import annotations

import argparse
import html
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Mapping, Optional, Sequence


ET.register_namespace("", "http://www.w3.org/2000/svg")
SVG_NAMESPACE = "http://www.w3.org/2000/svg"
XML_NAMESPACE = "http://www.w3.org/XML/1998/namespace"
SAFE_ELEMENTS = {
    "circle",
    "clippath",
    "defs",
    "desc",
    "ellipse",
    "feblend",
    "fecolormatrix",
    "fecomposite",
    "fedropshadow",
    "feflood",
    "fegaussianblur",
    "femerge",
    "femergenode",
    "feoffset",
    "filter",
    "g",
    "line",
    "lineargradient",
    "marker",
    "mask",
    "path",
    "pattern",
    "polygon",
    "polyline",
    "radialgradient",
    "rect",
    "stop",
    "style",
    "svg",
    "text",
    "title",
    "tspan",
}
COMMON_ATTRIBUTES = {
    "aria-describedby",
    "aria-hidden",
    "aria-label",
    "aria-labelledby",
    "class",
    "clip-path",
    "clip-rule",
    "color",
    "color-interpolation",
    "color-interpolation-filters",
    "display",
    "fill",
    "fill-opacity",
    "fill-rule",
    "filter",
    "focusable",
    "id",
    "mask",
    "marker-end",
    "marker-mid",
    "marker-start",
    "opacity",
    "paint-order",
    "role",
    "shape-rendering",
    "stroke",
    "stroke-dasharray",
    "stroke-dashoffset",
    "stroke-linecap",
    "stroke-linejoin",
    "stroke-miterlimit",
    "stroke-opacity",
    "stroke-width",
    "tabindex",
    "text-rendering",
    "transform",
    "vector-effect",
    "visibility",
}
ELEMENT_ATTRIBUTES = {
    "svg": {"height", "preserveaspectratio", "viewbox", "width", "x", "y"},
    "rect": {"height", "rx", "ry", "width", "x", "y"},
    "circle": {"cx", "cy", "r"},
    "ellipse": {"cx", "cy", "rx", "ry"},
    "line": {"x1", "x2", "y1", "y2"},
    "polyline": {"pathlength", "points"},
    "polygon": {"pathlength", "points"},
    "path": {"d", "pathlength"},
    "text": {
        "dominant-baseline",
        "dx",
        "dy",
        "font-family",
        "font-size",
        "font-style",
        "font-weight",
        "letter-spacing",
        "text-anchor",
        "word-spacing",
        "x",
        "y",
    },
    "tspan": {"dominant-baseline", "dx", "dy", "text-anchor", "x", "y"},
    "marker": {
        "markerheight",
        "markerunits",
        "markerwidth",
        "orient",
        "preserveaspectratio",
        "refx",
        "refy",
        "viewbox",
    },
    "lineargradient": {"gradienttransform", "gradientunits", "spreadmethod", "x1", "x2", "y1", "y2"},
    "radialgradient": {"cx", "cy", "fr", "fx", "fy", "gradienttransform", "gradientunits", "r", "spreadmethod"},
    "stop": {"offset", "stop-color", "stop-opacity"},
    "pattern": {
        "height",
        "patterncontentunits",
        "patterntransform",
        "patternunits",
        "preserveaspectratio",
        "viewbox",
        "width",
        "x",
        "y",
    },
    "clippath": {"clippathunits"},
    "mask": {"height", "maskcontentunits", "maskunits", "width", "x", "y"},
    "filter": {"filterunits", "height", "primitiveunits", "width", "x", "y"},
    "fedropshadow": {"dx", "dy", "flood-color", "flood-opacity", "stddeviation"},
    "fegaussianblur": {"in", "result", "stddeviation"},
    "feoffset": {"dx", "dy", "in", "result"},
    "feflood": {"flood-color", "flood-opacity", "result"},
    "fecomposite": {"in", "in2", "k1", "k2", "k3", "k4", "operator", "result"},
    "femerge": {"result"},
    "femergenode": {"in"},
    "fecolormatrix": {"in", "result", "type", "values"},
    "feblend": {"in", "in2", "mode", "result"},
}
LOCAL_URL_ATTRIBUTES = {"clip-path", "fill", "filter", "marker-end", "marker-mid", "marker-start", "mask", "stroke"}
LOCAL_URL_RE = re.compile(r"url\(\s*(['\"]?)#[A-Za-z_][\w:.-]*\1\s*\)\Z", re.IGNORECASE)
ACTIVE_VALUE_RE = re.compile(r"(?:javascript\s*:|vbscript\s*:|data\s*:)", re.IGNORECASE)
UNSAFE_CSS_RE = re.compile(
    r"(?:@|\\|url\s*\(|expression\s*\(|javascript\s*:|vbscript\s*:|data\s*:|https?\s*:|//|behavior\s*:|-moz-binding)",
    re.IGNORECASE,
)


def _local_name(value: str) -> str:
    return value.rsplit("}", 1)[-1].lower()


def _namespace(value: str) -> str:
    return value[1:].split("}", 1)[0] if value.startswith("{") else ""


def sanitize_svg(svg_text: str) -> str:
    """Return safe inline SVG or raise ValueError for active/external content."""

    if len(svg_text.encode("utf-8")) > 20 * 1024 * 1024:
        raise ValueError("SVG exceeds the 20 MiB interactive-export limit")
    if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", svg_text, re.IGNORECASE):
        raise ValueError("DTD and entity declarations are not allowed")
    try:
        root = ET.fromstring(svg_text)
    except ET.ParseError as error:
        raise ValueError(f"invalid SVG: {error}") from error
    if _local_name(root.tag) != "svg":
        raise ValueError("input root must be <svg>")

    for element in root.iter():
        tag = _local_name(element.tag)
        if _namespace(element.tag) not in {"", SVG_NAMESPACE}:
            raise ValueError(f"foreign XML namespace is not allowed: {tag}")
        if tag not in SAFE_ELEMENTS:
            raise ValueError(f"unsupported SVG element: {tag}")
        if tag == "style" and UNSAFE_CSS_RE.search(element.text or ""):
            raise ValueError("external or active CSS is not allowed")
        allowed_attributes = COMMON_ATTRIBUTES | ELEMENT_ATTRIBUTES.get(tag, set())
        for raw_name, raw_value in element.attrib.items():
            name = _local_name(raw_name)
            value = raw_value.strip()
            if name.startswith("on"):
                raise ValueError(f"event handler attribute is not allowed: {name}")
            namespace = _namespace(raw_name)
            if namespace and not (namespace == XML_NAMESPACE and name == "space"):
                raise ValueError(f"foreign attribute namespace is not allowed: {name}")
            if name != "space" and name not in allowed_attributes and not name.startswith(("aria-", "data-")):
                raise ValueError(f"unsupported SVG attribute on <{tag}>: {name}")
            if any(ord(character) < 32 and character not in "\t\n\r" for character in value):
                raise ValueError(f"control character is not allowed in attribute: {name}")
            if ACTIVE_VALUE_RE.search(value):
                raise ValueError(f"active reference is not allowed: {name}")
            if "url(" in value.lower():
                if name not in LOCAL_URL_ATTRIBUTES or not LOCAL_URL_RE.fullmatch(value):
                    raise ValueError(f"external reference is not allowed: {value}")
    root.set("role", root.get("role", "img"))
    root.set("focusable", "false")
    return ET.tostring(root, encoding="unicode")


def build_interactive_html(
    svg_text: str,
    title: str,
    metadata: Optional[Mapping[str, object]] = None,
) -> str:
    safe_svg = sanitize_svg(svg_text)
    safe_title = html.escape(title, quote=True)
    metadata_json = json.dumps(dict(metadata or {}), ensure_ascii=False, sort_keys=True).replace("<", "\\u003c")
    return f"""<!doctype html>
<html lang="en" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src data: blob:">
  <title>{safe_title}</title>
  <style>
    :root {{ color-scheme: dark; --page:#0f0f1a; --panel:#0f172a; --border:#334155; --text:#e2e8f0; --muted:#94a3b8; --accent:#a855f7; }}
    html[data-theme="light"] {{ color-scheme:light; --page:#f8fafc; --panel:#fff; --border:#cbd5e1; --text:#0f172a; --muted:#475569; --accent:#7c3aed; }}
    * {{ box-sizing:border-box; }}
    html,body {{ width:100%; height:100%; margin:0; overflow:hidden; background:linear-gradient(135deg,var(--page),#1a1a2e); color:var(--text); font-family:'SF Mono','Fira Code',ui-monospace,monospace; }}
    body {{ display:grid; grid-template-rows:auto 1fr; }}
    .toolbar {{ display:flex; flex-wrap:wrap; align-items:center; gap:8px; padding:10px 14px; background:color-mix(in srgb,var(--panel) 92%,transparent); border-bottom:1px solid var(--border); z-index:2; }}
    .title {{ margin-right:auto; font-size:13px; font-weight:700; }}
    button,select {{ min-height:34px; padding:6px 10px; color:var(--text); background:var(--panel); border:1px solid var(--border); border-radius:8px; font:inherit; cursor:pointer; }}
    button:hover,button:focus-visible,select:focus-visible {{ border-color:var(--accent); outline:2px solid color-mix(in srgb,var(--accent) 35%,transparent); outline-offset:1px; }}
    #stage {{ position:relative; overflow:hidden; touch-action:none; cursor:grab; }}
    #stage.dragging {{ cursor:grabbing; }}
    #canvas {{ width:100%; height:100%; display:grid; place-items:center; transform-origin:0 0; will-change:transform; }}
    #canvas svg {{ max-width:calc(100vw - 40px); max-height:calc(100vh - 92px); width:auto; height:auto; filter:drop-shadow(0 22px 60px rgba(0,0,0,.28)); user-select:none; }}
    #status {{ min-width:76px; color:var(--muted); font-size:12px; text-align:center; }}
    .sr-only {{ position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap; border:0; }}
    @media (prefers-reduced-motion:reduce) {{ * {{ scroll-behavior:auto!important; transition:none!important; }} }}
  </style>
</head>
<body>
  <header class="toolbar" aria-label="Diagram controls">
    <span class="title">{safe_title}</span>
    <button type="button" data-action="zoom-out" aria-label="Zoom out">−</button>
    <button type="button" data-action="reset" aria-label="Reset view">Reset</button>
    <button type="button" data-action="zoom-in" aria-label="Zoom in">+</button>
    <span id="status" aria-live="polite">100%</span>
    <button type="button" data-action="theme" aria-label="Toggle theme">Theme</button>
    <button type="button" data-action="copy" aria-label="Copy SVG source">Copy SVG</button>
    <select id="scale" aria-label="Raster export scale"><option value="1">1×</option><option value="2" selected>2×</option><option value="3">3×</option><option value="4">4×</option></select>
    <select id="format" aria-label="Export format"><option>SVG</option><option>PNG</option><option>JPEG</option><option>WebP</option></select>
    <button type="button" data-action="download">Export</button>
  </header>
  <main id="stage" tabindex="0" aria-label="Interactive diagram. Drag to pan; use plus and minus to zoom.">
    <div id="canvas">{safe_svg}</div>
    <p class="sr-only">Keyboard shortcuts: plus and minus zoom, zero resets, T toggles theme, S exports.</p>
  </main>
  <script>
  (() => {{
    'use strict';
    const metadata = {metadata_json};
    const stage = document.getElementById('stage');
    const canvas = document.getElementById('canvas');
    const svg = canvas.querySelector('svg');
    const status = document.getElementById('status');
    const scaleSelect = document.getElementById('scale');
    const formatSelect = document.getElementById('format');
    let view = {{ x:0, y:0, scale:1 }};
    let drag = null;
    const clamp = value => Math.max(.2, Math.min(8, value));
    const render = () => {{
      canvas.style.transform = `translate(${{view.x}}px,${{view.y}}px) scale(${{view.scale}})`;
      status.textContent = `${{Math.round(view.scale * 100)}}%`;
    }};
    const zoom = (factor, originX=stage.clientWidth/2, originY=stage.clientHeight/2) => {{
      const next = clamp(view.scale * factor);
      const ratio = next / view.scale;
      view.x = originX - (originX - view.x) * ratio;
      view.y = originY - (originY - view.y) * ratio;
      view.scale = next; render();
    }};
    const reset = () => {{ view = {{x:0,y:0,scale:1}}; render(); }};
    stage.addEventListener('wheel', event => {{ event.preventDefault(); const rect=stage.getBoundingClientRect(); zoom(event.deltaY < 0 ? 1.12 : .89, event.clientX-rect.left, event.clientY-rect.top); }}, {{passive:false}});
    stage.addEventListener('pointerdown', event => {{ drag={{id:event.pointerId,x:event.clientX,y:event.clientY,vx:view.x,vy:view.y}}; stage.setPointerCapture(event.pointerId); stage.classList.add('dragging'); }});
    stage.addEventListener('pointermove', event => {{ if(!drag||drag.id!==event.pointerId)return; view.x=drag.vx+event.clientX-drag.x; view.y=drag.vy+event.clientY-drag.y; render(); }});
    const endDrag = () => {{ drag=null; stage.classList.remove('dragging'); }};
    stage.addEventListener('pointerup', endDrag); stage.addEventListener('pointercancel', endDrag);
    const source = () => new XMLSerializer().serializeToString(svg);
    const saveBlob = (blob, extension) => {{ const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=`${{(metadata.slug||'fireworks-tech-graph')}}.${{extension}}`; a.click(); setTimeout(()=>URL.revokeObjectURL(a.href),1000); }};
    const copySource = async () => {{
      const value=source();
      try {{ await navigator.clipboard.writeText(value); status.textContent='Copied'; return; }} catch {{}}
      const area=document.createElement('textarea'); area.value=value; area.setAttribute('readonly',''); area.style.position='fixed'; area.style.opacity='0'; document.body.appendChild(area); area.select();
      status.textContent=document.execCommand('copy')?'Copied':'Copy failed'; area.remove();
    }};
    const exportDiagram = async () => {{
      const format = formatSelect.value.toLowerCase();
      if(format==='svg') {{ saveBlob(new Blob([source()],{{type:'image/svg+xml;charset=utf-8'}}),'svg'); return; }}
      const scale = Math.max(1,Math.min(4,Number(scaleSelect.value)||2));
      const box = svg.viewBox.baseVal; const width=box.width||svg.clientWidth; const height=box.height||svg.clientHeight;
      const image = new Image(); const url=URL.createObjectURL(new Blob([source()],{{type:'image/svg+xml'}}));
      await new Promise((resolve,reject)=>{{ image.onload=resolve; image.onerror=reject; image.src=url; }});
      const raster=document.createElement('canvas'); raster.width=Math.round(width*scale); raster.height=Math.round(height*scale);
      const ctx=raster.getContext('2d'); if(format==='jpeg'){{ctx.fillStyle='#ffffff';ctx.fillRect(0,0,raster.width,raster.height);}} ctx.drawImage(image,0,0,raster.width,raster.height); URL.revokeObjectURL(url);
      const mime=format==='jpeg'?'image/jpeg':format==='webp'?'image/webp':'image/png';
      const blob=await new Promise(resolve=>raster.toBlob(resolve,mime,.94)); if(blob) saveBlob(blob,format==='jpeg'?'jpg':format);
    }};
    document.querySelector('.toolbar').addEventListener('click', async event => {{
      const action=event.target.closest('[data-action]')?.dataset.action; if(!action)return;
      if(action==='zoom-in')zoom(1.2); else if(action==='zoom-out')zoom(.83); else if(action==='reset')reset();
      else if(action==='theme')document.documentElement.dataset.theme=document.documentElement.dataset.theme==='dark'?'light':'dark';
      else if(action==='download')await exportDiagram();
      else if(action==='copy') await copySource();
    }});
    document.addEventListener('keydown', event => {{
      if(event.target.matches('select'))return;
      if(event.key==='+'||event.key==='=')zoom(1.2); else if(event.key==='-')zoom(.83); else if(event.key==='0'||event.key.toLowerCase()==='r')reset();
      else if(event.key.toLowerCase()==='t')document.querySelector('[data-action=theme]').click(); else if(event.key.toLowerCase()==='s'){{event.preventDefault();exportDiagram();}}
    }});
    render();
  }})();
  </script>
</body>
</html>
"""


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("svg_file", type=Path)
    parser.add_argument("output_html", type=Path)
    parser.add_argument("--title")
    parser.add_argument("--slug", default="fireworks-tech-graph")
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    svg_text = args.svg_file.read_text(encoding="utf-8")
    output = build_interactive_html(svg_text, args.title or args.svg_file.stem, {"slug": args.slug})
    args.output_html.parent.mkdir(parents=True, exist_ok=True)
    args.output_html.write_text(output, encoding="utf-8")
    print(f"✓ Interactive HTML: {args.output_html}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
