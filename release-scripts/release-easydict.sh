#!/usr/bin/env bash

set -euo pipefail

APP_NAME="Easydict"
SCHEME_NAME="Easydict"
TARGET_NAME="Easydict"
CONFIGURATION="Release"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_PATH="$ROOT_DIR/Easydict.xcworkspace"
PROJECT_PATH="$ROOT_DIR/Easydict.xcodeproj/project.pbxproj"
DERIVED_DATA_DIR="$ROOT_DIR/.tmp/release-derived-data"
NOTARIZATION_ZIP_PATH="$ROOT_DIR/.tmp/release-notarization.zip"

CREATE_DMG_BIN="${CREATE_DMG_BIN:-create-dmg}"
APPCAST_PATH="$ROOT_DIR/appcast.xml"
RELEASE_NOTES_BASE_URL="https://github.com/tisfeng/easydict/releases/tag"
RELEASE_DOWNLOAD_BASE_URL="https://github.com/tisfeng/Easydict/releases/download"
RELEASE_DEVELOPMENT_TEAM="${RELEASE_DEVELOPMENT_TEAM:-45Z6V4YD5U}"
RELEASE_CODE_SIGN_IDENTITY="${RELEASE_CODE_SIGN_IDENTITY:-Developer ID Application: Canglong Dai (45Z6V4YD5U)}"
RELEASE_NOTARY_TEAM_ID="${RELEASE_NOTARY_TEAM_ID:-$RELEASE_DEVELOPMENT_TEAM}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-easydict-release}"
RELEASE_SPARKLE_CHANNEL="${RELEASE_SPARKLE_CHANNEL-beta}"
SHOW_BUILD_SETTINGS_TIMEOUT="${SHOW_BUILD_SETTINGS_TIMEOUT:-45}"
KEEP_RELEASE_TMP="${KEEP_RELEASE_TMP:-0}"

APP_BUNDLE_NAME="$APP_NAME.app"
APP_ZIP_NAME="$APP_NAME.zip"
APP_DMG_NAME="$APP_NAME.dmg"

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "error: required command not found: $command_name" >&2
        exit 1
    fi
}

require_file() {
    local file_path="$1"

    if [[ ! -e "$file_path" ]]; then
        echo "error: required file not found: $file_path" >&2
        exit 1
    fi
}

require_executable_file() {
    local file_path="$1"

    require_file "$file_path"
    if [[ ! -x "$file_path" ]]; then
        echo "error: required file is not executable: $file_path" >&2
        exit 1
    fi
}

resolve_sign_update() {
    local candidate_path

    if [[ -n "${SIGN_UPDATE:-}" ]]; then
        require_executable_file "$SIGN_UPDATE"
        printf '%s\n' "$SIGN_UPDATE"
        return
    fi

    if [[ -n "${SPARKLE_BIN_DIR:-}" ]]; then
        candidate_path="$SPARKLE_BIN_DIR/sign_update"
        require_executable_file "$candidate_path"
        printf '%s\n' "$candidate_path"
        return
    fi

    if candidate_path="$(command -v sign_update 2>/dev/null)"; then
        printf '%s\n' "$candidate_path"
        return
    fi

    candidate_path="$DERIVED_DATA_DIR/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
    if [[ -e "$candidate_path" ]]; then
        require_executable_file "$candidate_path"
        printf '%s\n' "$candidate_path"
        return
    fi

    echo "error: required Sparkle command not found: sign_update" >&2
    echo "Set SIGN_UPDATE, set SPARKLE_BIN_DIR, add sign_update to PATH, or run after the release build creates:" >&2
    echo "  $candidate_path" >&2
    exit 1
}

require_create_dmg() {
    local help_output

    if ! command -v "$CREATE_DMG_BIN" >/dev/null 2>&1; then
        echo "error: required command not found: $CREATE_DMG_BIN" >&2
        echo "Install sindresorhus/create-dmg with npm or set CREATE_DMG_BIN." >&2
        exit 1
    fi

    if ! help_output="$("$CREATE_DMG_BIN" --help 2>&1)"; then
        echo "error: failed to run $CREATE_DMG_BIN --help" >&2
        echo "$help_output" >&2
        exit 1
    fi

    if ! grep -F "create-dmg <app> [destination]" <<<"$help_output" >/dev/null \
        || ! grep -F -- "--identity=<value>" <<<"$help_output" >/dev/null \
        || ! grep -F -- "--no-version-in-filename" <<<"$help_output" >/dev/null; then
        echo "error: unsupported create-dmg command: $CREATE_DMG_BIN" >&2
        echo "Expected sindresorhus/create-dmg from npm." >&2
        echo "$help_output" >&2
        exit 1
    fi
}

