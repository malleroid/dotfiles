#!/usr/bin/env python3
"""Parse the Antigravity changelog out of the site's JS bundle into normalized JSON.

Antigravity (antigravity.google) is a client-rendered SPA whose changelog data is embedded
in the main JS bundle as object literals: `engineSections:[...]` and `ideSections:[...]`.
This reads the (optionally gzipped) bundle from stdin and prints
`[ { unit, date, version, section, url, change_count, changes[] } ]` — one element per
release, newest first, filtered to the last N days.

Fragility note: this is the least stable source (depends on the minified bundle's shape).
It therefore FAILS LOUD — if neither section marker is found, or zero entries parse, it
exits non-zero so a broken source is visible in the digest run instead of silently empty.
The registry can disable this source (enabled:false) if it breaks and isn't worth fixing now.

Invariant: keep every entry verbatim. Classification/translation is the skill's (LLM) job.
"""
import sys
import re
import json
import gzip
import html
import argparse
from datetime import datetime, timedelta, timezone

PAGE_URL = "https://antigravity.google/changelog"
BASE = "https://antigravity.google"
IDENT_KEY = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(?=\s*:)")


def read_stdin():
    raw = sys.stdin.buffer.read()
    if raw[:2] == b"\x1f\x8b":          # gzip magic — bundle is served pre-compressed
        raw = gzip.decompress(raw)
    return raw.decode("utf-8", "replace")


def extract_array(text, marker):
    """Return the JS array literal (including brackets) following `marker`, or None.

    Bracket-matches while respecting double-quoted strings so brackets inside HTML/prose
    don't throw off the count."""
    i = text.find(marker)
    if i < 0:
        return None
    i = text.index("[", i + len(marker) - 1)
    depth, j, in_str, esc = 0, i, False, False
    while j < len(text):
        c = text[j]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "[":
                depth += 1
            elif c == "]":
                depth -= 1
                if depth == 0:
                    return text[i:j + 1]
        j += 1
    return None


def js_to_json(s):
    """Quote bare identifier keys in a JS object/array literal (string-aware) → JSON text."""
    out, i, in_str, esc = [], 0, False, False
    while i < len(s):
        c = s[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        m = IDENT_KEY.match(s, i)
        if m:
            out.append('"' + m.group(0) + '"')
            i = m.end()
            continue
        out.append(c)
        i += 1
    return "".join(out)


def parse_array(text, marker):
    arr = extract_array(text, marker)
    if arr is None:
        return None
    return json.loads(js_to_json(arr))


def html_to_text(s):
    if not s:
        return ""
    s = re.sub(r"<a\s[^>]*href=['\"]([^'\"]+)['\"][^>]*>(.*?)</a>",
               lambda m: f"[{m.group(2)}]({m.group(1) if not m.group(1).startswith('/') else BASE + m.group(1)})",
               s, flags=re.I | re.S)
    s = re.sub(r"</p>\s*<p>", " / ", s, flags=re.I)
    s = re.sub(r"<br\s*/?>", " ", s, flags=re.I)
    s = re.sub(r"<[^>]+>", "", s)
    return html.unescape(s).strip()


def parse_date(date_str):
    date_str = date_str.strip()
    for fmt in ("%B %d, %Y", "%b %d, %Y"):
        try:
            return datetime.strptime(date_str, fmt).date()
        except ValueError:
            continue
    return None


def normalize(entry, section, cutoff):
    ver_field = entry.get("version", "")
    parts = ver_field.split("<br>")
    if len(parts) < 2:
        return None
    version = html_to_text(parts[0])
    date = parse_date(html_to_text(parts[1]))
    if date is None or date < cutoff:
        return None

    changes = []
    lead = html_to_text(entry.get("description", ""))
    if lead:
        changes.append(lead)
    summary = html_to_text((entry.get("accordion") or {}).get("changes", ""))
    if summary and summary != lead:
        changes.append(summary)
    for item in (entry.get("accordion") or {}).get("items", []):
        title = (item.get("title") or "").strip()
        for ai in item.get("accordion_items", []):
            t = html_to_text(ai.get("text", ""))
            if t:
                changes.append(f"[{title}] {t}")

    return {
        "unit": f"{section} {version}",
        "date": date.isoformat(),
        "version": version,
        "section": section,
        "url": PAGE_URL,
        "change_count": len(changes),
        "changes": changes,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=1)
    args = ap.parse_args()
    cutoff = datetime.now(timezone.utc).date() - timedelta(days=args.days)

    text = read_stdin()
    engine = parse_array(text, "engineSections:[")
    ide = parse_array(text, "ideSections:[")
    if engine is None and ide is None:
        sys.exit("parse-antigravity: changelog section markers not found — bundle shape changed")

    total = len(engine or []) + len(ide or [])
    if total == 0:
        sys.exit("parse-antigravity: zero changelog entries extracted — bundle shape changed")

    out = []
    for section, arr in (("engine", engine or []), ("ide", ide or [])):
        for entry in arr:
            n = normalize(entry, section, cutoff)
            if n is not None:
                out.append(n)
    out.sort(key=lambda e: (e["date"], e["version"]), reverse=True)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
