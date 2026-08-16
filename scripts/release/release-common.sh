#!/usr/bin/env bash

# Shared paths, configuration, and safety helpers for the Easydict release
# workflow. This file is sourced by the focused release stage scripts.

set -euo pipefail

RELEASE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SOURCE_ROOT="$(cd "$RELEASE_SCRIPT_DIR/../.." && pwd)"

RELEASE_REMOTE="${RELEASE_REMOTE:-origin}"
RELEASE_REPOSITORY="${RELEASE_REPOSITORY:-tisfeng/Easydict}"
RELEASE_DEV_BRANCH="${RELEASE_DEV_BRANCH:-dev}"
RELEASE_MAIN_BRANCH="${RELEASE_MAIN_BRANCH:-main}"
RELEASE_TEAM_ID="${RELEASE_TEAM_ID:-45Z6V4YD5U}"
DEFAULT_RELEASE_IDENTITY="Developer ID Application: Canglong Dai (45Z6V4YD5U)"
RELEASE_SIGN_IDENTITY="${RELEASE_SIGN_IDENTITY:-$DEFAULT_RELEASE_IDENTITY}"
RELEASE_SPARKLE_ACCOUNT="${RELEASE_SPARKLE_ACCOUNT:-ed25519}"

RELEASE_VERSION="${VERSION:-}"
RELEASE_CHANNEL="${CHANNEL:-beta}"
RELEASE_BUILD_OVERRIDE="${BUILD_NUMBER:-}"
RELEASE_NOTES_FILE="${NOTES_FILE:-}"

RELEASE_WORKFLOW_PATH="$RELEASE_SOURCE_ROOT/scripts/release/asc-workflow.json"
RELEASE_EXPORT_OPTIONS="$RELEASE_SCRIPT_DIR/export-options.plist"
RELEASE_PROJECT_PATH="Easydict.xcodeproj"
RELEASE_WORKSPACE_PATH="Easydict.xcworkspace"
RELEASE_SCHEME="Easydict"
RELEASE_TARGET="Easydict"

if [[ -n "$RELEASE_VERSION" ]]; then
    RELEASE_DIR="$RELEASE_SOURCE_ROOT/.tmp/release/$RELEASE_VERSION"
    RELEASE_WORKTREE="$RELEASE_DIR/worktree"
    RELEASE_BRANCH="release/sync-$RELEASE_VERSION"
    RELEASE_STATE_DIR="$RELEASE_DIR/state"
    RELEASE_METADATA_PATH="$RELEASE_STATE_DIR/release.env"
    RELEASE_ARCHIVE_PATH="$RELEASE_DIR/Easydict.xcarchive"
    RELEASE_DERIVED_DATA="$RELEASE_DIR/derived-data"
    RELEASE_EXPORT_DIR="$RELEASE_DIR/export"
    RELEASE_APP_PATH="$RELEASE_EXPORT_DIR/Easydict.app"
    RELEASE_ARTIFACT_DIR="$RELEASE_DIR/artifacts"
    RELEASE_ZIP_PATH="$RELEASE_ARTIFACT_DIR/Easydict.zip"
    RELEASE_DMG_PATH="$RELEASE_ARTIFACT_DIR/Easydict.dmg"
    RELEASE_CHECKSUM_PATH="$RELEASE_ARTIFACT_DIR/SHA256SUMS.txt"
    RELEASE_NOTARY_ZIP="$RELEASE_DIR/Easydict-notarization.zip"
    RELEASE_APPCAST_DIR="$RELEASE_DIR/appcast"
    RELEASE_APPCAST_PATH="$RELEASE_APPCAST_DIR/appcast.xml"
    RELEASE_VERIFY_DIR="$RELEASE_DIR/verify"
fi

release_log() {
    printf '[release] %s\n' "$*"
}

release_fail() {
    printf '[release] error: %s\n' "$*" >&2
    exit 1
}

require_release_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1 \
        || release_fail "required command not found: $command_name"
}

require_release_file() {
    local file_path="$1"

    [[ -f "$file_path" ]] \
        || release_fail "required file not found: $file_path"
}

require_release_dir() {
    local directory_path="$1"

    [[ -d "$directory_path" ]] \
        || release_fail "required directory not found: $directory_path"
}

