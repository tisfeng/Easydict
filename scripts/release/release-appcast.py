#!/usr/bin/env python3
"""Apply Easydict feed conventions and validate a generated Sparkle appcast.

Sparkle remains responsible for producing signatures, lengths, and update
metadata. This helper only preserves the GitHub release-notes link convention
and rejects unexpected feed churn before publication.
"""

from __future__ import annotations

import argparse
import copy
import html
import json
import os
from pathlib import Path
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

try:
    import markdown
except ImportError:
    markdown = None


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)

def sparkle_tag(name: str) -> str:
    """Return a namespaced Sparkle XML tag."""
    return f"{{{SPARKLE_NS}}}{name}"


def parse_appcast(path: Path) -> ET.ElementTree:
    """Parse an appcast and raise a concise error for invalid XML."""
    try:
        return ET.parse(path)
    except (ET.ParseError, OSError) as error:
        raise ValueError(f"failed to parse {path}: {error}") from error


def item_value(item: ET.Element, name: str) -> str:
    element = item.find(sparkle_tag(name))
    return "" if element is None or element.text is None else element.text


def plain_item_value(item: ET.Element, name: str) -> str:
    element = item.find(name)
    return "" if element is None or element.text is None else element.text


def item_key(item: ET.Element) -> tuple[str, str]:
    return (
        item_value(item, "shortVersionString"),
        item_value(item, "version"),
    )


def items_by_key(tree: ET.ElementTree) -> dict[tuple[str, str], ET.Element]:
    items = tree.getroot().findall("./channel/item")
    result: dict[tuple[str, str], ET.Element] = {}
    for item in items:
        key = item_key(item)
        if not all(key):
            raise ValueError(f"appcast item is missing version metadata: {key}")
        if key in result:
            raise ValueError(f"duplicate appcast item: {key}")
        result[key] = item
    return result


def find_target(
    tree: ET.ElementTree, version: str, build: str
) -> ET.Element:
    items = items_by_key(tree)
    key = (version, build)
    if key not in items:
        raise ValueError(f"appcast does not contain {version} ({build})")
    return items[key]


def write_appcast(tree: ET.ElementTree, path: Path) -> None:
    """Write an appcast with the declaration expected by Sparkle tooling."""
    ET.indent(tree, space="    ")
    tree.write(
        path,
        encoding="UTF-8",
        xml_declaration=True,
        short_empty_elements=True,
    )
    contents = path.read_text(encoding="UTF-8")
    _, separator, body = contents.partition("\n")
    if not separator:
        body = contents
    declaration = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    )
    path.write_text(declaration + body, encoding="UTF-8")


def markdown_to_sparkle_html(markdown_text: str) -> str:
    """Convert Markdown release notes to styled HTML suitable for Sparkle WKWebView."""
    if markdown is not None:
        body_html = markdown.markdown(markdown_text, extensions=["extra", "sane_lists"])
        # Auto-link bare URLs not inside existing href or attributes
        body_html = re.sub(
            r'(?<!href=")(?<!">)(https?://[^\s<"\']+)',
            r'<a href="\1">\1</a>',
            body_html,
        )
    else:
        lines = markdown_text.strip().split("\n")
        html_lines = []
        in_list = False

        def inline_format(text: str) -> str:
            tokens = re.split(r'(\[[^\]]+\]\([^\)]+\)|`[^`]+`|\*\*[^*]+\*\*)', text)
            parts = []
            for token in tokens:
                if not token:
                    continue
                link_m = re.match(r'^\[([^\]]+)\]\((https?://[^\)]+)\)$', token)
                if link_m:
                    t, u = link_m.group(1), link_m.group(2)
                    parts.append(f'<a href="{html.escape(u)}">{html.escape(t)}</a>')
                    continue
                code_m = re.match(r'^`([^`]+)`$', token)
                if code_m:
                    parts.append(f'<code>{html.escape(code_m.group(1))}</code>')
                    continue
                bold_m = re.match(r'^\*\*([^*]+)\*\*$', token)
                if bold_m:
                    parts.append(f'<strong>{html.escape(bold_m.group(1))}</strong>')
                    continue
                escaped = html.escape(token)
                escaped = re.sub(r'(https?://[^\s<]+)', r'<a href="\1">\1</a>', escaped)
                parts.append(escaped)
            return "".join(parts)

        for line in lines:
            stripped = line.strip()
            if not stripped:
                if in_list:
                    html_lines.append("</ul>")
                    in_list = False
                continue
            if stripped.startswith("### "):
                if in_list:
                    html_lines.append("</ul>")
                    in_list = False
                html_lines.append(f"<h3>{inline_format(stripped[4:])}</h3>")
            elif stripped.startswith("## "):
                if in_list:
                    html_lines.append("</ul>")
                    in_list = False
                html_lines.append(f"<h2>{inline_format(stripped[3:])}</h2>")
            elif stripped.startswith("# "):
                if in_list:
                    html_lines.append("</ul>")
                    in_list = False
                html_lines.append(f"<h2>{inline_format(stripped[2:])}</h2>")
            elif stripped.startswith("* ") or stripped.startswith("- "):
                if not in_list:
                    html_lines.append("<ul>")
                    in_list = True
                html_lines.append(f"<li>{inline_format(stripped[2:])}</li>")
            else:
                if in_list:
                    html_lines.append("</ul>")
                    in_list = False
                html_lines.append(f"<p>{inline_format(stripped)}</p>")

        if in_list:
            html_lines.append("</ul>")
        body_html = "\n".join(html_lines)

    return body_html


