#!/usr/bin/env bash

# Verifies release artifacts locally and confirms that the published GitHub
# release, Git refs, and Sparkle feed agree after publication.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

verify_signature() {
    local file_path="$1"

    codesign --verify --deep --strict --verbose=2 "$file_path"
}

verify_staple() {
    local file_path="$1"

    xcrun stapler validate "$file_path"
}

verify_checksums() {
    (
        cd "$RELEASE_ARTIFACT_DIR"
        shasum -a 256 -c "$(basename "$RELEASE_CHECKSUM_PATH")"
    )
}

verify_local_appcast() {
    python3 "$SCRIPT_DIR/release-appcast.py" validate \
        --original "$RELEASE_WORKTREE/appcast.xml" \
        --appcast "$RELEASE_APPCAST_PATH" \
        --archive "$RELEASE_ZIP_PATH" \
        --version "$RELEASE_SAVED_VERSION" \
        --build "$RELEASE_SAVED_BUILD" \
        --channel "$RELEASE_SAVED_CHANNEL" \
        --release-notes-url "$(release_notes_url)" \
        --download-url "$(release_download_prefix)Easydict.zip"
}

verify_zip_contents() {
    local extracted_app="$RELEASE_VERIFY_DIR/Easydict.app"

    safe_reset_release_dir "$RELEASE_VERIFY_DIR"
    ditto -x -k "$RELEASE_ZIP_PATH" "$RELEASE_VERIFY_DIR"
    require_release_dir "$extracted_app"
    verify_signature "$extracted_app"
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

    verify_signature "$RELEASE_APP_PATH"
    verify_staple "$RELEASE_APP_PATH"
    spctl --assess --type execute --verbose=2 "$RELEASE_APP_PATH"
    verify_signature "$RELEASE_DMG_PATH"
    verify_staple "$RELEASE_DMG_PATH"
    hdiutil verify "$RELEASE_DMG_PATH"
    verify_checksums
    verify_zip_contents
    verify_local_appcast

    release_log "local release artifacts verified"
}

fetch_published_refs() {
    git -C "$RELEASE_SOURCE_ROOT" fetch "$RELEASE_REMOTE" \
        "+refs/heads/$RELEASE_DEV_BRANCH:refs/remotes/$RELEASE_REMOTE/$RELEASE_DEV_BRANCH" \
        "+refs/heads/$RELEASE_MAIN_BRANCH:refs/remotes/$RELEASE_REMOTE/$RELEASE_MAIN_BRANCH" \
        "+refs/tags/$RELEASE_VERSION:refs/tags/$RELEASE_VERSION"
}

verify_published_refs() {
    local release_head dev_head main_head tag_head

    fetch_published_refs
    release_head="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    dev_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/remotes/$RELEASE_REMOTE/$RELEASE_DEV_BRANCH")"
    main_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
        "refs/remotes/$RELEASE_REMOTE/$RELEASE_MAIN_BRANCH")"
    tag_head="$(git -C "$RELEASE_SOURCE_ROOT" rev-list -n 1 \
        "refs/tags/$RELEASE_VERSION")"

    [[ "$dev_head" == "$release_head" ]] \
        || release_fail "$RELEASE_DEV_BRANCH does not match release HEAD"
    [[ "$main_head" == "$release_head" ]] \
        || release_fail "$RELEASE_MAIN_BRANCH does not match release HEAD"
    [[ "$tag_head" == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "release tag does not point to the version commit"
}

validate_remote_appcast() {
    python3 "$SCRIPT_DIR/release-appcast.py" validate \
        --original "$RELEASE_WORKTREE/appcast.xml" \
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
        verify_local
        ;;
    remote)
        verify_remote
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
