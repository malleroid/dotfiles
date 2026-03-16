# chezmoi + Nix 移行計画

## Context

現在の dotfiles は `link.sh` (29 symlinks) + `setup.sh` (macOS専用) + `Brewfile` (CLI 97 + cask 52) で管理。
**mac×2 + Ubuntu + Arch + devcontainer + EC2** への展開に向け、chezmoi (dotfiles) + Nix (CLIパッケージ) に移行する。

**ゴール**: `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply malleroid/dotfiles` 1行で全環境をセットアップ可能にする。

---

## Phase 0: 準備

### 0-1. ツールインストール
- `brew install chezmoi`

### 0-2. ブランチ作成
- `git checkout -b feature/chezmoi-nix-migration`

### 0-3. 現状スナップショットの保存
- 現在のsymlink状態を `docs/pre-migration-snapshot.txt` に記録

### 検証
- 既存の `link.sh` / `setup.sh` が正常に動作すること

---

## Phase 1: chezmoi スキャフォールド作成

既存ファイルはまだリネームしない。chezmoi の骨格だけ作る。

### 1-1. `.chezmoi.toml.tmpl` 作成

```toml
{{- $env_type := promptStringOnce . "env_type" "Environment type (full/ephemeral)" "full" -}}

[data]
  env_type = {{ $env_type | quote }}
  is_ephemeral = {{ eq $env_type "ephemeral" }}

[edit]
  command = "nvim"
```

### 1-2. `.chezmoiignore` 作成

```
# リポジトリ専用ファイル (デプロイしない)
README.md
Brewfile.casks
nix-packages.txt
.editorconfig
link.sh
setup.sh
Brewfile
docs/**
mcp/**
.ruby-lsp/**
.claude/plans/**
.claude/docs/**
.claude/settings.local.json
.claude/setup.fish
.claude/skills/**

# Fisher/自動生成 (各ツールが管理)
.config/fish/completions/**
.config/fish/conf.d/**
.config/fish/functions/**
.config/fish/themes/**
.config/fish/fish_variables

# Ephemeral 環境で除外
{{ if .is_ephemeral }}
.config/nvim/**
.config/wezterm/**
.config/gitui/**
.config/serpl/**
.config/rails-mcp/**
.copilot/**
.codex/**
.agents/**
{{ end }}
```

### 1-3. `nix-packages.txt` 作成 (空ファイル、Phase 3 で中身を入れる)

### 1-4. `Brewfile.casks` 作成
- 現 `Brewfile` から `cask` 行だけ抽出

### 1-5. 参照ファイルを `docs/` へ移動
- `netrc/.netrc.example` → `docs/netrc.example`
- `jiratui/config.yaml.example` → `docs/jiratui-config.yaml.example`

### 検証
- `chezmoi init --source . --dry-run` がエラーなく通ること
- 既存の `link.sh` はまだ動作すること

---

## Phase 2: ファイルリネーム (chezmoi 命名規約へ)

**これが最大の変更。** `git mv` で既存ファイルを chezmoi の命名規約にリネームする。

### 2-1. リネームマッピング

#### ホームディレクトリ直下

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `.gitconfig` | `dot_gitconfig` | |
| `.gitignore` | `dot_gitignore` | リポジトリ用 `.gitignore` とは分離 |
| `.commit_template` | `dot_commit_template` | |

