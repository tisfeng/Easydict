#!/usr/bin/env bash

# Generates a Sparkle-signed appcast candidate and installs it only after the
# corresponding GitHub release is publicly downloadable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

validate_candidate() {
    local original_path="$1"

    python3 "$SCRIPT_DIR/release-appcast.py" validate \
        --original "$original_path" \
        --appcast "$RELEASE_APPCAST_PATH" \
        --archive "$RELEASE_ZIP_PATH" \
        --version "$RELEASE_VERSION" \
        --build "$RELEASE_SAVED_BUILD" \
        --channel "$RELEASE_CHANNEL" \
        --release-notes-url "$(release_notes_url)" \
        --download-url "$(release_download_prefix)Easydict.zip"
}

# Lets Sparkle sign the ZIP, then rejects unrelated changes to older entries.
generate_candidate() {
    local generate_appcast
    local -a command

    require_release_worktree
    load_release_metadata
    require_release_file "$RELEASE_ZIP_PATH"
    require_release_file "$RELEASE_WORKTREE/appcast.xml"
    generate_appcast="$(resolve_generate_appcast)"

    safe_reset_release_dir "$RELEASE_APPCAST_DIR"
    cp "$RELEASE_WORKTREE/appcast.xml" "$RELEASE_APPCAST_PATH"
    cp "$RELEASE_ZIP_PATH" "$RELEASE_APPCAST_DIR/Easydict.zip"

    command=(
        "$generate_appcast"
        --account "$RELEASE_SPARKLE_ACCOUNT"
        --download-url-prefix "$(release_download_prefix)"
        --versions "$RELEASE_SAVED_BUILD"
        --maximum-versions 0
    )
    if [[ -n "${SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
        command+=(--ed-key-file "$SPARKLE_PRIVATE_KEY_FILE")
    fi
    if [[ "$RELEASE_CHANNEL" == beta ]]; then
        command+=(--channel beta)
    fi
    command+=("$RELEASE_APPCAST_DIR")

    release_log "generating Sparkle appcast candidate"
    "${command[@]}"
    require_release_file "$RELEASE_APPCAST_PATH"

    python3 "$SCRIPT_DIR/release-appcast.py" set-link \
        --appcast "$RELEASE_APPCAST_PATH" \
        --version "$RELEASE_VERSION" \
        --build "$RELEASE_SAVED_BUILD" \
        --url "$(release_notes_url)"
    xmllint --noout "$RELEASE_APPCAST_PATH"
    validate_candidate "$RELEASE_WORKTREE/appcast.xml"
}

# Commits the candidate only after the corresponding release is public.
install_candidate() {
    local expected_subject

    require_release_worktree
    load_release_metadata
    require_release_file "$RELEASE_APPCAST_PATH"
    validate_candidate "$RELEASE_WORKTREE/appcast.xml"

    cp "$RELEASE_APPCAST_PATH" "$RELEASE_WORKTREE/appcast.xml"
    git -C "$RELEASE_WORKTREE" diff --check
    git -C "$RELEASE_WORKTREE" add -- appcast.xml
    expected_subject="build(release): add $RELEASE_VERSION appcast entry"
    if ! git -C "$RELEASE_WORKTREE" diff --cached --quiet; then
        git -C "$RELEASE_WORKTREE" commit -m "$expected_subject"
    elif [[ "$(git -C "$RELEASE_WORKTREE" log -1 --format=%s)" \
        != "$expected_subject" ]]; then
        release_fail "appcast candidate produced no publishable change"
    fi
}

main() {
    local action="${1:-}"

    require_release_version
    case "$action" in
        generate)
            release_set_step "generate_appcast_candidate"
            generate_candidate
            ;;
        install)
            release_set_step "install_appcast"
            install_candidate
            ;;
        *)
            release_fail "usage: release-appcast.sh generate|install"
            ;;
    esac
}

main "$@"