require_signing_identity() {
    if [[ -z "$RELEASE_DEVELOPMENT_TEAM" ]]; then
        echo "error: RELEASE_DEVELOPMENT_TEAM must not be empty" >&2
        exit 1
    fi

    if [[ "$RELEASE_CODE_SIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
        echo "error: RELEASE_CODE_SIGN_IDENTITY must be a Developer ID Application identity" >&2
        echo "current value: $RELEASE_CODE_SIGN_IDENTITY" >&2
        exit 1
    fi

    if ! security find-identity -v -p codesigning \
        | grep -F "\"$RELEASE_CODE_SIGN_IDENTITY\"" \
        | grep -v "CSSMERR_TP_CERT_REVOKED" >/dev/null; then
        echo "error: required signing identity not found: $RELEASE_CODE_SIGN_IDENTITY" >&2
        echo "Install the Developer ID Application certificate or override RELEASE_CODE_SIGN_IDENTITY." >&2
        exit 1
    fi
}

require_notarytool_profile() {
    local history_output

    if [[ -z "$NOTARYTOOL_PROFILE" ]]; then
        echo "error: NOTARYTOOL_PROFILE must not be empty" >&2
        exit 1
    fi

    if [[ -z "$RELEASE_NOTARY_TEAM_ID" ]]; then
        echo "error: RELEASE_NOTARY_TEAM_ID must not be empty" >&2
        exit 1
    fi

    if ! history_output="$(
        xcrun notarytool history \
            --keychain-profile "$NOTARYTOOL_PROFILE" \
            --team-id "$RELEASE_NOTARY_TEAM_ID" \
            --output-format json 2>&1
    )"; then
        echo "error: notarytool profile $NOTARYTOOL_PROFILE is not available for team $RELEASE_NOTARY_TEAM_ID" >&2
        echo "$history_output" >&2
        echo "Create it with:" >&2
        echo "  xcrun notarytool store-credentials $NOTARYTOOL_PROFILE \\" >&2
        echo "      --apple-id <apple-id> \\" >&2
        echo "      --team-id $RELEASE_NOTARY_TEAM_ID \\" >&2
        echo "      --password <app-specific-password>" >&2
        exit 1
    fi
}

release_app_signing_targets() {
    local app_path="$1"
    local frameworks_path="$app_path/Contents/Frameworks"
    local sparkle_versions_path="$frameworks_path/Sparkle.framework/Versions"

    if [[ ! -d "$frameworks_path" ]]; then
        return
    fi

    if [[ -d "$sparkle_versions_path" ]]; then
        find "$sparkle_versions_path" \
            \( -name "Updater.app" -o -name "*.xpc" -o -name "Autoupdate" \) \
            -print | sort
    fi

    find "$frameworks_path" -mindepth 1 -maxdepth 1 -type d -name "*.framework" -print \
        | sort
    find "$frameworks_path" -mindepth 1 -maxdepth 1 -type f -name "*.dylib" -print \
        | sort
}

sign_release_target() {
    local target_path="$1"
    shift

    codesign --force \
        --sign "$RELEASE_CODE_SIGN_IDENTITY" \
        --options runtime \
        --timestamp \
        "$@" \
        "$target_path"
}

resign_release_app() {
    local app_path="$1"
    local target

    echo "Signing embedded release code..."
    while IFS= read -r target; do
        require_file "$target"
        sign_release_target "$target"
    done < <(release_app_signing_targets "$app_path")

    echo "Signing $APP_BUNDLE_NAME..."
    sign_release_target "$app_path" --preserve-metadata=entitlements
}

assert_developer_id_signature() {
    local file_path="$1"
    local target_name="$2"
    local verify_mode="${3:-strict}"
    local signature_output
    local team_identifier

    if [[ "$verify_mode" == "deep" ]]; then
        codesign --verify --deep --strict --verbose=2 "$file_path"
    else
        codesign --verify --strict --verbose=2 "$file_path"
    fi
    signature_output="$(codesign -dv --verbose=4 "$file_path" 2>&1)"

    if grep -Fx "Signature=adhoc" <<<"$signature_output" >/dev/null; then
        echo "error: $target_name is ad-hoc signed" >&2
        echo "$signature_output" >&2
        exit 1
    fi

    if ! grep -Fx "Authority=$RELEASE_CODE_SIGN_IDENTITY" <<<"$signature_output" >/dev/null; then
        echo "error: $target_name is not signed with $RELEASE_CODE_SIGN_IDENTITY" >&2
        echo "$signature_output" >&2
        exit 1
    fi

    if ! grep -F "Authority=Developer ID Application" <<<"$signature_output" >/dev/null; then
        echo "error: $target_name signature is not a Developer ID Application signature" >&2
        echo "$signature_output" >&2
        exit 1
    fi

    team_identifier="$(sed -n 's/^TeamIdentifier=//p' <<<"$signature_output" | head -n 1)"
    if [[ "$team_identifier" != "$RELEASE_DEVELOPMENT_TEAM" ]]; then
        echo "error: $target_name TeamIdentifier $team_identifier does not match $RELEASE_DEVELOPMENT_TEAM" >&2
        echo "$signature_output" >&2
        exit 1
    fi

    if ! grep -F "Timestamp=" <<<"$signature_output" >/dev/null; then
        echo "error: $target_name signature does not include a secure timestamp" >&2
        echo "$signature_output" >&2
        exit 1
    fi
}

assert_app_code_signature() {
    local app_path="$1"
    local target

    assert_developer_id_signature "$app_path" "app" "deep"

    while IFS= read -r target; do
        assert_developer_id_signature "$target" "$(basename "$target")"
    done < <(release_app_signing_targets "$app_path")
}

assert_dmg_code_signature() {
    local dmg_path="$1"

    assert_developer_id_signature "$dmg_path" "DMG"
}

notary_json_field() {
    local json_text="$1"
    local field_name="$2"

    python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get(sys.argv[2], ""))' \
        "$json_text" \
        "$field_name"
}

