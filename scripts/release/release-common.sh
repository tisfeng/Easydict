#!/usr/bin/env bash

# Shared paths, configuration, and safety helpers for the Easydict release
# workflow. This file is sourced by the focused release stage scripts.

set -euo pipefail

RELEASE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SOURCE_ROOT="${RELEASE_SOURCE_ROOT:-$(cd "$RELEASE_SCRIPT_DIR/../.." && pwd)}"

RELEASE_REMOTE="${RELEASE_REMOTE:-origin}"
RELEASE_REPOSITORY="${RELEASE_REPOSITORY:-tisfeng/Easydict}"
RELEASE_DEV_BRANCH="${RELEASE_DEV_BRANCH:-dev}"
RELEASE_MAIN_BRANCH="${RELEASE_MAIN_BRANCH:-main}"
RELEASE_TEAM_ID="${RELEASE_TEAM_ID:-45Z6V4YD5U}"
DEFAULT_RELEASE_IDENTITY="Developer ID Application: Canglong Dai (45Z6V4YD5U)"
RELEASE_SIGN_IDENTITY="${RELEASE_SIGN_IDENTITY:-$DEFAULT_RELEASE_IDENTITY}"
RELEASE_SPARKLE_ACCOUNT="${RELEASE_SPARKLE_ACCOUNT:-ed25519}"
RELEASE_STEP="${RELEASE_STEP:-release}"
RELEASE_RUN_MODE="${RELEASE_RUN_MODE:-new}"

RELEASE_VERSION="${VERSION:-}"
RELEASE_CHANNEL="${CHANNEL:-beta}"
RELEASE_BUILD_OVERRIDE="${BUILD_NUMBER:-}"
RELEASE_NOTES_FILE="${NOTES_FILE:-}"
RELEASE_DRAFT_MODE="${DRAFT_MODE:-normal}"

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
    RELEASE_SOURCE_METADATA_PATH="$RELEASE_STATE_DIR/source.env"
    RELEASE_METADATA_PATH="$RELEASE_STATE_DIR/release.env"
    RELEASE_CHANNEL_TRANSITION_PATH="$RELEASE_STATE_DIR/channel-transition.env"
    RELEASE_DRAFT_REFS_PATH="$RELEASE_STATE_DIR/draft-refs.env"
    RELEASE_PUBLISH_GIT_PATH="$RELEASE_STATE_DIR/publish-git.env"
    RELEASE_PUBLISH_INTEGRATION_WORKTREE="$RELEASE_DIR/publish-integration"
    RELEASE_REMOTE_BRANCH_CLEANUP_MARKER="$RELEASE_STATE_DIR/remote-release-branch-cleaned.complete"
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
    RELEASE_REPLACEMENT_DIR="$RELEASE_DIR/replacement"
    RELEASE_REPLACEMENT_METADATA_PATH="$RELEASE_REPLACEMENT_DIR/metadata.env"
    RELEASE_REPLACEMENT_BUILD_PATH="$RELEASE_REPLACEMENT_DIR/build.env"
    RELEASE_REPLACEMENT_ARCHIVE_PATH="$RELEASE_REPLACEMENT_DIR/archive.env"
    RELEASE_REPLACEMENT_NEW_DRAFT_PATH="$RELEASE_REPLACEMENT_DIR/new-draft.env"
    RELEASE_REPLACEMENT_DRAFT_SNAPSHOT_PATH="$RELEASE_REPLACEMENT_DIR/github-draft.json"
    RELEASE_REPLACEMENT_BACKUP_DIR="$RELEASE_REPLACEMENT_DIR/backup"
fi

release_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

release_set_step() {
    RELEASE_STEP="$1"
    export RELEASE_STEP
}

release_log() {
    printf '[%s] [INFO] [%s] %s\n' \
        "$(release_timestamp)" "$RELEASE_STEP" "$*" >&2
}

release_error() {
    printf '[%s] [ERROR] [%s] %s\n' \
        "$(release_timestamp)" "$RELEASE_STEP" "$*" >&2
}

release_fail() {
    release_error "$*"
    exit 1
}

release_log_dir() {
    if [[ -n "${RELEASE_DIR:-}" ]]; then
        printf '%s/logs\n' "$RELEASE_DIR"
    else
        printf '%s/.tmp/release/logs\n' "$RELEASE_SOURCE_ROOT"
    fi
}

release_safe_label() {
    local label="$1"

    label="${label//[^[:alnum:]_.-]/-}"
    printf '%s\n' "$label"
}

release_command_log() {
    local label="$1"

    printf '%s/%s.%s.log\n' \
        "$(release_log_dir)" "$RELEASE_STEP" "$(release_safe_label "$label")"
}

