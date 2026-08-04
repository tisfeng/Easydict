#!/usr/bin/env bash

# Public entry point for preparing, drafting, and publishing Easydict releases.
# The actual stages are declared in .asc/workflow.json and can be resumed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.asc/workflow.json"

usage() {
    cat <<'EOF'
Usage:
  release-easydict.sh prepare <version> [options]
  release-easydict.sh draft <version> [options]
  release-easydict.sh publish <version> [options]
  release-easydict.sh release <version> [options]
  release-easydict.sh resume <run-id>

Options:
  --channel beta|stable   Sparkle channel (default: beta)
  --build-number <value> Override the next build number
  --notes <file>          Use a release notes file instead of generated notes
  --dry-run               Preview the asc workflow without running it
  -h, --help              Show this help

The legacy release implementation remains available as:
  release-scripts/release-easydict-legacy.sh
EOF
}

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_value() {
    local option_name="$1"
    local option_value="${2:-}"

    [[ -n "$option_value" ]] || fail "$option_name requires a value"
}

main() {
    local action="${1:-}"

    case "$action" in
        -h | --help | help | '')
            usage
            return
            ;;
        resume)
            local run_id="${2:-}"
            require_value resume "$run_id"
            [[ $# -eq 2 ]] || fail "resume accepts only a run ID"

            local workflow_name="${run_id%%-*}"
            case "$workflow_name" in
                prepare | draft | publish | release)
                    ;;
                *)
                    fail "cannot infer workflow from run ID: $run_id"
                    ;;
            esac

            cd "$ROOT_DIR"
            asc workflow validate --file "$WORKFLOW_PATH" >/dev/null
            exec asc workflow run \
                --file "$WORKFLOW_PATH" \
                "$workflow_name" \
                --resume "$run_id"
            ;;
        prepare | draft | publish | release)
            ;;
        *)
            fail "unknown action: $action"
            ;;
    esac

    shift
    local version="${1:-}"
    require_value "$action" "$version"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
        || fail "version must use x.y.z format"
    shift

    local channel="beta"
    local build_number=""
    local notes_file=""
    local dry_run=0

    while (($# > 0)); do
        case "$1" in
            --channel)
                require_value "$1" "${2:-}"
                channel="$2"
                shift 2
                ;;
            --build-number)
                require_value "$1" "${2:-}"
                build_number="$2"
                shift 2
                ;;
            --notes)
                require_value "$1" "${2:-}"
                notes_file="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            -h | --help)
                usage
                return
                ;;
            *)
                fail "unknown option: $1"
                ;;
        esac
    done

    [[ "$channel" == beta || "$channel" == stable ]] \
        || fail "channel must be beta or stable"
    if [[ -n "$build_number" ]]; then
        [[ "$build_number" =~ ^[0-9]+$ ]] \
            || fail "build number must be a positive integer"
        ((10#$build_number > 0)) \
            || fail "build number must be greater than zero"
    fi
    if [[ -n "$notes_file" ]]; then
        [[ -f "$notes_file" ]] || fail "release notes file not found: $notes_file"
        notes_file="$(cd "$(dirname "$notes_file")" && pwd)/$(basename "$notes_file")"
    fi

    cd "$ROOT_DIR"
    asc workflow validate --file "$WORKFLOW_PATH" >/dev/null

    local -a command=(
        asc workflow run
        --file "$WORKFLOW_PATH"
    )
    if ((dry_run == 1)); then
        command+=(--dry-run)
    fi
    command+=(
        "$action"
        "VERSION:$version"
        "CHANNEL:$channel"
        "BUILD_NUMBER:$build_number"
        "NOTES_FILE:$notes_file"
    )

    exec "${command[@]}"
}

main "$@"
