#!/usr/bin/env bash

# Integrates a verified release into local dev during Publish, then advances
# dev, main, and the temporary release branch in one lease-protected push.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

remote_tracking_ref() {
    printf 'refs/remotes/%s/%s' "$RELEASE_REMOTE" "$1"
}

local_dev_ref() {
    printf 'refs/heads/%s' "$RELEASE_DEV_BRANCH"
}

worktree_path_is_registered() {
    local worktree_path="$1"
    local expected_path="$worktree_path"

    if [[ -d "$worktree_path" ]]; then
        expected_path="$(cd "$worktree_path" && pwd -P)"
    fi

    git -C "$RELEASE_SOURCE_ROOT" worktree list --porcelain \
        | awk -v expected="$expected_path" '
            $1 == "worktree" && substr($0, 10) == expected { found = 1 }
            END { exit(found ? 0 : 1) }
        '
}

dev_worktree_path() {
    git -C "$RELEASE_SOURCE_ROOT" worktree list --porcelain \
        | awk -v expected="refs/heads/$RELEASE_DEV_BRANCH" '
            $1 == "worktree" { path = substr($0, 10) }
            $1 == "branch" && $2 == expected { print path; exit }
        '
}

fetch_publish_refs() {
    release_log "fetching publish refs for dev, main, and $RELEASE_BRANCH"
    git -C "$RELEASE_SOURCE_ROOT" fetch --prune "$RELEASE_REMOTE" \
        "+refs/heads/$RELEASE_DEV_BRANCH:$(remote_tracking_ref "$RELEASE_DEV_BRANCH")" \
        "+refs/heads/$RELEASE_MAIN_BRANCH:$(remote_tracking_ref "$RELEASE_MAIN_BRANCH")" \
        "+refs/heads/$RELEASE_BRANCH:$(remote_tracking_ref "$RELEASE_BRANCH")"
}

remote_tag_commit() {
    local refs object_oid peeled_oid

    refs="$(git -C "$RELEASE_SOURCE_ROOT" ls-remote "$RELEASE_REMOTE" \
        "refs/tags/$RELEASE_VERSION" \
        "refs/tags/$RELEASE_VERSION^{}")"
    object_oid="$(awk -v ref="refs/tags/$RELEASE_VERSION" \
        '$2 == ref { print $1; exit }' <<<"$refs")"
    peeled_oid="$(awk -v ref="refs/tags/$RELEASE_VERSION^{}" \
        '$2 == ref { print $1; exit }' <<<"$refs")"
    printf '%s\n' "${peeled_oid:-$object_oid}"
}