notarize_file() {
    local file_path="$1"
    local submit_output
    local status
    local submission_id

    echo "Submitting $(basename "$file_path") for notarization..."
    if ! submit_output="$(
        xcrun notarytool submit "$file_path" \
            --keychain-profile "$NOTARYTOOL_PROFILE" \
            --team-id "$RELEASE_NOTARY_TEAM_ID" \
            --wait \
            --output-format json 2>&1
    )"; then
        echo "error: notarytool submit failed for $(basename "$file_path")" >&2
        echo "$submit_output" >&2
        exit 1
    fi
    echo "$submit_output"

    if ! status="$(notary_json_field "$submit_output" status)" \
        || ! submission_id="$(notary_json_field "$submit_output" id)"; then
        echo "error: failed to parse notarytool submit output" >&2
        echo "$submit_output" >&2
        exit 1
    fi

    if [[ "$status" != "Accepted" ]]; then
        echo "error: notarization status for $(basename "$file_path") is $status" >&2
        if [[ -n "$submission_id" ]]; then
            echo "Notarization log for $submission_id:" >&2
            if ! xcrun notarytool log "$submission_id" \
                --keychain-profile "$NOTARYTOOL_PROFILE" \
                --team-id "$RELEASE_NOTARY_TEAM_ID" >&2; then
                echo "warning: failed to fetch notarization log for $submission_id" >&2
            fi
        else
            echo "warning: notarytool did not return a submission id" >&2
        fi
        exit 1
    fi
}

staple_file() {
    local file_path="$1"

    echo "Stapling $(basename "$file_path")..."
    xcrun stapler staple "$file_path"
    xcrun stapler validate "$file_path"
}

notarize_app_bundle() {
    local app_path="$1"

    rm -f "$NOTARIZATION_ZIP_PATH"
    (
        cd "$ROOT_DIR"
        ditto -c -k --sequesterRsrc --keepParent "$(basename "$app_path")" "$NOTARIZATION_ZIP_PATH"
    )
    notarize_file "$NOTARIZATION_ZIP_PATH"
    staple_file "$app_path"
    rm -f "$NOTARIZATION_ZIP_PATH"
}

remove_release_tmp_path() {
    local path="$1"
    local release_tmp_dir="$ROOT_DIR/.tmp"

    if [[ "$path" != "$release_tmp_dir/"* ]]; then
        echo "warning: refusing to clean path outside .tmp: $path" >&2
        return
    fi

    rm -rf "$path"
}

