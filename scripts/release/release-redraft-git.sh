#!/usr/bin/env bash

# Owns the Git worktree, branch, and ref transition used only by an explicit
# same-version Draft replacement. Ordinary release synchronization remains in
# release-branch-sync.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

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

load_replacement_archive() {
    require_release_file "$RELEASE_REPLACEMENT_ARCHIVE_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_REPLACEMENT_ARCHIVE_PATH"

    [[ "$REPLACEMENT_ARCHIVE_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "replacement archive belongs to another version"
    case "$REPLACEMENT_ARCHIVED_BRANCH" in
        "release/replaced-$RELEASE_VERSION-"*)
            ;;
        *)
            release_fail "replacement archive branch is invalid"
            ;;
    esac
}

archive_replacement_state() {
    local actual_branch generated_path temporary_path

    load_replacement_metadata
    if replacement_is_complete local-archived; then
        release_log "old local release state is already archived"
        return
    fi

    if [[ ! -f "$RELEASE_REPLACEMENT_ARCHIVE_PATH" ]]; then
        mkdir -p "$RELEASE_REPLACEMENT_BACKUP_DIR"
        REPLACEMENT_ARCHIVED_BRANCH="release/replaced-$RELEASE_VERSION-$(date '+%Y%m%dT%H%M%S')-$$"
        temporary_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/archive.XXXXXX")"
        {
            printf 'REPLACEMENT_ARCHIVE_VERSION=%q\n' "$RELEASE_VERSION"
            printf 'REPLACEMENT_ARCHIVED_BRANCH=%q\n' \
                "$REPLACEMENT_ARCHIVED_BRANCH"
        } >"$temporary_path"
        mv "$temporary_path" "$RELEASE_REPLACEMENT_ARCHIVE_PATH"
    fi
    load_replacement_archive

    if worktree_path_is_registered "$RELEASE_WORKTREE"; then
        require_release_worktree
        [[ -z "$(git -C "$RELEASE_WORKTREE" status --porcelain \
            --untracked-files=all)" ]] \
            || release_fail "existing release worktree has pending changes; resume or clean it explicitly"
        [[ "$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)" \
            == "$REPLACEMENT_OLD_VERSION_COMMIT" ]] \
            || release_fail "existing release worktree does not match the Draft being replaced"
        actual_branch="$(git -C "$RELEASE_WORKTREE" branch --show-current)"
        if [[ "$actual_branch" == "$RELEASE_BRANCH" ]]; then
            git -C "$RELEASE_WORKTREE" switch --detach >/dev/null
        elif [[ -n "$actual_branch" ]]; then
            release_fail "release worktree is attached to unexpected branch: $actual_branch"
        fi

        if git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
            "refs/heads/$RELEASE_BRANCH"; then
            git -C "$RELEASE_SOURCE_ROOT" branch -m \
                "$RELEASE_BRANCH" "$REPLACEMENT_ARCHIVED_BRANCH"
        elif ! git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
            "refs/heads/$REPLACEMENT_ARCHIVED_BRANCH"; then
            release_fail "replacement archive branch is missing"
        fi

        mkdir -p "$RELEASE_REPLACEMENT_BACKUP_DIR"
        git -C "$RELEASE_SOURCE_ROOT" worktree move \
            "$RELEASE_WORKTREE" "$RELEASE_REPLACEMENT_BACKUP_DIR/worktree"
    elif ! worktree_path_is_registered \
        "$RELEASE_REPLACEMENT_BACKUP_DIR/worktree"; then
        release_fail "release worktree disappeared before it could be archived"
    fi

    for generated_path in \
        state Easydict.xcarchive derived-data export artifacts appcast \
        Easydict-notarization.zip verify; do
        if [[ -e "$RELEASE_DIR/$generated_path" ]]; then
            [[ ! -e "$RELEASE_REPLACEMENT_BACKUP_DIR/$generated_path" ]] \
                || release_fail "replacement backup already contains $generated_path"
            mv "$RELEASE_DIR/$generated_path" \
                "$RELEASE_REPLACEMENT_BACKUP_DIR/$generated_path"
        fi
    done

    ensure_release_layout
    mark_replacement_complete local-archived
    release_log "temporarily archived old local Draft state for rollback"
}

remote_version_tag_oid() {
    git -C "$RELEASE_SOURCE_ROOT" ls-remote "$RELEASE_REMOTE" \
        "refs/tags/$RELEASE_VERSION" \
        | awk -v ref="refs/tags/$RELEASE_VERSION" \
            '$2 == ref { print $1; exit }'
}

remote_release_branch_oid() {
    local oid

    oid="$(git -C "$RELEASE_SOURCE_ROOT" ls-remote "$RELEASE_REMOTE" \
        "refs/heads/$RELEASE_BRANCH" \
        | awk -v ref="refs/heads/$RELEASE_BRANCH" \
            '$2 == ref { print $1; exit }')"
    printf '%s\n' "${oid:-missing}"
}

