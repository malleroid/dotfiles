#!/usr/bin/env python3
"""release-digest pipeline entrypoint (for launchd / manual run).

  collect (dedup, read-only)  →  render (claude -p)  →  deliver (stdout + dated file)  →  commit

Fetchers run exactly once (in collect); render and commit reuse that envelope. Commit happens
only after the digest is delivered, so a render/delivery failure never marks items seen (they
resurface next run). Usage: run.py [days]   (default 7; should be <= collect's prune window).
"""
import sys
import json
import subprocess
from pathlib import Path

BIN = Path(__file__).resolve().parent
SKILL = BIN.parent
DAYS = sys.argv[1] if len(sys.argv) > 1 else "7"


def state_dir():
    import os
    p = os.environ.get("RELEASE_DIGEST_STATE")
    return (Path(p).parent if p else SKILL / "state")


def main():
    collected = subprocess.run([sys.executable, str(BIN / "collect.py"), "--days", DAYS],
                               capture_output=True, text=True)
    if collected.returncode != 0:
        sys.stderr.write(collected.stderr)
        sys.exit(1)
    envelope = collected.stdout
    env = json.loads(envelope)

    rendered = subprocess.run([sys.executable, str(BIN / "render.py")],
                              input=envelope, capture_output=True, text=True)
    if rendered.returncode != 0:
        sys.stderr.write(rendered.stderr)
        sys.exit(1)
    digest = rendered.stdout.strip() + "\n"

    # deliver: stdout (captured by launchd's log) + a dated file for history
    sys.stdout.write(digest)
    sys.stdout.flush()
    try:
        d = state_dir() / "digests"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"digest-{env.get('generated_jst', 'latest')}.md").write_text(digest)
    except OSError as e:
        sys.stderr.write(f"[run] could not write dated digest: {e}\n")

    # commit only after successful delivery, and only if anything was new
    if env.get("sources"):
        committed = subprocess.run([sys.executable, str(BIN / "collect.py"), "--commit"],
                                   input=envelope, capture_output=True, text=True)
        sys.stderr.write(committed.stderr)


if __name__ == "__main__":
    main()