cleanup_release_tmp() {
    local release_tmp_dir="$ROOT_DIR/.tmp"

    if [[ "$KEEP_RELEASE_TMP" == "1" ]]; then
        echo "Keeping release temporary files because KEEP_RELEASE_TMP=1."
        return
    fi

    echo "Cleaning release temporary files..."
    remove_release_tmp_path "$DERIVED_DATA_DIR"
    remove_release_tmp_path "$ROOT_DIR/.tmp/release-dmg-source"
    remove_release_tmp_path "$NOTARIZATION_ZIP_PATH"
    rmdir "$release_tmp_dir" 2>/dev/null || true
}

read_build_setting() {
    local setting_name="$1"
    local settings_output="$2"

    awk -F '= ' -v key="$setting_name" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            print $2
            exit
        }
    ' <<<"$settings_output"
}

read_project_build_settings() {
    python3 - "$PROJECT_PATH" "$TARGET_NAME" <<'PY'
from pathlib import Path
import re
import sys

project_path = Path(sys.argv[1])
target_name = sys.argv[2]
content = project_path.read_text(encoding="utf-8")

native_section_match = re.search(
    r"/\* Begin PBXNativeTarget section \*/(?P<body>.*?)/\* End PBXNativeTarget section \*/",
    content,
    re.S,
)
if not native_section_match:
    print("error: cannot find PBXNativeTarget section", file=sys.stderr)
    sys.exit(1)

target_match = re.search(
    r"([A-F0-9]+) /\* "
    + re.escape(target_name)
    + r" \*/ = \{(?P<body>.*?)\n\t\t\};",
    native_section_match.group("body"),
    re.S,
)
if not target_match:
    print(f"error: cannot find {target_name} target", file=sys.stderr)
    sys.exit(1)

config_list_match = re.search(
    r"buildConfigurationList = ([A-F0-9]+) "
    r"/\* Build configuration list for PBXNativeTarget \""
    + re.escape(target_name)
    + r"\" \*/;",
    target_match.group("body"),
)
if not config_list_match:
    print(f"error: cannot find {target_name} build configuration list", file=sys.stderr)
    sys.exit(1)

config_list_id = config_list_match.group(1)
config_list_block = re.search(
    re.escape(config_list_id)
    + r" /\* Build configuration list for PBXNativeTarget \""
    + re.escape(target_name)
    + r"\" \*/ = \{(?P<body>.*?)\n\t\t\};",
    content,
    re.S,
)
if not config_list_block:
    print(f"error: cannot read {target_name} build configuration list", file=sys.stderr)
    sys.exit(1)

release_config_match = re.search(
    r"([A-F0-9]+) /\* Release \*/,",
    config_list_block.group("body"),
)
if not release_config_match:
    print(f"error: cannot find {target_name} Release configuration", file=sys.stderr)
    sys.exit(1)

release_config_id = release_config_match.group(1)
release_config_block = re.search(
    re.escape(release_config_id)
    + r" /\* Release \*/ = \{(?P<body>.*?)\n\t\t\};",
    content,
    re.S,
)
if not release_config_block:
    print(f"error: cannot read {target_name} Release configuration", file=sys.stderr)
    sys.exit(1)

settings = {}
for key in ("MARKETING_VERSION", "CURRENT_PROJECT_VERSION"):
    match = re.search(r"\n\t\t\t\t" + key + r" = ([^;]+);", release_config_block.group("body"))
    if not match:
        print(f"error: cannot find {key} in {target_name} Release configuration", file=sys.stderr)
        sys.exit(1)
    settings[key] = match.group(1).strip().strip('"')

for key, value in settings.items():
    print(f"    {key} = {value}")
PY
}

assert_appcast_can_add_version() {
    local version="$1"
    local build_number="$2"

    python3 - "$APPCAST_PATH" "$version" "$build_number" <<'PY'
from pathlib import Path
import re
import sys

appcast_path = Path(sys.argv[1])
version = sys.argv[2]
build_number = sys.argv[3]
content = appcast_path.read_text(encoding="utf-8")

if re.search(r"<sparkle:shortVersionString>" + re.escape(version) + r"</sparkle:shortVersionString>", content):
    print(f"error: appcast already contains version {version}", file=sys.stderr)
    sys.exit(1)
if re.search(r"<sparkle:version>" + re.escape(build_number) + r"</sparkle:version>", content):
    print(f"error: appcast already contains build {build_number}", file=sys.stderr)
    sys.exit(1)
PY
}