write_publish_git_metadata() {
    local prepared_head="$1"
    local local_dev_base="$2"
    local remote_dev_base="$3"
    local remote_main_base="$4"
    local remote_release_base="$5"
    local appcast_commit="${6:-}"
    local integration_head="${7:-}"
    local local_update_mode="${8:-pending}"
    local temporary_path

    mkdir -p "$RELEASE_STATE_DIR"
    temporary_path="$(mktemp "$RELEASE_STATE_DIR/publish-git.XXXXXX")"
    {
        printf 'PUBLISH_GIT_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'PUBLISH_VERSION_COMMIT=%q\n' "$RELEASE_VERSION_COMMIT"
        printf 'PUBLISH_PREPARED_HEAD=%q\n' "$prepared_head"
        printf 'PUBLISH_LOCAL_DEV_BASE=%q\n' "$local_dev_base"
        printf 'PUBLISH_REMOTE_DEV_BASE=%q\n' "$remote_dev_base"
        printf 'PUBLISH_REMOTE_MAIN_BASE=%q\n' "$remote_main_base"
        printf 'PUBLISH_REMOTE_RELEASE_BASE=%q\n' "$remote_release_base"
        printf 'PUBLISH_APPCAST_COMMIT=%q\n' "$appcast_commit"
        printf 'PUBLISH_INTEGRATION_HEAD=%q\n' "$integration_head"
        printf 'PUBLISH_LOCAL_DEV_UPDATE_MODE=%q\n' "$local_update_mode"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_PUBLISH_GIT_PATH"
}

require_clean_integration_worktree() {
    worktree_path_is_registered "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" \
        || release_fail "publish integration worktree is not registered"
    [[ -z "$(git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" status \
        --porcelain --untracked-files=all)" ]] \
        || release_fail "publish integration worktree has unresolved changes:" \
            "$RELEASE_PUBLISH_INTEGRATION_WORKTREE"
}

merge_into_integration() {
    local commit="$1"
    local label="$2"
    local current_head

    current_head="$(git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" rev-parse HEAD)"
    if git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$commit" "$current_head"; then
        release_log "$label is already contained in publish integration"
    elif git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$current_head" "$commit"; then
        git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" merge --ff-only \
            "$commit" >/dev/null
        release_log "publish integration fast-forwarded to $label"
    else
        release_log "merging $label into publish integration"
        if ! git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" merge \
            --no-ff --no-edit "$commit" >/dev/null; then
            release_error "merge conflict while integrating $label"
            release_error \
                "resolve it in $RELEASE_PUBLISH_INTEGRATION_WORKTREE, commit, then resume"
            return 1
        fi
    fi
}

verify_dev_checkout_ready() {
    local expected_dev="$1"
    local checkout_path checkout_head

    checkout_path="$(dev_worktree_path)"
    if [[ -z "$checkout_path" ]]; then
        release_log "local $RELEASE_DEV_BRANCH is not checked out; it can be updated atomically"
        return
    fi

    checkout_head="$(git -C "$checkout_path" rev-parse HEAD)"
    [[ "$checkout_head" == "$expected_dev" ]] \
        || release_fail "checked-out local dev does not match refs/heads/$RELEASE_DEV_BRANCH"
    [[ -z "$(git -C "$checkout_path" status --porcelain \
        --untracked-files=all)" ]] \
        || release_fail \
            "local dev checkout must be clean before Publish: $checkout_path"
    release_log "local dev checkout is clean and can be fast-forwarded: $checkout_path"
}

require_remote_draft_refs() {
    local remote_release remote_main tag_commit

    remote_release="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_BRANCH")")"
    remote_main="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_MAIN_BRANCH")")"
    tag_commit="$(remote_tag_commit)"

    [[ "$remote_release" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "remote $RELEASE_BRANCH does not match the version commit"
    [[ "$tag_commit" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "remote Tag does not match the version commit"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$remote_main" "$RELEASE_VERSION_COMMIT" \
        || release_fail \
            "remote main advanced outside the Draft; rebuild the Draft before publishing"
}

prepare_publish_integration() {
    local local_dev remote_dev remote_main remote_release prepared_head

    require_release_worktree
    load_release_metadata
    fetch_publish_refs
    require_remote_draft_refs

    local_dev="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse "$(local_dev_ref)")"
    remote_dev="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_DEV_BRANCH")")"
    remote_main="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_MAIN_BRANCH")")"
    remote_release="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_BRANCH")")"
    verify_dev_checkout_ready "$local_dev"

    if worktree_path_is_registered "$RELEASE_PUBLISH_INTEGRATION_WORKTREE"; then
        load_publish_git_metadata
        require_clean_integration_worktree
        release_log "reusing publish integration worktree"
    else
        [[ ! -e "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" ]] \
            || release_fail "unregistered path blocks publish integration:" \
                "$RELEASE_PUBLISH_INTEGRATION_WORKTREE"
        git -C "$RELEASE_SOURCE_ROOT" worktree add --detach \
            "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" "$local_dev" >/dev/null
        write_publish_git_metadata \
            "$local_dev" "$local_dev" "$remote_dev" "$remote_main" \
            "$remote_release"
        release_log "created isolated publish integration worktree"
    fi

    merge_into_integration "$local_dev" "local $RELEASE_DEV_BRANCH"
    merge_into_integration "$remote_dev" "$RELEASE_REMOTE/$RELEASE_DEV_BRANCH"
    merge_into_integration "$RELEASE_VERSION_COMMIT" "$RELEASE_BRANCH"
    require_clean_integration_worktree
    prepared_head="$(git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" rev-parse HEAD)"
    write_publish_git_metadata \
        "$prepared_head" "$local_dev" "$remote_dev" "$remote_main" \
        "$remote_release"
    release_log "publish merge preflight completed @ $prepared_head"
}

