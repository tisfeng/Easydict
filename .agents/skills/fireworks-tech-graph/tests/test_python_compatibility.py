from __future__ import annotations

import ast
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PythonCompatibilityTest(unittest.TestCase):
    def test_python_sources_parse_with_the_supported_3_9_grammar(self) -> None:
        for directory in ("scripts", "tools", "tests"):
            for path in sorted((ROOT / directory).glob("*.py")):
                with self.subTest(path=path.relative_to(ROOT)):
                    ast.parse(
                        path.read_text(encoding="utf-8"),
                        filename=str(path),
                        feature_version=9,
                    )


if __name__ == "__main__":
    unittest.main()
