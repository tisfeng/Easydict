#!/usr/bin/env bash
# Prepare a pull request in the current checkout or an isolated Git worktree.
# The helper may add remotes and fetch refs, but never pushes or removes state.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh [--worktree] [--merge-latest] <pr-ref>

Accepted PR references:
  https://github.com/<base-owner>/<base-repo>/pull/<number>
  <base-owner>/<base-repo>#<number>
  <number>
Options:
  --worktree
      Create an isolated worktree and SHA-specific review branch. The current
      checkout may be dirty and remains unchanged. The worktree is retained.
  --merge-latest
      In local mode, prepare the PR head branch (or its collision fallback)
      and merge the latest base branch into that selected branch. With
      --worktree, use the isolated review/pr-<number>-merge-<head-sha> branch
      instead. Use only after the user explicitly asks for latest-base
      integration or conflict resolution. Never push the result.
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

same_github_repo_url() {
  local actual_url=$1 owner=$2 repo=$3

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
  local remote_name=$1 owner=$2 repo=$3
  local remote_url="https://github.com/${owner}/${repo}.git"
  local existing_url

  if existing_url=$(git config --get "remote.${remote_name}.url" 2>/dev/null); then
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
  local owner=$1 repo=$2 preferred=$3
  local remote url

  if [[ -n $preferred ]] && url=$(git config --get "remote.${preferred}.url" 2>/dev/null); then
    if same_github_repo_url "$url" "$owner" "$repo"; then
      printf '%s\n' "$preferred"
      return 0
    fi
  fi

  while IFS= read -r remote; do
    url=$(git config --get "remote.${remote}.url" 2>/dev/null || true)
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

branch_checked_out_elsewhere() {
  local branch=$1
  local current_branch

  current_branch=$(git branch --show-current || true)
  [[ $current_branch != "$branch" ]] || return 1
  [[ -n $(find_branch_worktree "$branch" || true) ]]
}

# Return a non-empty collision reason when the PR head branch cannot be
# prepared under its exact local name, or nothing when the exact-name path is
# safe. Reads only local refs, not network state.
unsafe_branch_reason() {
  local branch=$1
  local expected_upstream=$2
  local base=$3
  local actual_upstream

  if [[ $branch == "$base" ]]; then
    printf "PR head branch '%s' matches the base branch '%s'" "$branch" "$base"
    return 0
  fi

  case "$branch" in
    dev | main | master | develop | trunk)
      printf "PR head branch '%s' is a protected local branch name" "$branch"
      return 0
      ;;
  esac

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    if branch_checked_out_elsewhere "$branch"; then
      printf "local branch '%s' is checked out in another worktree" "$branch"
      return 0
    fi

    actual_upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/${branch}")
    if [[ $actual_upstream != "$expected_upstream" ]]; then
      [[ -n $actual_upstream ]] || actual_upstream="no upstream"
      printf "local branch '%s' has upstream '%s', not '%s'" \
        "$branch" "$actual_upstream" "$expected_upstream"
      return 0
    fi
  fi

  return 1
}

# Create or reuse the collision-fallback review branch
# review/pr-<number>-<head-short-sha> tracking the contributor remote branch.
prepare_collision_review_branch() {
  local reason=$1
  local head_short=${head_oid:0:10}
  local actual_head actual_upstream
  review_branch="review/pr-${pr_number}-${head_short}"

  if git show-ref --verify --quiet "refs/heads/${review_branch}"; then
    actual_head=$(git rev-parse "refs/heads/${review_branch}")
    actual_upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/${review_branch}")
    if [[ $actual_head != "$head_oid" || $actual_upstream != "$upstream_ref" ]]; then
      fail \
        "Review branch '${review_branch}' already exists with HEAD '${actual_head}'" \
        "or upstream '${actual_upstream:-none}', not PR head '${head_oid}'" \
        "tracking '${upstream_ref}'. Inspect or remove it before preparing this PR again."
    fi
    printf 'Reusing review branch: %s\n' "$review_branch"
    if [[ $(git branch --show-current) != "$review_branch" ]]; then
      git switch "$review_branch"
    fi
  else
    git switch --create "$review_branch" --track "$upstream_ref"
  fi

  printf 'Branch collision: %s. Falling back to a review branch.\n' "$reason"
}

