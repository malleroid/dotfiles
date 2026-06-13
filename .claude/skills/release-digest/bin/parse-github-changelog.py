#!/usr/bin/env python3
"""Parse the GitHub Changelog RSS feed into normalized JSON.

Reads the RSS feed (github.blog/changelog/feed/) from stdin and prints
`[ { unit, date, url, changelog_type, labels, title, change_count, changes[] } ]` to stdout —
one element per item (changelog post), newest first, filtered to the last N days.

Each <item> has a title, a per-post <link>, an RFC822 <pubDate>, an HTML <content:encoded>
body, and <category domain="changelog-type"> (Improvement/Retired/Release) plus one or more
<category domain="changelog-label"> (copilot/actions/security/...) — strong classification hints.
The lead <p> of the body is kept as the digest summary (full detail on the linked post).

Invariant: keep the item verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import html
import argparse
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from datetime import datetime, timedelta, timezone
from _window import cutoff_date, jst_date

CONTENT = "{http://purl.org/rss/1.0/modules/content/}"


def html_to_text(s):
    if not s:
        return ""
    s = re.sub(r"<a\s[^>]*href=['\"]([^'\"]+)['\"][^>]*>(.*?)</a>",
               lambda m: f"[{m.group(2)}]({m.group(1)})", s, flags=re.I | re.S)
    s = re.sub(r"<strong>(.*?)</strong>", r"**\1**", s, flags=re.I | re.S)
    s = re.sub(r"<code>(.*?)</code>", r"`\1`", s, flags=re.I | re.S)
    s = re.sub(r"<[^>]+>", "", s)
    return re.sub(r"\s+", " ", html.unescape(s)).strip()


def lead_paragraph(content_html):
    m = re.search(r"<p>(.*?)</p>", content_html, flags=re.I | re.S)
    return html_to_text(m.group(1)) if m else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    root = ET.fromstring(sys.stdin.buffer.read())
    out = []
    for item in root.iter("item"):
        pub = item.findtext("pubDate") or ""
        try:
            date = jst_date(parsedate_to_datetime(pub))
        except (TypeError, ValueError):
            continue
        if date < cutoff:
            continue
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        ctype, labels = "", []
        for cat in item.findall("category"):
            domain = cat.get("domain")
            if domain == "changelog-type":
                ctype = (cat.text or "").strip()
            elif domain == "changelog-label":
                labels.append((cat.text or "").strip())
        summary = lead_paragraph(item.findtext(f"{CONTENT}encoded") or "")
        if not summary:
            summary = html_to_text(re.sub(r"<p>The post .*?appeared first on.*?</p>", "",
                                          item.findtext("description") or "", flags=re.I | re.S))
        out.append({
            "unit": title,
            "date": date.isoformat(),
            "url": link,
            "changelog_type": ctype,
            "labels": labels,
            "title": html.unescape(title),
            "change_count": 1,
            "changes": [summary] if summary else [],
        })
    out.sort(key=lambda e: e["date"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