load_build_settings() {
    local settings_file
    local status=0
    local elapsed=0
    local timed_out=0
    settings_file="$(mktemp)"

    xcodebuild -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -showBuildSettings >"$settings_file" 2>&1 &
    local xcodebuild_pid=$!

    while kill -0 "$xcodebuild_pid" >/dev/null 2>&1; do
        if (( elapsed >= SHOW_BUILD_SETTINGS_TIMEOUT )); then
            timed_out=1
            kill "$xcodebuild_pid" >/dev/null 2>&1 || true
            wait "$xcodebuild_pid" >/dev/null 2>&1 || true
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    if (( timed_out == 0 )); then
        wait "$xcodebuild_pid" || status=$?
    fi

    if (( status == 0 && timed_out == 0 )) \
        && grep -q "MARKETING_VERSION" "$settings_file" \
        && grep -q "CURRENT_PROJECT_VERSION" "$settings_file"; then
        cat "$settings_file"
    else
        if (( timed_out == 1 )); then
            echo "warning: xcodebuild -showBuildSettings timed out, reading project file instead" >&2
        else
            echo "warning: xcodebuild -showBuildSettings failed, reading project file instead" >&2
        fi
        read_project_build_settings
    fi

    rm -f "$settings_file"
}

insert_appcast_item() {
    local version="$1"
    local build_number="$2"
    local pub_date="$3"
    local zip_length="$4"
    local signature="$5"

    python3 - "$APPCAST_PATH" "$version" "$build_number" "$pub_date" \
        "$zip_length" "$signature" "$RELEASE_NOTES_BASE_URL" \
        "$RELEASE_DOWNLOAD_BASE_URL" "$RELEASE_SPARKLE_CHANNEL" <<'PY'
from pathlib import Path
import html
import re
import sys

appcast_path = Path(sys.argv[1])
version = sys.argv[2]
build_number = sys.argv[3]
pub_date = sys.argv[4]
zip_length = sys.argv[5]
signature = sys.argv[6]
notes_base_url = sys.argv[7].rstrip("/")
download_base_url = sys.argv[8].rstrip("/")
sparkle_channel = sys.argv[9]

content = appcast_path.read_text(encoding="utf-8")

short_version_pattern = (
    r"<sparkle:shortVersionString>"
    + re.escape(version)
    + r"</sparkle:shortVersionString>"
)
build_pattern = (
    r"<sparkle:version>"
    + re.escape(build_number)
    + r"</sparkle:version>"
)
if re.search(short_version_pattern, content):
    print(f"error: appcast already contains version {version}", file=sys.stderr)
    sys.exit(1)
if re.search(build_pattern, content):
    print(f"error: appcast already contains build {build_number}", file=sys.stderr)
    sys.exit(1)

anchor = "        <title>Easydict</title>\n"
if anchor not in content:
    print("error: cannot find appcast channel title anchor", file=sys.stderr)
    sys.exit(1)

release_url = f"{notes_base_url}/{version}"
zip_url = f"{download_base_url}/{version}/Easydict.zip"
channel_line = ""
if sparkle_channel:
    channel_line = (
        "            <sparkle:channel>"
        + html.escape(sparkle_channel)
        + "</sparkle:channel>\n"
    )

item = f"""        <item>
            <title>{html.escape(version)}</title>
{channel_line}            <pubDate>{html.escape(pub_date)}</pubDate>
            <sparkle:version>{html.escape(build_number)}</sparkle:version>
            <sparkle:shortVersionString>{html.escape(version)}</sparkle:shortVersionString>
            <sparkle:releaseNotesLink>{html.escape(release_url)}</sparkle:releaseNotesLink>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="{html.escape(zip_url)}" length="{html.escape(zip_length)}" type="application/octet-stream" sparkle:edSignature="{html.escape(signature)}"/>
        </item>
"""

appcast_path.write_text(content.replace(anchor, anchor + item, 1), encoding="utf-8")
PY
}

