# 出力フォーマット

レビュー結果は **HTML ファイル**（全文）と **terminal サマリ**（親への戻り値）の 2 つに分けて出す。

## 出力先

```
./tmp/reviews/<識別子>-<YYYYMMDD-HHMMSS>.html
```

- 識別子: PR モードは `pr-<番号>`、working diff モードはブランチ名（`/` は `-` に置換）、ブランチが特定できなければ `working-diff`
- パスは常に **cwd からの相対**。worktree をレビューしている場合も cwd（元のリポジトリ）に書く
- `tmp/reviews/` が無ければ作る。global gitignore に `tmp/` があるので git status は汚れない

## terminal サマリ

親に返すのはこれだけ。Minor 以下は HTML にしか載せない。

```
REQUEST CHANGES — Critical 2 / Major 3
・ SQL injection (src/api/user.rb:42)
・ N+1 (src/services/list.rb:78)
・ 認可チェック漏れ (src/controllers/admin.rb:15)
→ ./tmp/reviews/pr-123-20260922-143052.html
```

- 1 行目: 判定 + Critical / Major の件数
- 2 行目以降: Critical と Major を 1 件 1 行。`短い要約 (ファイルパス:行番号)` の形式。**5 件を超えたら上位 5 件だけ出して `ほか N 件` を付ける**
- 最終行: HTML のパス
- Critical / Major が 0 件なら箇条書きは省き、`APPROVE — 指摘なし（Minor 2 / Nit 1）` のように件数だけ出す

## HTML

### 要件

- **自己完結**: CSS は `<style>` にインライン。外部 CSS / JS / フォント / 画像を一切参照しない（オフラインで開ける）
- **テーマ追従**: `prefers-color-scheme` で light / dark 両対応。ターミナルと行き来するので必須
- **検索はブラウザ任せ**: 独自の検索 UI や JS は書かない。JS 無しで完結させる
- **折りたたみ**: Minor / Nit / Praise と、長い「既存指摘の状況」は `<details>` で畳む。Critical / Major は常に開いた状態
- 日本語本文なので `<html lang="ja">`

### セクション構成

上から順に:

1. ヘッダ — 判定バッジ / 対象（PR 番号・ブランチ）/ 生成時刻 / 件数サマリ
2. 概要 — 変更内容と全体的な印象を 1-2 文。コードベースの健全性への影響を述べる
3. 既存指摘の状況 — PR モードで既存レビューコメントがある場合のみ。未解決スレッドごとに 対応済み / 部分対応 / 未対応 + 検証根拠
4. Critical Issues
5. Major Issues
6. Minor Suggestions（`<details>`）
7. Nits（`<details>`）
8. Praise（`<details>`）
9. テスト観点 — この変更で追加・更新すべきテスト、検証すべきエッジケース
10. 影響範囲 — 影響するシステム・ユーザー・機能、DB スキーマ、API 互換性
11. 人間が最終確認すべき観点 — AI では判断困難な業務ロジック、アーキテクチャ上の設計判断、合意が必要な変更

該当が無いセクションは丸ごと省く。

### 各指摘のマークアップ

```html
<article class="finding sev-critical">
  <h3><code>src/api/user.rb:42</code> <span class="cat">security</span></h3>
  <p>問題の説明とコード健全性への影響。</p>
  <pre><code>修正案のコード</code></pre>
  <p class="basis">根拠: OWASP Top 10 - A03:2021 Injection</p>
</article>
```

`sev-` は `critical` / `major` / `minor` / `nit` / `praise`。

### スケルトン

これをベースに肉付けする。CSS はこのまま使ってよい。

```html
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>レビュー: {{対象}}</title>
<style>
:root{
  --bg:#fff; --fg:#1a1a1a; --muted:#666; --border:#e0e0e0; --code-bg:#f6f8fa;
  --critical:#d1242f; --major:#bc4c00; --minor:#0969da; --nit:#6e7781; --praise:#1a7f37;
}
@media (prefers-color-scheme:dark){
  :root{
    --bg:#0d1117; --fg:#e6edf3; --muted:#9198a1; --border:#30363d; --code-bg:#161b22;
    --critical:#ff7b72; --major:#ffa657; --minor:#79c0ff; --nit:#8b949e; --praise:#3fb950;
  }
}
*{box-sizing:border-box}
body{
  margin:0 auto; padding:2rem 1.25rem 4rem; max-width:60rem;
  background:var(--bg); color:var(--fg);
  font:16px/1.75 -apple-system,BlinkMacSystemFont,"Hiragino Sans","Noto Sans JP",sans-serif;
}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
pre{background:var(--code-bg);border:1px solid var(--border);border-radius:6px;padding:.75rem 1rem;overflow-x:auto;font-size:.875rem;line-height:1.6}
code{background:var(--code-bg);padding:.1em .35em;border-radius:4px;font-size:.9em}
pre code{background:none;padding:0;font-size:inherit}
header{border-bottom:2px solid var(--border);padding-bottom:1rem;margin-bottom:2rem}
h1{font-size:1.5rem;margin:0 0 .5rem}
.verdict{display:inline-block;padding:.2em .7em;border-radius:999px;color:#fff;font-size:.8rem;font-weight:700;letter-spacing:.03em}
.verdict.approve{background:var(--praise)} .verdict.changes{background:var(--critical)} .verdict.comment{background:var(--minor)}
.meta{color:var(--muted);font-size:.85rem}
h2{font-size:1.15rem;margin:2.5rem 0 .75rem;padding-bottom:.3rem;border-bottom:1px solid var(--border)}
.finding{border-left:4px solid var(--border);padding:.25rem 0 .25rem 1rem;margin:1.5rem 0}
.finding h3{font-size:.95rem;margin:0 0 .5rem;font-weight:600}
.finding p{margin:.5rem 0}
.sev-critical{border-left-color:var(--critical)}
.sev-major{border-left-color:var(--major)}
.sev-minor{border-left-color:var(--minor)}
.sev-nit{border-left-color:var(--nit)}
.sev-praise{border-left-color:var(--praise)}
.cat{color:var(--muted);font-size:.75rem;font-weight:400;margin-left:.5rem}
.basis{color:var(--muted);font-size:.85rem}
details{margin:1rem 0} summary{cursor:pointer;font-weight:600;padding:.4rem 0}
</style>
</head>
<body>
<header>
  <h1>レビュー: {{対象}}</h1>
  <p><span class="verdict changes">REQUEST CHANGES</span></p>
  <p class="meta">{{生成時刻}} · Critical {{n}} / Major {{n}} / Minor {{n}} / Nit {{n}}</p>
</header>

<h2>概要</h2>
<p>{{概要}}</p>

<h2>Critical Issues</h2>
<article class="finding sev-critical">…</article>

<h2>Major Issues</h2>
<article class="finding sev-major">…</article>

<details><summary>Minor Suggestions ({{n}})</summary>…</details>
<details><summary>Nits ({{n}})</summary>…</details>
<details><summary>Praise ({{n}})</summary>…</details>

<h2>テスト観点</h2>
<h2>影響範囲</h2>
<h2>人間が最終確認すべき観点</h2>
</body>
</html>
```

## 判定

ヘッダの `.verdict` に出す。

- `APPROVE` (`.approve`) — コードベースの健全性を改善しており、承認可能
- `REQUEST CHANGES` (`.changes`) — Critical または Major な問題があり、修正が必要
- `COMMENT` (`.comment`) — フィードバックのみ提供