require_release_version() {
    [[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
        || release_fail "VERSION must use x.y.z format"

    case "$RELEASE_CHANNEL" in
        beta | stable)
            ;;
        *)
            release_fail "CHANNEL must be beta or stable"
            ;;
    esac

    if [[ -n "$RELEASE_BUILD_OVERRIDE" ]]; then
        [[ "$RELEASE_BUILD_OVERRIDE" =~ ^[0-9]+$ ]] \
            || release_fail "BUILD_NUMBER must be a positive integer"
        ((10#$RELEASE_BUILD_OVERRIDE > 0)) \
            || release_fail "BUILD_NUMBER must be greater than zero"
    fi
}

integer_is_greater() {
    local candidate="$1"
    local current="$2"

    [[ "$candidate" =~ ^[0-9]+$ && "$current" =~ ^[0-9]+$ ]] \
        || return 1
    ((10#$candidate > 10#$current))
}

version_is_greater() {
    local candidate="$1"
    local current="$2"
    local candidate_major candidate_minor candidate_patch
    local current_major current_minor current_patch

    IFS=. read -r candidate_major candidate_minor candidate_patch \
        <<<"$candidate"
    IFS=. read -r current_major current_minor current_patch <<<"$current"

    if ((10#$candidate_major != 10#$current_major)); then
        ((10#$candidate_major > 10#$current_major))
    elif ((10#$candidate_minor != 10#$current_minor)); then
        ((10#$candidate_minor > 10#$current_minor))
    else
        ((10#$candidate_patch > 10#$current_patch))
    fi
}

safe_reset_release_dir() {
    local directory_path="$1"

    case "$directory_path" in
        "$RELEASE_DIR"/*)
            ;;
        *)
            release_fail "refusing to reset path outside release directory: $directory_path"
            ;;
    esac

    rm -rf "$directory_path"
    mkdir -p "$directory_path"
}

ensure_release_layout() {
    require_release_version
    mkdir -p "$RELEASE_DIR" "$RELEASE_STATE_DIR" "$RELEASE_ARTIFACT_DIR"
}

require_release_worktree() {
    require_release_dir "$RELEASE_WORKTREE"
    git -C "$RELEASE_WORKTREE" rev-parse --is-inside-work-tree \
        >/dev/null 2>&1 \
        || release_fail "invalid release worktree: $RELEASE_WORKTREE"
}

# Persists only non-secret values needed to resume a later workflow stage.
write_release_metadata() {
    local build_number="$1"
    local version_commit="$2"

    mkdir -p "$RELEASE_STATE_DIR"
    {
        printf 'RELEASE_SAVED_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'RELEASE_SAVED_BUILD=%q\n' "$build_number"
        printf 'RELEASE_SAVED_CHANNEL=%q\n' "$RELEASE_CHANNEL"
        printf 'RELEASE_VERSION_COMMIT=%q\n' "$version_commit"
    } >"$RELEASE_METADATA_PATH"
}

# Loads the immutable version/build/channel chosen by the version stage.
load_release_metadata() {
    require_release_file "$RELEASE_METADATA_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_METADATA_PATH"

    [[ "$RELEASE_SAVED_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "release metadata belongs to another version"
    [[ "$RELEASE_SAVED_CHANNEL" == "$RELEASE_CHANNEL" ]] \
        || release_fail "release channel differs from saved metadata"
}

# Locates Sparkle's generator after Xcode has resolved package artifacts.
resolve_generate_appcast() {
    local candidate_path

    if [[ -n "${GENERATE_APPCAST:-}" ]]; then
        candidate_path="$GENERATE_APPCAST"
    elif [[ -n "${SPARKLE_BIN_DIR:-}" ]]; then
        candidate_path="$SPARKLE_BIN_DIR/generate_appcast"
    elif candidate_path="$(command -v generate_appcast 2>/dev/null)"; then
        :
    else
        candidate_path="$RELEASE_DERIVED_DATA/SourcePackages/artifacts"
        candidate_path+="/sparkle/Sparkle/bin/generate_appcast"
    fi

    [[ -x "$candidate_path" ]] \
        || release_fail "Sparkle generate_appcast not found: $candidate_path"
    printf '%s\n' "$candidate_path"
}

release_download_prefix() {
    printf 'https://github.com/tisfeng/Easydict/releases/download/%s/' \
        "$RELEASE_VERSION"
}

release_notes_url() {
    printf 'https://github.com/tisfeng/Easydict/releases/tag/%s' \
        "$RELEASE_VERSION"
}

release_appcast_url() {
    printf 'https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml'
}

release_file_size() {
    stat -f '%z' "$1"
}
