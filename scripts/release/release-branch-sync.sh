#!/usr/bin/env bash

# Synchronizes origin/dev into an isolated local-dev source worktree, builds an
# isolated release worktree, then updates both branches and the release tag
# through atomic remote pushes.

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

local_dev_ref() {
    printf 'refs/heads/%s' "$RELEASE_DEV_BRANCH"
}

log_current_checkout() {
    local current_branch current_changes

    current_branch="$(git -C "$RELEASE_SOURCE_ROOT" symbolic-ref \
        --quiet --short HEAD || printf 'detached HEAD')"
    current_changes="$(git -C "$RELEASE_SOURCE_ROOT" status --porcelain \
        --untracked-files=all)"

    if [[ -n "$current_changes" ]]; then
        release_log "current checkout: $current_branch (pending changes preserved; not used as release source)"
    else
        release_log "current checkout: $current_branch (unchanged; release source comes from local $RELEASE_DEV_BRANCH)"
    fi
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
    local main_only dev_only

    main_only="$(git -C "$RELEASE_SOURCE_ROOT" rev-list --count \
        "$(remote_dev_ref)..$(remote_main_ref)")"
    dev_only="$(git -C "$RELEASE_SOURCE_ROOT" rev-list --count \
        "$(remote_main_ref)..$(remote_dev_ref)")"
    release_log "remote branch delta: main-only=$main_only, dev-only=$dev_only"
}

sync_local_dev() {
    local local_commit remote_commit source_commit sync_worktree

    ensure_release_layout
    log_current_checkout
    fetch_release_refs
    report_branch_commits

    git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
        "$(local_dev_ref)" \
        || release_fail "local dev branch was not found"

    local_commit="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(local_dev_ref)")"
    remote_commit="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_dev_ref)")"

    sync_worktree="$(mktemp -d "$RELEASE_DIR/.dev-sync.XXXXXX")"
    rmdir "$sync_worktree"
    if ! git -C "$RELEASE_SOURCE_ROOT" worktree add --detach \
        "$sync_worktree" "$local_commit" >/dev/null 2>&1; then
        rmdir "$sync_worktree" 2>/dev/null || true
        release_fail "could not create isolated worktree from local $RELEASE_DEV_BRANCH"
    fi

    release_log "created isolated source worktree from local $RELEASE_DEV_BRANCH @ $local_commit"
    if git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$remote_commit" "$local_commit"; then
        release_log "isolated source already contains $RELEASE_REMOTE/$RELEASE_DEV_BRANCH"
    elif git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$local_commit" "$remote_commit"; then
        release_log "fast-forwarding isolated source to $RELEASE_REMOTE/$RELEASE_DEV_BRANCH"
        git -C "$sync_worktree" merge --ff-only "$remote_commit" >/dev/null 2>&1
        release_log "isolated source fast-forward completed"
    else
        release_log "merging $RELEASE_REMOTE/$RELEASE_DEV_BRANCH into isolated local $RELEASE_DEV_BRANCH source"
        if ! git -C "$sync_worktree" merge --no-edit "$remote_commit" >/dev/null 2>&1; then
            release_error "origin/dev could not be merged into isolated local dev source"
            release_error "resolve the conflict in this worktree, then rerun draft: $sync_worktree"
            release_error "current checkout was not modified"
            return 1
        fi
        release_log "isolated source merge completed"
    fi

    source_commit="$(git -C "$sync_worktree" rev-parse HEAD)"
    git -C "$RELEASE_SOURCE_ROOT" worktree remove "$sync_worktree"
    write_release_source_metadata \
        "$source_commit" \
        "$remote_commit" \
        "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse "$(remote_main_ref)")"
    release_log "release source: synchronized local $RELEASE_DEV_BRANCH @ $source_commit"
}

verify_remote_ancestry() {
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$(remote_dev_ref)" HEAD \
        || release_fail "release branch no longer contains current remote dev"
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$(remote_main_ref)" HEAD \
        || release_fail "release branch no longer contains current remote main"
}

