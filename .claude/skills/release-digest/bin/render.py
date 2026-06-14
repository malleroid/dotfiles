#!/usr/bin/env python3
"""Render a collector envelope into a Japanese digest via headless `claude -p`.

Reads the collector's JSON envelope (from `collect.py`) on stdin and prints a Japanese digest to
stdout. The per-source rendering rules (sources/<id>.md) are inlined into the prompt so the
headless model needs no tools or MCP — it is a pure text transform.

Env:
  RELEASE_DIGEST_MODEL   model alias for `claude -p` (default "sonnet")
"""
import sys
import os
import re
import json
import subprocess
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent
MODEL = os.environ.get("RELEASE_DIGEST_MODEL", "sonnet")

PREAMBLE = """\
あなたはリリースダイジェストの整形担当です。以下の各ソースの「新規アイテム(JSON)」を、その
ソースの整形ルールに厳密に従って日本語ダイジェストに変換してください。

全ソース共通の原則:
- 取得済みの情報は捨てない（並べ替え・要約はするが省略しない）。
- 重要度は動詞でなく内容(トピック)で判断する。
- 製品名・モデル名・API 名・コマンド名・設定名は英語のまま。
- 原文リンクは Slack mrkdwn 形式 `<URL|原文>` で付ける。
- 🚨 = 破壊的変更/deprecation/retire、⚠️ = 知らないとハマる挙動変更。
- ソース単位でグルーピングし、ソース見出し（例 `## Claude Code`）を付ける。

出力の鉄則（厳守）:
- **ダイジェスト本文のみを出力**する。先頭にラベル(💭/🔍 等)・前置き・後書き・コードフェンスを付けない。
- マークダウンで、人間がそのまま読める形に。

---
"""


def build_prompt(env):
    parts = [PREAMBLE]
    for src in env.get("sources", []):
        spec_path = SKILL / src["spec"] if src.get("spec") else None
        spec = spec_path.read_text() if spec_path and spec_path.exists() else "(spec なし)"
        parts.append(f"# ソース: {src['name']} (id: {src['id']})\n")
        parts.append(f"## このソースの整形ルール\n{spec}\n")
        parts.append("## このソースの新規アイテム(JSON)\n")
        parts.append("```json\n" + json.dumps(src.get("units", []), ensure_ascii=False, indent=2) + "\n```\n")
    return "".join(parts)


def strip_label(text):
    # defensively drop a leading response-source label line (💭 / 🔍 / 🔍💭) if it leaked in
    return re.sub(r"^\s*(?:🔍|💭|🔍💭)[^\n]*\n+", "", text, count=1)


def main():
    env = json.load(sys.stdin)
    if not env.get("sources"):
        print(f"# Release Digest ({env.get('generated_jst', '')})\n\n本日の新規リリースはありません。")
        return

    prompt = build_prompt(env)
    r = subprocess.run(
        ["claude", "-p", "--model", MODEL, "--strict-mcp-config", prompt],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        sys.stderr.write(f"[render] claude -p failed (exit {r.returncode}): {r.stderr.strip()}\n")
        sys.exit(1)
    print(strip_label(r.stdout).strip())


if __name__ == "__main__":
    main()
