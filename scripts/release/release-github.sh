#!/usr/bin/env bash

# Creates and verifies a GitHub draft release, uploads immutable local
# artifacts, and publishes the draft after all remote checks pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

release_exists() {
    gh release view "$RELEASE_VERSION" \
        --repo "$RELEASE_REPOSITORY" >/dev/null 2>&1
}

release_field() {
    local field="$1"

    gh release view "$RELEASE_VERSION" \
        --repo "$RELEASE_REPOSITORY" \
        --json "$field" \
        --jq ".$field"
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

# Creates the immutable draft or fills only assets that are still absent.
create_draft() {
    local asset_path
    local -a command

    load_release_metadata
    require_release_file "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_DMG_PATH"
    require_release_file "$RELEASE_CHECKSUM_PATH"

    if release_exists; then
        [[ "$(release_field isDraft)" == true ]] \
            || release_fail "$RELEASE_VERSION is already published"
        for asset_path in \
            "$RELEASE_ZIP_PATH" \
            "$RELEASE_DMG_PATH" \
            "$RELEASE_CHECKSUM_PATH"; do
            ensure_release_asset "$asset_path"
        done
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
        *)
            release_fail \
                "usage: release-github.sh draft|verify-draft|verify-ready|publish|verify-published"
            ;;
    esac
}

main "$@"
