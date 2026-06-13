#!/usr/bin/env python3
"""Normalize the opencode (sst/opencode) GitHub Releases JSON into the shared schema.

Reads the GitHub Releases API JSON array from stdin and prints
`[ { version, date, published_at, url, change_count, changes[] } ]` to stdout — one element per
release, newest first, filtered to the last N days, excluding draft/prerelease.

Release bodies are structured markdown: `## <Component>` (Core/Desktop/TUI/Web) → `### <Category>`
(Improvements/Bugfixes) → `- bullet`. Each bullet is kept verbatim, prefixed with its
`[Component/Category]` context as a classification hint. Releases that are bare prose (no
bullets, e.g. "Fixed issue with 1.17.2 desktop crashing") keep the whole body as one change.

Invariant: keep every line verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone

REPO_URL = "https://github.com/sst/opencode"


def parse_body(body):
    component = None
    category = None
    changes = []
    prose = []
    for raw in body.splitlines():
        line = raw.rstrip()
        # the trailing "Thank you to N community contributors" block is a raw per-PR dump
        # that duplicates the curated notes above — stop there.
        if re.search(r"thank you to .*contributors", line, re.I):
            break
        if line.startswith("## "):
            component, category = line[3:].strip(), None
        elif line.startswith("### "):
            category = line[4:].strip()
        elif re.match(r"^\s*[-*]\s+", line):
            item = re.sub(r"^\s*[-*]\s+", "", line).strip()
            ctx = "/".join(x for x in (component, category) if x)
            changes.append(f"[{ctx}] {item}" if ctx else item)
        elif line.strip():
            prose.append(line.strip())
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
