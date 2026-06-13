#!/usr/bin/env python3
"""Parse the Vertex AI (Generative AI) release-notes Atom feed into normalized JSON.

Reads the Atom feed (docs.cloud.google.com/feeds/generative-ai-on-vertex-ai-release-notes.xml)
from stdin and prints `[ { unit, date, url, change_count, changes[] } ]` to stdout — one element
per dated entry, newest first, filtered to the last N days.

Atom envelope gives a clean <updated> date and a per-entry deep-link (<link rel="alternate">).
Each entry's <content type="html"> body is split on <h3> category headings
(Feature / Deprecated / Announcement / Change), and each category section becomes one
changes[] item prefixed `[Category] ...`. The category is a strong classification hint.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import argparse
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser

ATOM = "{http://www.w3.org/2005/Atom}"
BASE = "https://docs.cloud.google.com"


class ContentParser(HTMLParser):
    """Split a release-note entry body into [(category, markdown_text), ...] by <h3>."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.sections = []
        self.cur = None          # current markdown buffer (list[str])
        self.category = None
        self.in_h3 = False
        self.h3_text = []
        self.href = None
        self.in_table = False
        self.row = []
        self.cell = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "h3":
            self._flush()
            self.in_h3, self.h3_text = True, []
        elif tag == "table":
            self.in_table = True
        elif tag == "tr":
            self.row = []
        elif tag in ("td", "th"):
            self.cell = []
        elif self.in_h3 or self.cell is not None:
            return  # h3 text captured separately; inline tags inside table cells are ignored
        elif tag == "a":
            self.href = a.get("href", "")
            self._emit("[")
        elif tag in ("strong", "b"):
            self._emit("**")
        elif tag == "code":
            self._emit("`")
        elif tag == "li":
            self._emit("\n- ")
        elif tag == "p":
            if self.cur and "".join(self.cur).strip():
                self._emit("\n")
        elif tag == "table":
            self.in_table = True
        elif tag == "tr":
            self.row = []
        elif tag in ("td", "th"):
            self.cell = []

    def handle_endtag(self, tag):
        if tag == "h3":
            self.in_h3 = False
            self.category = re.sub(r"\s+", " ", "".join(self.h3_text)).strip()
            self.cur = []
        elif tag in ("td", "th"):
            if self.cell is not None:
                self.row.append(re.sub(r"\s+", " ", "".join(self.cell)).strip())
                self.cell = None
        elif tag == "tr":
            if self.row:
                self._emit("\n- " + " | ".join(self.row))
            self.row = []
        elif tag == "table":
            self.in_table = False
        elif self.in_h3 or self.cell is not None:
            return
        elif tag == "a" and self.href is not None:
            url = self.href
            if url.startswith("/"):
                url = BASE + url
            self._emit(f"]({url})")
            self.href = None
        elif tag in ("strong", "b"):
            self._emit("**")
        elif tag == "code":
            self._emit("`")

    def handle_data(self, data):
        if self.in_h3:
            self.h3_text.append(data)
        elif self.cell is not None:
            self.cell.append(data)
        else:
            self._emit(re.sub(r"\s+", " ", data))

    def _emit(self, s):
        if self.cur is not None:
            self.cur.append(s)

    def _flush(self):
        if self.cur is not None:
            text = re.sub(r" {2,}", " ", "".join(self.cur)).strip()
            cat = self.category or "Update"
            if text:
                self.sections.append((cat, text))
        self.cur = None

    def result(self):
        self._flush()
        return self.sections


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    root = ET.fromstring(sys.stdin.buffer.read())
    out = []
    for entry in root.findall(f"{ATOM}entry"):
        updated = entry.findtext(f"{ATOM}updated", "")
        try:
            date = datetime.fromisoformat(updated).date()
        except ValueError:
            continue
        if date < cutoff:
            continue
        url = ""
        for link in entry.findall(f"{ATOM}link"):
            if link.get("rel") == "alternate":
                url = link.get("href", "")
        content = entry.findtext(f"{ATOM}content", "") or ""
        cp = ContentParser()
        cp.feed(content)
        changes = [f"[{cat}] {text}" for cat, text in cp.result()]
        if not changes:
            continue
        out.append({
            "unit": date.isoformat(),
            "date": date.isoformat(),
            "url": url,
            "change_count": len(changes),
            "changes": changes,
        })
    out.sort(key=lambda e: e["date"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
