---
allowed-tools: Bash(ghq list *), Bash(jq *), Read, Edit
description: "ghq 管理下の全リポジトリから .claude/settings.local.json を収集し、global settings.json への取り込みを提案する"
---

## Your task

Arguments: $ARGUMENTS

### Step 1: データ収集

以下を1レスポンスで並列実行する:
- `ghq list --full-path` を Bash ツールで実行してリポジトリ一覧を取得する
- `~/.claude/settings.json` を Read ツールで読み込む

続いて、取得したリポジトリ一覧の各パスに `.claude/settings.local.json` が存在するものを Read ツールで読み込む（存在しない場合はスキップ）。

### Step 2: 差分抽出

Per-repo の各 `permissions` エントリと global settings.json を比較し、グローバルにまだ存在しないエントリを列挙する。

**除外するもの（プロジェクト固有と判断）:**
- `hooks` セクション全体（`$CLAUDE_PROJECT_DIR` 参照を含む可能性が高い）
- `mcpServers` の定義
- `env` の環境変数
- `mcp__<server>__*` 形式で特定サーバーを示すツール権限（汎用性が低い）
- `enabledPlugins` / `alwaysThinkingEnabled` / `statusLine`（個人設定）

**グローバル化の候補:**
- `permissions.allow` の `Bash(...)` エントリ（汎用コマンド）
- `permissions.allow` の `WebFetch(domain:...)` エントリ
- `permissions.deny` / `permissions.ask` のエントリ

### Step 3: 候補提示

差分があれば以下のフォーマットで番号付きリストを提示する:

```
[1] 出所: <repo名>
    内容: "<エントリ文字列>"
    追加先: permissions.allow / permissions.deny / permissions.ask
    理由: <汎用化が適切な理由>
```

差分がなければ「すべての設定はすでにグローバルに含まれています」と伝えて終了する。

### Step 4: 確認と適用

- Arguments が `preview` の場合は提案のみ行い終了する
- それ以外の場合: 承認する番号（例: `1 3 5` または `all`）をユーザーに確認する
- 承認されたエントリを `~/.claude/settings.json`（= dotfiles の `.claude/settings.json`）の該当配列に Edit ツールで追記する
- 追記前に重複チェックを必ず行い、すでに存在するエントリは追加しない
- 適用後「N 件を追加しました。`git diff .claude/settings.json` で確認できます」と伝える
