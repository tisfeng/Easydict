# Contributing

Fireworks Tech Graph accepts fixes, fixtures, style documentation, and renderer improvements.

## Local checks

Requirements: Python 3.9+, Node.js 22.12+ for optional Chromium export, and either CairoSVG or `rsvg-convert`.

```bash
python3 -m unittest discover -s tests -v
TEST_OUTPUT_DIR="$(mktemp -d)" ./scripts/test-all-styles.sh
python3 tools/check_project_consistency.py
python3 tools/distribution.py --check
./tools/install-canary.sh "$PWD/skills/fireworks-tech-graph"
```

Geometry changes must include a failing fixture or unit test before the fix. Generated SVGs must pass the `geometry` check; declared jumps require a matching bridge mask.

Run `python3 tools/distribution.py --sync` after changing any packaged file. Commit the canonical root files and the refreshed nested mirror together.

Please keep secrets, tokens, cookies, generated caches, and local test output out of commits.

## Reproducible reports and visual changes

Include `fireworks.py version`, `doctor`, the command, expected behavior and a
minimal SVG or JSON with private content removed. Report whether a file was
created and whether its exported pixels were inspected.

For palette or typography changes, attach before/after renders, inspect Chinese
and long labels, and keep current source snapshots separate from historical
motion approvals. Run real Chromium regression when a change affects motion:

```bash
FIREWORKS_RUN_RENDER_REGRESSION=1 python3 -m unittest discover -s tests -p test_motion.py -v
```

Security reports follow [SECURITY.md](SECURITY.md). Do not put credentials or
unredacted customer diagrams into public issues.
