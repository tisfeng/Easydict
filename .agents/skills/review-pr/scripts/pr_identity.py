"""Compare GitHub PR identities without rewriting the collected evidence."""

from urllib.parse import urlsplit


def same_repository(actual, expected):
    """GitHub owner and repository names are case-insensitive."""
    return (isinstance(actual, str) and isinstance(expected, str)
            and bool(actual) and actual.casefold() == expected.casefold())


def matches_pr_url(value, repo, number):
    """Match the supported host and exact PR, ignoring only repository casing."""
    if (not isinstance(value, str) or type(number) is not int or number <= 0
            or any(ord(character) < 33 or ord(character) == 127 for character in value)):
        return False
    try:
        url = urlsplit(value)
    except ValueError:
        return False
    parts = url.path.split("/")
    return (url.scheme == "https" and url.netloc.casefold() == "github.com"
            and not url.query and not url.fragment
            and len(parts) == 5 and parts[0] == ""
            and parts[3:] == ["pull", str(number)]
            and same_repository("/".join(parts[1:3]), repo))
