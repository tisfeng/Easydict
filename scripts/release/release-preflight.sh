#!/usr/bin/env bash

# Validates the local release toolchain, credentials, version, and staged
# release state before an expensive or externally visible workflow phase.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

validate_create_dmg() {
    local help_output

    help_output="$(create-dmg --help 2>&1)" \
        || release_fail "failed to run create-dmg --help"
    grep -F 'create-dmg <app> [destination]' <<<"$help_output" >/dev/null \
        || release_fail "unsupported create-dmg implementation"
    grep -F -- '--identity=<value>' <<<"$help_output" >/dev/null \
        || release_fail "create-dmg does not support signing identities"
    grep -F -- '--no-version-in-filename' <<<"$help_output" >/dev/null \
        || release_fail "create-dmg cannot create the expected filename"
}

validate_release_tooling() {
    local tooling_status

    tooling_status="$(git -C "$RELEASE_SOURCE_ROOT" status --porcelain \
        --untracked-files=all -- scripts/release)"
    [[ -z "$tooling_status" ]] \
        || release_fail "release tooling has uncommitted changes"
}

# Ensures the running scripts are part of the remote histories being released.
validate_synced_tooling() {
    local source_tree release_tree tooling_path

    load_release_source_metadata
    for tooling_path in scripts/release; do
        source_tree="$(git -C "$RELEASE_SOURCE_ROOT" rev-parse \
            "$RELEASE_SOURCE_COMMIT:$tooling_path")"
        release_tree="$(git -C "$RELEASE_WORKTREE" rev-parse \
            "HEAD:$tooling_path")"
        [[ "$source_tree" == "$release_tree" ]] \
            || release_fail "$tooling_path differs from the release worktree"
    done
}

validate_signing_identity() {
    local identities

    [[ "$RELEASE_SIGN_IDENTITY" == Developer\ ID\ Application:* ]] \
        || release_fail "release identity must be a Developer ID Application"
    identities="$(security find-identity -v -p codesigning)"
    grep -F "\"$RELEASE_SIGN_IDENTITY\"" <<<"$identities" \
        | grep -v 'CSSMERR_TP_CERT_REVOKED' >/dev/null \
        || release_fail "signing identity not found: $RELEASE_SIGN_IDENTITY"
}