require_expected_upstream() {
  local branch=$1
  local expected_upstream=$2
  local actual_upstream

  actual_upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/${branch}")
  if [[ $actual_upstream != "$expected_upstream" ]]; then
    [[ -n $actual_upstream ]] || actual_upstream="no upstream"
    fail \
      "Local branch '${branch}' has upstream '${actual_upstream}'," \
      "not '${expected_upstream}'." \
      "Ask whether to use an isolated worktree or another checkout." \
      "Use --merge-latest only for an explicitly requested latest-base review."
  fi
}

# Capture the caller checkout so worktree mode can prove it stayed untouched.
capture_source_checkout() {
  source_branch=$(git branch --show-current || true)
  source_head=$(git rev-parse HEAD)
  source_status=$(git status --porcelain=v1)
}

# Fail if worktree preparation changed the checkout that invoked the helper.
verify_source_checkout() {
  local actual_branch actual_head actual_status
  actual_branch=$(git branch --show-current || true)
  actual_head=$(git rev-parse HEAD)
  actual_status=$(git status --porcelain=v1)

  [[ $actual_branch == "$source_branch" ]] || \
    fail "Source checkout branch changed during worktree preparation."
  [[ $actual_head == "$source_head" ]] || \
    fail "Source checkout HEAD changed during worktree preparation."
  [[ $actual_status == "$source_status" ]] || \
    fail "Source checkout files changed during worktree preparation."
}

# Resolve one stable review location from the repository's common Git dir.
resolve_worktree_target() {
  local common_dir main_worktree parent_dir repo_name suffix
  local head_short=${head_oid:0:10}
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
  [[ $common_dir == */.git ]] || \
    fail "Could not derive the main worktree from Git common dir '${common_dir}'."

  main_worktree=${common_dir%/.git}
  parent_dir=$(dirname "$main_worktree")
  repo_name=$(basename "$main_worktree")

  if [[ $mode == "merge" ]]; then
    suffix="pr-${pr_number}-merge-${head_short}"
    review_branch="review/pr-${pr_number}-merge-${head_short}"
  else
    suffix="pr-${pr_number}-${head_short}"
    review_branch="review/pr-${pr_number}-${head_short}"
  fi

  review_root="${parent_dir}/.review-pr-worktrees/${repo_name}"
  worktree_path="${review_root}/${suffix}"
}

# Find the registered worktree that currently owns a local branch.
find_branch_worktree() {
  local branch=$1
  local branch_ref="refs/heads/${branch}"
  local current_path="" line
  while IFS= read -r line; do
    case "$line" in
      "worktree "*)
        current_path=${line#worktree }
        ;;
      "branch ${branch_ref}")
        printf '%s\n' "$current_path"
        return 0
        ;;
    esac
  done < <(git worktree list --porcelain)

  return 1
}

# Reuse only an exact, clean worktree snapshot; never repair or overwrite it.
reuse_existing_worktree() {
  local existing_path actual_head actual_upstream parents
  local first_parent second_parent extra_parent
  if ! git show-ref --verify --quiet "refs/heads/${review_branch}"; then
    [[ ! -e $worktree_path ]] || \
      fail "Worktree path '${worktree_path}' already exists without the expected branch."
    return 1
  fi

  existing_path=$(find_branch_worktree "$review_branch" || true)
  [[ -n $existing_path ]] || \
    fail "Review branch '${review_branch}' exists outside a registered worktree."
  [[ $existing_path == "$worktree_path" ]] || \
    fail "Review branch '${review_branch}' is checked out at '${existing_path}', not '${worktree_path}'."
  [[ -d $existing_path ]] || \
    fail "Registered review worktree '${existing_path}' is unavailable."
  [[ -z $(git -C "$existing_path" status --porcelain=v1) ]] || \
    fail "Review worktree '${existing_path}' has uncommitted changes."

  actual_head=$(git -C "$existing_path" rev-parse HEAD)
  if [[ $mode == "prepare" ]]; then
    require_expected_upstream "$review_branch" "$upstream_ref"
    [[ $actual_head == "$head_oid" ]] || \
      fail "Review worktree '${existing_path}' no longer matches head '${head_oid}'."
  else
    actual_upstream=$(git for-each-ref --format='%(upstream:short)' \
      "refs/heads/${review_branch}")
    [[ -z $actual_upstream ]] || \
      fail "Merged review branch '${review_branch}' must remain local-only."
  fi
  if [[ $mode == "merge" && $actual_head == "$head_oid" ]]; then
    git merge-base --is-ancestor "$base_oid" "$actual_head" || \
      fail "Review worktree '${existing_path}' does not contain base '${base_oid}'."
  elif [[ $mode == "merge" && $actual_head == "$base_oid" ]]; then
    git merge-base --is-ancestor "$head_oid" "$actual_head" || \
      fail "Review worktree '${existing_path}' does not contain head '${head_oid}'."
  elif [[ $mode == "merge" ]]; then
    parents=$(git -C "$existing_path" show -s --format=%P HEAD)
    read -r first_parent second_parent extra_parent <<< "$parents"
    [[ $first_parent == "$head_oid" && $second_parent == "$base_oid" && -z ${extra_parent:-} ]] || \
      fail "Review worktree '${existing_path}' is not the expected head/base merge."
  fi

  printf 'Reusing review worktree: %s\n' "$existing_path"
  return 0
}