def fetch_github_release_body(repo: str, tag: str) -> str:
    """Fetch the release notes body from GitHub API for the specified tag."""
    url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    request = urllib.request.Request(url, headers={"User-Agent": "Easydict-Release-Tool"})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            payload = json.loads(response.read().decode("utf-8"))
            return payload.get("body", "") or ""
    except Exception:
        return ""


def set_release_notes_link(args: argparse.Namespace) -> None:
    """Set the release notes description and link on the generated target item."""
    tree = parse_appcast(args.appcast)
    item = find_target(tree, args.version, args.build)

    notes_text = getattr(args, "notes_text", "") or ""
    notes_file = getattr(args, "notes_file", None)
    if not notes_text and notes_file and Path(notes_file).exists():
        notes_text = Path(notes_file).read_text(encoding="UTF-8")
    repo = getattr(args, "repo", "")
    if not notes_text and repo:
        notes_text = fetch_github_release_body(repo, args.version)

    if notes_text.strip():
        formatted_html = markdown_to_sparkle_html(notes_text)
        desc_element = item.find("description")
        if desc_element is None:
            desc_element = ET.Element("description")
            children = list(item)
            pub_date = item.find("pubDate")
            insert_index = (
                children.index(pub_date) + 1
                if pub_date is not None
                else (children.index(item.find("title")) + 1 if item.find("title") is not None else 0)
            )
            item.insert(insert_index, desc_element)
        desc_element.text = formatted_html

        # Remove releaseNotesLink if present, so Sparkle renders description
        old_link = item.find(sparkle_tag("releaseNotesLink"))
        if old_link is not None:
            item.remove(old_link)

        # Set fullReleaseNotesLink to point to external GitHub release
        link_element = item.find(sparkle_tag("fullReleaseNotesLink"))
        if link_element is None:
            link_element = ET.Element(sparkle_tag("fullReleaseNotesLink"))
            children = list(item)
            version_element = item.find(sparkle_tag("shortVersionString"))
            insert_index = (
                children.index(version_element) + 1
                if version_element is not None
                else len(children)
            )
            item.insert(insert_index, link_element)
        link_element.text = args.url
    else:
        # Fallback to releaseNotesLink when no description is present
        link_element = item.find(sparkle_tag("releaseNotesLink"))
        if link_element is None:
            link_element = ET.Element(sparkle_tag("releaseNotesLink"))
            children = list(item)
            version_element = item.find(sparkle_tag("shortVersionString"))
            insert_index = (
                children.index(version_element) + 1
                if version_element is not None
                else len(children)
            )
            item.insert(insert_index, link_element)
        link_element.text = args.url

    write_appcast(tree, args.appcast)


def find_previous_beta(args: argparse.Namespace) -> None:
    """Print the newest beta item older than the current release."""
    if args.channel != "beta":
        print("")
        return

    tree = parse_appcast(args.appcast)
    current_item = find_target(tree, args.version, args.build)
    require_equal(item_value(current_item, "channel"), "beta", "Sparkle channel")

    items = tree.getroot().findall("./channel/item")
    current_index = items.index(current_item)
    for item in items[current_index + 1 :]:
        version = item_value(item, "shortVersionString")
        if version != args.version and item_value(item, "channel") == "beta":
            print(version)
            return
    print("")


def promote_previous_beta(args: argparse.Namespace) -> None:
    """Remove the beta channel from one persisted predecessor."""
    if not args.previous_version:
        return

    tree = parse_appcast(args.appcast)
    current_item = find_target(tree, args.version, args.build)
    require_equal(item_value(current_item, "channel"), "beta", "Sparkle channel")

    matching_items = [
        item
        for item in tree.getroot().findall("./channel/item")
        if item_value(item, "shortVersionString") == args.previous_version
    ]
    require_equal(
        len(matching_items),
        1,
        f"previous beta item count for {args.previous_version}",
    )
    previous_item = matching_items[0]
    channel = previous_item.find(sparkle_tag("channel"))
    if channel is None:
        return
    require_equal(channel.text, "beta", "previous Sparkle channel")
    previous_item.remove(channel)
    write_appcast(tree, args.appcast)


def canonical_item(item: ET.Element) -> bytes:
    clone = copy.deepcopy(item)
    for element in clone.iter():
        if element.text is not None and not element.text.strip():
            element.text = None
        if element.tail is not None and not element.tail.strip():
            element.tail = None
    return ET.tostring(clone, encoding="UTF-8")


def require_equal(actual: object, expected: object, label: str) -> None:
    if actual != expected:
        raise ValueError(f"{label}: expected {expected!r}, got {actual!r}")


