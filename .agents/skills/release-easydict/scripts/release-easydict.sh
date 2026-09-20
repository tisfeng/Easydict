#!/usr/bin/env bash

# Public entry point for preparing, drafting, and publishing Easydict releases.
# The actual stages are declared in .agents/skills/release-easydict/scripts/asc-workflow.json and can be resumed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
WORKFLOW_SOURCE_PATH="$SCRIPT_DIR/asc-workflow.json"
WORKFLOW_RUNTIME_DIR="$ROOT_DIR/.tmp/release/asc"
WORKFLOW_PATH="$WORKFLOW_RUNTIME_DIR/asc-workflow.json"
WORKFLOW_RUNS_DIR="$WORKFLOW_RUNTIME_DIR/runs"

usage() {
    cat <<'EOF'
Usage:
  release-easydict.sh prepare <version> [options]
  release-easydict.sh draft <version> [options]
  release-easydict.sh publish <version> [options]
  release-easydict.sh release <version> [options]
  release-easydict.sh resume <run-id>
  release-easydict.sh sync-notes <version> [options]

Options:
  --channel beta|stable   Sparkle channel (default: beta)
  --build-number <value> Override the next build number
  --replace-draft        Rebuild and safely replace the latest matching Draft
  --force-clean          Force a clean Xcode Archive
  --dry-run               Preview the asc workflow without running it
  --execute               Write synced notes to the published Release and main/dev appcasts
  --repo <owner/repo>     GitHub repository for sync-notes
  --notes-file <path>     Canonical changelog path for sync-notes
  --state <path>          Override sync-notes state JSON path
  -h, --help              Show this help

Workflow results are summarized in the terminal. Detailed stderr and result
JSON are saved under .tmp/release/<version>/logs/.
EOF
}

prepare_workflow_runtime() {
    local temporary_path

    mkdir -p "$WORKFLOW_RUNTIME_DIR"
    temporary_path="$(mktemp "$WORKFLOW_RUNTIME_DIR/asc-workflow.XXXXXX")"
    cp "$WORKFLOW_SOURCE_PATH" "$temporary_path"
    mv "$temporary_path" "$WORKFLOW_PATH"
}

run_notes_sync() {
    local version="$1"
    shift
    local repo="tisfeng/Easydict"
    local notes_file=""
    local state_path=""
    local execute=0

    while (($# > 0)); do
        case "$1" in
            --execute)
                execute=1
                shift
                ;;
            --repo)
                require_value "$1" "${2:-}"
                repo="$2"
                shift 2
                ;;
            --notes-file)
                require_value "$1" "${2:-}"
                notes_file="$2"
                shift 2
                ;;
            --state)
                require_value "$1" "${2:-}"
                state_path="$2"
                shift 2
                ;;
            -h | --help)
                usage
                return
                ;;
            *)
                fail "unknown option for sync-notes: $1"
                ;;
        esac
    done

    cd "$ROOT_DIR"
    local -a command=(
        python3 "$SCRIPT_DIR/release-notes-sync.py" "$version"
        --repo "$repo"
    )
    if [[ -n "$notes_file" ]]; then
        command+=(--notes-file "$notes_file")
    fi
    if [[ -n "$state_path" ]]; then
        command+=(--state "$state_path")
    fi
    if ((execute == 1)); then
        command+=(--execute)
    fi
    "${command[@]}"
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
    local run_file="$WORKFLOW_RUNS_DIR/$run_id.json"

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
        print(f"  - 版本提交：{draft_refs.get('DRAFT_VERSION_COMMIT', 'unknown')}")
        print(f"  - appcast 提交：{draft_refs.get('DRAFT_APPCAST_COMMIT', 'unknown')}")
        print("  - dev/main：Draft 阶段未修改")
    if publish_git.get("PUBLISH_INTEGRATION_HEAD"):
        print("- Publish Git 集成：")
        print(f"  - 本地与远程 dev：{publish_git['PUBLISH_INTEGRATION_HEAD']}")
        print(f"  - 远程 main：{publish_git.get('PUBLISH_APPCAST_COMMIT', 'unknown')}")
        print(f"  - 版本 Tag：{publish_git.get('PUBLISH_VERSION_COMMIT', 'unknown')}")
        cleaned = state.joinpath("remote-release-branch-cleaned.complete").exists()
        print(f"  - 临时远程分支：{'已清理' if cleaned else '保留，等待验证或恢复'}")
    timings = state / "timings.json"
    try:
        timing_payload = json.loads(timings.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        timing_payload = {}
    events = timing_payload.get("events", [])
    if events:
        print("- 实际步骤耗时：")
        for event in events:
            duration = event.get("duration_ms")
            if isinstance(duration, int):
                print(f"  - {event.get('step', 'unknown')}: {duration / 1000:.1f}s")
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
            prepare_workflow_runtime
            asc workflow validate --file "$WORKFLOW_PATH" >/dev/null
            export RELEASE_RUN_MODE=resume
            run_workflow "$resume_version" asc workflow run \
                --pretty \
                --file "$WORKFLOW_PATH" \
                "$workflow_name" \
                --resume "$run_id"
            return $?
            ;;
        sync-notes)
            local sync_version="${2:-}"
            require_value sync-notes "$sync_version"
            [[ "$sync_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
                || fail "version must use x.y.z format"
            shift 2
            run_notes_sync "$sync_version" "$@"
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
    local draft_mode="normal"
    local force_clean=0
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
            --replace-draft)
                draft_mode="replace"
                shift
                ;;
            --force-clean)
                [[ "$action" == prepare || "$action" == draft || "$action" == release ]] \
                    || fail "--force-clean is supported only with prepare, draft, or release"
                force_clean=1
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
    cd "$ROOT_DIR"
    prepare_workflow_runtime
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
        "DRAFT_MODE:$draft_mode"
        "FORCE_CLEAN:$force_clean"
    )

    export RELEASE_RUN_MODE=new
    run_workflow "$version" "${command[@]}"
}

main "$@"
