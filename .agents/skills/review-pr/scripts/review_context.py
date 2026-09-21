#!/usr/bin/env python3
"""Collect read-only problem evidence; never infer requirements from references."""

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import re
import subprocess
from urllib.parse import urlparse

from review_threads import graphql, next_cursor


REPO = r"[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*"
REFERENCE = re.compile(
    rf"https://github\.com/{REPO}/issues/[1-9]\d*(?:#issuecomment-\d+)?(?![\w/])"
    rf"|(?<![\w/.-])(?:{REPO})?#[1-9]\d*(?![\w/-])"
)
ISSUE_FIELDS = "id number url title body state updatedAt"
COMMENT_FIELDS = "id url body createdAt updatedAt author { login }"
PAGE = "pageInfo { hasNextPage endCursor }"


class ContextDriftError(ValueError):
    """The PR anchor changed; partial-context fallback must not hide that drift."""


def parse_reference(reference, repo):
    """Resolve literal GitHub issue identities without accepting arbitrary URLs."""
    if not isinstance(reference, str) or not re.fullmatch(REPO, repo):
        raise ValueError("Invalid issue reference or base repository")
    reference = reference.strip()
    if reference.startswith("https://"):
        url = urlparse(reference)
        match = re.fullmatch(rf"/({REPO})/issues/([1-9]\d*)/?", url.path)
        if url.netloc.lower() != "github.com" or url.query or not match:
            raise ValueError("Expected a github.com issue URL")
        repo, number = match.groups()
    else:
        match = re.fullmatch(rf"(?:(?P<repo>{REPO})#|#?)(?P<number>[1-9]\d*)", reference)
        if not match:
            raise ValueError("Expected #NUMBER, OWNER/REPO#NUMBER or a GitHub issue URL")
        repo, number = match.group("repo") or repo, match.group("number")
    return repo.lower(), int(number)


def normalized(reference, repo):
    owner_repo, number = parse_reference(reference, repo)
    return f"{owner_repo}#{number}"


def find_references(text, repo):
    """Find direct prose references; fenced and inline examples are not requirements."""
    text = re.sub(r"(?ms)^\s*(`{3,}|~{3,}).*?^\s*\1\s*$", "", text or "")
    text = re.sub(r"`[^`\n]*`", "", text)
    return sorted({normalized(match.group(), repo) for match in REFERENCE.finditer(text)})


def closing_references(repo, pr):
    """Expand a possibly capped gh reference list, retaining a PR-head guard."""
    references = pr.get("closingIssuesReferences")
    if not isinstance(references, list):
        raise ValueError("PR closing issue references were not collected")
    if len(references) < 100:
        return references
    owner, name = repo.split("/")
    query = """query($owner:String!,$name:String!,$number:Int!,$cursor:String){
      repository(owner:$owner,name:$name){pullRequest(number:$number){
        url headRefOid closingIssuesReferences(first:100,after:$cursor){
          nodes { id number url } %s
        }
      }}
    }""" % PAGE
    cursor, seen, result = None, set(), []
    while True:
        current = graphql(query, owner=owner, name=name, number=pr["number"], cursor=cursor)["repository"]["pullRequest"]
        if current["url"] != pr["url"] or current["headRefOid"] != pr["headRefOid"]:
            raise ContextDriftError("PR changed during closing issue collection")
        connection = current["closingIssuesReferences"]
        result.extend(connection["nodes"])
        cursor = next_cursor(connection, seen)
        if cursor is None:
            break
    if len({item["url"].lower() for item in result}) != len(result):
        raise ValueError("Duplicate closing issues during pagination")
    return result


def issue_query(include_comments):
    comments = f"nodes {{ {COMMENT_FIELDS} }} {PAGE}" if include_comments else ""
    cursor_declaration = ",$cursor:String" if include_comments else ""
    arguments = "(first:100,after:$cursor)" if include_comments else ""
    return """query($owner:String!,$name:String!,$number:Int!%s){
      repository(owner:$owner,name:$name){issueOrPullRequest(number:$number){
        __typename ... on Issue { %s comments%s { totalCount %s } }
      }}
    }""" % (cursor_declaration, ISSUE_FIELDS, arguments, comments)


