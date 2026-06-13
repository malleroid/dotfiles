#!/usr/bin/env python3
"""Parse the Gemini API release notes (DevSite HTML) into normalized JSON.

Reads the HTML of ai.google.dev/gemini-api/docs/changelog from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per date,
newest first, filtered to the last N days.

Page shape (server-rendered DevSite, stable):
  <div class="devsite-article-body ...">      <- only parse inside this container
    <h2 id="06-01-2026" data-text="June 1, 2026">June 1, 2026</h2>
    <ul>
      <li><p>text <a href="/gemini-api/...">link</a> <code>id</code></p>
        <ul><li>nested sub-bullet</li>...</ul></li>
      ...
    </ul>
  </div>

Each top-level <li> becomes one element of changes[] (nested <li> become "  - " sub-bullets).
Links are kept as [text](url) (relative /gemini-api/... is absolutized), <code> as `code`.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import html
import argparse
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser

PAGE_URL = "https://ai.google.dev/gemini-api/docs/changelog"
BASE = "https://ai.google.dev"
DATE_ID = re.compile(r"^\d{2}-\d{2}-\d{4}$")


class Parser(HTMLParser):
    def __init__(self, cutoff):
        super().__init__(convert_charrefs=True)
        self.cutoff = cutoff
        self.sections = []          # [{date, id, changes: [str, ...]}]
        self.cur_section = None
        self.cur_change = None      # list[str] buffer for the current top-level <li>
        # boundaries / nesting
        self.div_depth = 0
        self.in_article = False
        self.article_level = None
        self.list_depth = 0
        self.in_h2 = False
        self.h2_attrs = {}
        self.href = None

    # --- boundary + structure -------------------------------------------------
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "div":
            if not self.in_article and "devsite-article-body" in a.get("class", ""):
                self.in_article = True
                self.article_level = self.div_depth
            self.div_depth += 1
            return
        if not self.in_article:
            return
        if tag == "h2":
            self.in_h2, self.h2_attrs = True, a
            self._finish_change()
        elif tag in ("ul", "ol"):
            self.list_depth += 1
        elif tag == "li":
            if self.list_depth <= 1:
                self._finish_change()
                if self.cur_section is not None:
                    self.cur_change = []
            elif self.cur_change is not None:
                self.cur_change.append("\n  - ")
        elif tag == "a":
            self.href = a.get("href", "")
            self._emit("[")
        elif tag == "code":
            self._emit("`")
        elif tag in ("strong", "b"):
            self._emit("**")
        elif tag in ("em", "i"):
            self._emit("*")

    def handle_endtag(self, tag):
        if tag == "div":
            self.div_depth -= 1
            if self.in_article and self.div_depth == self.article_level:
                self.in_article = False
                self._finish_change()
            return
        if not self.in_article:
            return
        if tag == "h2":
            self.in_h2 = False
            self._open_section(self.h2_attrs)
        elif tag in ("ul", "ol"):
            self.list_depth -= 1
        elif tag == "a" and self.href is not None:
            url = self.href
            if url.startswith("/"):
                url = BASE + url
            self._emit(f"]({url})")
            self.href = None
        elif tag == "code":
            self._emit("`")
        elif tag in ("strong", "b"):
            self._emit("**")
        elif tag in ("em", "i"):
            self._emit("*")

    def handle_data(self, data):
        if self.in_h2:
            return
        if self.in_article:
            self._emit(re.sub(r"\s+", " ", data))

    # --- helpers --------------------------------------------------------------
    def _emit(self, s):
        if self.cur_change is not None:
            self.cur_change.append(s)

    def _finish_change(self):
        if self.cur_change is not None and self.cur_section is not None:
            text = "".join(self.cur_change).strip()
            text = re.sub(r" {2,}", " ", text)
            if text:
                self.cur_section["changes"].append(text)
        self.cur_change = None

    def _open_section(self, attrs):
        hid = attrs.get("id", "")
        if not DATE_ID.match(hid):
            self.cur_section = None  # non-date heading — stop attributing lists to a date
            return
        date = datetime.strptime(hid, "%m-%d-%Y").date()
        if date < self.cutoff:
            self.cur_section = None
            return
        self.cur_section = {"date": date, "id": hid, "changes": []}
        self.sections.append(self.cur_section)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    p = Parser(cutoff)
    p.feed(sys.stdin.read())

    out = [
        {
            "unit": s["date"].isoformat(),
            "date": s["date"].isoformat(),
            "url": f"{PAGE_URL}#{s['id']}",
            "change_count": len(s["changes"]),
            "changes": s["changes"],
        }
        for s in p.sections if s["changes"]
    ]
    out.sort(key=lambda e: e["date"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