print_source_checkout() {
  printf 'Source checkout: %s (%s)\n' \
    "${source_branch:-detached HEAD}" "unchanged"
}

prepare_pr_branch() {
  local current_branch branch_exists=false fetched_head local_head
  local ahead_count behind_count actual_head collision_reason
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

  collision_reason=$(unsafe_branch_reason "$head_branch" "$upstream_ref" "$base_branch" || true)

  ensure_remote "$remote_name" "$head_owner" "$head_repo"
  git fetch "$remote_name" "+refs/heads/${head_branch}:${remote_ref}"
  fetched_head=$(git rev-parse "$remote_ref")
  [[ $fetched_head == "$head_oid" ]] || \
    fail "PR head moved from '${head_oid}' to '${fetched_head}'. Rerun preparation."

  if [[ -z $collision_reason ]] && git show-ref --verify --quiet "refs/heads/${head_branch}"; then
    branch_exists=true
    local_head=$(git rev-parse "refs/heads/${head_branch}")
    if [[ $local_head != "$head_oid" ]] && \
      ! git merge-base --is-ancestor "$local_head" "$remote_ref"; then
      read -r ahead_count behind_count < <(
        git rev-list --left-right --count \
          "refs/heads/${head_branch}...${remote_ref}"
      )
      collision_reason="local branch '${head_branch}' does not safely fast-forward to PR head '${head_oid}' (ahead ${ahead_count}, behind ${behind_count})"
    fi
  fi

  if [[ -n $collision_reason ]]; then
    prepare_collision_review_branch "$collision_reason"

    current_branch=$(git branch --show-current || true)
    [[ $current_branch == "$review_branch" ]] || \
      fail "Prepared checkout is not on review branch '${review_branch}'."
    require_expected_upstream "$review_branch" "$upstream_ref"
    actual_head=$(git rev-parse HEAD)
    [[ $actual_head == "$head_oid" ]] || \
      fail "Prepared review branch '${review_branch}' is at '${actual_head}', not PR head '${head_oid}'."

    if [[ $mode == "merge" ]]; then
      merge_latest_base_into_current_branch "$current_branch" "$upstream_ref"
      return 0
    fi

    printf '\nPrepared PR #%s: %s\n' "$pr_number" "$pr_url"
    printf 'Remote: %s (%s)\n' "$remote_name" "https://github.com/${head_owner}/${head_repo}.git"
    printf 'Review branch: %s (collision fallback)\n' "$review_branch"
    printf 'Upstream: %s\n' "$upstream_ref"
    printf 'Head SHA: %s\n' "$head_oid"
    return 0
  fi

  if [[ $branch_exists == true ]]; then
    if [[ $current_branch == "$head_branch" ]]; then
      printf 'Already on branch: %s\n' "$head_branch"
    else
      git switch "$head_branch"
    fi
    git merge --ff-only "$upstream_ref"
  else
    git switch --create "$head_branch" --track "$upstream_ref"
  fi

  current_branch=$(git branch --show-current || true)
  [[ $current_branch == "$head_branch" ]] || \
    fail "Prepared checkout is not on PR branch '${head_branch}'."
  require_expected_upstream "$head_branch" "$upstream_ref"
  actual_head=$(git rev-parse HEAD)
  [[ $actual_head == "$head_oid" ]] || \
    fail "Prepared branch '${head_branch}' is at '${actual_head}', not PR head '${head_oid}'."

  if [[ $mode == "merge" ]]; then
    merge_latest_base_into_current_branch "$current_branch" "$upstream_ref"
    return 0
  fi

  printf '\nPrepared PR #%s: %s\n' "$pr_number" "$pr_url"
  printf 'Remote: %s (%s)\n' "$remote_name" "https://github.com/${head_owner}/${head_repo}.git"
  printf 'Branch: %s\n' "$head_branch"
  printf 'Upstream: %s\n' "$upstream_ref"
  printf 'Head SHA: %s\n' "$head_oid"
}