def read_issue(repo, number, include_comments=False):
    """Read a body and, when selected, all discussion pages with identity guards."""
    owner, name = repo.split("/")
    variables = dict(owner=owner, name=name, number=number)
    cursor, seen, header, items, count = None, set(), None, [], None
    while True:
        data = graphql(issue_query(include_comments), **variables,
                       **({"cursor": cursor} if include_comments else {}))
        repository = data.get("repository")
        node = repository.get("issueOrPullRequest") if repository else None
        if node is None:
            if header is not None:
                raise ValueError("Issue disappeared during discussion collection")
            return {"read_status": "unavailable", "diagnostic": "Issue not found or not visible"}
        if node.get("__typename") != "Issue":
            return {"read_status": "not_issue", "diagnostic": "Reference points to a pull request, not an issue"}
        current = {key: node[key] for key in ISSUE_FIELDS.split()}
        if parse_reference(current["url"], repo) != (repo.lower(), number) or current["number"] != number:
            raise ValueError("Issue identity does not match the requested repository/number")
        if not all(isinstance(current[key], str) for key in ("id", "url", "title", "body", "state", "updatedAt")):
            raise ValueError("Issue is missing required evidence fields")
        connection = node["comments"]
        total = connection["totalCount"]
        if not isinstance(total, int) or total < 0:
            raise ValueError("Invalid issue discussion count")
        if header is not None and (current != header or total != count):
            raise ValueError("Issue changed during discussion pagination")
        header, count = current, total
        if not include_comments:
            break
        for comment in connection["nodes"]:
            if not all(isinstance(comment.get(key), str) for key in ("id", "url", "body", "createdAt", "updatedAt")):
                raise ValueError("Issue discussion is missing required evidence fields")
            items.append(comment)
        cursor = next_cursor(connection, seen)
        if cursor is None:
            if len(items) != count or len({item["id"] for item in items}) != count:
                raise ValueError("Incomplete or duplicate issue discussion")
            final = graphql(issue_query(False), **variables)["repository"]["issueOrPullRequest"]
            if (final is None or final.get("__typename") != "Issue"
                    or {key: final[key] for key in ISSUE_FIELDS.split()} != header
                    or final["comments"]["totalCount"] != count):
                raise ValueError("Issue changed after discussion pagination")
            break
    return {"read_status": "read", "issue": header,
            "comments": {"status": "complete" if include_comments or count == 0 else "not_requested",
                         "totalCount": count, "items": items}}


def collect(repo, pr, issue_refs=(), discussion_refs=()):
    """Read direct sources in bounded parallelism; failures remain explicit gaps."""
    requested = sorted({normalized(ref, repo) for ref in issue_refs})
    discussions = sorted({normalized(ref, repo) for ref in discussion_refs})
    sources, reference_errors = {}, []

    def add(reference, relation):
        identity = parse_reference(reference, repo)
        sources.setdefault(identity, set()).add(relation)

    try:
        closing = closing_references(repo, pr)
    except ContextDriftError:
        raise
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as error:
        # A missing connection is a coverage failure, not proof of no linked issues.
        closing = pr.get("closingIssuesReferences") or []
        reference_errors.append(str(error))
    for item in closing:
        try:
            add(item["url"], "closing")
        except (ValueError, KeyError, TypeError) as error:
            reference_errors.append(str(error))
    for reference in find_references((pr.get("title") or "") + "\n" + (pr.get("body") or ""), repo):
        add(reference, "mentioned")
    for reference in requested:
        add(reference, "requested")
    for reference in discussions:
        add(reference, "discussion")

    def read(source):
        (source_repo, number), relations = source
        reference = f"{source_repo}#{number}"
        record = {"repo": source_repo, "number": number,
                  "url": f"https://github.com/{source_repo}/issues/{number}", "relations": sorted(relations)}
        try:
            record.update(read_issue(source_repo, number, reference in discussions))
        except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as error:
            detail = str(error)
            if isinstance(error, subprocess.CalledProcessError):
                detail = error.stderr or detail
            status = "read_failed"
            if re.search(r"FORBIDDEN|UNAUTHORIZED|HTTP (?:401|403)", detail, re.I):
                status = "permission_denied"
            elif re.search(r"NOT_FOUND|HTTP 404|Could not resolve", detail, re.I):
                status = "unavailable"
            record.update(read_status=status, diagnostic=detail)
        return record

    with ThreadPoolExecutor(max_workers=4) as executor:
        issues = list(executor.map(read, sorted(sources.items())))
    return {"schema_version": 1, "requested_issues": requested, "discussion_issues": discussions,
            "references_complete": not reference_errors, "reference_errors": reference_errors,
            "issues": issues}


def content_hash(value):
    """Return a stable SHA-256 digest for JSON-compatible content."""
    payload = json.dumps(
        value,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def source_id(issue):
    """Return the stable identity used to compare problem sources."""
    return f"{issue['repo']}#{issue['number']}"


def source_fingerprint(issue):
    """Fingerprint one source's content, excluding transport diagnostic wording."""
    return content_hash({key: value for key, value in issue.items() if key != "diagnostic"})


def fingerprint_pr(pr):
    """Fingerprint PR-level evidence without the problem context section."""
    result = {key: value for key, value in pr.items() if key != "reviewContext"}
    if isinstance(pr.get("closingIssuesReferences"), list):
        result["closingIssuesReferences"] = sorted(
            pr["closingIssuesReferences"], key=lambda item: json.dumps(item, sort_keys=True)
        )
    return result


def fingerprint_context(context):
    """Keep source content and coverage, excluding transport diagnostic wording."""
    if not isinstance(context, dict):
        return context
    result = dict(context)
    result.pop("reference_errors", None)
    result["issues"] = sorted(
        [{key: value for key, value in issue.items() if key != "diagnostic"}
         for issue in context.get("issues", [])], key=lambda issue: (issue["repo"], issue["number"]))
    return result


def coverage(context):
    """Describe requirement-evidence coverage without claiming the goal is understood."""
    if not isinstance(context, dict) or context.get("schema_version") != 1:
        return "not_collected"
    if not context.get("references_complete") or any(item.get("read_status") != "read" for item in context["issues"]):
        return "partial"
    return "bodies_collected"
