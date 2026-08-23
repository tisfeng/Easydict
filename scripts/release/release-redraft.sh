#!/usr/bin/env bash

# Freezes and later removes the exact GitHub Draft being replaced. The old
# remote Draft, temporary release branch, and Tag remain untouched until
# replacement artifacts pass local verification.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

json_field() {
    local json_path="$1"
    local field="$2"

    python3 - "$json_path" "$field" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
if isinstance(value, list):
    if not value:
        raise SystemExit(1)
    value = value[0]
value = value.get(sys.argv[2])
if isinstance(value, bool):
    print(str(value).lower())
elif value is not None:
    print(value)
PY
}

remote_tag_oids() {
    git -C "$RELEASE_SOURCE_ROOT" ls-remote "$RELEASE_REMOTE" \
        "refs/tags/$RELEASE_VERSION" \
        "refs/tags/$RELEASE_VERSION^{}"
}

remote_release_branch_oid() {
    local oid

    oid="$(git -C "$RELEASE_SOURCE_ROOT" ls-remote "$RELEASE_REMOTE" \
        "refs/heads/$RELEASE_BRANCH" \
        | awk -v ref="refs/heads/$RELEASE_BRANCH" \
            '$2 == ref { print $1; exit }')"
    printf '%s\n' "${oid:-missing}"
}

read_remote_tag_oid() {
    local refs="$1"

    awk -v ref="refs/tags/$RELEASE_VERSION" \
        '$2 == ref { print $1; exit }' <<<"$refs"
}

read_remote_tag_commit() {
    local refs="$1"
    local object_oid peeled_oid

    object_oid="$(read_remote_tag_oid "$refs")"
    peeled_oid="$(awk -v ref="refs/tags/$RELEASE_VERSION^{}" \
        '$2 == ref { print $1; exit }' <<<"$refs")"
    printf '%s\n' "${peeled_oid:-$object_oid}"
}

expected_prerelease() {
    if [[ "$RELEASE_CHANNEL" == beta ]]; then
        printf 'true\n'
    else
        printf 'false\n'
    fi
}

cleanup_incomplete_snapshot() {
    if [[ "$RELEASE_RUN_MODE" == new \
        && ! -f "$RELEASE_REPLACEMENT_METADATA_PATH" ]]; then
        case "$RELEASE_REPLACEMENT_DIR" in
            "$RELEASE_DIR/replacement")
                rm -rf "$RELEASE_REPLACEMENT_DIR"
                ;;
        esac
    fi
}

validate_frozen_draft_json() {
    local json_path="$1"
    local compare_updated_at="${2:-yes}"

    [[ "$(json_field "$json_path" id)" == "$REPLACEMENT_DRAFT_ID" ]] \
        || release_fail "GitHub Draft database ID changed during replacement"
    [[ "$(json_field "$json_path" tag_name)" == "$RELEASE_VERSION" ]] \
        || release_fail "GitHub Draft tag changed during replacement"
    [[ "$(json_field "$json_path" draft)" == true ]] \
        || release_fail "$RELEASE_VERSION is no longer a Draft"
    [[ "$(json_field "$json_path" prerelease)" \
        == "$(expected_prerelease)" ]] \
        || release_fail "GitHub Draft prerelease state changed"
    [[ "$(json_field "$json_path" created_at)" \
        == "$REPLACEMENT_DRAFT_CREATED_AT" ]] \
        || release_fail "GitHub Draft creation identity changed"
    if [[ "$compare_updated_at" == yes ]]; then
        [[ "$(json_field "$json_path" updated_at)" \
            == "$REPLACEMENT_DRAFT_UPDATED_AT" ]] \
            || release_fail "GitHub Draft changed after replacement started"
    fi
}

require_version_absent_from_public_appcast() {
    local appcast_path count

    appcast_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/appcast.XXXXXX")"
    gh api \
        -H 'Accept: application/vnd.github.raw+json' \
        "repos/$RELEASE_REPOSITORY/contents/appcast.xml?ref=$RELEASE_MAIN_BRANCH" \
        >"$appcast_path"
    count="$(xmllint --xpath \
        "count(//*[local-name()='shortVersionString' and text()='$RELEASE_VERSION'])" \
        "$appcast_path")"
    rm -f "$appcast_path"
    [[ "$count" == 0 ]] \
        || release_fail "$RELEASE_VERSION is already present in the public appcast"
}

