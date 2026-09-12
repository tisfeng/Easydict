#!/usr/bin/env python3
"""Opt-in, immutable local transport for fully collected PR evidence."""

import hashlib
import json
import os
from pathlib import Path


def encode(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def save(path, snapshot, report):
    """Create a task-owned private file; never replace an existing path/symlink."""
    raw = encode({"schema_version": 1, "snapshot": snapshot, "report": report})
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "wb") as stream:
        stream.write(raw)
    return hashlib.sha256(raw).hexdigest()


def read(path, expected_hash):
    raw = Path(path).read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected_hash:
        raise ValueError("Saved snapshot hash changed; recollect evidence")
    payload = json.loads(raw)
    if not isinstance(payload, dict) or payload.get("schema_version") != 1:
        raise ValueError("Unsupported saved snapshot")
    if not isinstance(payload.get("snapshot"), dict) or not isinstance(payload.get("report"), dict):
        raise ValueError("Saved snapshot is missing complete evidence/report")
    return payload


def page(path, expected_hash, offset=0, chars=24000):
    payload = read(path, expected_hash)
    snapshot, report = payload["snapshot"], payload["report"]
    raw = encode(report)
    text = raw.decode("utf-8")
    if offset < 0 or offset > len(text) or chars <= 0:
        raise ValueError("Page offset must be within evidence and chars must be positive")
    end = min(offset + chars, len(text))
    return {
        "schema_version": 1, "mode": report["mode"], "transport": "paged",
        "snapshot_file": str(Path(path).absolute()), "storage_sha256": expected_hash,
        "repo": snapshot["repo"], "number": snapshot["number"],
        "headRefOid": snapshot["headRefOid"], "baseRefName": snapshot["pr"]["baseRefName"],
        "baseRefOid": snapshot["pr"]["baseRefOid"],
        "fingerprints": snapshot["fingerprints"], "summary": snapshot["summary"],
        "page": {"text": text[offset:end], "sha256": hashlib.sha256(raw).hexdigest(),
                 "total_bytes": len(raw), "total_chars": len(text), "offset": offset,
                 "end": end, "next_offset": end if end < len(text) else None,
                 "complete": offset == 0 and end == len(text)},
    }
