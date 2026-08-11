#!/usr/bin/env bash

# Create a dated execution plan from the repository template.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <plan-slug>" >&2
  exit 1
fi

slug="$1"
if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Plan slug must use lowercase kebab-case: $slug" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
date_prefix="$(date +%Y-%m-%d)"
target="${repo_root}/docs/exec-plans/active/${date_prefix}-${slug}.md"

if [[ -e "$target" ]]; then
  echo "Plan already exists: $target" >&2
  exit 1
fi

cp "${repo_root}/docs/exec-plans/templates/execution-plan.md" "$target"
echo "$target"
