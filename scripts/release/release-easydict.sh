#!/usr/bin/env bash

# Public entry point for preparing, drafting, and publishing Easydict releases.
# The actual stages are declared in scripts/release/asc-workflow.json and can be resumed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/scripts/release/asc-workflow.json"

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
  --replace-draft        Rebuild and safely replace the latest matching Draft
  --dry-run               Preview the asc workflow without running it
  -h, --help              Show this help

Workflow results are summarized in the terminal. Detailed stderr and result
JSON are saved under .tmp/release/<version>/logs/.

The legacy release implementation remains available as:
  scripts/release/release-easydict-legacy.sh
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

resolve_resume_version() {
    local run_id="$1"
    local run_file="$ROOT_DIR/scripts/release/runs/$run_id.json"

    [[ -f "$run_file" ]] || return 1
    python3 - "$run_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    run = json.load(handle)

version = run.get("params", {}).get("VERSION", "")
if not version:
    raise SystemExit(1)
print(version)
PY
}

format_result() {
    local result_file="$1"
    local log_file="$2"
    local version="$3"

    python3 - "$result_file" "$log_file" "$ROOT_DIR" "$version" <<'PY'
import json
from pathlib import Path
import shlex
import sys

result_path, log_path, root_path, requested_version = sys.argv[1:]
try:
    with open(result_path, encoding="utf-8") as handle:
        result = json.load(handle)
except (OSError, json.JSONDecodeError) as error:
    print("发布工作流结果")
    print(f"- 状态：无法解析 asc 结果 JSON（{error}）")
    print(f"- 详细日志：{log_path}")
    print(f"- 结果 JSON：{result_path}")
    raise SystemExit(0)

workflow = result.get("workflow", "unknown")
status = result.get("status", "unknown")
failed_step = result.get("failed_step")
error = result.get("error")
run_id = result.get("run_id", "unknown")

print("发布工作流结果")
print(f"- 工作流：{workflow}")
print(f"- 状态：{status}")
if failed_step:
    print(f"- 失败步骤：{failed_step}")
if error:
    print(f"- 错误：{error}")
print(f"- 运行 ID：{run_id}")
print(f"- 详细日志：{log_path}")
print(f"- 结果 JSON：{result_path}")

steps = result.get("steps", [])
if steps:
    print("- 步骤：")
    for step in steps:
        name = step.get("name", "unknown")
        step_status = step.get("status", "unknown")
        marker = "✓" if step_status in {"ok", "success", "completed", "resumed", "dry-run"} else "✗"
        print(f"  {marker} {name} ({step_status})")


def read_env(path):
    values = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return values
    for line in lines:
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, raw = line.split("=", 1)
        try:
            parsed = shlex.split(raw)
        except ValueError:
            continue
        values[key] = parsed[0] if parsed else ""
    return values


version = result.get("params", {}).get("VERSION", "") or requested_version
if version:
    state = Path(root_path) / ".tmp" / "release" / version / "state"
    draft_refs = read_env(state / "draft-refs.env")
    publish_git = read_env(state / "publish-git.env")
    if draft_refs:
        print("- Draft Git 引用：")
        print(f"  - 临时分支：{draft_refs.get('DRAFT_RELEASE_BRANCH', 'unknown')}")
        print(f"  - 版本提交：{draft_refs.get('DRAFT_RELEASE_COMMIT', 'unknown')}")
        print("  - dev/main：Draft 阶段未修改")
    if publish_git.get("PUBLISH_INTEGRATION_HEAD"):
        print("- Publish Git 集成：")
        print(f"  - 本地与远程 dev：{publish_git['PUBLISH_INTEGRATION_HEAD']}")
        print(f"  - 远程 main：{publish_git.get('PUBLISH_APPCAST_COMMIT', 'unknown')}")
        print(f"  - 版本 Tag：{publish_git.get('PUBLISH_VERSION_COMMIT', 'unknown')}")
        cleaned = state.joinpath("remote-release-branch-cleaned.complete").exists()
        print(f"  - 临时远程分支：{'已清理' if cleaned else '保留，等待验证或恢复'}")
PY
}

run_workflow() {
    local version="$1"
    shift
    local log_dir="$ROOT_DIR/.tmp/release/$version/logs"
    local work_dir
    local result_tmp
    local live_tmp
    local live_pipe
    local run_id=""
    local safe_run_id
    local result_file
    local log_file
    local tee_pid
    local exit_code

    mkdir -p "$log_dir"
    work_dir="$(mktemp -d "$log_dir/.workflow.XXXXXX")"
    result_tmp="$work_dir/result.json"
    live_tmp="$work_dir/live.log"
    live_pipe="$work_dir/live.pipe"
    mkfifo "$live_pipe"

    # Keep stdout as a file for machine-readable asc JSON while teeing only
    # human-readable stderr to the terminal and its durable log. A named pipe
    # is used instead of /dev/fd process substitution for macOS/sandbox parity.
    tee "$live_tmp" <"$live_pipe" >&2 &
    tee_pid=$!
    set +e
    "$@" >"$result_tmp" 2>"$live_pipe"
    exit_code=$?
    set -e
    wait "$tee_pid" || true

    if [[ -s "$result_tmp" ]]; then
        run_id="$(python3 - "$result_tmp" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        result = json.load(handle)
except (OSError, json.JSONDecodeError):
    raise SystemExit(0)
print(result.get("run_id", ""))
PY
)"
    fi

    if [[ -n "$run_id" ]]; then
        safe_run_id="${run_id//[^[:alnum:]_.-]/-}"
    else
        safe_run_id="unknown-$$"
    fi
    result_file="$log_dir/workflow-$safe_run_id.json"
    log_file="$log_dir/workflow-$safe_run_id.log"
    mv "$result_tmp" "$result_file"
    mv "$live_tmp" "$log_file"
    rm -f "$live_pipe"
    rmdir "$work_dir"

    format_result "$result_file" "$log_file" "$version"
    return "$exit_code"
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
            local resume_version
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

            resume_version="$(resolve_resume_version "$run_id")" \
                || fail "cannot determine version from run file: $run_id"

            cd "$ROOT_DIR"
            asc workflow validate --file "$WORKFLOW_PATH" >/dev/null
            export RELEASE_RUN_MODE=resume
            run_workflow "$resume_version" asc workflow run \
                --pretty \
                --file "$WORKFLOW_PATH" \
                "$workflow_name" \
                --resume "$run_id"
            return $?
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
    local draft_mode="normal"
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
            --replace-draft)
                draft_mode="replace"
                shift
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
    if [[ "$draft_mode" == replace ]]; then
        [[ "$action" == draft ]] \
            || fail "--replace-draft is supported only with draft"
        [[ -z "$build_number" ]] \
            || fail "--replace-draft chooses the next build number automatically"
    fi
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
        --pretty
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
        "DRAFT_MODE:$draft_mode"
    )

    export RELEASE_RUN_MODE=new
    run_workflow "$version" "${command[@]}"
}

main "$@"
