#!/usr/bin/env bash

# Reconciles origin/dev and origin/main in an isolated release worktree, then
# updates both branches and the release tag through atomic remote pushes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

remote_dev_ref() {
    printf 'refs/remotes/%s/%s' "$RELEASE_REMOTE" "$RELEASE_DEV_BRANCH"
}

remote_main_ref() {
    printf 'refs/remotes/%s/%s' "$RELEASE_REMOTE" "$RELEASE_MAIN_BRANCH"
}

fetch_release_refs() {
    release_log "fetching $RELEASE_REMOTE/$RELEASE_DEV_BRANCH and"
    release_log "$RELEASE_REMOTE/$RELEASE_MAIN_BRANCH"
    git -C "$RELEASE_SOURCE_ROOT" fetch --prune "$RELEASE_REMOTE" \
        "+refs/heads/$RELEASE_DEV_BRANCH:$(remote_dev_ref)" \
        "+refs/heads/$RELEASE_MAIN_BRANCH:$(remote_main_ref)" \
        --tags

    git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
        "$(remote_dev_ref)" \
        || release_fail "remote dev branch was not fetched"
    git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
        "$(remote_main_ref)" \
        || release_fail "remote main branch was not fetched"
}

worktree_is_registered() {
    git -C "$RELEASE_SOURCE_ROOT" worktree list --porcelain \
        | awk -v expected="$RELEASE_WORKTREE" '
            $1 == "worktree" && $2 == expected { found = 1 }
            END { exit(found ? 0 : 1) }
        '
}

report_branch_commits() {
    release_log "commits found only on main:"
    git -C "$RELEASE_SOURCE_ROOT" log --oneline --no-decorate \
        "$(remote_dev_ref)..$(remote_main_ref)" \
        || true
    release_log "commits found only on dev:"
    git -C "$RELEASE_SOURCE_ROOT" log --oneline --no-decorate \
        "$(remote_main_ref)..$(remote_dev_ref)" \
        || true
}

verify_remote_ancestry() {
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$(remote_dev_ref)" HEAD \
        || release_fail "release branch no longer contains current remote dev"
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$(remote_main_ref)" HEAD \
        || release_fail "release branch no longer contains current remote main"
}

# Builds a clean union of remote dev and main without changing the caller.
prepare_worktree() {
    local created_worktree=0

    ensure_release_layout
    fetch_release_refs
    report_branch_commits

    if worktree_is_registered; then
        require_release_worktree
        release_log "reusing release worktree: $RELEASE_WORKTREE"
    else
        [[ ! -e "$RELEASE_WORKTREE" ]] \
            || release_fail "unregistered path blocks release worktree: $RELEASE_WORKTREE"

        if git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
            "refs/heads/$RELEASE_BRANCH"; then
            git -C "$RELEASE_SOURCE_ROOT" worktree add \
                "$RELEASE_WORKTREE" "$RELEASE_BRANCH"
        else
            git -C "$RELEASE_SOURCE_ROOT" worktree add \
                -b "$RELEASE_BRANCH" \
                "$RELEASE_WORKTREE" \
                "$(remote_dev_ref)"
            created_worktree=1
        fi
    fi

    if ((created_worktree == 1)); then
        release_log "merging remote main into the dev-based release branch"
        git -C "$RELEASE_WORKTREE" merge --no-edit "$(remote_main_ref)"
    else
        [[ -z "$(git -C "$RELEASE_WORKTREE" status --porcelain)" ]] \
            || release_fail "existing release worktree has pending changes; use asc resume"
    fi

    verify_remote_ancestry
    release_log "release worktree contains both remote branch histories"
}

ensure_tag() {
    local current_head tag_commit

    current_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    if git -C "$RELEASE_WORKTREE" show-ref --verify --quiet \
        "refs/tags/$RELEASE_VERSION"; then
        tag_commit="$(git -C "$RELEASE_WORKTREE" rev-list -n 1 \
            "$RELEASE_VERSION")"
        [[ "$tag_commit" == "$current_head" ]] \
            || release_fail "tag $RELEASE_VERSION points to another commit"
    else
        git -C "$RELEASE_WORKTREE" tag -a "$RELEASE_VERSION" \
            -m "Easydict $RELEASE_VERSION"
    fi
}

# Tags the version commit and moves both branches in one remote transaction.
push_version_refs() {
    require_release_worktree
    load_release_metadata
    fetch_release_refs
    verify_remote_ancestry

    [[ "$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)" \
        == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "release HEAD differs from the saved version commit"

    ensure_tag
    release_log "atomically updating dev, main, and $RELEASE_VERSION"
    git -C "$RELEASE_WORKTREE" push --atomic "$RELEASE_REMOTE" \
        "HEAD:refs/heads/$RELEASE_DEV_BRANCH" \
        "HEAD:refs/heads/$RELEASE_MAIN_BRANCH" \
        "refs/tags/$RELEASE_VERSION"
    fetch_release_refs
}

# Advances dev and main together so the public feed is never branch-specific.
push_appcast_refs() {
    require_release_worktree
    load_release_metadata
    fetch_release_refs
    verify_remote_ancestry

    [[ "$(git -C "$RELEASE_WORKTREE" log -1 --format=%s)" \
        == "build(release): add $RELEASE_VERSION appcast entry" ]] \
        || release_fail "release HEAD is not the expected appcast commit"

    release_log "atomically updating dev and main with the appcast commit"
    git -C "$RELEASE_WORKTREE" push --atomic "$RELEASE_REMOTE" \
        "HEAD:refs/heads/$RELEASE_DEV_BRANCH" \
        "HEAD:refs/heads/$RELEASE_MAIN_BRANCH"
    fetch_release_refs
}

# Removes only a clean registered worktree after remote verification succeeds.
cleanup_worktree() {
    if ! worktree_is_registered; then
        release_log "release worktree is already removed"
        return
    fi

    [[ -z "$(git -C "$RELEASE_WORKTREE" status --porcelain)" ]] \
        || release_fail "refusing to remove a dirty release worktree"
    git -C "$RELEASE_SOURCE_ROOT" worktree remove "$RELEASE_WORKTREE"
    if ! git -C "$RELEASE_SOURCE_ROOT" branch -d "$RELEASE_BRANCH"; then
        release_log "temporary branch retained: $RELEASE_BRANCH"
    fi
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        prepare)
            prepare_worktree
            ;;
        push-version)
            push_version_refs
            ;;
        push-appcast)
            push_appcast_refs
            ;;
        cleanup)
            cleanup_worktree
            ;;
        *)
            release_fail "usage: release-branch-sync.sh prepare|push-version|push-appcast|cleanup"
            ;;
    esac
}

main "$@"
