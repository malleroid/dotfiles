---
name: release-digest
allowed-tools: Bash(fish *), Bash(git rev-parse *)
description: "追跡対象 (Claude Code / Claude Platform API) のリリースを直近 N 日ぶん取得し、ソース×単位ごとに日本語ダイジェスト（トピック順、bugfix は末尾へ全列挙）を生成する。引数: 期間の日数 (デフォルト 1) と任意のソース指定 (cc|api|all)、または 'raw' で正規化 JSON のみ出力"
---

## このスキルについて

この dotfiles リポジトリ専用の **project skill**（全プロジェクト共通の global skill ではない）。
取得・正規化は決定的スクリプト（`bin/`）に任せ、**トピック分類・翻訳・整形のみ LLM が担う**。

設計の不変条件（崩さないこと）:

- **取得段階で情報を捨てない**。bugfix 行も全保持し、優先度は「並べ替え」で表現する（削除しない）。
- 重要度は **動詞（Added/Fixed）ではなくトピック**で判断する。
- 受け手はエンジニア、目的は情報共有・キャッチアップ。バーは低く、基本は網羅する。
- **ソース間で重複排除しない**。各ソースは自分の changelog 全文を出す（相互掲載も両方に載る）。

## Context

- 現在日時 (JST): !`date +'%Y-%m-%d %H:%M:%S %Z'`
- Repo root: !`git rev-parse --show-toplevel`

## Sources

| ソース | フェッチャ | 単位 | 取得方式 |
|--------|-----------|------|----------|
| Claude Code | `bin/fetch-claude-code` | version | gh api + jq |
| Claude Platform (API) | `bin/fetch-dev-platform` | 日付 | curl `.md` + python |

各フェッチャは `<repo-root>/.claude/skills/release-digest/` 配下にあり、`fish <path> <days>` で実行する。

## Your task

Arguments: $ARGUMENTS

### Step 0: 引数解釈

- 数値（例 `1` / `3` / `7`）→ その日数を window とする。空なら `1`。
- ソース指定トークン `cc` / `api` / `all` → 対象ソースを絞る（既定 `all`）。
- `raw` → Step 1 を実行し、各ソースの正規化 JSON をそのまま出力して終了（デバッグ用）。

### Step 1: フェッチ（決定的）

対象ソースごとに Bash ツールで対応フェッチャを実行し、正規化 JSON を得る（`<root>` は Context の Repo root、`<days>` は Step 0 の値）:

```
fish "<root>/.claude/skills/release-digest/bin/fetch-claude-code" <days>
fish "<root>/.claude/skills/release-digest/bin/fetch-dev-platform" <days>
```

共通スキーマ（要素 = 1 単位）:

```
{ date, url, change_count, changes[], ... }
  - Claude Code: version, published_at, bugfix_only も持つ
  - Claude Platform: unit (= 日付) を持つ
```

`changes` は原文の箇条書きを無加工で全保持。空配列 `[]` のソースは「直近 <days> 日に新規なし」と一言添える。

### Step 2: レンダリング（ソース × 単位ごとに 1 メッセージ）

**共通原則**（全ソース）:

- 1 単位 = 1 メッセージブロック。単位は日付（同日は version）降順。
- ヘッダーに原文リンクを Slack mrkdwn 形式 `<URL|原文>` で付ける。
- 各 `changes[]` 行をトピックへ分類し、トピックの優先度順に見出しを立てて列挙（該当 0 件の見出しは省略）。
- **トピック優先**: 先頭動詞でなく内容で判断する。迷うものは下位の雑多トピックへ落とさず、最も近い上位トピックへ寄せる（取りこぼし回避）。
- 製品名・モデル名・API 名・コマンド名・設定名は英語のまま（`Claude Opus 4.8` / `fallbackModel` / `stop_details` 等）。
- 🚨 **breaking**: 既存運用が壊れる変更（削除・改名・retire・deprecation・非互換）。行頭に 🚨。
- ⚠️ **注意**: 壊れはしないが挙動が実質変わり知らないとハマるもの。行頭に ⚠️。

#### A. Claude Code（単位 = version）

- `bugfix_only: true` の version → 最小 1 行: `*Claude Code <version>* — <date> · <<url>|原文>  ／ bugfix のみ`
- それ以外 → ヘッダー `*Claude Code <version>* — <date> · <<url>|原文>` ＋ 以下トピック順:
  1. 🔧 **機能** — 新機能・新コマンド・新オプション・既存機能の能力追加
  2. 🔁 **挙動変更** — 既存の挙動 / デフォルト / 出力が変わるもの
  3. 🛡 **セキュリティ/権限** — 権限・認証・サンドボックス・managed settings・deny/allow ルール
  4. 💻 **環境固有** — 特定 OS / IDE / 端末（Windows・macOS・WSL・JetBrains・VS Code 等）限定
  5. ⌨️ **入力/端末** — IME・キーボード・vim mode・端末描画・クリップボード
  6. ⚡ **パフォーマンス** — 速度・レイテンシ・リソース消費
  7. 🐛 **その他 bugfix** — 上記以外の一般的な修正
- 各行: トピック 1〜6 は日本語タイトル（太字）＋必要なら 1〜2 行要約。トピック 7 は要約なしの 1 行訳で、**件数が多くても全件列挙**（長ければ ` / ` 区切り可）。

#### B. Claude Platform / API（単位 = 日付）

- ヘッダー `*Claude Platform (API)* — <date> · <<url>|原文>` ＋ 以下トピック順（**deprecation/retire が最上位**）:
  1. 🚨 **破壊的変更・deprecation・retire** — モデル廃止予告・retire 日・beta 廃止・非互換変更。**retire 日は太字で強調**。
  2. 🆕 **新モデル** — Opus/Sonnet/Haiku のローンチ。**モデルの capabilities（context長・出力・thinking・画像・effort 等）は 1 項目に集約**してバラさない。
  3. 🔧 **API 機能・パラメータ・beta** — 新ツール・新パラメータ・beta header・GA 化・課金/レスポンス挙動の変更
  4. ☁️ **プラットフォーム展開** — Bedrock / Vertex / Foundry / AWS、SDK 言語追加
  5. 💰 **料金・レート制限**
  6. 📝 **その他** — docs / console UI・軽微・Claude Code 等の相互掲載（**落とさず載せる**）
- 各行: 日本語タイトル（太字）＋ 1〜2 行要約。bugfix 概念は基本無いので末尾列挙は不要。

### Step 3: 出力

- ソース単位でグルーピングし、その中で単位（version / 日付）降順に各メッセージブロックを出力する。
- 出力先は現状この会話（Phase 1）。将来は「1 単位 = 1 メッセージ」で Slack webhook へ投げる。追加のまとめ文は不要。

## 補足

- Claude Apps（Desktop / Cowork 等）は確定済みだが未実装。同じ「決定的フェッチ → LLM 整形」パターンで追加予定（情報源は `support.claude.com` の HTML、要 HTML パース）。
- 移植: `fetch-claude-code` の日付計算は BSD date 前提（macOS ローカル）。cron / Linux 移行時は GNU date へ。`fetch-dev-platform` は curl + python3 で OS 非依存。