#### ~/.config/* → `dot_config/`

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `fish/` | `dot_config/fish/` | |
| `fish/config.fish` | `dot_config/fish/config.fish.tmpl` | **テンプレート化** |
| `fish/fish_plugins` | `dot_config/fish/fish_plugins` | |
| `fish/custom_conf.d/abbreviations.fish` | `dot_config/fish/custom_conf.d/abbreviations.fish.tmpl` | **テンプレート化** |
| `fish/custom_conf.d/colors.fish` | `dot_config/fish/custom_conf.d/colors.fish` | |
| `fish/custom_conf.d/ssh_agent.fish` | `dot_config/fish/custom_conf.d/ssh_agent.fish.tmpl` | **テンプレート化** |
| `fish/custom_functions/*` | `dot_config/fish/custom_functions/*` | |
| `fish/.gitignore` | `dot_config/fish/dot_gitignore` | |
| `fish/conf.d/*` | (管理対象外) | Fisher 生成。`.chezmoiignore` で除外済 |
| `mise/` | `dot_config/mise/` | |
| `nvim/` | `dot_config/nvim/` | ツリーごと |
| `starship.toml` | `dot_config/starship.toml` | |
| `wezterm/` | `dot_config/wezterm/` | |
| `gitui/` | `dot_config/gitui/` | |
| `serpl/` | `dot_config/serpl/` | |
| `rails-mcp/projects.yml` | `dot_config/rails-mcp/projects.yml` | |

#### ~/.claude/* → `dot_claude/`

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `.claude/CLAUDE.md` | `dot_claude/CLAUDE.md` | |
| `.claude/settings.json` | `dot_claude/settings.json` | |
| `.claude/agents/` | `dot_claude/agents/` | ツリーごと |
| `.claude/hooks/*.sh` | `dot_claude/hooks/executable_*.sh` | 各ファイルに `executable_` prefix |
| (新規) | `dot_claude/symlink_skills.tmpl` | `~/.agents/skills` への symlink |

#### ~/.agents/* → `dot_agents/`

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `.agents/skills/` | `dot_agents/skills/` | ツリーごと |

#### ~/.copilot/* → `dot_copilot/`

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `copilot/mcp-config.json` | `dot_copilot/mcp-config.json` | |

#### ~/.codex/* → `dot_codex/`

| 現在 | chezmoi名 | 備考 |
|---|---|---|
| `codex/config.toml` | `dot_codex/create_config.toml` | **`create_` prefix**: 既存ファイルを上書きしない |
| `codex/AGENTS.md` | `dot_codex/AGENTS.md` | |

### 2-2. `.gitignore` の分離

現在の `.gitignore` はリポジトリ用とデプロイ用が兼用。分離する:

- **リポジトリ用** `.gitignore` (新内容):
  ```
  **/.claude/settings.local.json
  .serena/
  .chezmoi.toml
  ```

- **デプロイ用** `dot_gitignore` (= `~/.gitignore`):
  ```
  **/.claude/settings.local.json
  .serena/
  ```

### 2-3. symlink ファイル作成

`dot_claude/symlink_skills.tmpl`:
```
{{ .chezmoi.homeDir }}/.agents/skills
```

### 2-4. テンプレート化 (3ファイル)

#### `dot_config/fish/config.fish.tmpl`

L50-62 の `if test (uname) = "Darwin"` ブロックを置換:
```fish
{{ if eq .chezmoi.os "darwin" -}}
  # add homebrew path (append to avoid overriding mise)
  fish_add_path --append /opt/homebrew/bin
  fish_add_path --append /opt/homebrew/sbin
{{ end -}}
```

#### `dot_config/fish/custom_conf.d/abbreviations.fish.tmpl`

L104-106 を置換:
```fish
{{ if eq .chezmoi.os "darwin" -}}
# oath-toolkit
abbr -a awsmfa 'oathtool --totp --base32 $(security find-generic-password -a $USER -s oath-toolkit-aws-mfa -w) | pbcopy'
{{ end -}}
```

L112-116 を置換:
```fish
{{ if eq .chezmoi.os "darwin" -}}
abbr -a reload 'exec /opt/homebrew/bin/fish -l'
{{ else -}}
abbr -a reload 'exec fish -l'
{{ end -}}
```

#### `dot_config/fish/custom_conf.d/ssh_agent.fish.tmpl`

L10-12 を置換:
```fish
  {{ if eq .chezmoi.os "darwin" -}}
  ssh-add --apple-load-keychain
  {{ end -}}
```

