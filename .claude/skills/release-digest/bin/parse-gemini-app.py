#!/usr/bin/env python3
"""Parse the Gemini app (consumer) release notes into normalized JSON.

Reads the HTML of gemini.google/release-notes/?hl=en from stdin and prints
`[ { unit, date, url, change_count, changes[] } ]` to stdout — one element per date,
newest first, filtered to the last N days.

Page shape (server-rendered, CSS-module hashed class names — match on the stable semantic
prefix, not the full hashed class):
  <h2 class="_releaseNoteCardTitle_..">2026.05.19</h2>      <- date (YYYY.MM.DD)
  <div class="_features_..">
    <div>
      <h3 class="_featureTitle_..">Gemini Omni is ...</h3>   <- one feature
      <ul><li><div class="_featureBulletBody_..">
        <p><b>What:</b> ...</p><p>...</p></div></li>
        <li><div class="_featureBulletBody_.."><p><b>Why:</b> ...</p></div></li></ul>
    </div> ...
  </div>

Each feature becomes one element of changes[]: "<title>\nWhat: ...\nWhy: ...".

Invariant: keep every feature verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import html
import argparse
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser

PAGE_URL = "https://gemini.google/release-notes/"
BASE = "https://gemini.google"
DATE_TEXT = re.compile(r"^\s*(\d{4})\.(\d{2})\.(\d{2})\s*$")


class Parser(HTMLParser):
    def __init__(self, cutoff):
        super().__init__(convert_charrefs=True)
        self.cutoff = cutoff
        self.sections = []        # [{date, features: [str]}]
        self.cur_section = None
        self.cur_feature = None   # list[str]: [title, bullet, bullet, ...]
        self.depth = 0
        self.in_h2 = False
        self.h2_text = []
        self.cap_kind = None      # "title" | "bullet"
        self.cap_depth = None
        self.cap_buf = []
        self.href = None

    def handle_starttag(self, tag, attrs):
        self.depth += 1
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "h2":
            self.in_h2, self.h2_text = True, []
            return
        if self.cap_kind is not None:
            # inside a title or bullet capture: render light markdown
            if tag == "a":
                self.href = a.get("href", "")
                self.cap_buf.append("[")
            elif tag == "p" and "".join(self.cap_buf).strip():
                self.cap_buf.append(" ")
            elif tag in ("br",):
                self.cap_buf.append(" ")
            return
        if "_featureTitle" in cls:
            self._finish_feature()
            if self.cur_section is not None:
                self.cur_feature = []
                self.cap_kind, self.cap_depth, self.cap_buf = "title", self.depth, []
        elif "_featureBulletBody" in cls and self.cur_feature is not None:
            self.cap_kind, self.cap_depth, self.cap_buf = "bullet", self.depth, []

    def handle_endtag(self, tag):
        if tag == "h2":
            self.in_h2 = False
            self._open_section("".join(self.h2_text))
        elif self.cap_kind is not None:
            if tag == "a" and self.href is not None:
                url = self.href
                if url.startswith("/"):
                    url = BASE + url
                self.cap_buf.append(f"]({url})")
                self.href = None
            elif self.depth == self.cap_depth:
                text = re.sub(r"\s+", " ", "".join(self.cap_buf)).strip()
                if self.cap_kind == "title":
                    self.cur_feature.append(text)
                elif text:
                    self.cur_feature.append(text)
                self.cap_kind = self.cap_depth = None
                self.cap_buf = []
        self.depth -= 1

    def handle_data(self, data):
        if self.in_h2:
            self.h2_text.append(data)
        elif self.cap_kind is not None:
            self.cap_buf.append(data)

    def _open_section(self, text):
        m = DATE_TEXT.match(text)
        if not m:
            return
        date = datetime(int(m.group(1)), int(m.group(2)), int(m.group(3))).date()
        self._finish_feature()
        if date < self.cutoff:
            self.cur_section = None
            return
        self.cur_section = {"date": date, "features": []}
        self.sections.append(self.cur_section)

    def _finish_feature(self):
        if self.cur_feature and self.cur_section is not None:
            title, *bullets = self.cur_feature
            block = title + ("\n" + "\n".join(bullets) if bullets else "")
            self.cur_section["features"].append(html.unescape(block))
        self.cur_feature = None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    p = Parser(cutoff)
    p.feed(sys.stdin.read())
    p._finish_feature()

    out = [
        {
            "unit": s["date"].isoformat(),
            "date": s["date"].isoformat(),
            "url": PAGE_URL,
            "change_count": len(s["features"]),
            "changes": s["features"],
        }
        for s in p.sections if s["features"]
    ]
    out.sort(key=lambda e: e["date"], reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