# Runs a noisy command into a durable per-step log. Only the command summary is
# shown on success; a bounded tail is shown on failure for immediate diagnosis.
release_capture() {
    local label="$1"
    shift
    local log_path status

    mkdir -p "$(release_log_dir)"
    log_path="$(release_command_log "$label")"
    if "$@" >"$log_path" 2>&1; then
        release_log "$label completed (details: $log_path)"
        return 0
    else
        status=$?
    fi

    release_error "$label failed with exit status $status (details: $log_path)"
    printf '[%s] [ERROR] [%s] last 40 lines from %s:\n' \
        "$(release_timestamp)" "$RELEASE_STEP" "$log_path" >&2
    tail -n 40 "$log_path" >&2 || true
    return "$status"
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

    case "$RELEASE_DRAFT_MODE" in
        normal | replace)
            ;;
        *)
            release_fail "DRAFT_MODE must be normal or replace"
            ;;
    esac

    if [[ -n "$RELEASE_BUILD_OVERRIDE" ]]; then
        [[ "$RELEASE_BUILD_OVERRIDE" =~ ^[0-9]+$ ]] \
            || release_fail "BUILD_NUMBER must be a positive integer"
        ((10#$RELEASE_BUILD_OVERRIDE > 0)) \
            || release_fail "BUILD_NUMBER must be greater than zero"
    fi
}

release_is_replacement() {
    [[ "$RELEASE_DRAFT_MODE" == replace ]]
}

replacement_marker_path() {
    local marker_name="$1"

    printf '%s/%s.complete\n' "$RELEASE_REPLACEMENT_DIR" "$marker_name"
}

replacement_is_complete() {
    [[ -f "$(replacement_marker_path "$1")" ]]
}

mark_replacement_complete() {
    local marker_path

    mkdir -p "$RELEASE_REPLACEMENT_DIR"
    marker_path="$(replacement_marker_path "$1")"
    : >"$marker_path"
}

load_replacement_metadata() {
    require_release_file "$RELEASE_REPLACEMENT_METADATA_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_REPLACEMENT_METADATA_PATH"

    [[ "$REPLACEMENT_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "replacement metadata belongs to another version"
    [[ "$REPLACEMENT_CHANNEL" == "$RELEASE_CHANNEL" ]] \
        || release_fail "replacement metadata belongs to another channel"
    [[ "$REPLACEMENT_DRAFT_ID" =~ ^[0-9]+$ ]] \
        || release_fail "replacement Draft database ID is invalid"
    [[ "$REPLACEMENT_OLD_BUILD" =~ ^[0-9]+$ ]] \
        || release_fail "replacement source build is invalid"
    [[ "$REPLACEMENT_OLD_VERSION_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "replacement source commit is invalid"
    [[ "$REPLACEMENT_OLD_TAG_OID" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "replacement Tag object ID is invalid"
    [[ "$REPLACEMENT_OLD_TAG_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "replacement Tag commit is invalid"
    REPLACEMENT_OLD_RELEASE_BRANCH_OID="${REPLACEMENT_OLD_RELEASE_BRANCH_OID:-missing}"
    [[ "$REPLACEMENT_OLD_RELEASE_BRANCH_OID" == missing \
        || "$REPLACEMENT_OLD_RELEASE_BRANCH_OID" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "replacement release branch object ID is invalid"
}

load_replacement_build() {
    require_release_file "$RELEASE_REPLACEMENT_BUILD_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_REPLACEMENT_BUILD_PATH"

    [[ "$REPLACEMENT_BUILD_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "replacement build belongs to another version"
    [[ "$REPLACEMENT_BUILD_NUMBER" =~ ^[0-9]+$ ]] \
        || release_fail "replacement build number is invalid"
}

write_replacement_build() {
    local build_number="$1"
    local temporary_path

    mkdir -p "$RELEASE_REPLACEMENT_DIR"
    temporary_path="$(mktemp "$RELEASE_REPLACEMENT_DIR/build.XXXXXX")"
    {
        printf 'REPLACEMENT_BUILD_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'REPLACEMENT_BUILD_NUMBER=%q\n' "$build_number"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_REPLACEMENT_BUILD_PATH"
}

next_replacement_build() {
    local old_build="$1"
    local current_build="$2"
    local appcast_build="$3"
    local maximum

    [[ "$old_build" =~ ^[0-9]+$ \
        && "$current_build" =~ ^[0-9]+$ \
        && "$appcast_build" =~ ^[0-9]+$ ]] \
        || release_fail "replacement build inputs must be integers"

    maximum=$((10#$old_build))
    if ((10#$current_build > maximum)); then
        maximum=$((10#$current_build))
    fi
    if ((10#$appcast_build > maximum)); then
        maximum=$((10#$appcast_build))
    fi
    printf '%s\n' "$((maximum + 1))"
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
    mkdir -p \
        "$RELEASE_DIR" \
        "$RELEASE_STATE_DIR" \
        "$RELEASE_ARTIFACT_DIR" \
        "$(release_log_dir)"
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
    rm -f "$RELEASE_CHANNEL_TRANSITION_PATH"
}

# Persists the beta release being promoted so interrupted publish runs can
# resume without rediscovering a different predecessor.
write_release_channel_transition() {
    local previous_beta_version="$1"
    local temporary_path

    mkdir -p "$RELEASE_STATE_DIR"
    temporary_path="$(mktemp "$RELEASE_STATE_DIR/channel-transition.XXXXXX")"
    {
        printf 'RELEASE_TRANSITION_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'RELEASE_TRANSITION_CHANNEL=%q\n' "$RELEASE_CHANNEL"
        printf 'RELEASE_PREVIOUS_BETA_VERSION=%q\n' "$previous_beta_version"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_CHANNEL_TRANSITION_PATH"
}

load_release_channel_transition() {
    require_release_file "$RELEASE_CHANNEL_TRANSITION_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_CHANNEL_TRANSITION_PATH"

    [[ "$RELEASE_TRANSITION_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "channel transition belongs to another version"
    [[ "$RELEASE_TRANSITION_CHANNEL" == "$RELEASE_CHANNEL" ]] \
        || release_fail "channel transition belongs to another channel"
    if [[ -n "$RELEASE_PREVIOUS_BETA_VERSION" ]]; then
        [[ "$RELEASE_PREVIOUS_BETA_VERSION" \
            =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
            || release_fail "previous beta version is invalid"
        version_is_greater \
            "$RELEASE_VERSION" "$RELEASE_PREVIOUS_BETA_VERSION" \
            || release_fail "previous beta is not older than the release"
    fi
}

# Persists the local dev snapshot and the remote refs used to create the
# release worktree. These values make a resumed run independent of later
# changes to the caller's checkout or remote branches.
write_release_source_metadata() {
    local source_commit="$1"
    local remote_dev_commit="$2"
    local remote_main_commit="$3"

    mkdir -p "$RELEASE_STATE_DIR"
    {
        printf 'RELEASE_SOURCE_BRANCH=%q\n' "$RELEASE_DEV_BRANCH"
        printf 'RELEASE_SOURCE_COMMIT=%q\n' "$source_commit"
        printf 'RELEASE_SYNCED_REMOTE_DEV_COMMIT=%q\n' "$remote_dev_commit"
        printf 'RELEASE_SYNCED_REMOTE_MAIN_COMMIT=%q\n' "$remote_main_commit"
    } >"$RELEASE_SOURCE_METADATA_PATH"
}

# Loads the immutable source snapshot selected before the build begins.
load_release_source_metadata() {
    require_release_file "$RELEASE_SOURCE_METADATA_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_SOURCE_METADATA_PATH"

    [[ "$RELEASE_SOURCE_BRANCH" == "$RELEASE_DEV_BRANCH" ]] \
        || release_fail "release source branch differs from configured dev branch"
    [[ "$RELEASE_SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "release source commit is invalid"
    [[ "$RELEASE_SYNCED_REMOTE_DEV_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "synced remote dev commit is invalid"
    [[ "$RELEASE_SYNCED_REMOTE_MAIN_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
        || release_fail "synced remote main commit is invalid"
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

write_draft_refs_metadata() {
    local release_commit="$1"
    local tag_oid="$2"
    local temporary_path

    mkdir -p "$RELEASE_STATE_DIR"
    temporary_path="$(mktemp "$RELEASE_STATE_DIR/draft-refs.XXXXXX")"
    {
        printf 'DRAFT_REFS_VERSION=%q\n' "$RELEASE_VERSION"
        printf 'DRAFT_RELEASE_BRANCH=%q\n' "$RELEASE_BRANCH"
        printf 'DRAFT_RELEASE_COMMIT=%q\n' "$release_commit"
        printf 'DRAFT_TAG_OID=%q\n' "$tag_oid"
    } >"$temporary_path"
    mv "$temporary_path" "$RELEASE_DRAFT_REFS_PATH"
}

# Loads the frozen Git refs and integration result used by publish/resume.
load_publish_git_metadata() {
    require_release_file "$RELEASE_PUBLISH_GIT_PATH"
    # shellcheck disable=SC1090
    source "$RELEASE_PUBLISH_GIT_PATH"

    [[ "$PUBLISH_GIT_VERSION" == "$RELEASE_VERSION" ]] \
        || release_fail "publish Git metadata belongs to another version"
    for commit_name in \
        PUBLISH_VERSION_COMMIT \
        PUBLISH_PREPARED_HEAD \
        PUBLISH_LOCAL_DEV_BASE \
        PUBLISH_REMOTE_DEV_BASE \
        PUBLISH_REMOTE_MAIN_BASE \
        PUBLISH_REMOTE_RELEASE_BASE; do
        [[ "${!commit_name}" =~ ^[0-9a-f]{40}$ ]] \
            || release_fail "publish Git metadata has invalid $commit_name"
    done
    if [[ -n "${PUBLISH_APPCAST_COMMIT:-}" ]]; then
        [[ "$PUBLISH_APPCAST_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
            || release_fail "publish appcast commit is invalid"
    fi
    if [[ -n "${PUBLISH_INTEGRATION_HEAD:-}" ]]; then
        [[ "$PUBLISH_INTEGRATION_HEAD" =~ ^[0-9a-f]{40}$ ]] \
            || release_fail "publish integration commit is invalid"
    fi
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
