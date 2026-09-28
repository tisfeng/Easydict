# Security reporting

Please avoid posting exploit details, credentials or private diagrams in public
issues. Use GitHub private vulnerability reporting if it is available in the
repository Security tab. If no private channel is offered, open an issue asking
the maintainer for a private contact route without including the vulnerability.

Include the installed version/source, affected command, a minimal redacted input,
expected and actual behavior, and the security impact. No response-time guarantee
or enabled reporting channel is implied by this document.

SVG, HTML and browser rendering have different accepted-content boundaries.
Keep renderer sandboxing enabled unless an explicitly configured isolated runtime
requires the documented opt-in. Do not execute remote SVG scripts to reproduce an
issue. Maintainers should reproduce reports with minimum privileges and record
fixed versions in the changelog.
