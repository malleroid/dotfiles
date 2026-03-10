# MCP サーバー管理の移行計画

## 背景

- mcpm を使って MCP サーバー設定を複数クライアントに共通配布していた
- `playwright-mcp` → `@playwright/mcp` (Microsoft公式) への移行中に mcpm のプロキシが `@playwright/mcp` との通信でエラーを起こすことが判明
- mcpm 自体の開発が鈍化（最終リリース 2026-01-15、機能コミットは1ヶ月以上なし）
- mcpm は Copilot CLI / Gemini CLI を未サポート

## 現状の構成

```
mcp/
  mcpm/servers.json    # mcpm 管理の stdio サーバー定義（5サーバー）
  remote-servers.json  # リモート（SSE/HTTP）サーバー定義
  setup.fish           # mcpm client edit + claude mcp add で配布
```

### 現在のサーバー一覧

| サーバー | transport |
|---|---|
| serena | stdio |
| playwright-mcp (@playwright/mcp) | stdio |
| chrome-devtools-mcp | stdio |
| rails-mcp-server | stdio |
| awslabs.aws-documentation-mcp-server | stdio |
| atlassian-rovo | remote (SSE) |
| awslabs-aws-knowledge-mcp-server | remote (SSE) |

### 現在の配布先

| クライアント | 方法 | stdio | remote |
|---|---|---|---|
| Claude Code | mcpm + claude mcp add | o | o |
| Claude Desktop | mcpm | o | x |
| Codex CLI | mcpm | o | x |
| Copilot CLI | 未対応 | x | x |
| Gemini CLI | 未対応 | x | x |

## 課題

1. **mcpm プロキシの互換性問題**: `mcpm run` が `@playwright/mcp` との通信で `TaskGroup` エラーを起こす。サーバー自体は正常に動作する
2. **mcpm の開発停滞**: 新しい MCP サーバーへの追従が遅れるリスク
3. **対応クライアントの不足**: Copilot CLI / Gemini CLI は mcpm 未サポート
4. **プロキシという障害点**: `mcpm run` が中間に挟まることで、本来動くサーバーが動かなくなる

## 方針の選択肢

### A. mcpm を廃止し、CLI 直接 + 設定ファイル生成に移行

各クライアントの CLI（`claude mcp add`, `codex mcp add`, `gemini mcp add`）を直接叩き、CLI がないクライアント（Claude Desktop, Copilot CLI）は `jq` で設定ファイルを生成する。

**メリット**:
- プロキシ障害が原理的に起きない（各クライアントが直接サーバーを起動）
- 全5クライアントに対応可能
- mcpm への依存を排除

**デメリット**:
- Codex の TOML 変換、Copilot/Desktop の JSON 生成を自前で書く必要がある
- 各クライアント CLI の仕様変更に個別追従が必要

### B. mcpm を配布のみに使い、実行は各クライアント直接

mcpm の `client edit` で設定ファイルを書き換えるが、`mcpm run` プロキシは使わない。つまり各クライアントが直接サーバーコマンドを実行する設定を書き込む。

**メリット**:
- mcpm の配布機能は活用しつつプロキシ問題を回避
- setup.fish の変更が最小限

**デメリット**:
- mcpm の仕様上、`client edit --set-servers` は `mcpm run` 経由の設定を書き込むため、直接実行設定を書けるか要検証
- Copilot CLI / Gemini CLI は依然として未対応

### C. ハイブリッド（段階的移行）

1. まず `@playwright/mcp` の問題を `claude mcp add` で直接登録して解決
2. その後、全サーバーを段階的に CLI 直接方式に移行
3. 全移行完了後に mcpm を Brewfile から削除

## 推奨: C（ハイブリッド / 段階的移行）

## 実装ステップ

### Phase 1: @playwright/mcp の疎通確認（即時）

- [ ] `claude mcp add` で `@playwright/mcp` を直接登録
- [ ] ブラウザ起動・スナップショット取得で動作確認
- [ ] mcpm の playwright-mcp 設定は一旦残す（他クライアント向け）

```fish
claude mcp add --transport stdio --scope user playwright-mcp -- mcp-server-playwright --headless
```

### Phase 2: 共通サーバー定義の正規化

- [ ] `mcp/servers.json` を正規フォーマットで作成（mcpm 形式から独立）
- [ ] 各クライアントへの変換ロジックを `setup.fish` に実装

正規フォーマット案:
```json
{
  "playwright-mcp": {
    "command": "mcp-server-playwright",
    "args": ["--headless"],
    "env": {}
  },
  "serena": {
    "command": "uvx",
    "args": ["--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server", "--enable-web-dashboard", "false"],
    "env": {}
  }
}
```

### Phase 3: 全クライアントへの配布スクリプト実装

- [ ] Claude Code: `claude mcp add --scope user`
- [ ] Claude Desktop: `jq` で `claude_desktop_config.json` にマージ
- [ ] Codex CLI: `codex mcp add`
- [ ] Copilot CLI: `jq` で `~/.copilot/mcp-config.json` を生成
- [ ] Gemini CLI: `gemini mcp add --scope user`

### Phase 4: mcpm 依存の除去

- [ ] `setup.fish` から mcpm 関連コードを削除
- [ ] `mcp/mcpm/` ディレクトリを削除
- [ ] Brewfile から mcpm を削除
- [ ] `codex/config.toml` の `mcpm run` 参照を直接実行に変更

### Phase 5: リモートサーバーの拡張（任意）

- [ ] Gemini CLI にリモートサーバーを追加
- [ ] Copilot CLI にリモートサーバーを追加（対応状況を確認）

## クライアント別設定リファレンス

### Claude Code
- パス: `~/.claude.json`
- CLI: `claude mcp add --transport stdio --scope user <name> -- <command> [args...]`
- 環境変数: `${VAR:-default}`

### Claude Desktop
- パス: `~/Library/Application Support/Claude/claude_desktop_config.json`
- CLI: なし（ファイル直接編集）
- 環境変数展開: なし

### Codex CLI
- パス: `~/.codex/config.toml`（TOML）
- CLI: `codex mcp add <name> -- <command> [args...]`
- 固有機能: `enabled = false` で無効化、`enabled_tools`/`disabled_tools`

### Copilot CLI
- パス: `~/.copilot/mcp-config.json`
- CLI: `/mcp add`（対話モードのみ、自動化不向き）
- 環境変数: `${VAR}`
- 備考: `--additional-mcp-config @file.json` でセッション単位の追加も可能

### Gemini CLI
- パス: `~/.gemini/settings.json`
- CLI: `gemini mcp add --scope user <name> <command> -- [args...]`
- 環境変数: `$VAR`, `${VAR}`
- 固有機能: `trust: true`, `includeTools`/`excludeTools`

## 未解決事項

- [ ] `codex mcp add` が既存エントリを上書きするか、エラーになるか（べき等性）
- [ ] `gemini mcp add` の引数順序の正確な仕様（`--` の位置）
- [ ] Copilot CLI の `mcp-config.json` が他ツールと競合しないか
- [ ] リモートサーバーの OAuth フローが各クライアントでどう動くか
