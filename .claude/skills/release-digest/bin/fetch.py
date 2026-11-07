#!/usr/bin/env python3
"""Fetch one release-digest source and print its normalized JSON units.

Usage: fetch.py <source-id> <days>

The source's `fetch` declaration in sources.json says how to get the raw document:
  {"url": "..."}           HTTP GET (gzip-encoded bodies are decoded)
  {"gh": "repos/..."}      `gh api <path>` (GitHub REST via the session's credentials)
The raw bytes are piped to the declared `parser` with `--days <days>`; its stdout is passed through.
"""
import gzip
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

BIN = Path(__file__).resolve().parent
SKILL = BIN.parent
USER_AGENT = "release-digest/1.0 (+https://github.com/malleroid/dotfiles)"
TIMEOUT = 60


def http_get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as res:
        body = res.read()
    # Some hosts (antigravity.google) send gzip bytes even without a Content-Encoding header.
    while body[:2] == b"\x1f\x8b":
        body = gzip.decompress(body)
    return body


def gh_api(path: str) -> bytes:
    return subprocess.run(["gh", "api", path], check=True, capture_output=True).stdout


def raw_document(spec: dict) -> bytes:
    if "url" in spec:
        return http_get(spec["url"])
    if "gh" in spec:
        return gh_api(spec["gh"])
    raise ValueError(f"unknown fetch declaration: {spec}")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    source_id, days = sys.argv[1], sys.argv[2]
    sources = {s["id"]: s for s in json.loads((SKILL / "sources.json").read_text())}
    source = sources.get(source_id)
    if not source or not source.get("fetch"):
        print(f"fetch.py: no fetch declaration for {source_id!r}", file=sys.stderr)
        return 2
    raw = raw_document(source["fetch"])
    parsed = subprocess.run(
        [sys.executable, str(SKILL / source["parser"]), "--days", days],
        input=raw, capture_output=True,
    )
    sys.stderr.buffer.write(parsed.stderr)
    sys.stdout.buffer.write(parsed.stdout)
    return parsed.returncode


if __name__ == "__main__":
    sys.exit(main())
