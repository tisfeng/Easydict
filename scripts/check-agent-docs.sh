#!/usr/bin/env bash

# Validate agent documentation routes, public-doc paths, and plan/history
# directories without requiring an Xcode build or network access.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

required_files=(
  "AGENTS.md"
  ".claude/CLAUDE.md"
  "docs/agents/README.md"
  "docs/agents/repository-guide.md"
  "docs/agents/build-and-test.md"
  "docs/agents/code-quality.md"
  "docs/agents/swift-xcode.md"
  "docs/agents/localization.md"
  "docs/agents/testing.md"
  "docs/agents/skills.md"
  "docs/architecture/README.md"
  "docs/architecture/overview.md"
  "docs/user-docs/README.md"
  "docs/exec-plans/README.md"
  "docs/exec-plans/active/swift-migration.md"
  "docs/exec-plans/templates/execution-plan.md"
  "docs/histories/README.md"
  "docs/histories/template.md"
  "scripts/new-exec-plan.sh"
  "scripts/new-history.sh"
)

required_dirs=(
  "docs/user-docs/en"
  "docs/user-docs/zh"
  "docs/exec-plans/active"
  "docs/exec-plans/completed"
  "docs/histories"
)

for path in "${required_files[@]}"; do
  if [[ ! -e "${repo_root}/${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    failed=1
  fi
done

for path in "${required_dirs[@]}"; do
  if [[ ! -d "${repo_root}/${path}" ]]; then
    echo "Missing required directory: ${path}" >&2
    failed=1
  fi
done

if [[ "$(readlink "${repo_root}/.claude/CLAUDE.md")" != "../AGENTS.md" ]]; then
  echo ".claude/CLAUDE.md must remain a symlink to ../AGENTS.md" >&2
  failed=1
fi

if rg -n --hidden \
  "fireworks-tech-graph-quality-rules|(^|/)docs/(en|zh)/|docs/How-to-translate-Easydict|README_EN\.md" \
  "${repo_root}/AGENTS.md" "${repo_root}/README.md" \
  "${repo_root}/README_ZH.md" "${repo_root}/docs" \
  --glob '!docs/user-docs/**' >/dev/null; then
  echo "Found stale documentation route" >&2
  failed=1
fi

if rg -n --hidden "(^|/)docs/(en|zh)/|docs/How-to-translate-Easydict|README_EN\.md" \
  "${repo_root}/README.md" "${repo_root}/README_ZH.md" \
  "${repo_root}/docs/user-docs" >/dev/null; then
  echo "Found stale public-document link" >&2
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Agent documentation structure is valid"
