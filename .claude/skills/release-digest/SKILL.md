---
name: release-digest
allowed-tools: Bash(fish *), Bash(git rev-parse *), Read
description: "追跡対象のリリースを直近 N 日ぶん取得し、ソース×単位ごとに日本語ダイジェスト（トピック順、bugfix は末尾へ全列挙）を生成する。引数: 期間の日数 (デフォルト 1) と任意のソース指定 (id|all)、または 'raw' で正規化 JSON のみ出力"
---

## このスキルについて

この dotfiles リポジトリ専用の **project skill**（全プロジェクト共通の global skill ではない）。

アーキテクチャ: **source registry 駆動**。ソース固有の知識（フェッチャ・単位・トピック分類）は
`sources.json` と `sources/<id>.md` に外出しし、この SKILL.md は**共通の整形原則と registry を回す手順**だけを持つ。
ソース追加 = フェッチャ 1 本（`bin/`）＋ スペック 1 枚（`sources/`）＋ `sources.json` に 1 行、で完結し、この SKILL.md は触らない。
registry は将来の cron/Slack 配信パイプラインからも同じ定義として読まれる想定。

設計の不変条件（崩さないこと）:

- **取得段階で情報を捨てない**。bugfix 行も全保持し、優先度は「並べ替え」で表現する（削除しない）。
- 重要度は **動詞（Added/Fixed）ではなくトピック**で判断する。
- 受け手はエンジニア、目的は情報共有・キャッチアップ。バーは低く、基本は網羅する。
- **ソース間で重複排除しない**。各ソースは自分の changelog 全文を出す（相互掲載も両方に載る）。

## Context

- 現在日時 (JST): !`date +'%Y-%m-%d %H:%M:%S %Z'`
- Repo root: !`git rev-parse --show-toplevel`
- Skill dir: `<repo-root>/.claude/skills/release-digest/`

## Your task

Arguments: $ARGUMENTS

### Step 0: 引数解釈

- 数値（例 `1` / `3` / `7`）→ その日数を window とする。空なら `1`。
- ソース指定トークン（`sources.json` の `id`、例 `claude-code` / `dev-platform`）または `all` → 対象ソースを絞る（既定 `all`）。
- `raw` → Step 1 を実行し、各ソースの正規化 JSON をそのまま出力して終了（デバッグ用）。

### Step 1: registry 読み込み & フェッチ（決定的）

1. Read ツールで Skill dir の `sources.json` を読む。
2. `enabled: true` かつ Step 0 のフィルタに合致するソースごとに、次を実行する:
   - **フェッチ**: Bash ツールで `fish "<skill-dir>/<fetcher>" <days>` を実行し、正規化 JSON を得る。
   - **スペック読込**: Read ツールで `<skill-dir>/<spec>` を読み、そのソースのヘッダー形式・トピック分類規則を把握する。

共通スキーマ（要素 = 1 単位）: `{ date, url, change_count, changes[], ... }`。`changes` は原文の箇条書きを無加工で全保持。
空配列 `[]` のソースは「直近 <days> 日に新規なし」と一言添える。

### Step 2: レンダリング（ソース × 単位ごとに 1 メッセージ）

各ソースの**スペック**（Step 1 で読んだ `sources/<id>.md`）のヘッダー形式・トピック順に従って各単位をメッセージ化する。
その際、全ソース共通で以下の**原則**を守る:

- 1 単位 = 1 メッセージブロック。単位（version / 日付）は降順。
- ヘッダーに原文リンクを Slack mrkdwn 形式 `<URL|原文>` で付ける。
- 各 `changes[]` 行を、スペックのトピックへ**内容（動詞でなく）で**分類し、優先度順に見出しを立てて列挙（該当 0 件の見出しは省略）。
- 迷う行は下位の雑多トピックへ落とさず、最も近い上位トピックへ寄せる（取りこぼし回避）。
- 製品名・モデル名・API 名・コマンド名・設定名は英語のまま（`Claude Opus 4.8` / `fallbackModel` / `stop_details` 等）。
- 🚨 **breaking**: 既存運用が壊れる変更（削除・改名・retire・deprecation・非互換）。行頭に 🚨。
- ⚠️ **注意**: 壊れはしないが挙動が実質変わり、知らないとハマるもの。行頭に ⚠️。

### Step 3: 出力

- ソース単位でグルーピングし、その中で単位（version / 日付）降順に各メッセージブロックを出力する。
- 出力先は現状この会話（Phase 1）。将来は「1 単位 = 1 メッセージ」で Slack webhook へ投げる。追加のまとめ文は不要。

## 補足

- 移植: 各フェッチャの依存・OS 前提は当該スクリプトの先頭コメントを参照（例: `fetch-claude-code` は BSD date 前提）。
