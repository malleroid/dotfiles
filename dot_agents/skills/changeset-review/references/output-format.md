# 出力フォーマット

レビュー結果は **HTML ファイル**（全文）と **terminal サマリ**（親への戻り値）の 2 つに分けて出す。

## 書き出し手順

HTML は **agent が全文を書かない**。`<head>` と `<style>` は固定ファイルが持ち、agent は `<body>` の中身（fragment）だけを書く。

1. fragment を Write する: `./tmp/reviews/<識別子>.fragment.html`
2. ラップする（cwd = 元のリポジトリで実行）:
   ```
   ~/.claude/skills/changeset-review/scripts/review-html-wrap ./tmp/reviews/<識別子>.fragment.html <識別子>
   ```
3. stdout に出たパス（`./tmp/reviews/<識別子>-<YYYYMMDD-HHMMSS>.html`）を terminal サマリの最終行に使う。パスを自分で組み立てない

- 識別子: PR モードは `pr-<番号>`、working diff モードはブランチ名、ブランチが特定できなければ `working-diff`
- worktree をレビューしている場合も cwd（元のリポジトリ）で実行する
- スクリプトがエラーで終了したら（fragment に `<html>` / `<head>` / `<style>` / `<body>` 等が入っていた等）、fragment を直して再実行する

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

- **fragment のみ**: `<!doctype>` / `<html>` / `<head>` / `<style>` / `<body>` は書かない。CSS（light / dark 対応済み）は `assets/review-shell-head.html` にある
- **外部参照なし**: 外部 CSS / JS / フォント / 画像を一切参照しない（オフラインで開ける）
- **JS なし**: 独自の検索 UI や JS は書かない。検索はブラウザ任せ
- **折りたたみ**: Minor / Nit / Praise と、長い「既存指摘の状況」は `<details>` で畳む。Critical / Major は常に開いた状態

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

### fragment スケルトン

これをベースに肉付けする。`<header>` から書き始め、`</body>` は書かない。

```html
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
```

## 判定

ヘッダの `.verdict` に出す。

- `APPROVE` (`.approve`) — コードベースの健全性を改善しており、承認可能
- `REQUEST CHANGES` (`.changes`) — Critical または Major な問題があり、修正が必要
- `COMMENT` (`.comment`) — フィードバックのみ提供
