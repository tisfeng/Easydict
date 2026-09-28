# Interactive example

Open `interactive-architecture.html` directly in a browser. It is a single offline file generated from `fixtures/api-flow-style7.json` and contains no remote runtime dependencies.

Regenerate it with:

```bash
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
tmp_svg="$tmp_dir/api-flow.svg"
python3 scripts/fireworks.py render architecture fixtures/api-flow-style7.json "$tmp_svg"
python3 scripts/fireworks.py export-html "$tmp_svg" examples/interactive-architecture.html --title "API Integration Flow" --slug api-integration-flow
```
