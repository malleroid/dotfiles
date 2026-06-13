#!/usr/bin/env python3
"""Parse the OpenAI Codex changelog HTML into normalized JSON.

Reads the HTML of developers.openai.com/codex/changelog from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per date,
newest first, filtered to the last N days.

Page shape (very semantic — entry <li> carries an ISO date in its id):
  <li id="codex-2026-06-09-mobile" data-product="codex" data-codex-topics="codex-mobile">
    ... <h3>ChatGPT for iOS 1.2026.153</h3> ... <ul><li>bullet</li>...</ul>
  </li>

Each entry becomes one element of `changes[]` as a block:
  "**<title>** (topics)\n<paragraphs>\n- <bullet>..."
The per-entry anchor (#<li id>) is kept on the entry's first line as the url is per-date.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import argparse
from datetime import datetime, timedelta, timezone
from _window import cutoff_date
from html.parser import HTMLParser

PAGE_URL = "https://developers.openai.com/codex/changelog"
BASE = "https://developers.openai.com"
ENTRY_ID_RE = re.compile(r"^codex-(\d{4}-\d{2}-\d{2})(?:-|$)")


class Parser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.entries = []   # [{date, anchor, topics, title, body}]
        self.cur = None
        self.entry_depth = None
        self.h3_depth = None
        self.title = []
        self.body = []
        self.href = None
        self.depth = 0
        self.skip_depth = None  # svg/button noise inside entries

    def handle_starttag(self, tag, attrs):
        self.depth += 1
        a = dict(attrs)
        if self.cur is None:
            m = ENTRY_ID_RE.match(a.get("id", "")) if tag == "li" else None
            if m:
                self.cur = {
                    "date": datetime.strptime(m.group(1), "%Y-%m-%d").date(),
                    "anchor": a.get("id", ""),
                    "topics": a.get("data-codex-topics", ""),
                    "title": "",
                    "body": "",
                }
                self.entry_depth = self.depth
                self.title, self.body = [], []
            return
        # inside an entry
        if self.skip_depth is not None:
            return
        if tag in ("svg", "button", "script", "style"):
            self.skip_depth = self.depth
        elif tag == "h3":
            self.h3_depth = self.depth
            self.title = []
            # only the first h3 is the entry title; later ones (e.g. "New features",
            # "Improvements and bug fixes") are section headings within the body
            self.h3_is_section = bool(self.cur["title"])
        elif tag == "li":
            self.body.append("\n- ")
        elif tag == "p" and "".join(self.body).strip():
            self.body.append("\n")
        elif tag == "a":
            self.href = a.get("href", "")
            self.body.append("[")
        elif tag == "code":
            self.body.append("`")

    def handle_endtag(self, tag):
        if self.cur is not None:
            if self.skip_depth is not None:
                if self.depth == self.skip_depth:
                    self.skip_depth = None
            elif self.h3_depth is not None and self.depth == self.h3_depth:
                text = re.sub(r"\s+", " ", "".join(self.title)).strip()
                if self.h3_is_section:
                    self.body.append(f"\n**{text}**\n")
                else:
                    self.cur["title"] = text
                self.h3_depth = None
            elif tag == "a" and self.href is not None:
                url = self.href
                if url.startswith("/"):
                    url = BASE + url
                self.body.append(f"]({url})")
                self.href = None
            elif tag == "code":
                self.body.append("`")
            if self.depth == self.entry_depth:
                body = "".join(self.body)
                body = re.sub(r" {2,}", " ", body)
                # drop the visible date label duplicated inside the entry
                body = re.sub(rf"(^|\n)\s*{self.cur['date'].isoformat()}\s*(\n|$)", r"\1", body)
                self.cur["body"] = body.strip()
                self.entries.append(self.cur)
                self.cur = None
                self.entry_depth = None
        self.depth -= 1

    def handle_data(self, data):
        if self.cur is None or self.skip_depth is not None:
            return
        if self.h3_depth is not None:
            self.title.append(data)
        else:
            self.body.append(re.sub(r"\s+", " ", data))

    def handle_startendtag(self, tag, attrs):
        # self-closing tags (e.g. <img/>) — keep depth bookkeeping consistent
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    p = Parser()
    p.feed(sys.stdin.read())

    by_date = {}
    for e in p.entries:
        if e["date"] < cutoff:
            continue
        head = f"**{e['title']}**" if e["title"] else "**(untitled)**"
        if e["topics"]:
            head += f" ({e['topics']})"
        head += f"\n{PAGE_URL}#{e['anchor']}"
        block = head + ("\n" + e["body"] if e["body"] else "")
        by_date.setdefault(e["date"], []).append(block)

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
