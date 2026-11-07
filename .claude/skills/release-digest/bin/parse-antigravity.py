#!/usr/bin/env python3
"""Parse the Antigravity changelog page (antigravity.google/docs/changelog) into normalized JSON.

Reads the server-rendered HTML on stdin and prints
`[ { unit, date, version, section, url, title, change_count, changes[] } ]` — one element per
release entry, newest first, filtered to the last N days.

Page shape (Astro, one panel per product):
  <article class="rn-row release-entry" id="rel-<product>-<version>">
    <time class="rn-date-text">November 3, 2026</time>
    <h3 class="rn-headline">Headline</h3>
    <div class="rn-summary"><p>Summary</p></div>
    <details data-item-title="Improvements"> <li class="rn-item">...</li> ... </details>
  </article>

changes[] starts with the summary, followed by each item prefixed with its `[Category]`.
Fails loud (non-zero exit) when no release entry parses, so a layout change is visible.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import argparse
import json
import re
import sys
from datetime import datetime
from html.parser import HTMLParser

from _window import cutoff_date

PAGE_URL = "https://antigravity.google/docs/changelog"
ENTRY_ID = re.compile(r"^rel-([a-z0-9-]+?)-(\d[\w.]*)$")
SECTIONS = {
    "hub": "App",
    "cli": "CLI",
    "ide": "IDE",
    "sdk": "SDK",
    "vscode": "VS Code extension",
    "visual-studio": "Visual Studio extension",
    "jetbrains": "JetBrains extension",
    "zed": "Zed extension",
    "xcode": "Xcode extension",
    "eclipse": "Eclipse extension",
}


class Parser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.entries = []
        self.entry = None
        self.depth = 0
        self.capture = None
        self.buf = []
        self.category = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        cls = a.get("class", "") or ""
        if tag == "article" and "release-entry" in cls:
            m = ENTRY_ID.match(a.get("id", ""))
            self.entry = {"id": a.get("id", ""), "product": m.group(1) if m else "", "version": m.group(2) if m else "",
                          "date": None, "title": "", "summary": "", "items": []} if m else None
            self.depth = 0
        if self.entry is None:
            return
        if tag == "article":
            self.depth += 1
        if tag == "details":
            self.category = a.get("data-item-title")
        if tag == "code" and self.capture:
            self.buf.append("`")
        kind = None
        if tag == "time" and "rn-date-text" in cls:
            kind = "date"
        elif tag == "h3" and "rn-headline" in cls:
            kind = "title"
        elif tag == "div" and "rn-summary" in cls:
            kind = "summary"
        elif tag == "li" and "rn-item" in cls:
            kind = "item"
        elif tag == "summary":
            kind = "skip"
        if kind and self.capture is None:
            self.capture = (kind, tag)
            self.buf = []

    def handle_endtag(self, tag):
        if self.entry is None:
            return
        if tag == "code" and self.capture:
            self.buf.append("`")
        if self.capture and tag == self.capture[1]:
            kind = self.capture[0]
            text = " ".join("".join(self.buf).split())
            if kind == "date":
                self.entry["date"] = datetime.strptime(text, "%B %d, %Y").date()
            elif kind == "title":
                self.entry["title"] = text
            elif kind == "summary":
                self.entry["summary"] = text
            elif kind == "item" and text:
                self.entry["items"].append(f"[{self.category}] {text}" if self.category else text)
            self.capture = None
            self.buf = []
        if tag == "article":
            self.depth -= 1
            if self.depth <= 0:
                self.entries.append(self.entry)
                self.entry = None

    def handle_data(self, data):
        if self.capture and self.capture[0] != "skip":
            self.buf.append(data)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = cutoff_date(args.days)

    p = Parser()
    p.feed(sys.stdin.read())
    if not p.entries:
        print("parse-antigravity: no release entries found (page layout changed?)", file=sys.stderr)
        return 1

    out = []
    for e in p.entries:
        if e["date"] is None or e["date"] < cutoff:
            continue
        section = SECTIONS.get(e["product"], e["product"])
        changes = ([e["summary"]] if e["summary"] else []) + e["items"]
        out.append({
            "unit": f"{section} {e['version']}",
            "date": e["date"].isoformat(),
            "version": e["version"],
            "section": section,
            "url": f"{PAGE_URL}#{e['id']}",
            "title": e["title"],
            "change_count": len(changes),
            "changes": changes,
        })
    out.sort(key=lambda u: u["date"], reverse=True)
    json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