ensure_replacement_tag() {
    local current_head local_tag_oid local_tag_commit

    current_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    if git -C "$RELEASE_WORKTREE" show-ref --verify --quiet \
        "refs/tags/$RELEASE_VERSION"; then
        local_tag_oid="$(git -C "$RELEASE_WORKTREE" rev-parse \
            "refs/tags/$RELEASE_VERSION")"
        local_tag_commit="$(git -C "$RELEASE_WORKTREE" rev-parse \
            "refs/tags/$RELEASE_VERSION^{commit}")"
        if [[ "$local_tag_commit" == "$current_head" ]]; then
            return
        fi
        [[ "$local_tag_oid" == "$REPLACEMENT_OLD_TAG_OID" ]] \
            || release_fail "local replacement Tag has an unexpected identity"
        git -C "$RELEASE_WORKTREE" tag -d "$RELEASE_VERSION" >/dev/null
    fi
    git -C "$RELEASE_WORKTREE" tag -a "$RELEASE_VERSION" \
        -m "Easydict $RELEASE_VERSION"
}

push_replacement_refs() {
    local current_head local_tag_oid remote_tag_oid remote_release_oid
    local branch_lease

    require_release_worktree
    load_release_metadata
    load_replacement_metadata
    current_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    [[ "$current_head" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "release HEAD differs from the saved version commit"

    ensure_replacement_tag
    local_tag_oid="$(git -C "$RELEASE_WORKTREE" rev-parse \
        "refs/tags/$RELEASE_VERSION")"
    remote_tag_oid="$(remote_version_tag_oid)"
    remote_release_oid="$(remote_release_branch_oid)"
    if [[ "$remote_tag_oid" == "$local_tag_oid" \
        && "$remote_release_oid" == "$current_head" ]]; then
        write_draft_refs_metadata "$current_head" "$local_tag_oid"
        mark_replacement_complete refs-replaced
        release_log "replacement refs were already updated"
        return
    fi
    [[ "$remote_tag_oid" == "$REPLACEMENT_OLD_TAG_OID" ]] \
        || release_fail "remote Tag no longer matches the frozen replacement identity"
    [[ "$remote_release_oid" == "$REPLACEMENT_OLD_RELEASE_BRANCH_OID" ]] \
        || release_fail "remote release branch no longer matches the frozen replacement identity"

    if [[ "$REPLACEMENT_OLD_RELEASE_BRANCH_OID" == missing ]]; then
        branch_lease="--force-with-lease=refs/heads/$RELEASE_BRANCH:"
    else
        branch_lease="--force-with-lease=refs/heads/$RELEASE_BRANCH:"
        branch_lease+="$REPLACEMENT_OLD_RELEASE_BRANCH_OID"
    fi

    release_log \
        "atomically replacing $RELEASE_BRANCH and $RELEASE_VERSION with lease protection"
    git -C "$RELEASE_WORKTREE" push --atomic \
        "$branch_lease" \
        "--force-with-lease=refs/tags/$RELEASE_VERSION:$REPLACEMENT_OLD_TAG_OID" \
        "$RELEASE_REMOTE" \
        "+HEAD:refs/heads/$RELEASE_BRANCH" \
        "+refs/tags/$RELEASE_VERSION:refs/tags/$RELEASE_VERSION"

    [[ "$(remote_version_tag_oid)" == "$local_tag_oid" ]] \
        || release_fail "remote replacement Tag did not reach the expected object"
    [[ "$(remote_release_branch_oid)" == "$current_head" ]] \
        || release_fail "remote release branch did not reach the replacement commit"
    write_draft_refs_metadata "$current_head" "$local_tag_oid"
    mark_replacement_complete refs-replaced
}

cleanup_replacement() {
    local backup_worktree

    if [[ ! -e "$RELEASE_REPLACEMENT_DIR" ]]; then
        release_log "replacement backup is already removed"
        return
    fi
    load_replacement_metadata
    load_replacement_archive
    replacement_is_complete refs-replaced \
        || release_fail "replacement refs are not complete"
    replacement_is_complete draft-deleted \
        || release_fail "old Draft deletion is not complete"
    replacement_is_complete new-draft-created \
        || release_fail "new Draft creation is not complete"

    backup_worktree="$RELEASE_REPLACEMENT_BACKUP_DIR/worktree"
    if worktree_path_is_registered "$backup_worktree"; then
        [[ -z "$(git -C "$backup_worktree" status --porcelain \
            --untracked-files=all)" ]] \
            || release_fail "refusing to remove a dirty replacement backup worktree"
        git -C "$RELEASE_SOURCE_ROOT" worktree remove "$backup_worktree"
    fi
    if git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
        "refs/heads/$REPLACEMENT_ARCHIVED_BRANCH"; then
        git -C "$RELEASE_SOURCE_ROOT" branch -D \
            "$REPLACEMENT_ARCHIVED_BRANCH" >/dev/null
    fi

    case "$RELEASE_REPLACEMENT_DIR" in
        "$RELEASE_DIR/replacement")
            rm -rf "$RELEASE_REPLACEMENT_DIR"
            ;;
        *)
            release_fail "refusing to remove unexpected replacement path"
            ;;
    esac
    git -C "$RELEASE_SOURCE_ROOT" worktree prune
    release_log "removed obsolete local Draft state and temporary rollback backup"
}

main() {
    local action="${1:-}"

    require_release_version
    release_is_replacement \
        || release_fail "release-redraft-git.sh requires DRAFT_MODE=replace"
    case "$action" in
        archive)
            release_set_step "archive_replaced_local_state"
            archive_replacement_state
            ;;
        push-refs)
            release_set_step "push_draft_refs"
            push_replacement_refs
            ;;
        cleanup)
            release_set_step "cleanup_draft_replacement"
            cleanup_replacement
            ;;
        *)
            release_fail "usage: release-redraft-git.sh archive|push-refs|cleanup"
            ;;
    esac
}

main "$@"
