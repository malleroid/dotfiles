#!/usr/bin/env python3
"""Parse the OpenAI API changelog HTML into normalized JSON.

Reads the HTML of developers.openai.com/api/docs/changelog from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per date,
newest first, filtered to the last N days.

Page shape (Astro SSG, hashed CSS class names — do NOT rely on full class strings):
  <h3 ...>June, 2026</h3>                      <- month section (text pattern is stable)
  <div class="_Badge_...">Jun 9</div>          <- date badge starts an entry
  <div class="_Badge_...">Feature</div>        <- category badge (Feature/Update/Fix/...)
  <div class="_Badge_...">v1/responses</div>   <- affected API/model badges (0..n)
  <div class="..._MarkdownContent_...">...</div> <- entry body (p / li / a / code)

Each entry becomes one element of `changes[]` as:
  "[<category>] (<tags>) <body markdown>"
Links are kept as [text](url), inline code as `code`. Nothing is dropped.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job —
the source-provided category is passed through as a hint, not used to filter.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone
from _window import cutoff_date
from html.parser import HTMLParser

PAGE_URL = "https://developers.openai.com/api/docs/changelog"
BASE = "https://developers.openai.com"
CATEGORIES = {"Feature", "Update", "Fix", "Announcement", "Deprecation"}
MONTH_RE = re.compile(r"^\s*([A-Z][a-z]+),\s+(\d{4})\s*$")
DATEBADGE_RE = re.compile(r"^\s*([A-Z][a-z]{2})\s+(\d{1,2})\s*$")


class Parser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.month = None          # (month_name, year)
        self.entries = []          # [{date, category, tags, body}]
        self.cur = None
        # transient capture state
        self.badge_depth = None
        self.badge_text = []
        self.body_depth = None
        self.body = []
        self.h3_depth = None
        self.h3_text = []
        self.href = None
        self.depth = 0

    def handle_starttag(self, tag, attrs):
        self.depth += 1
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "h3":
            self.h3_depth, self.h3_text = self.depth, []
        elif self.body_depth is not None:
            # inside an entry body: rebuild minimal markdown
            if tag == "li":
                self.body.append("\n- ")
            elif tag == "p" and self.body and "".join(self.body).strip():
                self.body.append("\n")
            elif tag == "a":
                self.href = a.get("href", "")
                self.body.append("[")
            elif tag == "code":
                self.body.append("`")
        elif "_Badge_" in cls:
            self.badge_depth, self.badge_text = self.depth, []
        elif "MarkdownContent" in cls and self.cur is not None:
            self.body_depth, self.body = self.depth, []

    def handle_endtag(self, tag):
        if self.h3_depth is not None and self.depth == self.h3_depth:
            m = MONTH_RE.match("".join(self.h3_text))
            if m:
                self.month = (m.group(1), int(m.group(2)))
            self.h3_depth = None
        if self.badge_depth is not None and self.depth == self.badge_depth:
            self._finish_badge("".join(self.badge_text).strip())
            self.badge_depth = None
        if self.body_depth is not None and self.depth == self.body_depth:
            self.cur["body"] = "".join(self.body).strip()
            self.body_depth = None
        if self.body_depth is not None:
            if tag == "a":
                url = self.href or ""
                if url.startswith("/"):
                    url = BASE + url
                self.body.append(f"]({url})")
                self.href = None
            elif tag == "code":
                self.body.append("`")
        self.depth -= 1

    def handle_data(self, data):
        if self.h3_depth is not None:
            self.h3_text.append(data)
        elif self.badge_depth is not None:
            self.badge_text.append(data)
        elif self.body_depth is not None:
            self.body.append(re.sub(r"\s+", " ", data))

    def _finish_badge(self, text):
        m = DATEBADGE_RE.match(text)
        if m and self.month:
            # date badge starts a new entry; year comes from the month section
            d = datetime.strptime(f"{m.group(1)} {m.group(2)} {self.month[1]}", "%b %d %Y").date()
            self.cur = {"date": d, "category": None, "tags": [], "body": ""}
            self.entries.append(self.cur)
        elif self.cur is not None and text in CATEGORIES:
            self.cur["category"] = text
        elif self.cur is not None and text:
            self.cur["tags"].append(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    p = Parser()
    p.feed(sys.stdin.read())

    by_date = {}
    for e in p.entries:
        if e["date"] < cutoff or not e["body"]:
            continue
        prefix = f"[{e['category']}]" if e["category"] else "[—]"
        tags = f" ({', '.join(e['tags'])})" if e["tags"] else ""
        by_date.setdefault(e["date"], []).append(f"{prefix}{tags} {e['body']}")

    out = [
        {
            "unit": d.isoformat(),
            "date": d.isoformat(),
            "url": PAGE_URL,
            "change_count": len(changes),
            "changes": changes,
        }
        for d, changes in sorted(by_date.items(), reverse=True)
    ]
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
