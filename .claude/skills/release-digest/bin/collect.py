#!/usr/bin/env python3
"""release-digest collector: run enabled fetchers, dedup new change items, manage seen-state.

Modes:
  (default)  fetch all enabled sources over --days, emit only NEW items (per source/unit) as a
             JSON envelope on stdout. Does NOT modify state (read-only).
  --seed     fetch all sources and mark every current hash as seen (no emit) — first-run priming.
  --commit   read a previously-emitted envelope from stdin and mark its hashes seen (first_seen =
             today JST), prune hashes older than --prune-days, write state. Run AFTER delivery.

Dedup key (K1): item content hash = sha1(source_id + "::" + whitespace-normalized change text).
State (S2): per-source map { source: { hash: "YYYY-MM-DD" } } at $RELEASE_DIGEST_STATE
            (default <skill>/state/seen.json).

The two-phase emit/commit split honors "on-deliver": commit only after the rendered digest has
actually been delivered (stdout/file now, Slack later), so a failed render never loses items.
"""
import sys
import os
import json
import hashlib
import subprocess
import argparse
from pathlib import Path
from datetime import timedelta

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _window import cutoff_date  # cutoff_date(n) == JST today minus n days

SKILL = Path(__file__).resolve().parent.parent
DEFAULT_STATE = SKILL / "state" / "seen.json"


def state_path():
    return Path(os.environ["RELEASE_DIGEST_STATE"]) if os.environ.get("RELEASE_DIGEST_STATE") else DEFAULT_STATE


def load_state():
    p = state_path()
    return json.loads(p.read_text()) if p.exists() else {}


def save_state(seen):
    p = state_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(seen, ensure_ascii=False, indent=2) + "\n")


def item_hash(source_id, text):
    norm = " ".join(text.split())
    return hashlib.sha1(f"{source_id}::{norm}".encode("utf-8")).hexdigest()


def unit_item_texts(unit):
    """The texts to hash for a unit: each change, or a title/version fallback for thin units."""
    changes = unit.get("changes") or []
    if changes:
        return changes
    fallback = unit.get("title") or unit.get("version") or unit.get("unit") or unit.get("date")
    return [fallback] if fallback else []


def run_fetcher(fetcher_rel, days, attempts=2):
    """Run a fetcher, retrying on clear failures (non-zero exit / non-JSON) to ride out
    transient network hiccups. A successful-but-empty `[]` is taken at face value."""
    path = SKILL / fetcher_rel
    for attempt in range(1, attempts + 1):
        r = subprocess.run(["fish", str(path), str(days)], capture_output=True, text=True)
        if r.returncode != 0:
            last = f"exit {r.returncode}: {r.stderr.strip()}"
        else:
            try:
                return json.loads(r.stdout)
            except json.JSONDecodeError:
                last = "non-JSON output"
        if attempt < attempts:
            continue
        sys.stderr.write(f"[collect] {fetcher_rel} failed after {attempts} attempts ({last})\n")
        return None


def fetch_all(days):
    for s in json.loads((SKILL / "sources.json").read_text()):
        if not s.get("enabled") or not s.get("fetcher"):
            continue
        units = run_fetcher(s["fetcher"], days)
        if units is None:
            continue
        yield {"id": s["id"], "name": s["name"], "spec": s.get("spec"), "units": units}


def collect(days):
    """Return (digest_sources, commit_map) for items whose hash is not yet in state."""
    seen = load_state()
    digest, commit = [], {}
    for src in fetch_all(days):
        sid = src["id"]
        seen_src = seen.get(sid, {})
        new_units, new_hashes = [], []
        for unit in src["units"]:
            changes = unit.get("changes") or []
            if changes:
                kept = []
                for ch in changes:
                    h = item_hash(sid, ch)
                    if h not in seen_src:
                        kept.append(ch)
                        new_hashes.append(h)
                if kept:
                    u = dict(unit)
                    u["changes"] = kept
                    new_units.append(u)
            else:  # thin (title-only) unit — dedup on its signature
                texts = unit_item_texts(unit)
                if texts and item_hash(sid, texts[0]) not in seen_src:
                    new_hashes.append(item_hash(sid, texts[0]))
                    new_units.append(dict(unit))
        if new_units:
            digest.append({"id": sid, "name": src["name"], "spec": src["spec"], "units": new_units})
        if new_hashes:
            commit[sid] = new_hashes
    return digest, commit


def do_seed(days):
    seen = load_state()
    today = cutoff_date(0).isoformat()
    n = 0
    for src in fetch_all(days):
        d = seen.setdefault(src["id"], {})
        for unit in src["units"]:
            for text in unit_item_texts(unit):
                if d.setdefault(item_hash(src["id"], text), today) == today:
                    n += 1
    save_state(seen)
    sys.stderr.write(f"[collect] seeded; state now has {sum(len(v) for v in seen.values())} hashes\n")


def do_commit(commit_map, prune_days):
    seen = load_state()
    today = cutoff_date(0).isoformat()
    keep_from = cutoff_date(prune_days).isoformat()
    for sid, hashes in commit_map.items():
        d = seen.setdefault(sid, {})
        for h in hashes:
            d.setdefault(h, today)
    for sid in list(seen.keys()):
        seen[sid] = {h: ts for h, ts in seen[sid].items() if ts >= keep_from}
        if not seen[sid]:
            del seen[sid]
    save_state(seen)
    sys.stderr.write(f"[collect] committed; pruned to >= {keep_from}; "
                     f"{sum(len(v) for v in seen.values())} hashes retained\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=7, help="fetch lookback window (<= prune-days)")
    ap.add_argument("--prune-days", type=int, default=14, help="retain seen hashes this many days")
    ap.add_argument("--seed", action="store_true", help="prime state with current items, no emit")
    ap.add_argument("--commit", action="store_true", help="mark stdin envelope's hashes seen")
    args = ap.parse_args()

    if args.seed:
        do_seed(args.days)
        return
    if args.commit:
        env = json.load(sys.stdin)
        do_commit(env.get("commit", {}), args.prune_days)
        return

    digest, commit = collect(args.days)
    print(json.dumps({
        "window_days": args.days,
        "generated_jst": cutoff_date(0).isoformat(),
        "sources": digest,
        "commit": commit,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
