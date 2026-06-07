---
name: release-digest
allowed-tools: Bash(fish *), Bash(git rev-parse *)
description: "Claude Code のリリースノートを直近 N 日ぶん取得し、version ごとに日本語ダイジェスト（機能・挙動・セキュリティ等をトピック順に、bugfix は末尾へ全列挙）を生成する。引数: 期間の日数 (デフォルト 1)、または 'raw' で正規化 JSON のみ出力"
---

## このスキルについて

この dotfiles リポジトリ専用の **project skill**（全プロジェクト共通の global skill ではない）。
複数ソース対応の前段として、まず **Claude Code 1 ソースだけ**を対象にした最小版。
取得・正規化は決定的スクリプトに任せ、**トピック分類・翻訳・整形のみ LLM が担う**。

設計の不変条件（崩さないこと）:

- **取得段階で情報を捨てない**。bugfix 行も全保持し、優先度は「並べ替え」で表現する（削除しない）。
- 重要度は **動詞（Added/Fixed）ではなくトピック**で判断する。`Fixed` でもセキュリティ/権限/環境/入力に該当すれば上位へ引き上げる。
- 受け手はエンジニア、目的は情報共有・キャッチアップ。バーは低く、基本は網羅する。

## Context

- 現在日時 (JST): !`date +'%Y-%m-%d %H:%M:%S %Z'`
- Repo root: !`git rev-parse --show-toplevel`

## Your task

Arguments: $ARGUMENTS

### Step 0: 引数解釈

- 数値（例 `1` / `3` / `7`）→ その日数を window とする
- 空 → window = `1`（直近 1 日）
- `raw` → Step 1 を実行し、正規化 JSON をそのまま出力して終了（デバッグ用）

### Step 1: フェッチ（決定的）

Bash ツールで次を実行し、正規化済み JSON を得る（`<repo-root>` は Context の Repo root、`<days>` は Step 0 の値）:

```
fish "<repo-root>/.claude/skills/release-digest/bin/fetch-claude-code" <days>
```

得られる各要素のスキーマ:

```
{ version, date, published_at, url, change_count, bugfix_only, changes[] }
```

- `draft` / `prerelease` は除外済み、`published_at >= now-<days>` で絞り込み済み
- `changes` は CHANGELOG の箇条書きを無加工で全保持

JSON が空配列 `[]` の場合は「直近 <days> 日に対象リリースはありません」と返して終了する。

### Step 2: レンダリング（version ごとに 1 メッセージ）

`date`（同日なら version 番号）の **降順**で、各 version を以下の規則でメッセージ化する。

**(a) `bugfix_only: true` の version** — 最小 1 行のみ:

```
*Claude Code <version>* — <date> · <<url>|原文>  ／ bugfix のみ
```

**(b) それ以外の version** — ヘッダー＋トピック別の本文:

```
*Claude Code <version>* — <date> · <<url>|原文>
```

`changes[]` の各行を次の **トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🔧 **機能** — 新機能・新コマンド・新オプション・既存機能の能力追加
2. 🔁 **挙動変更** — 既存の挙動 / デフォルト / 出力が変わるもの
3. 🛡 **セキュリティ/権限** — 権限・認証・サンドボックス・managed settings・deny/allow ルール関連
4. 💻 **環境固有** — 特定 OS / IDE / 端末（Windows・macOS・WSL・JetBrains・VS Code 等）限定の修正
5. ⌨️ **入力/端末** — IME・キーボード・vim mode・端末描画・クリップボード関連
6. ⚡ **パフォーマンス** — 速度・レイテンシ・リソース消費
7. 🐛 **その他 bugfix** — 上記いずれにも属さない一般的な修正

分類の原則:

- **トピック優先**: 先頭動詞でなく内容で判断する。`Fixed` でも内容が権限なら 🛡、IME なら ⌨️。
- 1 行が複数トピックに跨る場合は、重要度順（機能 > 挙動 > セキュリティ > 環境 > 入力 > perf > その他）で **最も高いトピック 1 つ**に置く。
- 迷うものは「その他 bugfix」へ落とさず、最も近い上位トピックに寄せる（取りこぼし回避）。

各行の書き方:

- **トピック 1〜6**: 日本語タイトル（太字）＋必要なら 1〜2 行の補足要約。製品名・コマンド名・モデル名・設定名は英語のまま（`fallbackModel` / `Workers` / `Opus 4.8` 等）。
- **トピック 7（その他 bugfix）**: 要約は付けず、1 行の簡潔な日本語訳のみ。**件数が多くても全件列挙する**（省略禁止）。長くなる場合は ` / ` 区切りでまとめてよい。

マーク:

- 🚨 **breaking**: 既存のユーザー運用が壊れる変更（環境変数 / フラグ / コマンドの削除・改名、デフォルトの非互換変更、retire / deprecation）。行頭に 🚨。
- ⚠️ **注意**: 壊れはしないが挙動が実質変わり、知らないとハマるもの（権限の厳格化、認証継承の修正など）。行頭に ⚠️。

### Step 3: 出力

- version ごとに独立したメッセージブロックとして出力する（将来 Slack へ「1 version = 1 メッセージ」で投げる単位）。
- 全 version 出力後、追加のまとめ文は不要。

## 補足

- 出力先は現状この会話（Phase 1）。Slack webhook 配信は後続フェーズ。
- Claude Code 以外のソース（OpenAI / Cloudflare 等）は未対応。同じ「決定的フェッチ → LLM 整形」パターンで順次追加していく。
