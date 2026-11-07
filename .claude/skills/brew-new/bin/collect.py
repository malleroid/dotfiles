#!/usr/bin/env python3
"""List formulae and casks newly added to Homebrew between two JST dates.

New additions are found through merged pull requests labelled "new formula" in
Homebrew/homebrew-core and "new cask" in Homebrew/homebrew-cask, queried with the
REST search API via `gh api` (GraphQL is unavailable in cloud sessions). Each
entry is enriched with desc/homepage from formulae.brew.sh; enrichment failures
leave those fields null instead of dropping the entry.

Prints a JSON array sorted by date, kind and name.
"""
import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import date, datetime, timedelta, timezone

JST = timezone(timedelta(hours=9))
SOURCES = (
    ("formula", "Homebrew/homebrew-core", "new formula"),
    ("cask", "Homebrew/homebrew-cask", "new cask"),
)
PER_PAGE = 100
TITLE_SUFFIX = re.compile(r"\s*\(new (?:formula|cask)\)\s*$")


def search(repo: str, label: str, since: date, until: date) -> list[dict]:
    start = datetime.combine(since, datetime.min.time(), JST).isoformat()
    end = datetime.combine(until, datetime.max.time().replace(microsecond=0), JST).isoformat()
    query = f'repo:{repo} is:pr is:merged label:"{label}" merged:{start}..{end}'
    items: list[dict] = []
    page = 1
    while True:
        out = subprocess.run(
            ["gh", "api", "-X", "GET", "search/issues",
             "-f", f"q={query}", "-f", f"per_page={PER_PAGE}", "-f", f"page={page}"],
            check=True, capture_output=True, text=True,
        ).stdout
        batch = json.loads(out)["items"]
        items.extend(batch)
        if len(batch) < PER_PAGE:
            return items
        page += 1


def parse_title(title: str) -> list[tuple[str, str]]:
    packages = []
    for part in TITLE_SUFFIX.sub("", title).split(" / "):
        name, _, version = part.strip().partition(" ")
        if name:
            packages.append((name, version.strip()))
    return packages


def enrich(kind: str, name: str) -> dict:
    url = f"https://formulae.brew.sh/api/{kind}/{name}.json"
    try:
        with urllib.request.urlopen(url, timeout=15) as res:
            data = json.load(res)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        print(f"warning: {url}: {e}", file=sys.stderr)
        return {"desc": None, "homepage": None}
    return {"desc": data.get("desc"), "homepage": data.get("homepage")}


def collect(since: date, until: date) -> list[dict]:
    entries = []
    for kind, repo, label in SOURCES:
        for pr in search(repo, label, since, until):
            merged_at = pr["pull_request"]["merged_at"]
            merged_jst = datetime.fromisoformat(merged_at.replace("Z", "+00:00")).astimezone(JST)
            for name, version in parse_title(pr["title"]):
                entries.append({
                    "date": merged_jst.date().isoformat(),
                    "kind": kind,
                    "name": name,
                    "version": version,
                    "pr_number": pr["number"],
                    "pr_url": pr["html_url"],
                    "merged_at": merged_at,
                    **enrich(kind, name),
                })
    return sorted(entries, key=lambda e: (e["date"], e["kind"], e["name"]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--since", type=date.fromisoformat, required=True, help="JST date, inclusive")
    parser.add_argument("--until", type=date.fromisoformat, required=True, help="JST date, inclusive")
    args = parser.parse_args()
    if args.since > args.until:
        parser.error("--since must not be after --until")
    json.dump(collect(args.since, args.until), sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
