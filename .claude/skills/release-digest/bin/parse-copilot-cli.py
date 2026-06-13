#!/usr/bin/env python3
"""Normalize the GitHub Copilot CLI (github/copilot-cli) Releases JSON into the shared schema.

Reads the GitHub Releases API JSON array from stdin and prints
`[ { version, date, published_at, url, change_count, changes[] } ]` to stdout — one element per
release, newest first, filtered to the last N days, excluding draft/prerelease.

Release bodies come in two shapes:
  (a) bold category labels:  **Added** / **Improved** / **Fixed** then `- bullet`
  (b) flat:                  a bare date line (e.g. "2026-06-09") then `- bullet`
Each bullet is kept verbatim, prefixed with its `[Category]` label as a hint when present.

Invariant: keep every line verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone

REPO_URL = "https://github.com/github/copilot-cli"
BOLD_LABEL = re.compile(r"^\*\*(.+?)\*\*$")
BARE_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def parse_body(body):
    category = None
    changes = []
    prose = []
    for raw in body.splitlines():
        line = raw.strip()
        if not line or BARE_DATE.match(line):
            continue
        m = BOLD_LABEL.match(line)
        if m:
            category = m.group(1).strip()
        elif re.match(r"^[-*]\s+", line):
            item = re.sub(r"^[-*]\s+", "", line).strip()
            changes.append(f"[{category}] {item}" if category else item)
        else:
            prose.append(line)
    if not changes and prose:
        changes = [" ".join(prose)]
    return changes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    releases = json.load(sys.stdin)
    out = []
    for r in releases:
        if r.get("draft") or r.get("prerelease"):
            continue
        published = r.get("published_at", "")
        try:
            date = datetime.fromisoformat(published.replace("Z", "+00:00")).date()
        except ValueError:
            continue
        if date < cutoff:
            continue
        changes = parse_body(r.get("body", "") or "")
        if not changes:
            continue
        out.append({
            "version": r.get("tag_name", ""),
            "date": date.isoformat(),
            "published_at": published,
            "url": r.get("html_url", REPO_URL),
            "change_count": len(changes),
            "changes": changes,
        })
    out.sort(key=lambda e: e["published_at"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
