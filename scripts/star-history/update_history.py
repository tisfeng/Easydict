#!/usr/bin/env python3
"""Update and publish repository-owned Star History data."""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen

from history import append_star_count_snapshot, build_history, validate_history
from render_chart import write_outputs


API_ROOT = "https://api.github.com"
PAGE_SIZE = 100
MAX_ATTEMPTS = 4
JSON_ACCEPT = "application/vnd.github+json"
STAR_ACCEPT = "application/vnd.github.star+json"
AVATAR_SIZE = 64


def api_get(path: str, token: str, accept: str = STAR_ACCEPT) -> object:
    request = Request(
        f"{API_ROOT}{path}",
        headers={
            "Accept": accept,
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "Easydict-star-history",
        },
    )
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with urlopen(request, timeout=20) as response:
                return json.load(response)
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            retryable = error.code in {429, 500, 502, 503, 504}
            if not retryable or attempt == MAX_ATTEMPTS:
                raise RuntimeError(
                    f"GitHub API request failed for {path}: {detail}"
                ) from error
        except (URLError, TimeoutError) as error:
            if attempt == MAX_ATTEMPTS:
                raise RuntimeError(
                    f"GitHub API request failed for {path}: {error}"
                ) from error

        delay = 2 ** (attempt - 1)
        print(
            f"Retrying GitHub API request for {path} in {delay}s "
            f"(attempt {attempt + 1}/{MAX_ATTEMPTS})",
            flush=True,
        )
        time.sleep(delay)


def _avatar_url_with_size(url: str, size: int = AVATAR_SIZE) -> str:
    """Request a bounded GitHub avatar size while preserving other URL options."""

    parsed = urlsplit(url)
    query = [
        (key, value)
        for key, value in parse_qsl(parsed.query, keep_blank_values=True)
        if key != "s"
    ]
    query.append(("s", str(size)))
    return urlunsplit(parsed._replace(query=urlencode(query)))


def fetch_avatar(url: str, token: str) -> dict[str, str] | None:
    """Download the repository avatar so published SVGs remain self-contained."""

    request = Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "User-Agent": "Easydict-star-history",
        },
    )
    try:
        with urlopen(request, timeout=20) as response:
            content = response.read(1_000_000)
            mime_type = response.headers.get_content_type()
    except (HTTPError, URLError, TimeoutError) as error:
        print(f"warning: failed to fetch repository avatar: {error}", file=sys.stderr)
        return None

    if not mime_type.startswith("image/"):
        print(
            f"warning: repository avatar returned unexpected content type {mime_type}",
            file=sys.stderr,
        )
        return None
    return {
        "mimeType": mime_type,
        "data": base64.b64encode(content).decode("ascii"),
    }


def fetch_repository_info(
    repository: str,
    token: str,
    include_avatar: bool = False,
) -> tuple[int, dict[str, str] | None]:
    """Fetch the repository's current star count and optional avatar."""

    repository_info = api_get(f"/repos/{repository}", token, accept=JSON_ACCEPT)
    if not isinstance(repository_info, dict) or not isinstance(
        repository_info.get("stargazers_count"), int
    ):
        raise RuntimeError("repository response did not contain stargazers_count")
    current_count = repository_info["stargazers_count"]
    avatar = None
    owner = repository_info.get("owner")
    if include_avatar and isinstance(owner, dict):
        avatar_url = owner.get("avatar_url")
        if isinstance(avatar_url, str):
            avatar = fetch_avatar(_avatar_url_with_size(avatar_url), token)

    return current_count, avatar


def fetch_stargazers(
    repository: str,
    token: str,
) -> list[dict[str, object]]:
    """Fetch stargazer timestamps for the one-time initial backfill."""

    entries: list[dict[str, object]] = []
    page = 1
    while True:
        response = api_get(
            f"/repos/{repository}/stargazers?per_page={PAGE_SIZE}&page={page}",
            token,
        )
        if not isinstance(response, list):
            raise RuntimeError(f"stargazers response was not a list on page {page}")
        if not response:
            break
        entries.extend(entry for entry in response if isinstance(entry, dict))
        print(f"Fetched stargazers page {page}: {len(response)} entries", flush=True)
        if len(response) < PAGE_SIZE:
            break
        page += 1

    return entries


def load_existing(path: Path) -> dict[str, object] | None:
    if not path.exists():
        return None
    history = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(history, dict):
        raise ValueError("existing history is not an object")
    validate_history(history)
    return history


def write_json_if_changed(path: Path, history: dict[str, object]) -> None:
    rendered = json.dumps(history, ensure_ascii=False, indent=2) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") == rendered:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(rendered, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--data-dir", type=Path, required=True)
    parser.add_argument("--site-dir", type=Path, required=True)
    parser.add_argument("--mode", choices=("verify", "update"), default="update")
    args = parser.parse_args()

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("GH_TOKEN or GITHUB_TOKEN is required")

    history_path = args.data_dir / "history.json"
    existing = load_existing(history_path) if args.mode == "update" else None
    current_count, avatar = fetch_repository_info(
        args.repo, token, include_avatar=args.mode == "update"
    )
    generated_at = (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )
    if args.mode == "verify":
        print(f"Verified repository access; current count is {current_count}")
        print("Verification complete; no files were written")
        return 0

    if existing is None:
        entries = fetch_stargazers(args.repo, token)
        history = build_history(args.repo, entries, generated_at, avatar=avatar)
        print(
            f"Backfilled {len(entries)} stargazers; "
            f"initial count is {history['starCount']}"
        )
    else:
        history = append_star_count_snapshot(
            existing,
            snapshot_date=generated_at[:10],
            observed_count=current_count,
            generated_at=generated_at,
            avatar=avatar,
        )
        print(
            f"Appended weekly snapshot; observed count is {current_count}, "
            f"chart count is {history['starCount']}"
        )

    write_json_if_changed(history_path, history)
    write_outputs(history, args.data_dir, args.site_dir)
    print(f"Generated Star History outputs in {args.data_dir}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
