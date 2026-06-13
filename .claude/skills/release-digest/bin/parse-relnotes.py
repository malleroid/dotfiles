#!/usr/bin/env python3
"""Parse the Claude Developer Platform release-notes markdown into normalized JSON.

Reads the raw `.md` of platform.claude.com/docs/en/release-notes/overview from stdin and
prints `[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per dated
`### <Month D, YYYY>` section, newest first, filtered to the last N days.

Invariant: keep every bullet verbatim. Classification/translation is the skill's (LLM) job,
not this parser's.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone
from _window import cutoff_date

PAGE_URL = "https://platform.claude.com/docs/en/release-notes/overview"
BASE = "https://platform.claude.com"


def parse_heading_date(s):
    # "June 5, 2026" and the older "April 9th, 2025" ordinal form.
    s = re.sub(r"(\d+)(st|nd|rd|th)", r"\1", s)
    return datetime.strptime(s.strip(), "%B %d, %Y").date()


def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def absolutize(text):
    # Rewrite relative doc links: ](/docs/...) -> ](https://platform.claude.com/docs/...)
    return re.sub(r"\]\((/[^)]+)\)", lambda m: "](" + BASE + m.group(1) + ")", text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    sections = []
    cur = None
    for line in sys.stdin.read().splitlines():
        m = re.match(r"^###\s+(.+?)\s*$", line)
        if m:
            try:
                d = parse_heading_date(m.group(1))
            except ValueError:
                cur = None  # not a date heading; ignore until the next one
                continue
            cur = {"heading": m.group(1), "date": d, "changes": []} if d >= cutoff else None
            if cur is not None:
                sections.append(cur)
            continue
        if cur is not None and line.startswith("- "):
            cur["changes"].append(absolutize(line[2:].strip()))

    out = [
        {
            "unit": s["date"].isoformat(),
            "date": s["date"].isoformat(),
            "url": f"{PAGE_URL}#{slug(s['heading'])}",
            "change_count": len(s["changes"]),
            "changes": s["changes"],
        }
        for s in sections
    ]
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
