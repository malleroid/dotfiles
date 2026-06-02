---
name: release-digest
allowed-tools: Bash(cat *), WebFetch
description: "追跡対象 SaaS / AI ツールの changelog / blog RSS を読み、最近の機能追加・破壊的変更を日本語要約してダイジェスト出力する。引数: 期間 (1d|3d|7d|14d|30d, デフォルト 7d) もしくは 'validate' でフィード設定の検証のみ"
---

## Context

- Skill directory: `~/.agents/skills/release-digest/`
- 現在日時 (JST): !`date +'%Y-%m-%d %H:%M:%S %Z'`
- Feeds config (`feeds.json`):

!`cat "$HOME/.agents/skills/release-digest/feeds.json"`

## Your task

Arguments: $ARGUMENTS

### Step 0: 引数解釈

- 引数が `validate` の場合 → Step 1 のみ実行し、各フィードの enabled / url 状態を表で出力して終了
- 引数が `1d` / `3d` / `7d` / `14d` / `30d` の場合 → その期間を window とする
- 引数が空の場合 → window = `7d`
- それ以外 → 「期間は `1d` / `3d` / `7d` / `14d` / `30d` のいずれかを指定してください」と返して終了

### Step 1: 設定確認

Context に inline された `feeds.json` を参照する。各エントリのスキーマ:

```
{
  "name": string,        // 表示名
  "url": string,         // fetch 先 URL
  "format": "rss" | "atom" | "html" | "unknown",
  "enabled": boolean,
  "notes": string?       // 任意メモ
}
```

引数が `validate` の場合: 全エントリを以下の表で出力して終了する。`enabled` / `url` が `TODO` のものは要対応として明示。

```
| name | enabled | format | url |
|------|---------|--------|-----|
```

### Step 2: フィード取得 (並列)

`enabled === true` のフィードに対し、**1 レスポンス内で全 WebFetch を並列実行**する。各 WebFetch の `prompt` は以下のテンプレートを使う:

```
このページから過去 <window> 以内に公開された項目を抽出し、JSON 配列で返してください。
各項目の構造:
  {
    "title": string,           // 原文タイトル
    "url": string,             // 詳細ページの URL (相対 URL の場合は絶対化)
    "published": "YYYY-MM-DD", // 不明な場合は "unknown"
    "raw_summary": string,     // 概要 (1-3 文程度の原文)
    "category_hint": string    // 著者が付けたタグ・セクション名があれば
  }

ルール:
- <window> より古い項目はスキップ
- RSS/Atom フィードの場合: <item>/<entry> 単位で抽出
- HTML changelog の場合: 日付見出しごとに 1 項目として抽出 (同じ日に複数項目があれば分割)
- 該当 0 件の場合は空配列 [] を返す
```

`<window>` は Step 0 で決定した値 (例: `past 7 days`)。

### Step 3: 分類・フィルタ・翻訳・要約

取得した全項目を 1 つのリストにフラット化した上で、以下の処理を行う:

1. **分類** (内容から判断):
   - `feature_addition`: 新機能・新 API・新モデル・新ベータ・GA 化など
   - `breaking_change`: 破壊的変更・廃止予告・retire・互換性に影響する変更
   - `bug_fix`: バグ修正のみ
   - `other`: 営業発表・人事・ブログ的記事・コミュニティ告知など
2. **フィルタ**: `bug_fix` と `other` を除外 (feature_addition と breaking_change のみ残す)
3. **翻訳**: タイトルを自然な日本語に。**製品名・モデル名・API 名・固有名詞は英語のまま** (例: 「Claude Opus 4.7」「Workers」「Web Search Tool」)
4. **要約**: `raw_summary` を 1-2 行の日本語に要約。「何ができるようになったか」「誰が嬉しいか」を主眼に、宣伝文句やマーケ表現は削る
5. **マーク**: `breaking_change` の項目は冒頭に 🚨、`feature_addition` は通常表示

### Step 4: 出力

以下のフォーマットで Markdown を 1 つの message として出力する。フィード単位でグルーピングし、その中で日付降順:

```markdown
# Release Digest (過去 <window>)

> 生成日: <YYYY-MM-DD>
> 対象: <enabled なフィード数> フィード / 抽出: <分類後の項目数> 件

## Claude Platform
- **<JP タイトル>** ([原文](URL)) — <published>
  <1-2 行要約>
- 🚨 **<JP タイトル>** ([原文](URL)) — <published>
  <破壊的変更の要約>

## Claude Code
- ...

## OpenAI
（新着なし）
```

- 各セクションでフィルタ後 0 件の場合は `（新着なし）` と書く
- 全フィードで 0 件の場合は `期間内に新規アイテムはありませんでした。` と本文に書いて終了
- WebFetch が失敗したフィードは末尾に `## 取得失敗` セクションを設けて理由と共に列挙

### Step 5: 配信先 (Phase 2 用フック)

現状は会話への stdout 出力のみ。将来的に Slack webhook 配信を行う想定だが、本 skill では実装しない。

## 注意事項

- WebFetch のキャッシュは 15 分なので、同一 URL に対する重複呼び出しは避ける
- HTML changelog ページ (例: Claude Platform) は WebFetch の小モデルが解釈する。`<window>` を厳密に守るよう prompt で明示すること
- 日付不明な項目は「unknown」として残し、フィルタの対象外にする (古い可能性があるので末尾に置く)
- 翻訳時は「Claude」「Workers」など固有の製品名を勝手に意訳しない