snapshot_replacement() {
    local top_release_path refs
    local draft_id draft_node_id draft_tag draft_state draft_prerelease
    local draft_created_at draft_updated_at
    local local_tag_oid local_tag_commit remote_tag_oid remote_tag_commit
    local remote_release_oid
    local temporary_path

    if ! release_is_replacement; then
        release_log "ordinary Draft; no replacement snapshot required"
        return
    fi
    if [[ -e "$RELEASE_REPLACEMENT_DIR" ]]; then
        if [[ "$RELEASE_RUN_MODE" == new ]]; then
            release_fail \
                "unfinished Draft replacement exists; resume its asc run instead of starting another replacement"
        fi
        if [[ -f "$RELEASE_REPLACEMENT_METADATA_PATH" ]]; then
            load_replacement_metadata
            release_log "reusing frozen Draft replacement identity"
            return
        fi
    fi

    mkdir -p "$RELEASE_REPLACEMENT_DIR"
    trap cleanup_incomplete_snapshot EXIT
    require_release_file "$RELEASE_METADATA_PATH"
    load_release_metadata

    top_release_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/release.XXXXXX")"
    gh api "repos/$RELEASE_REPOSITORY/releases?per_page=1" \
        >"$top_release_path"
    draft_id="$(json_field "$top_release_path" id)"
    draft_node_id="$(json_field "$top_release_path" node_id)"
    draft_tag="$(json_field "$top_release_path" tag_name)"
    draft_state="$(json_field "$top_release_path" draft)"
    draft_prerelease="$(json_field "$top_release_path" prerelease)"
    draft_created_at="$(json_field "$top_release_path" created_at)"
    draft_updated_at="$(json_field "$top_release_path" updated_at)"

    [[ "$draft_id" =~ ^[0-9]+$ ]] \
        || release_fail "latest GitHub release has no valid database ID"
    [[ "$draft_tag" == "$RELEASE_VERSION" ]] \
        || release_fail "$RELEASE_VERSION is not the latest GitHub Release entry"
    [[ "$draft_state" == true ]] \
        || release_fail "$RELEASE_VERSION is not a GitHub Draft"
    [[ "$draft_prerelease" == "$(expected_prerelease)" ]] \
        || release_fail "GitHub Draft prerelease state does not match the channel"
    [[ -n "$draft_node_id" && -n "$draft_created_at" \
        && -n "$draft_updated_at" ]] \
        || release_fail "GitHub Draft identity is incomplete"

    python3 - "$top_release_path" \
        "$RELEASE_REPLACEMENT_DRAFT_SNAPSHOT_PATH" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    releases = json.load(handle)
with open(sys.argv[2], "w", encoding="utf-8") as handle:
    json.dump(releases[0], handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY

    require_version_absent_from_public_appcast

    git -C "$RELEASE_SOURCE_ROOT" show-ref --verify --quiet \
        "refs/tags/$RELEASE_VERSION" \
        || release_fail "local tag $RELEASE_VERSION was not found"
    local_tag_oid="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/tags/$RELEASE_VERSION")"
    local_tag_commit="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/tags/$RELEASE_VERSION^{commit}")"
    refs="$(remote_tag_oids)"
    remote_tag_oid="$(read_remote_tag_oid "$refs")"
    remote_tag_commit="$(read_remote_tag_commit "$refs")"
    [[ "$remote_tag_oid" =~ ^[0-9a-f]{40}$ \
        && "$remote_tag_commit" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "remote tag $RELEASE_VERSION is missing or invalid"
    [[ "$local_tag_oid" == "$remote_tag_oid" \
        && "$local_tag_commit" == "$remote_tag_commit" ]] \
        || release_fail "local and remote $RELEASE_VERSION tags do not match"
    [[ "$RELEASE_VERSION_COMMIT" == "$remote_tag_commit" ]] \
        || release_fail "saved release commit does not match the existing Tag"
    remote_release_oid="$(remote_release_branch_oid)"

    temporary_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/metadata.XXXXXX")"
    {
        printf 'REPLACEMENT_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'REPLACEMENT_CHANNEL=%q\n' "$RELEASE_CHANNEL"
        printf 'REPLACEMENT_DRAFT_ID=%q\n' "$draft_id"
        printf 'REPLACEMENT_DRAFT_NODE_ID=%q\n' "$draft_node_id"
        printf 'REPLACEMENT_DRAFT_CREATED_AT=%q\n' "$draft_created_at"
        printf 'REPLACEMENT_DRAFT_UPDATED_AT=%q\n' "$draft_updated_at"
        printf 'REPLACEMENT_OLD_BUILD=%q\n' "$RELEASE_SAVED_BUILD"
        printf 'REPLACEMENT_OLD_VERSION_COMMIT=%q\n' \
            "$RELEASE_VERSION_COMMIT"
        printf 'REPLACEMENT_OLD_TAG_OID=%q\n' "$remote_tag_oid"
        printf 'REPLACEMENT_OLD_TAG_COMMIT=%q\n' "$remote_tag_commit"
        printf 'REPLACEMENT_OLD_RELEASE_BRANCH_OID=%q\n' \
            "$remote_release_oid"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_REPLACEMENT_METADATA_PATH"
    trap - EXIT
    rm -f "$top_release_path"
    release_log \
        "frozen latest GitHub Draft $RELEASE_VERSION (database ID $draft_id)"
}

revalidate_replacement() {
    local current_path top_path refs remote_tag_oid remote_release_oid

    if ! release_is_replacement; then
        release_log "ordinary Draft; no replacement revalidation required"
        return
    fi
    load_replacement_metadata
    if replacement_is_complete refs-replaced; then
        release_log "replacement refs are already updated"
        return
    fi

    current_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/current.XXXXXX")"
    top_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/top.XXXXXX")"
    gh api "repos/$RELEASE_REPOSITORY/releases/$REPLACEMENT_DRAFT_ID" \
        >"$current_path"
    gh api "repos/$RELEASE_REPOSITORY/releases?per_page=1" >"$top_path"
    validate_frozen_draft_json "$current_path" yes
    [[ "$(json_field "$top_path" id)" == "$REPLACEMENT_DRAFT_ID" ]] \
        || release_fail "the Draft being replaced is no longer the latest Release entry"

    refs="$(remote_tag_oids)"
    remote_tag_oid="$(read_remote_tag_oid "$refs")"
    [[ "$remote_tag_oid" == "$REPLACEMENT_OLD_TAG_OID" ]] \
        || release_fail "remote Tag changed after replacement started"
    remote_release_oid="$(remote_release_branch_oid)"
    [[ "$remote_release_oid" == "$REPLACEMENT_OLD_RELEASE_BRANCH_OID" ]] \
        || release_fail "remote release branch changed after replacement started"
    rm -f "$current_path" "$top_path"
    release_log "Draft, release branch, and Tag replacement identity is still unchanged"
}

delete_replaced_draft() {
    local current_path top_path remaining_id

    if ! release_is_replacement; then
        release_log "ordinary Draft; no old Draft deletion required"
        return
    fi
    load_replacement_metadata
    replacement_is_complete refs-replaced \
        || release_fail "refusing to delete the old Draft before refs are replaced"
    if replacement_is_complete draft-deleted; then
        release_log "old GitHub Draft is already deleted"
        return
    fi

    current_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/delete.XXXXXX")"
    top_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/delete-top.XXXXXX")"
    if gh api "repos/$RELEASE_REPOSITORY/releases/$REPLACEMENT_DRAFT_ID" \
        >"$current_path" 2>/dev/null; then
        validate_frozen_draft_json "$current_path" yes
        gh api "repos/$RELEASE_REPOSITORY/releases?per_page=1" >"$top_path"
        [[ "$(json_field "$top_path" id)" == "$REPLACEMENT_DRAFT_ID" ]] \
            || release_fail "the Draft being replaced is no longer the latest Release entry"
        release_log \
            "deleting replaced GitHub Draft database ID $REPLACEMENT_DRAFT_ID"
        gh api --method DELETE \
            "repos/$RELEASE_REPOSITORY/releases/$REPLACEMENT_DRAFT_ID"
    else
        remaining_id="$(gh api --paginate \
            "repos/$RELEASE_REPOSITORY/releases?per_page=100" \
            --jq ".[] | select(.id == $REPLACEMENT_DRAFT_ID) | .id")"
        [[ -z "$remaining_id" ]] \
            || release_fail "could not read the frozen GitHub Draft by database ID"
        if gh release view "$RELEASE_VERSION" \
            --repo "$RELEASE_REPOSITORY" >/dev/null 2>&1; then
            release_fail "another GitHub Release now occupies $RELEASE_VERSION"
        fi
        release_log "old GitHub Draft was already deleted"
    fi
    rm -f "$current_path" "$top_path"

    remaining_id="$(gh api --paginate \
        "repos/$RELEASE_REPOSITORY/releases?per_page=100" \
        --jq ".[] | select(.id == $REPLACEMENT_DRAFT_ID) | .id")"
    [[ -z "$remaining_id" ]] \
        || release_fail "old GitHub Draft still exists after deletion"
    mark_replacement_complete draft-deleted
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        snapshot)
            release_set_step "snapshot_draft_replacement"
            snapshot_replacement
            ;;
        revalidate)
            release_set_step "revalidate_draft_replacement"
            revalidate_replacement
            ;;
        delete-draft)
            release_set_step "delete_replaced_github_draft"
            delete_replaced_draft
            ;;
        *)
            release_fail \
                "usage: release-redraft.sh snapshot|revalidate|delete-draft"
            ;;
    esac
}

main "$@"
