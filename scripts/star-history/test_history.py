#!/usr/bin/env python3
"""High-signal tests for Star History aggregation and rendering."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from history import (  # noqa: E402
    aggregate_stargazers,
    append_star_count_snapshot,
    build_history,
    validate_history,
)
from render_chart import render_svg, render_viewer, write_outputs  # noqa: E402


class HistoryTests(unittest.TestCase):
    def test_aggregate_stargazers_returns_utc_cumulative_daily_counts(self) -> None:
        entries = [
            {"starred_at": "2024-01-02T23:00:00-05:00"},
            {"starred_at": "2024-01-01T01:00:00Z"},
            {"starred_at": "2024-01-02T02:00:00Z"},
        ]
        self.assertEqual(
            aggregate_stargazers(entries),
            [
                {"date": "2024-01-01", "count": 1},
                {"date": "2024-01-02", "count": 2},
                {"date": "2024-01-03", "count": 3},
            ],
        )

    def test_build_history_uses_available_stargazer_points(self) -> None:
        history = build_history(
            "tisfeng/Easydict",
            [{"starred_at": "2024-01-01T00:00:00Z"}],
            generated_at="2026-08-15T00:00:00Z",
        )
        self.assertEqual(history["starCount"], 1)
        self.assertEqual(history["points"][-1], {"date": "2024-01-01", "count": 1})

    def test_append_snapshot_does_not_lower_history_after_unstars(self) -> None:
        history = {
            "schemaVersion": 1,
            "repository": "tisfeng/Easydict",
            "generatedAt": "2026-08-09T00:00:00Z",
            "starCount": 10,
            "points": [
                {"date": "2024-01-01", "count": 9},
                {"date": "2024-01-02", "count": 10},
            ],
        }
        updated = append_star_count_snapshot(
            history,
            snapshot_date="2026-08-16",
            observed_count=9,
            generated_at="2026-08-16T00:00:00Z",
        )
        self.assertEqual(updated["starCount"], 10)
        self.assertEqual(updated["points"][-1], {"date": "2026-08-16", "count": 10})
        self.assertEqual(updated["points"][:2], history["points"])

    def test_render_outputs_include_both_modes_and_themes(self) -> None:
        history = build_history(
            "tisfeng/Easydict",
            [
                {"starred_at": "2024-01-01T00:00:00Z"},
                {"starred_at": "2024-02-01T00:00:00Z"},
            ],
            generated_at="2026-08-15T00:00:00Z",
            avatar={"mimeType": "image/png", "data": "YQ=="},
        )
        light_svg = render_svg(history)
        self.assertIn("Star History", light_svg)
        self.assertIn("data:image/png;base64,YQ==", light_svg)
        self.assertNotIn("★ tisfeng/easydict", light_svg)
        self.assertIn("xkcdify", light_svg)
        self.assertIn("font-family:xkcd", light_svg)
        self.assertIn("M0.000", light_svg)
        self.assertIn("L700.000", light_svg)
        self.assertIn("#17191f", render_svg(history, dark=True))
        viewer = render_viewer(history)
        self.assertIn("Timeline", viewer)
        self.assertIn('mode === "Timeline"', viewer)
        self.assertIn('? index', viewer)
        self.assertIn('? "Timeline" : "Date"', viewer)
        self.assertIn("var(--chart-line)", viewer)

        with tempfile.TemporaryDirectory() as temporary_dir:
            root = Path(temporary_dir)
            data_dir = root / "data"
            site_dir = root / "site"
            write_outputs(history, data_dir, site_dir)
            self.assertTrue((data_dir / "star-history-light.svg").exists())
            self.assertTrue((data_dir / "star-history-dark.svg").exists())
            self.assertTrue((site_dir / "star-history/index.html").exists())

    def test_validate_history_allows_flat_points_but_rejects_decreases(self) -> None:
        history = {
            "schemaVersion": 1,
            "repository": "tisfeng/Easydict",
            "starCount": 2,
            "points": [
                {"date": "2024-01-01", "count": 2},
                {"date": "2024-01-02", "count": 2},
            ],
        }
        validate_history(history)
        history["points"][1]["count"] = 1
        with self.assertRaisesRegex(ValueError, "must not decrease"):
            validate_history(history)


if __name__ == "__main__":
    unittest.main()
