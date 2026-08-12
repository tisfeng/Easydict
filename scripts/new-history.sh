#!/usr/bin/env bash

# Create a timestamped change history from the repository template.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <task-slug>" >&2
  exit 1
fi

slug="$1"
if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "History slug must use lowercase kebab-case: $slug" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
month_dir="${repo_root}/docs/histories/$(date +%Y-%m)"
timestamp="$(date +%Y%m%d-%H%M)"
target="${month_dir}/${timestamp}-${slug}.md"

if [[ -e "$target" ]]; then
  echo "History already exists: $target" >&2
  exit 1
fi

mkdir -p "$month_dir"
cp "${repo_root}/docs/histories/template.md" "$target"
echo "$target"