main() {
    cd "$ROOT_DIR"

    require_command xcodebuild
    require_command xcbeautify
    require_command python3
    require_command ditto
    require_create_dmg
    require_command codesign
    require_command security
    require_command xcrun
    require_file "$APPCAST_PATH"
    require_file "$PROJECT_PATH"
    require_signing_identity
    require_notarytool_profile

    if ! [[ "$SHOW_BUILD_SETTINGS_TIMEOUT" =~ ^[0-9]+$ ]]; then
        echo "error: SHOW_BUILD_SETTINGS_TIMEOUT must be an integer" >&2
        exit 1
    fi

    local settings_output
    settings_output="$(load_build_settings)"

    local version
    local build_number
    version="$(read_build_setting MARKETING_VERSION "$settings_output")"
    build_number="$(read_build_setting CURRENT_PROJECT_VERSION "$settings_output")"

    if [[ -z "$version" || -z "$build_number" ]]; then
        echo "error: failed to read MARKETING_VERSION or CURRENT_PROJECT_VERSION" >&2
        exit 1
    fi
    assert_appcast_can_add_version "$version" "$build_number"

    echo "Building $APP_NAME $version ($build_number)..."
    rm -rf "$DERIVED_DATA_DIR"
    xcodebuild build \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_DIR" \
        "DEVELOPMENT_TEAM=$RELEASE_DEVELOPMENT_TEAM" \
        "CODE_SIGN_STYLE=Manual" \
        "CODE_SIGN_IDENTITY=$RELEASE_CODE_SIGN_IDENTITY" \
        "OTHER_CODE_SIGN_FLAGS=--timestamp" \
        "DEPLOYMENT_POSTPROCESSING=YES" \
        "ENABLE_DEBUG_DYLIB=NO" \
        "EASYDICT_RELEASE_PACKAGING=YES" | xcbeautify

    local built_app_path="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_BUNDLE_NAME"
    require_file "$built_app_path"

    echo "Preparing $APP_BUNDLE_NAME..."
    rm -rf "$ROOT_DIR/$APP_BUNDLE_NAME"
    ditto "$built_app_path" "$ROOT_DIR/$APP_BUNDLE_NAME"
    resign_release_app "$ROOT_DIR/$APP_BUNDLE_NAME"
    assert_app_code_signature "$ROOT_DIR/$APP_BUNDLE_NAME"

    notarize_app_bundle "$ROOT_DIR/$APP_BUNDLE_NAME"

    echo "Creating $APP_ZIP_NAME..."
    rm -f "$ROOT_DIR/$APP_ZIP_NAME"
    (
        cd "$ROOT_DIR"
        ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE_NAME" "$APP_ZIP_NAME"
    )

    echo "Signing $APP_ZIP_NAME for Sparkle..."
    local sign_update_bin
    sign_update_bin="$(resolve_sign_update)"

    local sign_output
    if [[ -n "${SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
        sign_output="$(
            cd "$ROOT_DIR"
            "$sign_update_bin" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" "$APP_ZIP_NAME"
        )"
    else
        sign_output="$(
            cd "$ROOT_DIR"
            "$sign_update_bin" "$APP_ZIP_NAME"
        )"
    fi
    echo "$sign_output"

    local zip_length
    local signature
    zip_length="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' <<<"$sign_output" | head -n 1)"
    signature="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' <<<"$sign_output" | head -n 1)"

    if [[ -z "$zip_length" || -z "$signature" ]]; then
        echo "error: failed to parse Sparkle signature output" >&2
        echo "$sign_output" >&2
        exit 1
    fi

    local actual_zip_length
    actual_zip_length="$(stat -f '%z' "$ROOT_DIR/$APP_ZIP_NAME")"
    if [[ "$zip_length" != "$actual_zip_length" ]]; then
        echo "error: Sparkle length $zip_length does not match $APP_ZIP_NAME size $actual_zip_length" >&2
        exit 1
    fi

    echo "Updating appcast.xml..."
    local pub_date
    pub_date="$(TZ=Asia/Shanghai date '+%a, %d %b %Y %H:%M:%S %z')"
    insert_appcast_item "$version" "$build_number" "$pub_date" "$zip_length" "$signature"

    echo "Creating $APP_DMG_NAME..."
    rm -f "$ROOT_DIR/$APP_DMG_NAME"
    (
        cd "$ROOT_DIR"
        "$CREATE_DMG_BIN" \
            --overwrite \
            --no-version-in-filename \
            --identity="$RELEASE_CODE_SIGN_IDENTITY" \
            "$APP_BUNDLE_NAME" \
            "$ROOT_DIR"
    )
    require_file "$ROOT_DIR/$APP_DMG_NAME"
    assert_dmg_code_signature "$ROOT_DIR/$APP_DMG_NAME"
    notarize_file "$ROOT_DIR/$APP_DMG_NAME"
    staple_file "$ROOT_DIR/$APP_DMG_NAME"

    echo "Release artifacts ready:"
    echo "  $ROOT_DIR/$APP_BUNDLE_NAME"
    echo "  $ROOT_DIR/$APP_ZIP_NAME"
    echo "  $ROOT_DIR/$APP_DMG_NAME"
    cleanup_release_tmp
}

main "$@"
