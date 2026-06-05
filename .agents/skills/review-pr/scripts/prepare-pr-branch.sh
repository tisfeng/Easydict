#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh <pr-ref>

Accepted PR references:
  https://github.com/<base-owner>/<base-repo>/pull/<number>
  <base-owner>/<base-repo>#<number>
  <number>
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

same_github_repo_url() {
  local actual_url=$1
  local owner=$2
  local repo=$3

  case "$actual_url" in
    "https://github.com/${owner}/${repo}.git" | \
    "https://github.com/${owner}/${repo}" | \
    "git@github.com:${owner}/${repo}.git" | \
    "ssh://git@github.com/${owner}/${repo}.git")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

command -v gh >/dev/null 2>&1 || fail "GitHub CLI 'gh' is required."
command -v git >/dev/null 2>&1 || fail "Git is required."

pr_ref=$1
view_ref=$pr_ref
repo_args=()

if [[ $pr_ref =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)(/.*)?$ ]]; then
  view_ref=${BASH_REMATCH[3]}
  repo_args=(--repo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}")
elif [[ $pr_ref =~ ^([^/[:space:]]+)/([^/#[:space:]]+)#([0-9]+)$ ]]; then
  view_ref=${BASH_REMATCH[3]}
  repo_args=(--repo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}")
elif [[ $pr_ref =~ ^[0-9]+$ ]]; then
  view_ref=$pr_ref
else
  fail "Unsupported PR reference: ${pr_ref}"
fi

metadata=$(
  gh pr view "$view_ref" "${repo_args[@]}" \
    --json headRefName,headRepository,headRepositoryOwner,number,url \
    --jq '[.headRepositoryOwner.login, .headRepository.name, .headRefName, (.number | tostring), .url] | @tsv'
)

IFS=$'\t' read -r head_owner head_repo head_branch pr_number pr_url <<< "$metadata"

[[ -n ${head_owner:-} ]] || fail "PR head owner is empty. The fork may be unavailable."
[[ -n ${head_repo:-} ]] || fail "PR head repository is empty. The fork may be unavailable."
[[ -n ${head_branch:-} ]] || fail "PR head branch is empty."

current_branch=$(git branch --show-current || true)

if [[ -n $(git status --porcelain=v1) ]]; then
  if [[ $current_branch == "$head_branch" ]]; then
    fail "Worktree has uncommitted changes on PR branch '${head_branch}'. Clean it before preparing or reviewing the PR."
  fi

  fail "Worktree has uncommitted changes on branch '${current_branch:-detached HEAD}'. Commit, stash, or clean them before switching to PR branch '${head_branch}'."
fi

remote_name=$head_owner
remote_url="https://github.com/${head_owner}/${head_repo}.git"
remote_ref="refs/remotes/${remote_name}/${head_branch}"
upstream_ref="${remote_name}/${head_branch}"

if existing_url=$(git remote get-url "$remote_name" 2>/dev/null); then
  if ! same_github_repo_url "$existing_url" "$head_owner" "$head_repo"; then
    fail "Remote '${remote_name}' points to '${existing_url}', not '${remote_url}'."
  fi
  printf 'Remote exists: %s -> %s\n' "$remote_name" "$existing_url"
else
  git remote add "$remote_name" "$remote_url"
  printf 'Remote added: %s -> %s\n' "$remote_name" "$remote_url"
fi

git fetch "$remote_name" "+refs/heads/${head_branch}:${remote_ref}"

if git show-ref --verify --quiet "refs/heads/${head_branch}"; then
  git branch --set-upstream-to="$upstream_ref" "$head_branch"
  if [[ $current_branch == "$head_branch" ]]; then
    printf 'Already on branch: %s\n' "$head_branch"
  else
    git switch "$head_branch"
  fi
  git merge --ff-only "$upstream_ref"
else
  git switch --create "$head_branch" --track "$upstream_ref"
fi

printf '\nPrepared PR #%s: %s\n' "$pr_number" "$pr_url"
printf 'Remote: %s (%s)\n' "$remote_name" "$remote_url"
printf 'Branch: %s\n' "$head_branch"
printf 'Upstream: %s\n' "$upstream_ref"
