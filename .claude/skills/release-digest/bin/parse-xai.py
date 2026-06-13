#!/usr/bin/env python3
"""Parse the xAI / Grok API release notes (docs.x.ai) into normalized JSON.

Reads the HTML of docs.x.ai/docs/release-notes from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per dated entry,
newest first, filtered to the last N days.

Page shape (server-rendered Next.js; Tailwind utility classes, not hashed):
  <h2 id="june">June</h2>            <- current-year month (bare); prior years: id="june-2025"
  <div class="...grid-cols-[5rem...">
    <div class="...tabular-nums"><div>June 10<span></span></div></div>   <- per-entry date
    <div class="min-w-0"><h3 id="anchor"><a href="#anchor">Title</a></h3>
      <ul><li><strong>Sub</strong> — desc <a href="/...">link</a></li>...</ul></div>
  </div>

The year is inherited from the month heading (bare month = the page's current year, taken from
"Last updated: ... , YYYY"); the day comes from the per-entry "Month Day" date cell. Each entry
becomes one element of changes[]: "<title>\n<description>".

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import html
import argparse
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser

PAGE_URL = "https://docs.x.ai/docs/release-notes"
BASE = "https://docs.x.ai"
H2_ID = re.compile(r"^([a-z]+)(?:-(\d{4}))?$")
DATE_CELL = re.compile(r"^([A-Z][a-z]+)\s+(\d{1,2})$")
MONTHS = {m: i for i, m in enumerate(
    ["January", "February", "March", "April", "May", "June",
     "July", "August", "September", "October", "November", "December"], 1)}


class Parser(HTMLParser):
    def __init__(self, cutoff, page_year):
        super().__init__(convert_charrefs=True)
        self.cutoff = cutoff
        self.page_year = page_year
        self.section_year = page_year
        self.entries = []
        self.cur = None
        self.pending_date = None      # (month_num, day) from the last date cell
        self.cap = None               # 'h2' | 'date' | 'title' | 'content'
        self.cap_depth = None
        self.buf = []
        self.href = None
        self.depth = 0

    def handle_starttag(self, tag, attrs):
        self.depth += 1
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "h2" and a.get("id"):
            self._begin("h2", buf=True)
            self._h2_id = a["id"]
        elif "tabular-nums" in cls and self.cap != "date":
            self._begin("date", buf=True)
        elif tag == "h3" and a.get("id"):
            self._finish_entry()
            self._begin("title", buf=True)
            self._h3_id = a["id"]
        elif self.cap == "content":
            if tag == "a":
                self.href = a.get("href", "")
                self.buf.append("[")
            elif tag in ("strong", "b"):
                self.buf.append("**")
            elif tag == "code":
                self.buf.append("`")
            elif tag == "li":
                self.buf.append("\n- ")
            elif tag == "p" and "".join(self.buf).strip():
                self.buf.append("\n")

    def handle_endtag(self, tag):
        # content is open-ended (closed by the next structural element), so only the
        # bounded captures (h2 / date / title) auto-end on depth match.
        if self.cap in ("h2", "date", "title") and self.depth == self.cap_depth:
            self._end_capture()
        elif self.cap == "content":
            if tag == "a" and self.href is not None:
                url = self.href
                if url.startswith("/"):
                    url = BASE + url
                self.buf.append(f"]({url})")
                self.href = None
            elif tag in ("strong", "b"):
                self.buf.append("**")
            elif tag == "code":
                self.buf.append("`")
        self.depth -= 1

    def handle_data(self, data):
        if self.cap in ("h2", "date", "title", "content"):
            self.buf.append(data)

    # --- capture lifecycle ----------------------------------------------------
    def _begin(self, kind, buf=False):
        # opening a new structural element ends any in-progress content capture
        if self.cap == "content" and kind in ("h2", "date", "title"):
            self._store_content()
        self.cap, self.cap_depth, self.buf = kind, self.depth, []

    def _end_capture(self):
        text = re.sub(r"\s+", " ", "".join(self.buf)).strip()
        kind = self.cap
        self.cap = self.cap_depth = None
        self.buf = []
        if kind == "h2":
            self._set_section(text)
        elif kind == "date":
            self._set_date(text)
        elif kind == "title":
            self._start_entry(text)
            # after the title, the following siblings are the description
            self.cap, self.cap_depth, self.buf = "content", self.depth, []

    def _set_section(self, text):
        m = re.match(r"^([A-Z][a-z]+)(?:\s+(\d{4}))?$", text)
        if m:
            self.section_year = int(m.group(2)) if m.group(2) else self.page_year

    def _set_date(self, text):
        m = DATE_CELL.match(text)
        if m and m.group(1) in MONTHS:
            self.pending_date = (MONTHS[m.group(1)], int(m.group(2)))

    def _start_entry(self, title):
        date = None
        if self.pending_date:
            try:
                date = datetime(self.section_year, self.pending_date[0], self.pending_date[1]).date()
            except ValueError:
                date = None
        self.cur = {"date": date, "anchor": getattr(self, "_h3_id", ""),
                    "title": html.unescape(title), "content": []}

    def _store_content(self):
        text = re.sub(r" {2,}", " ", "".join(self.buf)).strip()
        if self.cur is not None and text:
            self.cur["content"].append(html.unescape(text))

    def _finish_entry(self):
        if self.cap == "content":
            self._store_content()
        if self.cur is not None:
            self.entries.append(self.cur)
        self.cur = None

    def close(self):
        super().close()
        self._finish_entry()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    text = sys.stdin.read()
    m = re.search(r"Last updated:[^<]*?(\d{4})", text)
    page_year = int(m.group(1)) if m else datetime.now(timezone.utc).year

    p = Parser(cutoff, page_year)
    p.feed(text)
    p.close()

    out = []
    for e in p.entries:
        if e["date"] is None or e["date"] < cutoff:
            continue
        body = e["title"] + ("\n" + "\n".join(e["content"]) if e["content"] else "")
        url = f"{PAGE_URL}#{e['anchor']}" if e["anchor"] else PAGE_URL
        out.append({
            "unit": e["date"].isoformat(),
            "date": e["date"].isoformat(),
            "url": url,
            "change_count": 1,
            "changes": [body],
        })
    # merge entries sharing a date into one element
    merged = {}
    for o in out:
        merged.setdefault(o["date"], {"unit": o["date"], "date": o["date"],
                                      "url": o["url"], "changes": []})
        merged[o["date"]]["changes"].extend(o["changes"])
    result = sorted(merged.values(), key=lambda e: e["date"], reverse=True)
    for r in result:
        r["change_count"] = len(r["changes"])
        r["changes"] = r["changes"]
    print(json.dumps([{"unit": r["unit"], "date": r["date"], "url": r["url"],
                       "change_count": r["change_count"], "changes": r["changes"]}
                      for r in result], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
