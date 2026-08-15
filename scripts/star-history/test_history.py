#!/usr/bin/env python3
"""High-signal tests for Star History aggregation and rendering."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from history import aggregate_stargazers, build_history, validate_history  # noqa: E402
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

    def test_build_history_rejects_count_mismatch(self) -> None:
        with self.assertRaisesRegex(ValueError, "does not match"):
            build_history(
                "tisfeng/Easydict",
                [{"starred_at": "2024-01-01T00:00:00Z"}],
                current_count=2,
                generated_at="2026-08-15T00:00:00Z",
            )

    def test_render_outputs_include_both_modes_and_themes(self) -> None:
        history = build_history(
            "tisfeng/Easydict",
            [
                {"starred_at": "2024-01-01T00:00:00Z"},
                {"starred_at": "2024-02-01T00:00:00Z"},
            ],
            current_count=2,
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
        self.assertIn("Timeline", render_viewer(history))
        self.assertIn("var(--chart-line)", render_viewer(history))

        with tempfile.TemporaryDirectory() as temporary_dir:
            root = Path(temporary_dir)
            data_dir = root / "data"
            site_dir = root / "site"
            write_outputs(history, data_dir, site_dir)
            self.assertTrue((data_dir / "star-history-light.svg").exists())
            self.assertTrue((data_dir / "star-history-dark.svg").exists())
            self.assertTrue((site_dir / "star-history/index.html").exists())

    def test_validate_history_rejects_non_increasing_points(self) -> None:
        history = {
            "schemaVersion": 1,
            "repository": "tisfeng/Easydict",
            "starCount": 2,
            "points": [
                {"date": "2024-01-01", "count": 2},
                {"date": "2024-01-02", "count": 2},
            ],
        }
        with self.assertRaisesRegex(ValueError, "strictly increasing"):
            validate_history(history)


if __name__ == "__main__":
    unittest.main()
