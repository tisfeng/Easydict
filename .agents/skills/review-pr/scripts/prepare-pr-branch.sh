#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh [--rebase-latest] <pr-ref>

Accepted PR references:
  https://github.com/<base-owner>/<base-repo>/pull/<number>
  <base-owner>/<base-repo>#<number>
  <number>

Options:
  --rebase-latest
      Create review/pr-<number>-<head-sha> from the PR head and rebase it onto
      the latest base branch. The branch is local-only and is never pushed.
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

parse_pr_ref() {
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
}

read_pr_metadata() {
  metadata=$(
    gh pr view "$view_ref" "${repo_args[@]}" \
      --json baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,number,url \
      --jq '[.headRepositoryOwner.login, .headRepository.name, .headRefName, .headRefOid, .baseRefName, (.number | tostring), .url] | @tsv'
  )

  IFS=$'\t' read -r head_owner head_repo head_branch head_oid base_branch pr_number pr_url <<< "$metadata"

  [[ -n ${head_owner:-} ]] || fail "PR head owner is empty. The fork may be unavailable."
  [[ -n ${head_repo:-} ]] || fail "PR head repository is empty. The fork may be unavailable."
  [[ -n ${head_branch:-} ]] || fail "PR head branch is empty."
  [[ -n ${head_oid:-} ]] || fail "PR head SHA is empty."
  [[ -n ${base_branch:-} ]] || fail "PR base branch is empty."

  if [[ $pr_url =~ ^https://github\.com/([^/]+)/([^/]+)/pull/[0-9]+(/.*)?$ ]]; then
    base_owner=${BASH_REMATCH[1]}
    base_repo=${BASH_REMATCH[2]}
  else
    fail "Could not parse base repository from PR URL: ${pr_url}"
  fi
}

ensure_remote() {
  local remote_name=$1
  local owner=$2
  local repo=$3
  local remote_url="https://github.com/${owner}/${repo}.git"
  local existing_url

  if existing_url=$(git remote get-url "$remote_name" 2>/dev/null); then
    if ! same_github_repo_url "$existing_url" "$owner" "$repo"; then
      fail "Remote '${remote_name}' points to '${existing_url}', not '${remote_url}'."
    fi
    printf 'Remote exists: %s -> %s\n' "$remote_name" "$existing_url"
  else
    git remote add "$remote_name" "$remote_url"
    printf 'Remote added: %s -> %s\n' "$remote_name" "$remote_url"
  fi
}

find_matching_remote() {
  local owner=$1
  local repo=$2
  local preferred=$3
  local remote
  local url

  if [[ -n $preferred ]] && url=$(git remote get-url "$preferred" 2>/dev/null); then
    if same_github_repo_url "$url" "$owner" "$repo"; then
      printf '%s\n' "$preferred"
      return 0
    fi
  fi

  while IFS= read -r remote; do
    url=$(git remote get-url "$remote" 2>/dev/null || true)
    if same_github_repo_url "$url" "$owner" "$repo"; then
      printf '%s\n' "$remote"
      return 0
    fi
  done < <(git remote)

  return 1
}

require_clean_worktree() {
  local action=$1
  local current_branch

  current_branch=$(git branch --show-current || true)
  if [[ -n $(git status --porcelain=v1) ]]; then
    fail "Worktree has uncommitted changes on branch '${current_branch:-detached HEAD}'. Clean it before ${action}."
  fi
}

prepare_pr_branch() {
  local current_branch
  local remote_name=$head_owner
  local remote_ref="refs/remotes/${remote_name}/${head_branch}"
  local upstream_ref="${remote_name}/${head_branch}"

  current_branch=$(git branch --show-current || true)

  if [[ -n $(git status --porcelain=v1) ]]; then
    if [[ $current_branch == "$head_branch" ]]; then
      fail "Worktree has uncommitted changes on PR branch '${head_branch}'. Clean it before preparing or reviewing the PR."
    fi

    fail "Worktree has uncommitted changes on branch '${current_branch:-detached HEAD}'. Commit, stash, or clean them before switching to PR branch '${head_branch}'."
  fi

  ensure_remote "$remote_name" "$head_owner" "$head_repo"
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
  printf 'Remote: %s (%s)\n' "$remote_name" "https://github.com/${head_owner}/${head_repo}.git"
  printf 'Branch: %s\n' "$head_branch"
  printf 'Upstream: %s\n' "$upstream_ref"
}

prepare_rebased_review_branch() {
  local head_remote=$head_owner
  local head_remote_ref="refs/remotes/${head_remote}/${head_branch}"
  local base_remote
  local base_remote_ref
  local base_upstream
  local review_branch
  local head_short=${head_oid:0:10}

  require_clean_worktree "preparing a rebased review branch"

  ensure_remote "$head_remote" "$head_owner" "$head_repo"

  if base_remote=$(find_matching_remote "$base_owner" "$base_repo" "origin"); then
    printf 'Base remote exists: %s -> %s\n' "$base_remote" "$(git remote get-url "$base_remote")"
  else
    base_remote=$base_owner
    ensure_remote "$base_remote" "$base_owner" "$base_repo"
  fi

  base_remote_ref="refs/remotes/${base_remote}/${base_branch}"
  base_upstream="${base_remote}/${base_branch}"
  review_branch="review/pr-${pr_number}-${head_short}"

  if git show-ref --verify --quiet "refs/heads/${review_branch}"; then
    fail "Local review branch '${review_branch}' already exists. Inspect or remove it before preparing this PR again."
  fi

  git fetch "$head_remote" "+refs/heads/${head_branch}:${head_remote_ref}"
  git fetch "$base_remote" "+refs/heads/${base_branch}:${base_remote_ref}"
  git switch --create "$review_branch" "$head_remote_ref"

  if git rebase "$base_upstream"; then
    printf '\nPrepared rebased PR #%s: %s\n' "$pr_number" "$pr_url"
    printf 'Review branch: %s\n' "$review_branch"
    printf 'Base: %s/%s (%s)\n' "$base_remote" "$base_branch" "https://github.com/${base_owner}/${base_repo}.git"
    printf 'Head: %s/%s (%s)\n' "$head_remote" "$head_branch" "https://github.com/${head_owner}/${head_repo}.git"
    printf 'Head SHA: %s\n' "$head_oid"
    printf 'Push: not performed\n'
  else
    printf '\nRebase stopped with conflicts for PR #%s: %s\n' "$pr_number" "$pr_url" >&2
    printf 'Review branch: %s\n' "$review_branch" >&2
    printf 'Base: %s\n' "$base_upstream" >&2
    printf '\nInspect conflicts:\n' >&2
    printf '  git status --short\n' >&2
    printf '  git diff --name-only --diff-filter=U\n' >&2
    printf '  git diff --cc\n' >&2
    printf '\nAfter semantic conflict resolution:\n' >&2
    printf '  git add <resolved-files>\n' >&2
    printf '  git rebase --continue\n' >&2
    exit 2
  fi
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

mode=prepare
if [[ ${1:-} == "--rebase-latest" ]]; then
  mode=rebase
  shift
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

command -v gh >/dev/null 2>&1 || fail "GitHub CLI 'gh' is required."
command -v git >/dev/null 2>&1 || fail "Git is required."

parse_pr_ref "$1"
read_pr_metadata

if [[ $mode == "rebase" ]]; then
  prepare_rebased_review_branch
else
  prepare_pr_branch
fi
