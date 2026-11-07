#!/usr/bin/env python3
"""Losslessly normalize the GitHub Releases API response for Claude Code.

Reads the Releases JSON array on stdin and prints
`[ { version, date, published_at, url, change_count, bugfix_only, changes[] } ]`
for non-draft, non-prerelease versions whose JST publish date is within the last N days.

Invariant: keep every CHANGELOG bullet. Classification and translation are the skill's job.
"""
import argparse
import json
import sys
from datetime import datetime

from _window import cutoff_date, jst_date

BUGFIX_ONLY = ["Bug fixes and reliability improvements"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    units = []
    for rel in json.load(sys.stdin):
        if rel.get("draft") or rel.get("prerelease") or not rel.get("published_at"):
            continue
        day = jst_date(datetime.fromisoformat(rel["published_at"].replace("Z", "+00:00")))
        if day < cutoff:
            continue
        changes = [line[2:] for line in (rel.get("body") or "").split("\n") if line.startswith("- ")]
        units.append({
            "version": rel["tag_name"],
            "date": day.isoformat(),
            "published_at": rel["published_at"],
            "url": rel["html_url"],
            "change_count": len(changes),
            "bugfix_only": changes == BUGFIX_ONLY,
            "changes": changes,
        })
    json.dump(units, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
