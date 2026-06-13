#!/usr/bin/env python3
"""Parse the Kiro (AWS) changelog Atom feed into normalized JSON.

Reads the Atom feed (kiro.dev/changelog/feed.atom) from stdin and prints
`[ { unit, date, url, category, title, change_count, changes[] } ]` to stdout — one element per
entry, newest first, filtered to the last N days.

Each <entry> is one feature release: <title> carries a category prefix (e.g. "CLI: ..."),
<category term="CLI"> gives the category, <link href> is the per-entry deep-link, <published> is
an ISO date, and <summary type="html"> is a teaser paragraph (long entries end with "..."; the
full detail lives on the linked page). The teaser + title is enough for a digest line.

Invariant: keep the entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import html
import argparse
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone

ATOM = "{http://www.w3.org/2005/Atom}"


def html_to_text(s):
    if not s:
        return ""
    s = re.sub(r"<a\s[^>]*href=['\"]([^'\"]+)['\"][^>]*>(.*?)</a>",
               lambda m: f"[{m.group(2)}]({m.group(1)})", s, flags=re.I | re.S)
    s = re.sub(r"<strong>(.*?)</strong>", r"**\1**", s, flags=re.I | re.S)
    s = re.sub(r"<code>(.*?)</code>", r"`\1`", s, flags=re.I | re.S)
    s = re.sub(r"</p>\s*<p>", " / ", s, flags=re.I)
    s = re.sub(r"<li>", "\n- ", s, flags=re.I)
    s = re.sub(r"<br\s*/?>", " ", s, flags=re.I)
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return html.unescape(s).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    root = ET.fromstring(sys.stdin.buffer.read())
    out = []
    for entry in root.findall(f"{ATOM}entry"):
        published = entry.findtext(f"{ATOM}published") or entry.findtext(f"{ATOM}updated") or ""
        try:
            date = datetime.fromisoformat(published.replace("Z", "+00:00")).date()
        except ValueError:
            continue
        if date < cutoff:
            continue
        title = (entry.findtext(f"{ATOM}title") or "").strip()
        link_el = entry.find(f"{ATOM}link")
        url = link_el.get("href") if link_el is not None else ""
        cat_el = entry.find(f"{ATOM}category")
        category = cat_el.get("term") if cat_el is not None else ""
        summary = html_to_text(entry.findtext(f"{ATOM}summary") or "")
        out.append({
            "unit": title,
            "date": date.isoformat(),
            "url": url,
            "category": category,
            "title": html.unescape(title),
            "change_count": 1,
            "changes": [summary] if summary else [],
        })
    out.sort(key=lambda e: e["date"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
