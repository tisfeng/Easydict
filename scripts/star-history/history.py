#!/usr/bin/env python3
"""Pure data functions for repository-owned Star History generation."""

from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
from typing import Any, Iterable


def starred_date(value: str) -> str:
    """Convert an ISO-8601 timestamp to its UTC calendar date."""

    if not value:
        raise ValueError("stargazer entry is missing starred_at")

    normalized = value.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        raise ValueError(f"stargazer timestamp has no timezone: {value}")
    return parsed.astimezone(timezone.utc).date().isoformat()


def aggregate_stargazers(entries: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Build cumulative daily counts from stargazer timestamps."""

    counts_by_date: Counter[str] = Counter()
    for entry in entries:
        timestamp = entry.get("starred_at")
        if not isinstance(timestamp, str):
            raise ValueError("stargazer entry is missing starred_at")
        counts_by_date[starred_date(timestamp)] += 1

    total = 0
    points: list[dict[str, Any]] = []
    for date in sorted(counts_by_date):
        total += counts_by_date[date]
        points.append({"date": date, "count": total})
    return points


def build_history(
    repository: str,
    entries: Iterable[dict[str, Any]],
    generated_at: str,
    avatar: dict[str, str] | None = None,
) -> dict[str, Any]:
    """Build the initial history document from stargazer timestamps."""

    points = aggregate_stargazers(entries)
    final_count = points[-1]["count"] if points else 0

    history: dict[str, Any] = {
        "schemaVersion": 1,
        "repository": repository,
        "generatedAt": generated_at,
        "starCount": final_count,
        "points": points,
    }
    if avatar is not None:
        history["avatar"] = avatar
    return history


def append_star_count_snapshot(
    history: dict[str, Any],
    snapshot_date: str,
    observed_count: int,
    generated_at: str,
    avatar: dict[str, str] | None = None,
) -> dict[str, Any]:
    """Append a monotonic weekly star-count snapshot to existing history."""

    validate_history(history)
    if not isinstance(observed_count, int) or observed_count < 0:
        raise ValueError("observed star count must be a non-negative integer")

    points = [dict(point) for point in history["points"]]
    previous_count = points[-1]["count"] if points else 0
    snapshot_count = max(previous_count, observed_count)

    if points and snapshot_date < points[-1]["date"]:
        raise ValueError("snapshot date must not precede the latest history point")
    if points and snapshot_date == points[-1]["date"]:
        points[-1]["count"] = max(points[-1]["count"], snapshot_count)
    else:
        points.append({"date": snapshot_date, "count": snapshot_count})

    updated = dict(history)
    updated["generatedAt"] = generated_at
    updated["starCount"] = points[-1]["count"] if points else 0
    updated["points"] = points
    if avatar is not None:
        updated["avatar"] = avatar
    validate_history(updated)
    return updated


def validate_history(history: dict[str, Any]) -> None:
    """Validate persisted history before it is rendered or published."""

    if history.get("schemaVersion") != 1:
        raise ValueError("unsupported history schema")
    if not isinstance(history.get("repository"), str):
        raise ValueError("history repository is missing")

    avatar = history.get("avatar")
    if avatar is not None:
        if not isinstance(avatar, dict):
            raise ValueError("history avatar must be an object")
        if not isinstance(avatar.get("mimeType"), str) or not isinstance(
            avatar.get("data"), str
        ):
            raise ValueError("history avatar must contain mimeType and data")

    points = history.get("points")
    if not isinstance(points, list):
        raise ValueError("history points must be a list")

    previous_date = ""
    previous_count = 0
    for point in points:
        if not isinstance(point, dict):
            raise ValueError("history points must be objects")
        date = point.get("date")
        count = point.get("count")
        if not isinstance(date, str) or not isinstance(count, int):
            raise ValueError("history points must contain date and integer count")
        if date <= previous_date:
            raise ValueError("history point dates must be strictly increasing")
        if count < previous_count:
            raise ValueError("history point counts must not decrease")
        previous_date = date
        previous_count = count

    if history.get("starCount") != previous_count:
        raise ValueError("history starCount does not match the final point")
