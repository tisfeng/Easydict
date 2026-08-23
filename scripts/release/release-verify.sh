#!/usr/bin/env bash

# Verifies release artifacts locally and confirms that the published GitHub
# release, Git refs, and Sparkle feed agree after publication.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

verify_signature() {
    local file_path="$1"
    local label="${2:-verify-signature}"

    release_capture "$label" \
        codesign --verify --deep --strict --verbose=2 "$file_path"
}

verify_staple() {
    local file_path="$1"
    local label="${2:-verify-staple}"

    release_capture "$label" xcrun stapler validate "$file_path"
}

verify_checksums() {
    (
        cd "$RELEASE_ARTIFACT_DIR"
        shasum -a 256 -c "$(basename "$RELEASE_CHECKSUM_PATH")"
    )
}

verify_local_appcast() {
    local -a transition_args=()

    if [[ -f "$RELEASE_CHANNEL_TRANSITION_PATH" ]]; then
        load_release_channel_transition
        if [[ -n "$RELEASE_PREVIOUS_BETA_VERSION" ]]; then
            transition_args+=(
                --previous-beta-version "$RELEASE_PREVIOUS_BETA_VERSION"
            )
        fi
    fi

    python3 "$SCRIPT_DIR/release-appcast.py" validate \
        --original "$RELEASE_WORKTREE/appcast.xml" \
        --appcast "$RELEASE_APPCAST_PATH" \
        --archive "$RELEASE_ZIP_PATH" \
        --version "$RELEASE_SAVED_VERSION" \
        --build "$RELEASE_SAVED_BUILD" \
        --channel "$RELEASE_SAVED_CHANNEL" \
        --release-notes-url "$(release_notes_url)" \
        --download-url "$(release_download_prefix)Easydict.zip" \
        "${transition_args[@]}"
}

verify_zip_contents() {
    local extracted_app="$RELEASE_VERIFY_DIR/Easydict.app"

    safe_reset_release_dir "$RELEASE_VERIFY_DIR"
    ditto -x -k "$RELEASE_ZIP_PATH" "$RELEASE_VERIFY_DIR"
    require_release_dir "$extracted_app"
    verify_signature "$extracted_app" "verify-zip-signature"
    release_capture "assess-zip-app" \
        spctl --assess --type execute --verbose=2 "$extracted_app"
}

# Reopens every generated artifact before any remote refs are changed.
verify_local() {
    require_release_version
    load_release_metadata
    require_release_worktree
    require_release_dir "$RELEASE_APP_PATH"
    require_release_file "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_DMG_PATH"
    require_release_file "$RELEASE_CHECKSUM_PATH"
    require_release_file "$RELEASE_APPCAST_PATH"

    verify_signature "$RELEASE_APP_PATH" "verify-app-signature"
    verify_staple "$RELEASE_APP_PATH" "verify-app-staple"
    release_capture "assess-app" \
        spctl --assess --type execute --verbose=2 "$RELEASE_APP_PATH"
    verify_signature "$RELEASE_DMG_PATH" "verify-dmg-signature"
    verify_staple "$RELEASE_DMG_PATH" "verify-dmg-staple"
    release_capture "verify-dmg-container" hdiutil verify "$RELEASE_DMG_PATH"
    verify_checksums
    verify_zip_contents
    verify_local_appcast

    release_log "local release artifacts verified"
}

fetch_published_refs() {
    git -C "$RELEASE_SOURCE_ROOT" fetch "$RELEASE_REMOTE" \
        "+refs/heads/$RELEASE_DEV_BRANCH:refs/remotes/$RELEASE_REMOTE/$RELEASE_DEV_BRANCH" \
        "+refs/heads/$RELEASE_MAIN_BRANCH:refs/remotes/$RELEASE_REMOTE/$RELEASE_MAIN_BRANCH" \
        "+refs/heads/$RELEASE_BRANCH:refs/remotes/$RELEASE_REMOTE/$RELEASE_BRANCH" \
        "+refs/tags/$RELEASE_VERSION:refs/tags/$RELEASE_VERSION"
}

