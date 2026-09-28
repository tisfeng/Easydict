#!/usr/bin/env bash

# Notarizes the exported Easydict app, creates the final Sparkle archive, and
# builds, notarizes, and staples the downloadable disk image.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

# Confirms the exported app has the expected identity, team, and timestamp.
verify_app_signature() {
    local authority signature_output team_id

    release_capture "verify-app-signature" \
        codesign --verify --deep --strict --verbose=2 "$RELEASE_APP_PATH"
    signature_output="$(codesign -dv --verbose=4 "$RELEASE_APP_PATH" 2>&1)"
    authority="$(sed -n 's/^Authority=//p' <<<"$signature_output" \
        | head -n 1)"
    team_id="$(sed -n 's/^TeamIdentifier=//p' <<<"$signature_output" \
        | head -n 1)"
    [[ "$authority" == "$RELEASE_SIGN_IDENTITY" ]] \
        || release_fail "unexpected app signing authority: $authority"
    [[ "$team_id" == "$RELEASE_TEAM_ID" ]] \
        || release_fail "unexpected app team identifier: $team_id"
    grep -F 'Timestamp=' <<<"$signature_output" >/dev/null \
        || release_fail "application signature has no secure timestamp"
}

# Confirms create-dmg used the requested Developer ID identity.
verify_dmg_signature() {
    local signature_output

    release_capture "verify-dmg-signature" \
        codesign --verify --strict --verbose=2 "$RELEASE_DMG_PATH"
    signature_output="$(codesign -dv --verbose=4 "$RELEASE_DMG_PATH" 2>&1)"
    grep -Fx "Authority=$RELEASE_SIGN_IDENTITY" \
        <<<"$signature_output" >/dev/null \
        || release_fail "disk image has an unexpected signing authority"
    grep -Fx "TeamIdentifier=$RELEASE_TEAM_ID" \
        <<<"$signature_output" >/dev/null \
        || release_fail "disk image has an unexpected team identifier"
    grep -F 'Timestamp=' <<<"$signature_output" >/dev/null \
        || release_fail "disk image signature has no secure timestamp"
}

# Retries transient upload or polling failures without skipping acceptance.
submit_notarization() {
    local file_path="$1"
    local attempt

    for attempt in 1 2 3; do
        release_log "notarization attempt $attempt/3: $(basename "$file_path")"
        if asc notarization submit \
            --file "$file_path" \
            --wait \
            --timeout 1h \
            --output table; then
            return
        fi
        if ((attempt < 3)); then
            release_log "notarization submission failed; retrying in 15 seconds"
            sleep 15
        fi
    done

    release_fail "notarization failed after three attempts: $file_path"
}

notarize_app() {
    load_release_metadata
    require_release_dir "$RELEASE_APP_PATH"
    verify_app_signature

    rm -f "$RELEASE_NOTARY_ZIP"
    ditto -c -k --sequesterRsrc --keepParent \
        "$RELEASE_APP_PATH" "$RELEASE_NOTARY_ZIP"
    release_log "submitting application for notarization"
    submit_notarization "$RELEASE_NOTARY_ZIP"

    release_capture "staple-app" xcrun stapler staple "$RELEASE_APP_PATH"
    release_capture "validate-app-staple" \
        xcrun stapler validate "$RELEASE_APP_PATH"
    release_capture "assess-app" \
        spctl --assess --type execute --verbose=4 "$RELEASE_APP_PATH"
    release_log "application notarization and Gatekeeper validation passed"
}

# Archives the stapled app that Sparkle will sign and distribute.
create_sparkle_zip() {
    load_release_metadata
    require_release_dir "$RELEASE_APP_PATH"
    release_capture "validate-app-staple" \
        xcrun stapler validate "$RELEASE_APP_PATH"
    safe_reset_release_dir "$RELEASE_ARTIFACT_DIR"

    release_log "creating final Sparkle archive"
    ditto -c -k --sequesterRsrc --keepParent \
        "$RELEASE_APP_PATH" "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_ZIP_PATH"
}

# Builds and notarizes the DMG, then records checksums for both artifacts.
create_notarized_dmg() {
    load_release_metadata
    require_release_file "$RELEASE_ZIP_PATH"
    rm -f "$RELEASE_DMG_PATH"

    release_log "creating signed disk image"
    create-dmg \
        --overwrite \
        --no-version-in-filename \
        --identity="$RELEASE_SIGN_IDENTITY" \
        "$RELEASE_APP_PATH" \
        "$RELEASE_ARTIFACT_DIR"
    require_release_file "$RELEASE_DMG_PATH"
    verify_dmg_signature

    release_log "submitting disk image for notarization"
    submit_notarization "$RELEASE_DMG_PATH"
    release_capture "staple-dmg" xcrun stapler staple "$RELEASE_DMG_PATH"
    release_capture "validate-dmg-staple" \
        xcrun stapler validate "$RELEASE_DMG_PATH"

    (
        cd "$RELEASE_ARTIFACT_DIR"
        shasum -a 256 Easydict.zip Easydict.dmg >SHA256SUMS.txt
    )
    require_release_file "$RELEASE_CHECKSUM_PATH"
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        notarize-app)
            release_set_step "notarize_application"
            notarize_app
            ;;
        zip)
            release_set_step "create_sparkle_zip"
            create_sparkle_zip
            ;;
        dmg)
            release_set_step "create_notarized_dmg"
            create_notarized_dmg
            ;;
        *)
            release_fail "usage: release-package.sh notarize-app|zip|dmg"
            ;;
    esac
}

main "$@"