update_local_dev() {
    local new_head="$1"
    local old_head="$2"
    local checkout_path checkout_head

    checkout_path="$(dev_worktree_path)"
    if [[ -z "$checkout_path" ]]; then
        git -C "$RELEASE_SOURCE_ROOT" update-ref \
            "$(local_dev_ref)" "$new_head" "$old_head"
        printf 'update-ref\n'
        return
    fi

    checkout_head="$(git -C "$checkout_path" rev-parse HEAD)"
    [[ "$checkout_head" == "$old_head" ]] \
        || release_fail "local dev changed after publish preflight"
    [[ -z "$(git -C "$checkout_path" status --porcelain \
        --untracked-files=all)" ]] \
        || release_fail "local dev checkout changed after publish preflight"
    git -C "$checkout_path" merge --ff-only "$new_head" >/dev/null
    printf 'checked-out-fast-forward\n'
}

published_refs_already_match() {
    local remote_dev="$1"
    local remote_main="$2"
    local remote_release="$3"

    [[ -n "${PUBLISH_INTEGRATION_HEAD:-}" \
        && -n "${PUBLISH_APPCAST_COMMIT:-}" \
        && "$remote_dev" == "$PUBLISH_INTEGRATION_HEAD" \
        && "$remote_main" == "$PUBLISH_APPCAST_COMMIT" \
        && "$remote_release" == "$PUBLISH_APPCAST_COMMIT" ]]
}

push_published_refs() {
    local appcast_head integration_head local_dev
    local remote_dev remote_main remote_release local_update_mode

    require_release_worktree
    load_release_metadata
    load_publish_git_metadata
    require_clean_integration_worktree
    [[ "$(git -C "$RELEASE_WORKTREE" log -1 --format=%s)" \
        == "build(release): add $RELEASE_VERSION appcast entry" ]] \
        || release_fail "release HEAD is not the expected appcast commit"
    appcast_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"

    fetch_publish_refs
    remote_dev="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_DEV_BRANCH")")"
    remote_main="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_MAIN_BRANCH")")"
    remote_release="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_BRANCH")")"
    if published_refs_already_match "$remote_dev" "$remote_main" "$remote_release"; then
        [[ "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse "$(local_dev_ref)")" \
            == "$PUBLISH_INTEGRATION_HEAD" ]] \
            || release_fail "remote publish completed but local dev is not synchronized"
        release_log "published Git refs already match the saved integration"
        return
    fi

    [[ "$remote_main" == "$PUBLISH_REMOTE_MAIN_BASE" ]] \
        || release_fail "remote main changed after publish preflight"
    [[ "$remote_release" == "$PUBLISH_REMOTE_RELEASE_BASE" ]] \
        || release_fail "remote release branch changed after publish preflight"
    [[ "$(remote_tag_commit)" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "remote Tag changed after publish preflight"

    local_dev="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse "$(local_dev_ref)")"
    verify_dev_checkout_ready "$local_dev"
    merge_into_integration "$local_dev" "current local $RELEASE_DEV_BRANCH"
    merge_into_integration "$remote_dev" \
        "current $RELEASE_REMOTE/$RELEASE_DEV_BRANCH"
    merge_into_integration "$appcast_head" "published appcast commit"
    require_clean_integration_worktree
    integration_head="$(git -C "$RELEASE_PUBLISH_INTEGRATION_WORKTREE" rev-parse HEAD)"

    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$remote_dev" "$integration_head" \
        || release_fail "publish integration does not contain current remote dev"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$local_dev" "$integration_head" \
        || release_fail "publish integration does not contain current local dev"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$appcast_head" "$integration_head" \
        || release_fail "publish integration does not contain the appcast commit"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$remote_main" "$appcast_head" \
        || release_fail "publishing main would not be a fast-forward"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$remote_release" "$appcast_head" \
        || release_fail "publishing the release branch would not be a fast-forward"

    local_update_mode="$(update_local_dev "$integration_head" "$local_dev")"
    [[ "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse "$(local_dev_ref)")" \
        == "$integration_head" ]] \
        || release_fail "local dev did not reach the publish integration"
    write_publish_git_metadata \
        "$PUBLISH_PREPARED_HEAD" "$local_dev" "$remote_dev" "$remote_main" \
        "$remote_release" "$appcast_head" "$integration_head" \
        "$local_update_mode"

    release_log "atomically publishing local dev, main, and $RELEASE_BRANCH"
    git -C "$RELEASE_SOURCE_ROOT" push --atomic \
        "--force-with-lease=refs/heads/$RELEASE_DEV_BRANCH:$remote_dev" \
        "--force-with-lease=refs/heads/$RELEASE_MAIN_BRANCH:$remote_main" \
        "--force-with-lease=refs/heads/$RELEASE_BRANCH:$remote_release" \
        "$RELEASE_REMOTE" \
        "$(local_dev_ref):refs/heads/$RELEASE_DEV_BRANCH" \
        "$appcast_head:refs/heads/$RELEASE_MAIN_BRANCH" \
        "$appcast_head:refs/heads/$RELEASE_BRANCH"

    fetch_publish_refs
    [[ "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_DEV_BRANCH")")" == "$integration_head" ]] \
        || release_fail "remote dev did not reach the publish integration"
    [[ "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_MAIN_BRANCH")")" == "$appcast_head" ]] \
        || release_fail "remote main did not reach the appcast commit"
    [[ "$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "$(remote_tracking_ref "$RELEASE_BRANCH")")" == "$appcast_head" ]] \
        || release_fail "remote release branch did not reach the appcast commit"
    release_log "local and remote dev now match @ $integration_head"
}