### 検証
```
chezmoi init --source . --dry-run
chezmoi diff                    # 現在のホームとの差分確認
chezmoi apply --dry-run -v      # 適用プレビュー
```
全ターゲットパスが link.sh のものと一致すること。

---

## Phase 3: Nix パッケージリスト作成

### 3-1. Brewfile CLI ツールの nixpkgs 名を検証

各ツールに対して `nix search nixpkgs#<name>` で存在確認。

**名前が異なるもの (既知)**:
| Brewfile 名 | nixpkgs 名 |
|---|---|
| `awscli` | `awscli2` |
| `git-delta` | `delta` |
| `gnu-sed` | `gnused` |
| `grep` | `gnugrep` |
| `spotify_player` | `spotify-player` |

### 3-2. 分類

- **nixpkgs にある**: → `nix-packages.txt` に記載
- **nixpkgs にない**: → `Brewfile.cli-fallback` (macOS のみ) or 個別 `run_once_` スクリプト
- **macOS GUI 専用**: → `Brewfile.casks` (既に Phase 1 で作成済)

### 3-3. `nix-packages.txt` を完成させる

1行1パッケージ。`#` でコメント可。

### 検証
```
nix profile install nixpkgs#bat  # 1つ試す
which bat
bat --version
```

---

## Phase 4: run スクリプト作成

`setup.sh` の各ステップを chezmoi run スクリプトに分解する。
全スクリプトは bash (fish 未インストールの可能性があるため)。

### 実行順序と naming convention

| ファイル名 | トリガー | 内容 |
|---|---|---|
| `run_once_before_01-install-nix.sh.tmpl` | 初回のみ | Nix インストール (ephemeral skip) |
| `run_once_before_02-install-homebrew.sh.tmpl` | 初回のみ | Homebrew インストール (macOS のみ) |
| `run_onchange_after_10-nix-packages.sh.tmpl` | `nix-packages.txt` 変更時 | `nix profile install` |
| `run_onchange_after_11-brew-casks.sh.tmpl` | `Brewfile.casks` 変更時 | `brew bundle` (macOS のみ) |
| `run_once_after_20-mise-install.sh.tmpl` | 初回のみ | `mise install` |
| `run_once_after_21-change-shell.sh.tmpl` | 初回のみ | fish を default shell に (ephemeral skip) |
| `run_once_after_22-fisher-bootstrap.sh.tmpl` | 初回のみ | Fisher + plugins (ephemeral skip) |
| `run_once_after_23-gh-extensions.sh.tmpl` | 初回のみ | gh-dash, gh-poi |
| `run_once_after_24-native-tools.sh.tmpl` | 初回のみ | ollama, claude, opencode (curl) |

### スクリプト設計のポイント

- 全スクリプト冒頭で `{{ if .is_ephemeral }}exit 0{{ end }}` ガード (該当するもの)
- OS 分岐は `{{ if eq .chezmoi.os "darwin" }}` / `{{ if eq .chezmoi.os "linux" }}`
- 冪等性: `command -v <tool> >/dev/null && exit 0` で既インストール時 skip
- `run_onchange_` のトリガー: `# hash: {{ include "nix-packages.txt" | sha256sum }}`

### `run_onchange_after_10-nix-packages.sh.tmpl` の構造

```bash
#!/bin/bash
{{ if .is_ephemeral -}}
exit 0
{{ end -}}

# nix-packages.txt hash: {{ include "nix-packages.txt" | sha256sum }}

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix not installed, skipping"
  exit 0
fi

while IFS= read -r pkg; do
  [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
  nix profile install "nixpkgs#$pkg" 2>/dev/null || echo "WARN: $pkg not found"
done < {{ joinPath .chezmoi.sourceDir "nix-packages.txt" | quote }}
```

