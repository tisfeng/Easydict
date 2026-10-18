"""Shared release PR classification rules."""

from __future__ import annotations

from typing import Any


IGNORED_BOT_LOGINS = {
    "app/dependabot",
    "app/github-actions",
    "dependabot[bot]",
    "github-actions[bot]",
}


def author_login(pr: dict[str, Any]) -> str:
    author = pr.get("author")
    if isinstance(author, dict):
        login = author.get("login")
    else:
        login = author
    return login if isinstance(login, str) else ""


def author_is_bot(pr: dict[str, Any]) -> bool:
    author = pr.get("author")
    return isinstance(author, dict) and author.get("is_bot") is True


def classify_release_pr(pr: dict[str, Any]) -> dict[str, str]:
    """Return the stable inclusion decision used by notes and follow-up."""
    login = author_login(pr)
    normalized_login = login.casefold()
    if author_is_bot(pr) or normalized_login in IGNORED_BOT_LOGINS:
        if "star-history" in str(pr.get("title") or "").casefold():
            reason = "generated star-history assets by a bot"
        elif "dependabot" in normalized_login or "deps" in str(
            pr.get("title") or ""
        ).casefold():
            reason = "automated dependency update by a bot"
        else:
            reason = "automated PR authored by a bot"
        return {"decision": "ignored", "reason": reason}
    return {"decision": "included", "reason": "human-authored release change"}
