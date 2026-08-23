#!/usr/bin/env bash

# Creates and verifies a GitHub draft release, uploads immutable local
# artifacts, and publishes the draft after all remote checks pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

release_exists_for_version() {
    local version="$1"

    gh release view "$version" \
        --repo "$RELEASE_REPOSITORY" >/dev/null 2>&1
}

release_exists() {
    release_exists_for_version "$RELEASE_VERSION"
}

release_field_for_version() {
    local version="$1"
    local field="$2"

    gh release view "$version" \
        --repo "$RELEASE_REPOSITORY" \
        --json "$field" \
        --jq ".$field"
}

release_field() {
    release_field_for_version "$RELEASE_VERSION" "$1"
}

remote_asset_size() {
    local asset_name="$1"

    gh release view "$RELEASE_VERSION" \
        --repo "$RELEASE_REPOSITORY" \
        --json assets \
        --jq ".assets[] | select(.name == \"$asset_name\") | .size"
}

ensure_release_asset() {
    local asset_path="$1"
    local asset_name local_size remote_size

    asset_name="$(basename "$asset_path")"
    local_size="$(release_file_size "$asset_path")"
    remote_size="$(remote_asset_size "$asset_name")"
    if [[ -z "$remote_size" ]]; then
        release_log "uploading missing release asset: $asset_name"
        gh release upload "$RELEASE_VERSION" "$asset_path" \
            --repo "$RELEASE_REPOSITORY"
    elif [[ "$remote_size" != "$local_size" ]]; then
        release_fail "$asset_name exists with a different size"
    fi
}

# Requires every remote asset to match the immutable local artifact size.
verify_assets() {
    local asset_path asset_name local_size remote_size

    for asset_path in \
        "$RELEASE_ZIP_PATH" \
        "$RELEASE_DMG_PATH" \
        "$RELEASE_CHECKSUM_PATH"; do
        require_release_file "$asset_path"
        asset_name="$(basename "$asset_path")"
        local_size="$(release_file_size "$asset_path")"
        remote_size="$(remote_asset_size "$asset_name")"
        [[ "$remote_size" == "$local_size" ]] \
            || release_fail "$asset_name is missing or has the wrong size"
    done
}

verify_release_state() {
    local expected_draft="$1"
    local expected_prerelease=false

    [[ "$(release_field tagName)" == "$RELEASE_VERSION" ]] \
        || release_fail "GitHub release tag does not match $RELEASE_VERSION"
    [[ "$(release_field isDraft)" == "$expected_draft" ]] \
        || release_fail "GitHub release draft state is unexpected"
    if [[ "$RELEASE_CHANNEL" == beta ]]; then
        expected_prerelease=true
    fi
    [[ "$(release_field isPrerelease)" == "$expected_prerelease" ]] \
        || release_fail "GitHub prerelease state does not match the channel"
    verify_assets
}

verify_previous_release_ready() {
    load_release_channel_transition
    if [[ -z "$RELEASE_PREVIOUS_BETA_VERSION" ]]; then
        return
    fi

    release_exists_for_version "$RELEASE_PREVIOUS_BETA_VERSION" \
        || release_fail \
            "previous beta release not found: $RELEASE_PREVIOUS_BETA_VERSION"
    [[ "$(release_field_for_version \
        "$RELEASE_PREVIOUS_BETA_VERSION" tagName)" \
        == "$RELEASE_PREVIOUS_BETA_VERSION" ]] \
        || release_fail "previous beta release tag is unexpected"
    [[ "$(release_field_for_version \
        "$RELEASE_PREVIOUS_BETA_VERSION" isDraft)" == false ]] \
        || release_fail "previous beta release is still a draft"
}

verify_previous_release_promoted() {
    verify_previous_release_ready
    if [[ -z "$RELEASE_PREVIOUS_BETA_VERSION" ]]; then
        return
    fi

    [[ "$(release_field_for_version \
        "$RELEASE_PREVIOUS_BETA_VERSION" isPrerelease)" == false ]] \
        || release_fail "previous beta release is still marked as a prerelease"
}

promote_previous_release() {
    verify_previous_release_ready
    if [[ -z "$RELEASE_PREVIOUS_BETA_VERSION" ]]; then
        release_log "no previous GitHub prerelease requires promotion"
        return
    fi

    if [[ "$(release_field_for_version \
        "$RELEASE_PREVIOUS_BETA_VERSION" isPrerelease)" == true ]]; then
        release_log \
            "promoting GitHub release $RELEASE_PREVIOUS_BETA_VERSION to stable"
        gh release edit "$RELEASE_PREVIOUS_BETA_VERSION" \
            --repo "$RELEASE_REPOSITORY" \
            --prerelease=false
    else
        release_log \
            "GitHub release $RELEASE_PREVIOUS_BETA_VERSION is already stable"
    fi
    verify_previous_release_promoted
}

