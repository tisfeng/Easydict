#!/usr/bin/env python3
"""Read preparation metadata from an identity- and hash-bound saved snapshot."""

import argparse
import re
import sys

import snapshot_transport
from pr_identity import matches_pr_url, same_repository


def metadata(path, storage_hash, repo, number):
    saved = snapshot_transport.read(path, storage_hash)["snapshot"]
    pr = saved["pr"]
    if (saved["schema_version"] != 1 or not same_repository(saved["repo"], repo)
            or saved["number"] != number or pr["number"] != number
            or not matches_pr_url(pr["url"], repo, number)
            or pr["headRefOid"] != saved["headRefOid"]):
        raise ValueError("Saved snapshot does not match the requested PR identity/head")
    owner = pr["headRepositoryOwner"]["login"]
    repository = pr["headRepository"]["name"]
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*", owner):
        raise ValueError("Invalid head owner")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", repository):
        raise ValueError("Invalid head repository")
    if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", pr["headRefOid"]):
        raise ValueError("Invalid head SHA")
    values = [owner, repository, pr["headRefName"], pr["headRefOid"], pr["baseRefName"],
              str(number), pr["url"]]
    if any(not isinstance(value, str) or not value or any(c.isspace() for c in value)
           or "\0" in value for value in values):
        raise ValueError("Missing or unsafe preparation metadata")
    return "\t".join(values)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot-file", required=True)
    parser.add_argument("--storage-sha256", required=True)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr", type=int, required=True)
    args = parser.parse_args()
    try:
        print(metadata(args.snapshot_file, args.storage_sha256, args.repo, args.pr))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