merge_latest_base_into_current_branch() {
  local selected_branch=$1
  local expected_upstream=$2
  local current_head parents first_parent second_parent extra_parent

  require_expected_upstream "$selected_branch" "$expected_upstream"
  current_head=$(git rev-parse HEAD)
  [[ $current_head == "$head_oid" ]] || \
    fail "Selected branch '${selected_branch}' is at '${current_head}', not PR head '${head_oid}' before latest-base merge."

  prepare_merge_refs

  if git merge --no-edit "$base_upstream"; then
    current_head=$(git rev-parse HEAD)
    git merge-base --is-ancestor "$head_oid" "$current_head" || \
      fail "Merged branch '${selected_branch}' no longer contains PR head '${head_oid}'."
    git merge-base --is-ancestor "$base_oid" "$current_head" || \
      fail "Merged branch '${selected_branch}' does not contain base '${base_oid}'."

    if [[ $current_head != "$head_oid" && $current_head != "$base_oid" ]]; then
      parents=$(git show -s --format=%P HEAD)
      read -r first_parent second_parent extra_parent <<< "$parents"
      [[ $first_parent == "$head_oid" && $second_parent == "$base_oid" && -z ${extra_parent:-} ]] || \
        fail "Latest-base merge on '${selected_branch}' is not the expected head/base merge."
    fi

    printf '\nPrepared merged PR #%s: %s\n' "$pr_number" "$pr_url"
    printf 'Review branch: %s\n' "$selected_branch"
    printf 'Upstream: %s\n' "$expected_upstream"
    printf 'Base: %s/%s (%s)\n' "$base_remote" "$base_branch" \
      "https://github.com/${base_owner}/${base_repo}.git"
    printf 'Head: %s/%s (%s)\n' "$head_remote" "$head_branch" \
      "https://github.com/${head_owner}/${head_repo}.git"
    printf 'Head SHA: %s\n' "$head_oid"
    printf 'Push: not performed\n'
  else
    printf '\nMerge stopped with conflicts for PR #%s: %s\n' "$pr_number" "$pr_url" >&2
    printf 'Review branch: %s\n' "$selected_branch" >&2
    printf 'Base: %s\n' "$base_upstream" >&2
    printf '\nInspect conflicts:\n' >&2
    printf '  git status --short\n' >&2
    printf '  git diff --name-only --diff-filter=U\n' >&2
    printf '  git diff --cc\n' >&2
    printf '\nAfter semantic conflict resolution:\n' >&2
    printf '  git add <resolved-files>\n' >&2
    printf '  git commit --no-edit\n' >&2
    printf '\nIf conflicts cannot be resolved safely:\n' >&2
    printf '  git merge --abort\n' >&2
    exit 2
  fi
}

# Fetch the exact PR head and latest base refs used by merged review modes.
prepare_merge_refs() {
  local fetched_head
  head_remote=$head_owner
  head_remote_ref="refs/remotes/${head_remote}/${head_branch}"
  ensure_remote "$head_remote" "$head_owner" "$head_repo"

  if base_remote=$(find_matching_remote "$base_owner" "$base_repo" "origin"); then
    printf 'Base remote exists: %s -> %s\n' "$base_remote" \
      "$(git config --get "remote.${base_remote}.url")"
  else
    base_remote=$base_owner
    ensure_remote "$base_remote" "$base_owner" "$base_repo"
  fi

  base_remote_ref="refs/remotes/${base_remote}/${base_branch}"
  base_upstream="${base_remote}/${base_branch}"

  git fetch "$head_remote" "+refs/heads/${head_branch}:${head_remote_ref}"
  git fetch "$base_remote" "+refs/heads/${base_branch}:${base_remote_ref}"
  fetched_head=$(git rev-parse "$head_remote_ref")
  [[ $fetched_head == "$head_oid" ]] || \
    fail "PR head moved from '${head_oid}' to '${fetched_head}'. Rerun preparation."
  base_oid=$(git rev-parse "$base_remote_ref")
}

