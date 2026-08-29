#!/usr/bin/env bash

# Updates release metadata, creates an Xcode archive, and exports a Developer
# ID application from the synchronized release worktree.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

read_project_value() {
    local key="$1"

    asc xcode version view \
        --project "$RELEASE_WORKTREE/Easydict.xcodeproj" \
        --target "$RELEASE_TARGET" \
        --configuration Release \
        --output json \
        | python3 -c \
            "import json,sys; print(json.load(sys.stdin)['$key'])"
}

resolve_build_number() {
    local current_version="$1"
    local current_build="$2"
    local latest_appcast_build target_build

    if release_is_replacement; then
        if [[ -f "$RELEASE_REPLACEMENT_BUILD_PATH" ]]; then
            load_replacement_build
            printf '%s\n' "$REPLACEMENT_BUILD_NUMBER"
            return
        fi
        load_replacement_metadata
        latest_appcast_build="$(xmllint --xpath \
            'string((//*[local-name()="version"])[1])' \
            "$RELEASE_WORKTREE/appcast.xml")"
        target_build="$(next_replacement_build \
            "$REPLACEMENT_OLD_BUILD" \
            "$current_build" \
            "$latest_appcast_build")"
        write_replacement_build "$target_build"
        printf '%s\n' "$target_build"
    elif [[ -f "$RELEASE_METADATA_PATH" ]]; then
        load_release_metadata
        printf '%s\n' "$RELEASE_SAVED_BUILD"
    elif [[ -n "$RELEASE_BUILD_OVERRIDE" ]]; then
        printf '%s\n' "$RELEASE_BUILD_OVERRIDE"
    elif [[ "$current_version" == "$RELEASE_VERSION" ]]; then
        printf '%s\n' "$current_build"
    else
        printf '%s\n' "$((10#$current_build + 1))"
    fi
}

# Applies and commits the version metadata inside the release worktree only.
update_version() {
    local current_version current_build target_build
    local latest_appcast_build version_commit

    require_release_worktree
    current_version="$(read_project_value version)"
    current_build="$(read_project_value buildNumber)"
    target_build="$(resolve_build_number "$current_version" "$current_build")"
    latest_appcast_build="$(xmllint --xpath \
        'string((//*[local-name()="version"])[1])' \
        "$RELEASE_WORKTREE/appcast.xml")"

    [[ "$target_build" =~ ^[0-9]+$ ]] \
        || release_fail "resolved build number is not an integer"
    [[ "$latest_appcast_build" =~ ^[0-9]+$ ]] \
        || release_fail "latest appcast build is not an integer"
    integer_is_greater "$target_build" "$latest_appcast_build" \
        || release_fail "build $target_build must be greater than $latest_appcast_build"

    if [[ "$current_version" != "$RELEASE_VERSION" \
        || "$current_build" != "$target_build" ]]; then
        release_log "updating version to $RELEASE_VERSION ($target_build)"
        asc xcode version edit \
            --project "$RELEASE_WORKTREE/Easydict.xcodeproj" \
            --target "$RELEASE_TARGET" \
            --version "$RELEASE_VERSION" \
            --build-number "$target_build" \
            --output table
    fi

    [[ "$(read_project_value version)" == "$RELEASE_VERSION" ]] \
        || release_fail "marketing version update did not persist"
    [[ "$(read_project_value buildNumber)" == "$target_build" ]] \
        || release_fail "build number update did not persist"

    git -C "$RELEASE_WORKTREE" diff --check
    git -C "$RELEASE_WORKTREE" add -- \
        Easydict.xcodeproj/project.pbxproj
    if ! git -C "$RELEASE_WORKTREE" diff --cached --quiet; then
        git -C "$RELEASE_WORKTREE" commit \
            -m "build(release): bump version metadata to $RELEASE_VERSION"
    fi

    version_commit="$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)"
    write_release_metadata "$target_build" "$version_commit"
    release_log "version commit: $version_commit"
}

# Produces the signed archive that all later artifacts derive from.
archive_application() {
    require_release_worktree
    load_release_metadata
    [[ "$(git -C "$RELEASE_WORKTREE" rev-parse HEAD)" \
        == "$RELEASE_VERSION_COMMIT" ]] \
        || release_fail "release worktree moved beyond the version commit"

    release_log "archiving Easydict $RELEASE_VERSION ($RELEASE_SAVED_BUILD)"
    asc xcode archive \
        --workspace "$RELEASE_WORKTREE/$RELEASE_WORKSPACE_PATH" \
        --scheme "$RELEASE_SCHEME" \
        --configuration Release \
        --archive-path "$RELEASE_ARCHIVE_PATH" \
        --clean \
        --overwrite \
        --xcodebuild-flag=-destination \
        --xcodebuild-flag=generic/platform=macOS \
        --xcodebuild-flag=-derivedDataPath \
        --xcodebuild-flag="$RELEASE_DERIVED_DATA" \
        --xcodebuild-flag="DEVELOPMENT_TEAM=$RELEASE_TEAM_ID" \
        --xcodebuild-flag=CODE_SIGN_STYLE=Manual \
        --xcodebuild-flag="CODE_SIGN_IDENTITY=$RELEASE_SIGN_IDENTITY" \
        --xcodebuild-flag=OTHER_CODE_SIGN_FLAGS=--timestamp \
        --xcodebuild-flag=DEPLOYMENT_POSTPROCESSING=YES \
        --xcodebuild-flag=ENABLE_DEBUG_DYLIB=NO \
        --xcodebuild-flag=EASYDICT_RELEASE_PACKAGING=YES \
        --output table
    require_release_dir "$RELEASE_ARCHIVE_PATH"
}

# Exports the Developer ID app and checks its embedded version metadata.
export_application() {
    local exported_version exported_build

    load_release_metadata
    require_release_dir "$RELEASE_ARCHIVE_PATH"
    safe_reset_release_dir "$RELEASE_EXPORT_DIR"

    release_log "exporting Developer ID application"
    release_capture "export-archive" xcodebuild -exportArchive \
        -archivePath "$RELEASE_ARCHIVE_PATH" \
        -exportPath "$RELEASE_EXPORT_DIR" \
        -exportOptionsPlist "$RELEASE_EXPORT_OPTIONS"
    require_release_dir "$RELEASE_APP_PATH"

    exported_version="$(/usr/libexec/PlistBuddy \
        -c 'Print :CFBundleShortVersionString' \
        "$RELEASE_APP_PATH/Contents/Info.plist")"
    exported_build="$(/usr/libexec/PlistBuddy \
        -c 'Print :CFBundleVersion' \
        "$RELEASE_APP_PATH/Contents/Info.plist")"
    [[ "$exported_version" == "$RELEASE_VERSION" ]] \
        || release_fail "exported app has version $exported_version"
    [[ "$exported_build" == "$RELEASE_SAVED_BUILD" ]] \
        || release_fail "exported app has build $exported_build"
}

main() {
    local action="${1:-}"

    require_release_version
    ensure_release_layout
    case "$action" in
        version)
            release_set_step "update_version"
            update_version
            ;;
        archive)
            release_set_step "archive_application"
            archive_application
            ;;
        export)
            release_set_step "export_application"
            export_application
            ;;
        *)
            release_fail "usage: release-build.sh version|archive|export"
            ;;
    esac
}

main "$@"
