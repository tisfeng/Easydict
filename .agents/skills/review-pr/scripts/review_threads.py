#!/usr/bin/env python3
"""Collect complete review threads or apply evidence-backed, snapshot-bound decisions."""

import argparse
import hashlib
import json
import subprocess
import sys


COMMENT_FIELDS = "id databaseId url body updatedAt createdAt author { login } commit { oid }"
PAGE = "pageInfo { hasNextPage endCursor }"
THREAD_FIELDS = "id isResolved isOutdated viewerCanResolve path line originalLine"


def graphql(query, **variables):
    args = ["gh", "api", "graphql", "-f", "query=" + query]
    for key, value in variables.items():
        if value is not None:
            args += ["-F", f"{key}={value}"]
    result = subprocess.run(args, check=True, capture_output=True, text=True, timeout=60)
    payload = json.loads(result.stdout)
    if payload.get("errors") or not payload.get("data"):
        raise ValueError("GraphQL returned errors or missing data: " + json.dumps(payload))
    return payload["data"]


def next_cursor(connection, seen):
    info = connection["pageInfo"]
    if not info["hasNextPage"]:
        return None
    cursor = info["endCursor"]
    if not cursor or cursor in seen:
        raise ValueError("Incomplete or cyclic pagination")
    seen.add(cursor)
    return cursor


def collect(repo, number):
    owner, name = repo.split("/")
    query = """query($owner:String!,$name:String!,$number:Int!,$cursor:String){
      repository(owner:$owner,name:$name){pullRequest(number:$number){
        id url headRefOid state reviewThreads(first:100,after:$cursor){
          nodes { %s comments(first:100){nodes{%s} %s} } %s
        }
      }}
    }""" % (THREAD_FIELDS, COMMENT_FIELDS, PAGE, PAGE)
    comments_query = """query($id:ID!,$cursor:String){node(id:$id){
      ... on PullRequestReviewThread { comments(first:100,after:$cursor){nodes{%s} %s} }
    }}""" % (COMMENT_FIELDS, PAGE)
    cursor, seen, threads, identity = None, set(), [], None
    while True:
        pr = graphql(query, owner=owner, name=name, number=number, cursor=cursor)["repository"]["pullRequest"]
        current = {key: pr[key] for key in ("id", "url", "headRefOid", "state")}
        if identity is not None and current != identity:
            raise ValueError("PR changed during collection; collect again")
        identity = current
        connection = pr["reviewThreads"]
        for thread in connection["nodes"]:
            comments = thread["comments"]
            nodes = list(comments["nodes"])
            comment_seen = set()
            while True:
                comment_cursor = next_cursor(comments, comment_seen)
                if comment_cursor is None:
                    break
                comments = graphql(comments_query, id=thread["id"], cursor=comment_cursor)["node"]["comments"]
                nodes.extend(comments["nodes"])
            thread["comments"] = nodes
            threads.append(thread)
        cursor = next_cursor(connection, seen)
        if cursor is None:
            break
    if len({t["id"] for t in threads}) != len(threads):
        raise ValueError("Duplicate threads during collection")
    for thread in threads:
        if len({c["id"] for c in thread["comments"]}) != len(thread["comments"]):
            raise ValueError("Duplicate comments during collection")
    # Comment pagination can outlive the final thread page's head observation.
    final_query = """query($owner:String!,$name:String!,$number:Int!){
      repository(owner:$owner,name:$name){pullRequest(number:$number){id url headRefOid state}}
    }"""
    final = graphql(final_query, owner=owner, name=name, number=number)["repository"]["pullRequest"]
    if final != identity:
        raise ValueError("PR changed during collection; collect again")
    return {"repo": repo, "number": number, **identity, "threads": threads}


def fingerprint(thread):
    content = {key: value for key, value in thread.items() if key != "fingerprint"}
    return hashlib.sha256(json.dumps(content, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def validate_plan(plan):
    if plan.get("version") != 1:
        raise ValueError("Unsupported plan version")
    for key in ("repo", "number", "id", "headRefOid", "decisions"):
        if key not in plan:
            raise ValueError("Missing plan field: " + key)
    seen = set()
    for decision in plan["decisions"]:
        if decision["thread_id"] in seen:
            raise ValueError("Duplicate decision")
        seen.add(decision["thread_id"])
        if decision["assessment"] not in ("fixed", "not_applicable"):
            raise ValueError("Only fixed/not_applicable can be resolved")
        for key in ("fingerprint", "evidence", "permalink"):
            if not isinstance(decision.get(key), str) or not decision[key].strip():
                raise ValueError("Missing decision field: " + key)
        if decision.get("evidence_head") != plan["headRefOid"]:
            raise ValueError("Evidence must refer to the remote head")


def apply_plan(plan):
    validate_plan(plan)
    results = []
    for decision in plan["decisions"]:
        record = dict(decision)
        results.append(record)
        attempted = False
        try:
            before = collect(plan["repo"], plan["number"])
            if before["id"] != plan["id"] or before["headRefOid"] != plan["headRefOid"] or before["state"] != "OPEN":
                record["status"] = "stale_pr"
                break
            thread = next((t for t in before["threads"] if t["id"] == decision["thread_id"]), None)
            if thread is None:
                record["status"] = "missing_thread"
                continue
            if thread["isResolved"]:
                record["status"] = "already_resolved"
                continue
            if fingerprint(thread) != decision["fingerprint"]:
                record["status"] = "stale_thread"
                continue
            if not thread["viewerCanResolve"]:
                record["status"] = "cannot_resolve"
                continue
            attempted = True
            graphql("mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}", id=thread["id"])
            after = collect(plan["repo"], plan["number"])
            actual = next((t for t in after["threads"] if t["id"] == thread["id"]), None)
            record["observed_head"] = after["headRefOid"]
            if actual is None:
                record["status"] = "unknown_after_mutation"
                break
            expected = dict(thread, isResolved=True, viewerCanResolve=actual["viewerCanResolve"])
            if (after["headRefOid"] != plan["headRefOid"] or after["id"] != plan["id"]
                    or after["state"] != "OPEN" or actual != expected):
                record["status"] = "changed_after_mutation"
                record["isResolved"] = actual["isResolved"]
                break
            record["status"] = "resolved"
        except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as error:
            record["status"] = "unknown_after_mutation" if attempted else "error"
            record["error"] = str(error)
            break
    for decision in plan["decisions"][len(results):]:
        results.append(dict(decision, status="not_attempted"))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    snapshot = sub.add_parser("collect")
    snapshot.add_argument("--repo", required=True)
    snapshot.add_argument("--pr", type=int, required=True)
    apply = sub.add_parser("apply")
    apply.add_argument("--plan", required=True)
    apply.add_argument("--allow-resolve", action="store_true")
    args = parser.parse_args()
    try:
        if args.command == "collect":
            result = collect(args.repo, args.pr)
            for thread in result["threads"]:
                thread["fingerprint"] = fingerprint(thread)
            failed = False
        else:
            if not args.allow_resolve:
                parser.error("apply requires --allow-resolve after workflow authorization")
            with open(args.plan, encoding="utf-8") as stream:
                result = apply_plan(json.load(stream))
            failed = any(r["status"] not in ("resolved", "already_resolved") for r in result)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 1 if failed else 0
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