record_replacement_draft() {
    local draft_id temporary_path

    if ! release_is_replacement; then
        return
    fi
    load_replacement_metadata
    draft_id="$(release_field databaseId)"
    [[ "$draft_id" =~ ^[0-9]+$ ]] \
        || release_fail "new GitHub Draft database ID is invalid"
    [[ "$draft_id" != "$REPLACEMENT_DRAFT_ID" ]] \
        || release_fail "GitHub returned the old Draft during replacement"

    temporary_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/new-draft.XXXXXX")"
    {
        printf 'REPLACEMENT_NEW_DRAFT_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'REPLACEMENT_NEW_DRAFT_ID=%q\n' "$draft_id"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_REPLACEMENT_NEW_DRAFT_PATH"
    mark_replacement_complete new-draft-created
}

# Creates the immutable draft or fills only assets that are still absent.
create_draft() {
    local asset_path
    local -a command

    load_release_metadata
    if release_is_replacement; then
        load_replacement_metadata
        replacement_is_complete draft-deleted \
            || release_fail "old GitHub Draft must be deleted before creating its replacement"
    fi
    require_release_file "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_DMG_PATH"
    require_release_file "$RELEASE_CHECKSUM_PATH"

    if release_exists; then
        [[ "$(release_field isDraft)" == true ]] \
            || release_fail "$RELEASE_VERSION is already published"
        if release_is_replacement; then
            [[ "$(release_field databaseId)" \
                != "$REPLACEMENT_DRAFT_ID" ]] \
                || release_fail "old GitHub Draft still occupies $RELEASE_VERSION"
        fi
        for asset_path in \
            "$RELEASE_ZIP_PATH" \
            "$RELEASE_DMG_PATH" \
            "$RELEASE_CHECKSUM_PATH"; do
            ensure_release_asset "$asset_path"
        done
        record_replacement_draft
        return
    fi

    command=(
        gh release create "$RELEASE_VERSION"
        "$RELEASE_ZIP_PATH"
        "$RELEASE_DMG_PATH"
        "$RELEASE_CHECKSUM_PATH"
        --repo "$RELEASE_REPOSITORY"
        --title "Easydict $RELEASE_VERSION"
        --draft
        --verify-tag
    )
    if [[ "$RELEASE_CHANNEL" == beta ]]; then
        command+=(--prerelease)
    fi
    if [[ -n "$RELEASE_NOTES_FILE" ]]; then
        command+=(--notes-file "$RELEASE_NOTES_FILE")
    else
        command+=(--generate-notes)
    fi

    release_log "creating GitHub draft release"
    "${command[@]}"
    record_replacement_draft
}

# Publishing is idempotent so an interrupted asc step can safely resume.
publish_release() {
    if [[ "$(release_field isDraft)" == true ]]; then
        verify_release_state true
        release_log "publishing GitHub release $RELEASE_VERSION"
        gh release edit "$RELEASE_VERSION" \
            --repo "$RELEASE_REPOSITORY" \
            --draft=false
    else
        verify_release_state false
        release_log "GitHub release $RELEASE_VERSION is already published"
    fi
}

verify_ready() {
    if [[ "$(release_field isDraft)" == true ]]; then
        verify_release_state true
    else
        verify_release_state false
    fi
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        draft)
            release_set_step "create_github_draft"
            create_draft
            ;;
        verify-draft)
            release_set_step "verify_github_draft"
            load_release_metadata
            verify_release_state true
            ;;
        verify-ready)
            release_set_step "verify_github_release_ready"
            load_release_metadata
            verify_ready
            ;;
        verify-previous-ready)
            release_set_step "verify_previous_github_release_ready"
            load_release_metadata
            verify_previous_release_ready
            ;;
        publish)
            release_set_step "publish_github_release"
            load_release_metadata
            publish_release
            ;;
        verify-published)
            release_set_step "verify_github_release"
            load_release_metadata
            verify_release_state false
            ;;
        promote-previous)
            release_set_step "promote_previous_github_release"
            load_release_metadata
            promote_previous_release
            ;;
        verify-previous)
            release_set_step "verify_previous_github_release"
            load_release_metadata
            verify_previous_release_promoted
            ;;
        *)
            release_fail \
                "usage: release-github.sh draft|verify-draft|verify-ready|verify-previous-ready|publish|verify-published|promote-previous|verify-previous"
            ;;
    esac
}

main "$@"