print_worktree_summary() {
  printf '\nPrepared PR #%s in worktree: %s\n' "$pr_number" "$pr_url"
  printf 'Worktree: %s\n' "$worktree_path"
  printf 'Review branch: %s\n' "$review_branch"
  if [[ $mode == "prepare" ]]; then
    printf 'Upstream: %s\n' "$upstream_ref"
  else
    printf 'Base: %s/%s (%s)\n' "$base_remote" "$base_branch" \
      "https://github.com/${base_owner}/${base_repo}.git"
    printf 'Head: %s/%s (%s)\n' "$head_remote" "$head_branch" \
      "https://github.com/${head_owner}/${head_repo}.git"
  fi
  printf 'Head SHA: %s\n' "$head_oid"
  print_source_checkout
  printf 'Push: not performed\n'
}

# Create or safely reuse the explicit isolated worktree review mode.
prepare_review_worktree() {
  local fetched_head

  capture_source_checkout
  resolve_worktree_target
  if [[ $mode == "prepare" ]]; then
    head_remote=$head_owner
    head_remote_ref="refs/remotes/${head_remote}/${head_branch}"
    upstream_ref="${head_remote}/${head_branch}"
    ensure_remote "$head_remote" "$head_owner" "$head_repo"
    git fetch "$head_remote" "+refs/heads/${head_branch}:${head_remote_ref}"
    fetched_head=$(git rev-parse "$head_remote_ref")
    [[ $fetched_head == "$head_oid" ]] || \
      fail "PR head moved from '${head_oid}' to '${fetched_head}'. Rerun preparation."
  else
    prepare_merge_refs
  fi

  if reuse_existing_worktree; then
    verify_source_checkout
    print_worktree_summary
    return 0
  fi

  mkdir -p "$review_root"
  if [[ $mode == "prepare" ]]; then
    git worktree add --track -b "$review_branch" "$worktree_path" \
      "$upstream_ref"
  else
    git worktree add --no-track -b "$review_branch" "$worktree_path" \
      "$head_remote_ref"
    if ! git -C "$worktree_path" merge --no-edit "$base_upstream"; then
      verify_source_checkout
      printf '\nMerge stopped with conflicts for PR #%s: %s\n' \
        "$pr_number" "$pr_url" >&2
      printf 'Worktree: %s\nReview branch: %s\nBase: %s\n' \
        "$worktree_path" "$review_branch" "$base_upstream" >&2
      printf '\nInspect conflicts:\n' >&2
      printf '  git -C %q status --short\n' "$worktree_path" >&2
      printf '  git -C %q diff --name-only --diff-filter=U\n' \
        "$worktree_path" >&2
      printf '  git -C %q diff --cc\n' "$worktree_path" >&2
      printf '\nAfter semantic conflict resolution:\n' >&2
      printf '  git -C %q add <resolved-files>\n' "$worktree_path" >&2
      printf '  git -C %q commit --no-edit\n' "$worktree_path" >&2
      printf '\nIf conflicts cannot be resolved safely:\n' >&2
      printf '  git -C %q merge --abort\n' "$worktree_path" >&2
      exit 2
    fi
  fi

  verify_source_checkout
  print_worktree_summary
}

mode=prepare
checkout_mode=local
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --worktree)
      checkout_mode=worktree
      ;;
    --merge-latest)
      mode=merge
      ;;
    --rebase-latest)
      fail "--rebase-latest is no longer supported. Use --merge-latest for remote collaboration PRs."
      ;;
    --*)
      fail "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
  shift
done

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

command -v gh >/dev/null 2>&1 || fail "GitHub CLI 'gh' is required."
command -v git >/dev/null 2>&1 || fail "Git is required."

parse_pr_ref "$1"
read_pr_metadata

if [[ $checkout_mode == "worktree" ]]; then
  prepare_review_worktree
else
  prepare_pr_branch
fi
