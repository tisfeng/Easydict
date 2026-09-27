#!/usr/bin/env python3
"""Report the installed preparation helper and its bundled runtime dependencies."""

import hashlib
import json
from pathlib import Path
import sys


# Keep the transitive preparation dependencies explicit, including this collector.
# Snapshot collection and reporting assets are outside this execution boundary.
PREPARATION_FILES = (
    "scripts/prepare-pr-branch.sh",
    "scripts/prepare_helper_fingerprint.py",
    "scripts/prepare_pr_metadata.py",
    "scripts/pr_identity.py",
    "scripts/snapshot_transport.py",
)


def collect():
    """Hash relative names and file bytes independently of the installation path."""
    root = Path(__file__).resolve().parent.parent
    files = {name: hashlib.sha256((root / name).read_bytes()).hexdigest()
             for name in PREPARATION_FILES}
    manifest = json.dumps(files, sort_keys=True, separators=(",", ":")).encode("utf-8")
    entrypoint = "scripts/prepare-pr-branch.sh"
    return {
        "path": str(root / entrypoint),
        "sha256": files[entrypoint],
        "files": files,
        "bundle_sha256": hashlib.sha256(manifest).hexdigest(),
    }


def main():
    try:
        print(json.dumps(collect(), sort_keys=True))
        return 0
    except OSError as error:
        print(f"Cannot fingerprint preparation assets: {error}. "
              "Restore the complete skill installation and rerun preparation.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