cleanup_remote_release_branch() {
    local remote_release

    load_publish_git_metadata
    [[ -n "${PUBLISH_APPCAST_COMMIT:-}" ]] \
        || release_fail "published appcast commit is missing from Git metadata"
    remote_release="$(git -C "$RELEASE_SOURCE_ROOT" ls-remote \
        "$RELEASE_REMOTE" "refs/heads/$RELEASE_BRANCH" \
        | awk -v ref="refs/heads/$RELEASE_BRANCH" \
            '$2 == ref { print $1; exit }')"
    if [[ -n "$remote_release" ]]; then
        [[ "$remote_release" == "$PUBLISH_APPCAST_COMMIT" ]] \
            || release_fail "refusing to delete an unexpected remote release branch"
        git -C "$RELEASE_SOURCE_ROOT" push \
            "--force-with-lease=refs/heads/$RELEASE_BRANCH:$remote_release" \
            "$RELEASE_REMOTE" ":refs/heads/$RELEASE_BRANCH"
    fi
    [[ -z "$(git -C "$RELEASE_SOURCE_ROOT" ls-remote \
        "$RELEASE_REMOTE" "refs/heads/$RELEASE_BRANCH")" ]] \
        || release_fail "remote release branch still exists after cleanup"
    : >"$RELEASE_REMOTE_BRANCH_CLEANUP_MARKER"

    if worktree_path_is_registered "$RELEASE_PUBLISH_INTEGRATION_WORKTREE"; then
        require_clean_integration_worktree
        git -C "$RELEASE_SOURCE_ROOT" worktree remove \
            "$RELEASE_PUBLISH_INTEGRATION_WORKTREE"
    fi
    release_log "removed temporary remote release branch and integration worktree"
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        prepare)
            release_set_step "prepare_publish_git"
            prepare_publish_integration
            ;;
        push)
            release_set_step "push_published_refs"
            push_published_refs
            ;;
        cleanup)
            release_set_step "cleanup_remote_release_branch"
            cleanup_remote_release_branch
            ;;
        *)
            release_fail "usage: release-publish-git.sh prepare|push|cleanup"
            ;;
    esac
}

main "$@"