verify_published_refs() {
    local release_head dev_head local_dev_head main_head temporary_head tag_head

    load_publish_git_metadata
    fetch_published_refs
    release_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    local_dev_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/heads/$RELEASE_DEV_BRANCH")"
    dev_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/remotes/$RELEASE_REMOTE/$RELEASE_DEV_BRANCH")"
    main_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/remotes/$RELEASE_REMOTE/$RELEASE_MAIN_BRANCH")"
    temporary_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/remotes/$RELEASE_REMOTE/$RELEASE_BRANCH")"
    tag_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-list -n 1 \
        "refs/tags/$RELEASE_VERSION")"

    [[ "$release_head" == "$PUBLISH_APPCAST_COMMIT" ]] \
        || release_fail "release worktree does not match the saved appcast commit"
    [[ "$local_dev_head" == "$PUBLISH_INTEGRATION_HEAD" \
        && "$dev_head" == "$PUBLISH_INTEGRATION_HEAD" ]] \
        || release_fail "local and remote dev do not match publish integration"
    [[ "$main_head" == "$PUBLISH_APPCAST_COMMIT" ]] \
        || release_fail "$RELEASE_MAIN_BRANCH does not match the appcast commit"
    [[ "$temporary_head" == "$PUBLISH_APPCAST_COMMIT" ]] \
        || release_fail "$RELEASE_BRANCH does not match the appcast commit"
    [[ "$tag_head" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "release tag does not point to the version commit"
    git -C "$RELEASE_SOURCE_ROOT" merge-base --is-ancestor \
        "$PUBLISH_APPCAST_COMMIT" "$PUBLISH_INTEGRATION_HEAD" \
        || release_fail "publish integration does not contain the appcast commit"
}

validate_remote_appcast() {
    python3 "$SCRIPT_DIR/release-appcast.py" validate \
        --original "$RELEASE_APPCAST_PATH" \
        --appcast "$RELEASE_VERIFY_DIR/remote-appcast.xml" \
        --archive "$RELEASE_ZIP_PATH" \
        --version "$RELEASE_SAVED_VERSION" \
        --build "$RELEASE_SAVED_BUILD" \
        --channel "$RELEASE_SAVED_CHANNEL" \
        --release-notes-url "$(release_notes_url)" \
        --download-url "$(release_download_prefix)Easydict.zip"
}

# Allows for raw-content propagation while requiring an exact valid feed.
verify_remote_appcast() {
    local attempt
    local appcast_url

    mkdir -p "$RELEASE_VERIFY_DIR"
    appcast_url="$(release_appcast_url)?release=$RELEASE_VERSION"
    for attempt in 1 2 3 4 5 6; do
        curl --fail --silent --show-error --location \
            "$appcast_url&attempt=$attempt" \
            --output "$RELEASE_VERIFY_DIR/remote-appcast.xml"
        if validate_remote_appcast; then
            return
        fi
        if ((attempt < 6)); then
            release_log "remote appcast is not current yet; retrying"
            sleep 5
        fi
    done

    release_fail "published appcast did not converge"
}

verify_asset_urls() {
    local asset_name

    for asset_name in Easydict.zip Easydict.dmg SHA256SUMS.txt; do
        curl --fail --silent --show-error --location --head \
            "$(release_download_prefix)$asset_name" >/dev/null
    done
}

# Downloads the small checksum asset and compares its content byte-for-byte.
verify_remote_checksum() {
    local remote_checksum="$RELEASE_VERIFY_DIR/remote-SHA256SUMS.txt"

    gh release download "$RELEASE_VERSION" \
        --repo "$RELEASE_REPOSITORY" \
        --pattern SHA256SUMS.txt \
        --output "$remote_checksum" \
        --clobber
    cmp -s "$RELEASE_CHECKSUM_PATH" "$remote_checksum" \
        || release_fail "published checksum file differs from the local file"
}

# Confirms all external surfaces converge before cleanup is allowed.
verify_remote() {
    require_release_version
    load_release_metadata
    require_release_worktree
    "$SCRIPT_DIR/release-github.sh" verify-published
    "$SCRIPT_DIR/release-github.sh" verify-previous
    verify_published_refs
    verify_remote_appcast
    verify_remote_checksum
    verify_asset_urls
    release_log "published release, refs, assets, and appcast verified"
}

usage() {
    printf 'Usage: %s <local|remote>\n' "$(basename "$0")"
}

case "${1:-}" in
    local)
        release_set_step "verify_local_release"
        verify_local
        ;;
    remote)
        release_set_step "verify_remote_release"
        verify_remote
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
