#!/usr/bin/env python3
"""Parse the Claude Apps release-notes markdown into normalized JSON.

Reads the raw `.md` of the support.claude.com release-notes article from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per dated
`### <Month D, YYYY>` section, newest first, filtered to the last N days.

Page shape (differs from the Dev Platform notes):
  ## June 2026              <- month group, ignored
  ### June 9, 2026          <- date section
  **Entry title**           <- bold line starts an entry
  Paragraph text...         <- description (may include `- ` sub-bullets)

Each entry (title + following paragraphs/bullets, up to the next bold-title line or heading)
becomes one element of `changes[]`, kept verbatim with newlines preserved.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone
from _window import cutoff_date

PAGE_URL = "https://support.claude.com/en/articles/12138966-release-notes"
BASE = "https://support.claude.com"


def parse_heading_date(s):
    s = re.sub(r"(\d+)(st|nd|rd|th)", r"\1", s)
    return datetime.strptime(s.strip(), "%B %d, %Y").date()


def absolutize(text):
    return re.sub(r"\]\((/[^)]+)\)", lambda m: "](" + BASE + m.group(1) + ")", text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    sections = []  # [{date, entries: [[line, ...], ...]}]
    cur = None     # current section (or None when outside the window)
    entry = None   # current entry's line list

    for line in sys.stdin.read().splitlines():
        if line.startswith("## ") and not line.startswith("### "):
            entry = None  # month group heading — entries never span it
            continue
        m = re.match(r"^###\s+(.+?)\s*$", line)
        if m:
            entry = None
            try:
                d = parse_heading_date(m.group(1))
            except ValueError:
                cur = None
                continue
            cur = {"date": d, "entries": []} if d >= cutoff else None
            if cur is not None:
                sections.append(cur)
            continue
        if cur is None:
            continue
        stripped = line.strip()
        if not stripped:
            continue
        # A non-bullet line opening with ** starts a new entry (its title).
        if stripped.startswith("**") and not stripped.startswith("- "):
            entry = [absolutize(stripped)]
            cur["entries"].append(entry)
        elif entry is not None:
            entry.append(absolutize(stripped))

    out = [
        {
            "unit": s["date"].isoformat(),
            "date": s["date"].isoformat(),
            "url": PAGE_URL,
            "change_count": len(s["entries"]),
            "changes": ["\n".join(e) for e in s["entries"]],
        }
        for s in sections
    ]
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