### 検証
```
chezmoi execute-template < run_once_before_01-install-nix.sh.tmpl  # テンプレート展開確認
chezmoi apply --dry-run -v  # スクリプト実行順序の確認
```

---

## Phase 5: プライマリマシンで統合テスト

### 5-1. 既存 symlink の除去
- `link.sh` が作った symlink を全て `rm` (ファイル実体は dotfiles repo にある)

### 5-2. codex 特殊対応
- `~/.codex/config.toml` が symlink → 実ファイルにコピー (machine-specific `[projects]` を保持)
  ```
  cp -L ~/.codex/config.toml ~/.codex/config.toml.bak
  rm ~/.codex/config.toml
  mv ~/.codex/config.toml.bak ~/.codex/config.toml
  ```

### 5-3. chezmoi apply
```
chezmoi init --source . --apply
```

### 5-4. 検証チェックリスト

| 確認項目 | コマンド |
|---|---|
| fish 起動 | `fish` (エラーなし) |
| starship プロンプト | 目視確認 |
| abbreviations | `abbr -s` (全定義存在) |
| ssh-agent (macOS) | `ssh-add -l` |
| git delta pager | `git log` (delta で表示) |
| nvim プラグイン | `nvim` → `:Lazy` |
| wezterm 設定 | wezterm 再起動 |
| claude skills symlink | `ls -la ~/.claude/skills` → `~/.agents/skills` |
| codex config | `cat ~/.codex/config.toml` → `[projects]` セクション保持 |
| chezmoi diff | `chezmoi diff` → 差分なし |
| chezmoi verify | `chezmoi verify` → exit 0 |

---

## Phase 6: セカンダリマシン / Linux テスト

### 6-1. macOS 2台目
```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply malleroid/dotfiles
```
- `env_type` → "full"
- 全パッケージ + 設定が入ること

### 6-2. Ubuntu / Arch (VM or コンテナ)
```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply malleroid/dotfiles
```
- Nix で CLI パッケージが入ること
- Homebrew / cask ステップが skip されること
- fish テンプレートが Linux 向けに展開されること

### 6-3. devcontainer (ephemeral)
- `postCreateCommand` に設定:
  ```
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --data='{"env_type":"ephemeral"}' malleroid/dotfiles
  ```
- Nix / Homebrew が skip されること
- 設定ファイルのみデプロイされること
- nvim/wezterm/gitui 等が除外されること

---

## Phase 7: クリーンアップ

### 削除対象
| ファイル | 理由 |
|---|---|
| `link.sh` | chezmoi に置換 |
| `setup.sh` | run スクリプトに置換 |
| `Brewfile` | `Brewfile.casks` + `nix-packages.txt` に分割 |
| `netrc/` | `docs/` に移動済 |
| `jiratui/` | `docs/` に移動済 (example) |
| `jira-cli/` | `docs/` に移動済 (example) |
| `raycast/` | `docs/` に移動済 |
| `fish/conf.d/` | Fisher 生成ファイル。chezmoi 管理外 |

### README.md 更新
```markdown
## Setup
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply malleroid/dotfiles
```

### master にマージ

---

## ディレクトリ構造 (最終形)