validate_sparkle_key() {
    if [[ -n "${SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
        require_release_file "$SPARKLE_PRIVATE_KEY_FILE"
        return
    fi

    security find-generic-password \
        -s 'https://sparkle-project.org' \
        -a "$RELEASE_SPARKLE_ACCOUNT" >/dev/null 2>&1 \
        || release_fail "Sparkle key not found for account: $RELEASE_SPARKLE_ACCOUNT"
}

validate_environment() {
    local command_name
    local configured_team

    require_release_version
    for command_name in \
        asc cmp codesign create-dmg curl ditto gh git hdiutil plutil python3 \
        security shasum spctl stat xcodebuild xmllint xcrun; do
        require_release_command "$command_name"
    done

    require_release_file "$RELEASE_WORKFLOW_PATH"
    require_release_file "$RELEASE_EXPORT_OPTIONS"
    require_release_file "$RELEASE_SOURCE_ROOT/appcast.xml"
    require_release_dir "$RELEASE_SOURCE_ROOT/Easydict.xcodeproj"
    require_release_dir "$RELEASE_SOURCE_ROOT/Easydict.xcworkspace"

    plutil -lint "$RELEASE_EXPORT_OPTIONS" >/dev/null
    configured_team="$(/usr/libexec/PlistBuddy \
        -c 'Print :teamID' "$RELEASE_EXPORT_OPTIONS")"
    [[ "$configured_team" == "$RELEASE_TEAM_ID" ]] \
        || release_fail "export team ID differs from RELEASE_TEAM_ID"

    git -C "$RELEASE_SOURCE_ROOT" remote get-url "$RELEASE_REMOTE" \
        >/dev/null
    [[ -n "$(git -C "$RELEASE_SOURCE_ROOT" config user.name)" ]] \
        || release_fail "git user.name is not configured"
    [[ -n "$(git -C "$RELEASE_SOURCE_ROOT" config user.email)" ]] \
        || release_fail "git user.email is not configured"

    if [[ -n "$RELEASE_NOTES_FILE" ]]; then
        require_release_file "$RELEASE_NOTES_FILE"
    fi

    validate_create_dmg
    validate_release_tooling
    validate_signing_identity
    validate_sparkle_key
    asc auth status --validate >/dev/null
    gh auth status >/dev/null

    ensure_release_layout
    release_log "toolchain and credentials are ready"
}

# Rejects version or build regressions before any expensive build begins.
validate_release() {
    local latest_version latest_build current_version current_build
    local existing_draft

    require_release_worktree
    require_release_file "$RELEASE_WORKTREE/appcast.xml"
    validate_synced_tooling

    latest_version="$(xmllint --xpath \
        'string((//*[local-name()="shortVersionString"])[1])' \
        "$RELEASE_WORKTREE/appcast.xml")"
    latest_build="$(xmllint --xpath \
        'string((//*[local-name()="version"])[1])' \
        "$RELEASE_WORKTREE/appcast.xml")"
    [[ -n "$latest_version" && -n "$latest_build" ]] \
        || release_fail "failed to read the latest appcast version"
    [[ "$latest_build" =~ ^[0-9]+$ ]] \
        || release_fail "latest appcast build is not numeric"

    current_version="$(asc xcode version view \
        --project "$RELEASE_WORKTREE/Easydict.xcodeproj" \
        --target "$RELEASE_TARGET" \
        --configuration Release \
        --output json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
    current_build="$(asc xcode version view \
        --project "$RELEASE_WORKTREE/Easydict.xcodeproj" \
        --target "$RELEASE_TARGET" \
        --configuration Release \
        --output json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["buildNumber"])')"

    if [[ "$current_version" != "$RELEASE_VERSION" ]]; then
        version_is_greater "$RELEASE_VERSION" "$latest_version" \
            || release_fail "$RELEASE_VERSION must be newer than $latest_version"
    fi

    if [[ -n "$RELEASE_BUILD_OVERRIDE" ]]; then
        integer_is_greater "$RELEASE_BUILD_OVERRIDE" "$latest_build" \
            || release_fail "build number must be greater than $latest_build"
    elif release_is_replacement; then
        # The version stage freezes max(old Draft, current project, appcast)+1.
        :
    elif [[ "$current_version" == "$RELEASE_VERSION" ]]; then
        integer_is_greater "$current_build" "$latest_build" \
            || release_fail "prepared build number must be greater than $latest_build"
    fi

    if existing_draft="$(gh release view "$RELEASE_VERSION" \
        --repo "$RELEASE_REPOSITORY" \
        --json isDraft \
        --jq '.isDraft' 2>/dev/null)"; then
        [[ "$existing_draft" == true ]] \
            || release_fail "$RELEASE_VERSION is already published"
        if release_is_replacement; then
            load_replacement_metadata
            release_log "rebuilding the frozen GitHub Draft for $RELEASE_VERSION"
        else
            require_release_file "$RELEASE_METADATA_PATH"
            release_log "reusing the existing GitHub draft for $RELEASE_VERSION"
        fi
    elif release_is_replacement; then
        release_fail "the frozen GitHub Draft disappeared before local preparation completed"
    fi

    release_log "release version $RELEASE_VERSION passed preflight"
}

validate_publish() {
    require_release_worktree
    load_release_metadata
    require_release_file "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_DMG_PATH"
    require_release_file "$RELEASE_CHECKSUM_PATH"
    require_release_file "$RELEASE_APPCAST_PATH"
    require_release_file "$RELEASE_CHANNEL_TRANSITION_PATH"
    "$SCRIPT_DIR/release-github.sh" verify-ready
    "$SCRIPT_DIR/release-github.sh" verify-previous-ready
}

main() {
    local action="${1:-}"

    case "$action" in
        environment)
            release_set_step "preflight_environment"
            validate_environment
            ;;
        release)
            release_set_step "preflight_release"
            validate_release
            ;;
        publish)
            release_set_step "preflight_publish"
            validate_publish
            ;;
        *)
            release_fail "usage: release-preflight.sh environment|release|publish"
            ;;
    esac
}

main "$@"
