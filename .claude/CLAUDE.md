# \~/.claude/CLAUDE.md

## Security & Compliance 🛡️

### 🚫 Commit 禁止パターン

- `*.pem`
- `*.key`
- `*.env` / `.env.*`
- `config/credentials.yml.enc`
- `*secrets*`
- `*.p12`
- `id_rsa*` / `id_ed25519*`

> Claude はこれらに一致するファイルを **生成・追加・表示・共有しないこと**。

### ⛔ シェル操作の範囲制限

- Claude が実行するシェルコマンドは **現在の作業ディレクトリ（= このリポジトリ）内** に限定すること。
- リポジトリ外のファイル・ディレクトリを作成／変更／削除／移動する操作は禁止。
- `curl` / `wget` など外部リクエストを発行するコマンドは事前確認なしに実行しない。

### その他原則

1. 社外秘コード・個人情報を含むファイルは公開リポジトリへ push しない。
2. 会社／OSS／副業などの区分に応じた追加ルールは各リポジトリの CLAUDE.md で定義する。

---

## Shell & Environment 🐟

- すべての端末で **fish shell 5.x** を使用。
- dotfiles により `fish_add_path` 等を設定済み。Claude は fish 前提でコマンドを提示する。

---

## Code Style (Placeholder) ✏️

<!-- 後日、共通スタイルを追加する場合に使用 -->

---

## AI Workflow 🤖

### コードレビュー

コードレビューを行う場合は `code-reviewer` sub-agent を使うこと。レビュー基準・出力フォーマットの詳細はそちらに定義されている。
親コンテキストで差分取得（git fetch/diff, gh pr diff等）を行わず、ユーザーの指示をそのまま sub-agent に委譲すること。

---

## Repository-Specific Overrides (例示) 📝

```markdown
## If repo includes "github.com/your-company/"

# - default branch: main

# - branch naming: feature/JIRA-123-description

# - CI: GitHub Actions, secrets via OIDC
```

---

## Plan Mode

- プランファイルは `$HOME/.claude/plans/` ではなく、現在の作業ディレクトリの `.claude/plans/` に保存すること。
- 保存先例: `{作業ディレクトリ}/.claude/plans/{plan-name}.md`

---

## Context7 MCP

- ライブラリ固有の API を使うコード生成・実装時は Context7 を積極的に使うこと
- 特に更新頻度の高いライブラリ（Next.js, React, Cloudflare Workers 等）では API シグネチャ確認に優先的に使うこと
- 汎用的なプログラミング質問（アルゴリズム、設計パターン等）では使わないこと
- レート制限があるため、同一ライブラリへの重複呼び出しは避けること

---

## メンテナンス指針

- dotfiles 更新時にこのファイルも点検し、不要行を削除・新規禁止パターンを追加。
- ファイルサイズは **50 KB 未満** を目安に維持。大きくなる場合は各リポジトリ側へ移動。