```
dotfiles/
├── .chezmoi.toml.tmpl
├── .chezmoiignore
├── .gitignore
├── README.md
├── Brewfile.casks                              # macOS GUI アプリ
├── nix-packages.txt                            # CLI ツール (全OS共通)
│
├── dot_gitconfig
├── dot_gitignore
├── dot_commit_template
│
├── dot_config/
│   ├── starship.toml
│   ├── fish/
│   │   ├── config.fish.tmpl                    # テンプレート
│   │   ├── fish_plugins
│   │   ├── dot_gitignore
│   │   ├── custom_conf.d/
│   │   │   ├── abbreviations.fish.tmpl         # テンプレート
│   │   │   ├── colors.fish
│   │   │   └── ssh_agent.fish.tmpl             # テンプレート
│   │   └── custom_functions/
│   │       ├── cf-terraforming.fish
│   │       ├── jira-batch-create.fish
│   │       ├── jira-create.fish
│   │       └── mlx-transcribe.fish
│   ├── mise/
│   │   └── config.toml
│   ├── nvim/                                   # ツリーごと
│   ├── wezterm/
│   ├── gitui/
│   ├── serpl/
│   └── rails-mcp/
│       └── projects.yml
│
├── dot_claude/
│   ├── CLAUDE.md
│   ├── settings.json
│   ├── agents/                                 # 6 sub-agents
│   ├── hooks/
│   │   ├── executable_guard_force_push.sh
│   │   ├── executable_guard_project_dir.sh
│   │   ├── executable_guard_secrets.sh
│   │   └── executable_notify.sh
│   └── symlink_skills.tmpl                     # → ~/.agents/skills
│
├── dot_agents/
│   └── skills/                                 # 9 skills ツリーごと
│
├── dot_copilot/
│   └── mcp-config.json
│
├── dot_codex/
│   ├── create_config.toml                      # create_ prefix (上書きしない)
│   └── AGENTS.md
│
├── run_once_before_01-install-nix.sh.tmpl
├── run_once_before_02-install-homebrew.sh.tmpl
├── run_onchange_after_10-nix-packages.sh.tmpl
├── run_onchange_after_11-brew-casks.sh.tmpl
├── run_once_after_20-mise-install.sh.tmpl
├── run_once_after_21-change-shell.sh.tmpl
├── run_once_after_22-fisher-bootstrap.sh.tmpl
├── run_once_after_23-gh-extensions.sh.tmpl
├── run_once_after_24-native-tools.sh.tmpl
│
├── docs/
│   ├── netrc.example
│   ├── jiratui-config.yaml.example
│   └── pre-migration-snapshot.txt
│
└── mcp/                                        # run スクリプトから参照
    ├── servers.json
    ├── remote-servers.json
    └── setup.fish
```

---

## テンプレート化対象ファイル一覧

| ファイル | テンプレート箇所 | 現在の行 |
|---|---|---|
| `fish/config.fish` | Darwin: homebrew PATH | L50-62 |
| `fish/custom_conf.d/abbreviations.fish` | Darwin: awsmfa (Keychain) | L104-106 |
| `fish/custom_conf.d/abbreviations.fish` | Darwin vs Linux: reload パス | L112-116 |
| `fish/custom_conf.d/ssh_agent.fish` | Darwin: apple-load-keychain | L10-12 |

---

## 重要な設計判断

| 判断 | 理由 |
|---|---|
| `dot_config/` (not `private_dot_config/`) | `~/.config` を 0700 にすると他ツールに影響する可能性 |
| `fish/conf.d/` は管理しない | Fisher 生成ファイル。chezmoi と競合する |
| `codex/config.toml` は `create_` prefix | machine-specific `[projects]` を保持するため |
| `.claude/skills` は symlink | `.agents/skills` と同一実体を参照 |
| `nix-packages.txt` は plain text | Nix 言語不要。`run_onchange_` が hash で変更検知 |
| ephemeral は Nix skip | devcontainer/EC2 でのディスク消費とセットアップ時間を回避 |

---

## 既知のリスクと対策

| リスク | 対策 |
|---|---|
| `nix profile` は experimental feature | Determinate Systems installer を使用。安定化の方向に向かっている |
| nixpkgs にないツール | `Brewfile.cli-fallback` (macOS) or 個別インストールスクリプト |
| chezmoi と Fisher のファイル競合 | `.chezmoiignore` で `conf.d/`, `functions/`, `completions/` を除外 |
| `.gitignore` の二重用途 | リポジトリ用とデプロイ用を分離 |
| 既存マシンの codex `[projects]` 喪失 | Phase 5-2 で symlink → 実ファイルに変換してから apply |

---

*作成日: 2026-03-16*
