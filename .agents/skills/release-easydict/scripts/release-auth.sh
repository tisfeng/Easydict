#!/usr/bin/env bash

# Select file-backed ASC credentials only within the release process tree.
configure_release_auth() {
    local config_path="${EASYDICT_RELEASE_ASC_CONFIG:-$HOME/.config/easydict/release/asc-config.json}"
    local profile="Easydict Release"

    if ! python3 - "$config_path" "$profile" <<'PY'
import json
import os
from pathlib import Path
import stat
import subprocess
import sys


def validate_private_file(path):
    if not path.is_absolute() or path.is_symlink():
        raise ValueError("credential paths must be absolute regular files, not symlinks")
    info = path.stat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid():
        raise ValueError("credential files must be owned by the current user")
    if stat.S_IMODE(info.st_mode) != 0o600:
        raise ValueError("credential files must have mode 600")
    parent = path.parent.stat()
    if parent.st_uid != os.getuid() or stat.S_IMODE(parent.st_mode) != 0o700:
        raise ValueError("credential directories must be owned by the current user with mode 700")
    result = subprocess.run(
        ["git", "-C", str(path.resolve().parent), "rev-parse", "--is-inside-work-tree"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    if result.returncode == 0:
        raise ValueError("credentials must be stored outside Git worktrees")


try:
    config = Path(sys.argv[1])
    validate_private_file(config)
    data = json.loads(config.read_text())
    profiles = [key for key in data.get("keys", []) if key.get("name") == sys.argv[2]]
    if len(profiles) != 1:
        raise ValueError("release config must contain exactly one matching profile")
    profile = profiles[0]
    if not profile.get("key_id") or not profile.get("issuer_id"):
        raise ValueError("release profile requires key_id and issuer_id")
    validate_private_file(Path(profile["private_key_path"]))
except (OSError, ValueError, KeyError, TypeError, AttributeError):
    print("error: release ASC file authentication is missing or invalid; use an external config and key with file mode 600 and directory mode 700", file=sys.stderr)
    sys.exit(1)
PY
    then
        return 1
    fi

    # Prevent ambient credentials from being mixed with the release profile.
    unset ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY_PATH ASC_PRIVATE_KEY ASC_PRIVATE_KEY_B64 ASC_KEY_TYPE
    export ASC_CONFIG_PATH="$config_path"
    export ASC_PROFILE="$profile"
    export ASC_BYPASS_KEYCHAIN=1
    export ASC_STRICT_AUTH=1
}