verify_release_source_ancestry() {
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$RELEASE_SOURCE_COMMIT" HEAD \
        || release_fail "release worktree does not contain the saved local dev source"
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT" HEAD \
        || release_fail "release worktree does not contain the saved remote main source"
}

release_worktree_matches_source() {
    git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
        "$RELEASE_SOURCE_COMMIT" HEAD \
        && git -C "$RELEASE_WORKTREE" merge-base --is-ancestor \
            "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT" HEAD \
        || return 1

    if [[ "$RELEASE_RUN_MODE" == new && -f "$RELEASE_METADATA_PATH" ]]; then
        # A new run may reuse matching artifacts, but never mix channels from
        # an earlier attempt for the same version.
        # shellcheck disable=SC1090
        source "$RELEASE_METADATA_PATH"
        [[ "${RELEASE_SAVED_VERSION:-}" == "$RELEASE_VERSION" ]] \
            || return 1
        [[ "${RELEASE_SAVED_CHANNEL:-}" == "$RELEASE_CHANNEL" ]] \
            || return 1
    fi
    return 0
}

release_branch_matches_source() {
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$RELEASE_SOURCE_COMMIT" "refs/heads/$RELEASE_BRANCH" \
        && git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
            "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT" "refs/heads/$RELEASE_BRANCH"
}

require_no_remote_version_tag() {
    local status

    if git -C "$RELEASE_SOURCE_ROOT" ls-remote --exit-code "$RELEASE_REMOTE" \
        "refs/tags/$RELEASE_VERSION" >/dev/null 2>&1; then
        release_fail "remote tag $RELEASE_VERSION already exists; refusing to rebuild release state"
    else
        status=$?
    fi

    case "$status" in
        2)
            ;;
        *)
            release_fail "unable to verify whether remote tag $RELEASE_VERSION exists"
            ;;
    esac
}

archive_stale_branch() {
    local archived_branch

    [[ "$RELEASE_RUN_MODE" != resume ]] \
        || release_fail "resumed release branch is stale; refusing to replace its saved release source"
    require_no_remote_version_tag
    archived_branch="release/stale-$RELEASE_VERSION-$(date '+%Y%m%dT%H%M%S')-$$"
    git -C "$RELEASE_SOURCE_ROOT" branch -m \
        "$RELEASE_BRANCH" "$archived_branch"
    release_log "archived stale release branch as $archived_branch"
}

archive_stale_worktree() {
    local archived_branch archive_dir generated_path
    local actual_branch

    [[ "$RELEASE_RUN_MODE" != resume ]] \
        || release_fail "resumed release worktree is stale; refusing to replace its saved release source"
    require_release_worktree
    [[ -z "$(git -C "$RELEASE_WORKTREE" status --porcelain \
        --untracked-files=all)" ]] \
        || release_fail "existing release worktree has pending changes; use asc resume"
    actual_branch="$(git -C "$RELEASE_WORKTREE" branch --show-current)"
    [[ "$actual_branch" == "$RELEASE_BRANCH" ]] \
        || release_fail "release worktree is attached to unexpected branch: $actual_branch"
    require_no_remote_version_tag

    mkdir -p "$RELEASE_DIR/stale"
    archive_dir="$(mktemp -d "$RELEASE_DIR/stale/attempt.XXXXXX")"
    archived_branch="release/stale-$RELEASE_VERSION-$(date '+%Y%m%dT%H%M%S')-$$"
    git -C "$RELEASE_WORKTREE" switch --detach >/dev/null
    git -C "$RELEASE_SOURCE_ROOT" branch -m \
        "$RELEASE_BRANCH" "$archived_branch"
    git -C "$RELEASE_SOURCE_ROOT" worktree move \
        "$RELEASE_WORKTREE" "$archive_dir/worktree"

    for generated_path in \
        state Easydict.xcarchive derived-data export artifacts appcast \
        Easydict-notarization.zip verify; do
        if [[ -e "$RELEASE_DIR/$generated_path" ]]; then
            mv "$RELEASE_DIR/$generated_path" "$archive_dir/$generated_path"
        fi
    done

    release_log "archived stale release worktree: $archive_dir/worktree"
    release_log "archived stale release branch: $archived_branch"
}