def validate_promoted_item(
    original_item: ET.Element,
    candidate_item: ET.Element,
    key: tuple[str, str],
) -> None:
    """Allow only removal of the beta channel from the predecessor."""
    if candidate_item.find(sparkle_tag("channel")) is not None:
        raise ValueError(f"promoted appcast item still has a channel: {key}")

    expected_item = copy.deepcopy(original_item)
    channel = expected_item.find(sparkle_tag("channel"))
    if channel is None:
        require_equal(
            canonical_item(candidate_item),
            canonical_item(expected_item),
            f"unexpected change to promoted appcast item {key}",
        )
        return
    require_equal(
        channel.text,
        "beta",
        f"original channel for promoted appcast item {key}",
    )
    expected_item.remove(channel)
    require_equal(
        canonical_item(candidate_item),
        canonical_item(expected_item),
        f"unexpected change to promoted appcast item {key}",
    )


def validate_appcast(args: argparse.Namespace) -> None:
    """Validate the target update and ensure old items were preserved."""
    original_tree = parse_appcast(args.original)
    candidate_tree = parse_appcast(args.appcast)
    original_items = items_by_key(original_tree)
    candidate_items = items_by_key(candidate_tree)
    target_key = (args.version, args.build)
    original_order = list(original_items)
    candidate_order = list(candidate_items)

    expected_keys = set(original_items)
    expected_keys.add(target_key)
    require_equal(set(candidate_items), expected_keys, "appcast versions")
    expected_order = [target_key]
    expected_order.extend(key for key in original_order if key != target_key)
    require_equal(candidate_order, expected_order, "appcast item order")

    promoted_keys: list[tuple[str, str]] = []
    for key, original_item in original_items.items():
        if key == target_key:
            continue
        candidate_item = candidate_items[key]
        if key[0] == args.previous_beta_version:
            validate_promoted_item(original_item, candidate_item, key)
            promoted_keys.append(key)
            continue
        require_equal(
            canonical_item(candidate_item),
            canonical_item(original_item),
            f"unexpected change to old appcast item {key}",
        )

    if args.previous_beta_version:
        require_equal(
            len(promoted_keys),
            1,
            f"promoted appcast item count for {args.previous_beta_version}",
        )

    item = candidate_items[target_key]
    require_equal(plain_item_value(item, "title"), args.version, "item title")
    if not plain_item_value(item, "pubDate"):
        raise ValueError("target appcast item has no publication date")
    notes_link = (
        item_value(item, "fullReleaseNotesLink")
        or item_value(item, "releaseNotesLink")
    )
    require_equal(
        notes_link,
        args.release_notes_url,
        "release notes URL",
    )
    require_equal(
        item_value(item, "minimumSystemVersion"),
        "13.0",
        "minimum system version",
    )

    channel = item_value(item, "channel")
    expected_channel = "beta" if args.channel == "beta" else ""
    require_equal(channel, expected_channel, "Sparkle channel")

    enclosure = item.find("enclosure")
    if enclosure is None:
        raise ValueError("target appcast item has no enclosure")
    require_equal(enclosure.get("url"), args.download_url, "download URL")
    require_equal(
        enclosure.get("length"),
        str(os.path.getsize(args.archive)),
        "archive length",
    )
    require_equal(
        enclosure.get("type"),
        "application/octet-stream",
        "archive content type",
    )
    signature = enclosure.get(sparkle_tag("edSignature"), "")
    if not signature:
        raise ValueError("target enclosure has no Sparkle EdDSA signature")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    set_link = subparsers.add_parser("set-link")
    set_link.add_argument("--appcast", type=Path, required=True)
    set_link.add_argument("--version", required=True)
    set_link.add_argument("--build", required=True)
    set_link.add_argument("--url", required=True)
    set_link.add_argument("--notes-file", type=Path, default=None)
    set_link.add_argument("--notes-text", default="")
    set_link.add_argument("--repo", default="")
    set_link.set_defaults(handler=set_release_notes_link)

    find_previous = subparsers.add_parser("find-previous-beta")
    find_previous.add_argument("--appcast", type=Path, required=True)
    find_previous.add_argument("--version", required=True)
    find_previous.add_argument("--build", required=True)
    find_previous.add_argument(
        "--channel", choices=("beta", "stable"), required=True
    )
    find_previous.set_defaults(handler=find_previous_beta)

    promote_previous = subparsers.add_parser("promote-previous-beta")
    promote_previous.add_argument("--appcast", type=Path, required=True)
    promote_previous.add_argument("--version", required=True)
    promote_previous.add_argument("--build", required=True)
    promote_previous.add_argument("--previous-version", required=True)
    promote_previous.set_defaults(handler=promote_previous_beta)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--original", type=Path, required=True)
    validate.add_argument("--appcast", type=Path, required=True)
    validate.add_argument("--archive", type=Path, required=True)
    validate.add_argument("--version", required=True)
    validate.add_argument("--build", required=True)
    validate.add_argument("--channel", choices=("beta", "stable"), required=True)
    validate.add_argument("--release-notes-url", required=True)
    validate.add_argument("--download-url", required=True)
    validate.add_argument("--previous-beta-version", default="")
    validate.set_defaults(handler=validate_appcast)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        args.handler(args)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())