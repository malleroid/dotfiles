#!/usr/bin/env python3
"""Parse the Gemini API release notes (AI Studio markdown) into normalized JSON.

Reads aistudio.google.com/docs/changelog.md from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per date,
newest first, filtered to the last N days.

Page shape:
  ## November 6, 2026  {% id="11-06-2026" %}

  *   **Title**: text that wraps
    onto indented continuation lines, with [links](/docs/...).
      *   nested sub-bullet

Each top-level bullet becomes one element of changes[] (nested bullets become "  - " sub-lines).
Relative links are absolutized.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import argparse
import json
import re
import sys
from datetime import datetime

from _window import cutoff_date

PAGE_URL = "https://aistudio.google.com/docs/changelog"
BASE = "https://aistudio.google.com"
HEADING = re.compile(r"^##\s+(.+?)\s*(?:\{%\s*id=\"([^\"]+)\"\s*%\})?\s*$")
TOP_BULLET = re.compile(r"^\*\s+(.*)$")
SUB_BULLET = re.compile(r"^\s{2,}\*\s+(.*)$")
REL_LINK = re.compile(r"\]\((/[^)]*)\)")


def absolutize(text: str) -> str:
    return REL_LINK.sub(lambda m: f"]({BASE}{m.group(1)})", text)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    sections = []
    cur = None
    item = None

    def flush():
        nonlocal item
        if cur is not None and item is not None:
            cur["changes"].append(absolutize(item.strip()))
        item = None

    for line in sys.stdin.read().splitlines():
        m = HEADING.match(line)
        if m:
            flush()
            try:
                day = datetime.strptime(m.group(1), "%B %d, %Y").date()
            except ValueError:
                cur = None
                continue
            anchor = m.group(2) or day.strftime("%m-%d-%Y")
            cur = {"date": day, "anchor": anchor, "changes": []} if day >= cutoff else None
            if cur is not None:
                sections.append(cur)
            continue
        if cur is None:
            continue
        if (sub := SUB_BULLET.match(line)) and item is not None:
            item += f"\n  - {sub.group(1).strip()}"
        elif top := TOP_BULLET.match(line):
            flush()
            item = top.group(1).strip()
        elif line.strip() and item is not None:
            item += " " + line.strip()
    flush()

    out = [
        {
            "unit": s["date"].isoformat(),
            "date": s["date"].isoformat(),
            "url": f"{PAGE_URL}#{s['anchor']}",
            "change_count": len(s["changes"]),
            "changes": s["changes"],
        }
        for s in sections
    ]
    json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