create_release_worktree() {
    git -C "$RELEASE_SOURCE_ROOT" worktree add \
        -b "$RELEASE_BRANCH" \
        "$RELEASE_WORKTREE" \
        "$RELEASE_SOURCE_COMMIT" >/dev/null 2>&1 \
        || release_fail "could not create release worktree: $RELEASE_WORKTREE"
    release_log "created release worktree: $RELEASE_WORKTREE"
    release_log "merging saved remote main into the local dev release source"
    git -C "$RELEASE_WORKTREE" merge --no-edit \
        "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT" >/dev/null 2>&1 \
        || release_fail "saved remote main could not be merged into release worktree"
    release_log "release worktree merge completed"
}

# Builds a clean release source from the synchronized local dev and main.
prepare_worktree() {
    local created_worktree=0

    ensure_release_layout
    if [[ -f "$RELEASE_SOURCE_METADATA_PATH" ]]; then
        load_release_source_metadata
    else
        sync_local_dev
        load_release_source_metadata
    fi
    git -C "$RELEASE_SOURCE_ROOT" cat-file -e \
        "$RELEASE_SOURCE_COMMIT^{commit}" \
        || release_fail "saved local dev source commit is unavailable"
    git -C "$RELEASE_SOURCE_ROOT" cat-file -e \
        "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT^{commit}" \
        || release_fail "saved remote main source commit is unavailable"
    report_branch_commits

    if worktree_is_registered; then
        require_release_worktree
        release_log "reusing release worktree: $RELEASE_WORKTREE"
        if ! release_worktree_matches_source; then
            release_log "stale release worktree detected; rebuilding from local dev source"
            archive_stale_worktree
            created_worktree=1
        fi
    else
        [[ ! -e "$RELEASE_WORKTREE" ]] \
            || release_fail "unregistered path blocks release worktree: $RELEASE_WORKTREE"

        if git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
            "refs/heads/$RELEASE_BRANCH"; then
            if release_branch_matches_source; then
                git -C "$RELEASE_SOURCE_ROOT" worktree add \
                    "$RELEASE_WORKTREE" "$RELEASE_BRANCH" >/dev/null 2>&1 \
                    || release_fail "could not attach the matching release worktree"
            else
                archive_stale_branch
                created_worktree=1
            fi
        else
            created_worktree=1
        fi
    fi

    if ((created_worktree == 1)); then
        create_release_worktree
    else
        [[ -z "$(git -C "$RELEASE_WORKTREE" status --porcelain)" ]] \
            || release_fail "existing release worktree has pending changes; use asc resume"
    fi

    write_release_source_metadata \
        "$RELEASE_SOURCE_COMMIT" \
        "$RELEASE_SYNCED_REMOTE_DEV_COMMIT" \
        "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT"
    verify_release_source_ancestry
    release_log "release worktree contains local dev and remote main source histories"
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
        sync-dev)
            release_set_step "sync_local_dev"
            sync_local_dev
            ;;
        prepare)
            release_set_step "prepare_release_worktree"
            prepare_worktree
            ;;
        push-version)
            release_set_step "push_version_refs"
            push_version_refs
            ;;
        push-appcast)
            release_set_step "push_appcast_refs"
            push_appcast_refs
            ;;
        cleanup)
            release_set_step "cleanup_release_worktree"
            cleanup_worktree
            ;;
        *)
            release_fail "usage: release-branch-sync.sh sync-dev|prepare|push-version|push-appcast|cleanup"
            ;;
    esac
}

main "$@"
