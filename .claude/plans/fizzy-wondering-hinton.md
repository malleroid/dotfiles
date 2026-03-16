# dotfiles 管理ツール — 代替案分析結果

## 背景

現在の dotfiles は自作シェルスクリプト (`link.sh` + `setup.sh`) で管理。
今後 **mac×2 + Ubuntu + Arch + devcontainer + remote EC2** へ展開予定のため、
multi-OS 対応のツール・アーキテクチャへ移行を検討する。

管理対象は3層:
| 層 | 現状 | 規模 |
|---|---|---|
| 設定ファイル | `link.sh` (29 symlinks) | fish, nvim, git, claude, wezterm 等 |
| パッケージ | `Brewfile` (macOS 専用) | CLI ~80 + GUI cask ~50 |
| セットアップ | `setup.sh` | brew, mise, shell変更, fisher, gh ext, curl installs |

---

## 選択肢の概要

| # | 選択肢 | 概要 |
|---|--------|------|
| A | chezmoi 単体 | dotfiles + パッケージ管理を全て chezmoi の `run_once_`/`run_onchange_` スクリプトで。OS 別パッケージリストを手動同期 |
| B | chezmoi + Nix (pkg mgr) | dotfiles は chezmoi、CLI パッケージは Nix (`nix profile install`) で全 OS 統一。Nix 言語/Flakes 不要 |
| C | home-manager (Nix) 全統合 | パッケージも設定ファイルも全て Nix で宣言的管理。既存設定を Nix 形式に書き直す |
| D | chezmoi + Ansible | dotfiles は chezmoi、プロビジョニング (パッケージ + システム設定) は Ansible playbook |

---

## 比較表

| 評価軸 | 重み | A: chezmoi単体 | B: chezmoi+Nix | C: home-manager | D: chezmoi+Ansible | 備考 |
|--------|------|----------------|----------------|-----------------|-------------------|------|
| マルチOS対応 | **高** | ◎ | ◎ | ◎ | ◎ | 全方式とも chezmoi or Nix のテンプレートで OS 分岐可。設定ファイルレベルではほぼ同等 |
| パッケージリスト統一 | **高** | ✗ | ◎ | ◎ | △ | A: Brewfile/apt.txt/pacman.txt を手動同期 (名前差異: `fd`↔`fd-find` 等)。B/C: Nix パッケージ名は全 OS 同一。D: Ansible の `package` モジュールで抽象化可能だが名前差異は残る |
| ブートストラップ容易性 | **高** | ◎ | ○ | △ | △ | A: `curl \| sh` 1行で chezmoi 導入、依存ゼロ。B: chezmoi は即座、Nix は初回 ~数分。C: Nix 必須で skip 不可。D: Python + Ansible 必要 |
| 保守性 (長期) | **高** | △ | ◎ | ◎ | ○ | A: 3リスト同期が継続的負担。B: パッケージ追加は1箇所。C: 全て1箇所だが Nix デバッグの苦痛。D: 2ツール管理 |
| 学習コスト (初期) | 中 | ◎ | ○ | ✗ | △ | A: chezmoi のみ。B: chezmoi + `nix profile install` (コマンド1つ)。C: Nix 言語 + Flakes + nix-darwin。D: chezmoi + Ansible |
| 既存資産の活用 | 中 | ◎ | ◎ | ✗ | ◎ | C のみ fish/nvim/starship 等の設定を Nix 形式に全面書き直し。他は既存ファイルをそのまま流用 |
| シークレット管理 | 低 | ○ | ○ | ○ | ○ | A/B/D: chezmoi の 1Password/age 統合。C: sops-nix/agenix。全方式で対応可能 |
| 成熟度 | 中 | ◎ | ◎ | ◎ | ◎ | chezmoi: 18.5k stars, 週次リリース。Nix: 20年の歴史。Ansible: 60k+ stars。全て十分に成熟 |
| mise との共存 | 中 | ◎ | ◎ | △ | ◎ | C: Nix がランタイム管理も担う思想で mise と役割重複。他は自然に共存 |

---

## 各選択肢の詳細

### A: chezmoi 単体

```
dotfiles/
├── .chezmoi.toml.tmpl                        # 初回対話 (OS検出, ephemeral判定)
├── .chezmoiignore                            # 環境別ファイル除外 (テンプレート)
├── run_onchange_install-packages.sh.tmpl     # パッケージインストール
├── run_once_setup.sh.tmpl                    # 初期セットアップ
├── Brewfile                                  # macOS用
├── packages/
│   ├── apt.txt                               # Ubuntu用
│   └── pacman.txt                            # Arch用
└── dot_config/
    └── fish/, nvim/, ...
```

- **メリット**:
  - 単一ツールで完結。覚えることが最も少ない
  - devcontainer/EC2 での bootstrap が最速 (curl 1行、依存ゼロ)
  - `ephemeral` フラグで軽量/フルセットアップを分岐可
  - 既存 fish/nvim 設定をそのまま `chezmoi add` で取り込み
- **デメリット**:
  - **パッケージリスト3つの手動同期が最大の弱点**。80 CLI ツールの Brewfile ↔ apt.txt ↔ pacman.txt 同期が継続的負担
  - パッケージ名の OS 間差異 (`fd` vs `fd-find`, `bat` vs `batcat`) を自力で管理
  - OS が増えるたびにリスト追加。メンテ負荷は線形に増加
- **適するケース**: 対象 OS が少ない (2-3) か、パッケージ数が少ない場合

### B: chezmoi + Nix (パッケージマネージャとして)

```
dotfiles/
├── .chezmoi.toml.tmpl
├── run_once_before_install-nix.sh.tmpl       # Nix 自体のインストール
├── run_onchange_nix-packages.sh.tmpl         # nix profile で CLI パッケージ導入
├── Brewfile.casks                            # macOS GUI アプリだけ残す
└── dot_config/
    └── fish/, nvim/, ...
```

- **メリット**:
  - **CLI パッケージリストが1箇所** (`nix profile install nixpkgs#bat nixpkgs#fd ...`)。全 OS 同一名
  - 既存 dotfiles をそのまま活用。chezmoi がテンプレートで OS 分岐を担う
  - Nix 言語/Flakes の学習不要。`nix profile install` コマンドだけ
  - ephemeral 環境では Nix を skip して chezmoi の設定ファイルだけにフォールバック可
  - mise との役割分担が明確 (CLI ツール = Nix, 言語ランタイム = mise, GUI = Brewfile cask)
- **デメリット**:
  - Nix のディスク消費 (~数GB)。ephemeral 環境では skip が現実的
  - Nix の初回インストールに数分かかる
  - 2ツール管理 (ただし Nix 側は `nix profile install/remove` だけで単純)
  - Nix 自体のバージョンアップや breaking change のリスク (⚠️ `nix profile` は experimental feature)
- **適するケース**: multi-OS で CLI パッケージ数が多く、既存設定を活かしたい場合

### C: home-manager (Nix) 全統合

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [ bat eza fd ripgrep fzf starship fish neovim ... ];
  programs.fish = { enable = true; shellInit = ''...''; plugins = [ ... ]; };
  programs.starship = { enable = true; settings = { ... }; };
}
```

- **メリット**:
  - **究極の宣言的管理**。パッケージ + 設定 + サービスが単一ソースに
  - ロールバックが容易 (`home-manager generations`, `nix profile rollback`)
  - nix-darwin との組み合わせで macOS のシステム設定まで管理可
  - 環境の完全再現性が最も高い
- **デメリット**:
  - **学習コストが圧倒的に高い**。Nix 言語 + Flakes + nix-darwin + home-manager の概念理解
  - **既存の fish/nvim/starship 等の設定を Nix 形式に全面書き直し**。移行コスト大
  - Nix のエラーメッセージが難解。デバッグが苦痛
  - fish + Nix の環境変数橋渡しに `babelfish`/`foreign-env` が必要な場合あり
  - mise との役割重複 (Nix が言語ランタイムも管理する思想)
  - devcontainer/EC2 で Nix インストールが必須。skip できない
- **適するケース**: 環境の完全再現性を最優先し、Nix 習得に時間を投資できる場合

### D: chezmoi + Ansible

```
dotfiles/           ← chezmoi 管理 (設定ファイル)
ansible/
├── playbook.yml
├── inventory/
├── roles/
│   ├── packages/   ← OS 別パッケージ (package モジュールで抽象化)
│   ├── shell/      ← fish, starship
│   └── devtools/   ← mise, gh extensions
```

- **メリット**:
  - Ansible の `package` モジュールで OS 間パッケージ管理を一定程度抽象化
  - `ansible-pull` でリモートマシンのプロビジョニングも可能
  - role ベースで構成を再利用可能
  - Ansible は業務でのインフラ管理スキルとしても活きる
- **デメリット**:
  - **2ツール管理の煩雑さ**。chezmoi + Ansible それぞれの設定・更新が必要
  - Python 依存。devcontainer/EC2 で Python が入っている保証がない
  - 個人 dotfiles 管理としては heavyweight
  - パッケージ名の OS 間差異は Ansible でも完全には解消されない (変数マッピングが必要)
- **適するケース**: 業務でも Ansible を使っており、インフラプロビジョニングと統合したい場合

---

## 推奨: B — chezmoi + Nix (パッケージマネージャとして)

**根拠**:

1. **重み「高」の4軸で最もバランスが良い**
   - マルチOS対応: ◎ (chezmoi テンプレート)
   - パッケージリスト統一: ◎ (Nix で全 OS 同一)
   - ブートストラップ容易性: ○ (chezmoi のみなら ◎、Nix 込みでも実用的)
   - 保守性: ◎ (パッケージ追加は1箇所)

2. **方式 A との決定的な差**: CLI 80個 × 3 OS のパッケージリスト同期は現実的でない。Nix の導入コスト < 長期の同期コスト

3. **方式 C との決定的な差**: 既存 fish/nvim/starship 設定の書き直しが不要。学習コストが桁違いに低い

4. **方式 D との決定的な差**: Ansible は個人 dotfiles には over-engineering。Python 依存が ephemeral 環境でネックになる

**⚠️ 留意点**: `nix profile` は Nix の experimental feature。将来の API 変更リスクがある。ただし Nix コミュニティの方向性として `nix profile` は安定化に向かっている (出典: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile)

---

## ADR 用セクション（コピー可）

### コンテキスト

現在の dotfiles は macOS 単一環境向けの自作シェルスクリプト (`link.sh` による 29 symlinks + `setup.sh` による Homebrew ベースのセットアップ) で管理されている。
今後 mac×2, Ubuntu, Arch Linux, devcontainer, remote EC2 への展開が予定されており、以下の課題が顕在化する:

- `Brewfile` (CLI ~80 + GUI cask ~50) が macOS 専用で、Linux 向けの等価なパッケージリストが存在しない
- `setup.sh` が macOS のパスやパッケージマネージャにハードコードされている
- 設定ファイルに OS 固有の分岐メカニズムがない
- devcontainer/EC2 でのワンライナーブートストラップに対応していない

### 検討内容

**選択肢 A: chezmoi 単体**
- 概要: chezmoi の `run_once_`/`run_onchange_` スクリプトで dotfiles + パッケージ管理を全て行う。OS 別のパッケージリスト (Brewfile, apt.txt, pacman.txt) を手動同期
- メリット: 単一ツール、最小学習コスト、最速ブートストラップ
- デメリット: CLI 80個 × 3+ OS のパッケージリスト手動同期が継続的負担。OS 追加時に線形に増加

**選択肢 B: chezmoi + Nix (パッケージマネージャとして)**
- 概要: dotfiles は chezmoi、CLI パッケージは Nix (`nix profile install`) で全 OS 統一管理。Nix 言語の習得不要
- メリット: パッケージリスト1箇所、既存設定流用、mise との明確な役割分担
- デメリット: Nix のディスク消費 (~数GB)、`nix profile` は experimental feature

**選択肢 C: home-manager (Nix) 全統合**
- 概要: パッケージも設定ファイルも全て Nix で宣言的管理
- メリット: 究極の宣言的管理、完全再現性、ロールバック容易
- デメリット: Nix 言語習得が必須、既存設定の全面書き直し、デバッグ困難

**選択肢 D: chezmoi + Ansible**
- 概要: dotfiles は chezmoi、プロビジョニングは Ansible
- メリット: Ansible の OS 抽象化、業務スキル転用
- デメリット: 2ツール管理、Python 依存、個人用途には heavyweight

**比較表**:

| 評価軸 | 重み | A: chezmoi単体 | B: chezmoi+Nix | C: home-manager | D: chezmoi+Ansible |
|--------|------|----------------|----------------|-----------------|-------------------|
| マルチOS対応 | 高 | ◎ | ◎ | ◎ | ◎ |
| パッケージリスト統一 | 高 | ✗ | ◎ | ◎ | △ |
| ブートストラップ容易性 | 高 | ◎ | ○ | △ | △ |
| 保守性 (長期) | 高 | △ | ◎ | ◎ | ○ |
| 学習コスト (初期) | 中 | ◎ | ○ | ✗ | △ |
| 既存資産の活用 | 中 | ◎ | ◎ | ✗ | ◎ |
| シークレット管理 | 低 | ○ | ○ | ○ | ○ |
| 成熟度 | 中 | ◎ | ◎ | ◎ | ◎ |
| mise との共存 | 中 | ◎ | ◎ | △ | ◎ |

### 影響

**選択: B — chezmoi + Nix (パッケージマネージャとして)**

- **トレードオフ**: 2ツール管理 (chezmoi + Nix) を受け入れる代わりに、パッケージリストの統一管理を得る
- **リスク**: `nix profile` は experimental feature であり、将来の API 変更に追従が必要
- **アクションアイテム**:
  1. chezmoi 導入: `link.sh` の 29 symlinks を `chezmoi add` で取り込み
  2. `setup.sh` を chezmoi の `run_once_`/`run_onchange_` スクリプトに分解
  3. Nix をパッケージマネージャとして導入。Brewfile の CLI 部分を `nix profile install` に移行
  4. Brewfile を cask (macOS GUI アプリ) のみに縮小
  5. Ubuntu / Arch / devcontainer / EC2 での動作検証

---

## 付録: dotfiles 管理ツール単体比較

以下はアーキテクチャ方式の選定前に行った、個別ツールの比較調査。

### A1. 総合比較

| | chezmoi | GNU Stow | tuckr | yadm | dotbot | rcm | home-manager | dotter | toml-bombadil |
|---|---|---|---|---|---|---|---|---|---|
| **言語** | Go | Perl | Rust | Python/Shell | Python | Perl/Shell | Nix | Rust | Rust |
| **GitHub Stars** | ~18.5k | ~1k | ~435 | ~6.2k | ~7.8k | ~3.2k | ~9.5k | ~1.9k | ~325 |
| **最終リリース** | 2026-03 | 2024 | 2026-02 | 不明(タグ) | 2025-11 | 2022-12 | 継続的 | 2025-08 | 2025-04 |
| **ライセンス** | MIT | GPL-3.0 | GPL-3.0 | GPL-3.0 | MIT | BSD-3 | MIT | Unlicense | MIT |
| **brew install** | o | o | x (cargo) | o | 不要(submod) | o | nix経由 | x (cargo) | x (cargo) |

### A2. ファイル管理方式

| ツール | symlink | コピー | テンプレート展開 |
|---|:---:|:---:|:---:|
| chezmoi | 設定可能 | **default** | Go text/template |
| GNU Stow | **default** | - | - |
| tuckr | **default** | - | - |
| yadm | - | - | Jinja2 (外部依存) |
| dotbot | **default** | - | plugin |
| rcm | **default** | - | - |
| home-manager | Nix store経由 | build生成 | Nix言語 |
| dotter | 自動判定 | テンプレート時 | Handlebars |
| toml-bombadil | copy経由 | テンプレート時 | Tera (Jinja2互換) |

### A3. マルチマシン対応

| ツール | OS分岐 | ホスト分岐 | 方式 |
|---|:---:|:---:|---|
| chezmoi | o | o | テンプレート条件分岐 (`text/template`) |
| GNU Stow | - | - | なし (手動パッケージ選択) |
| tuckr | o | - | サフィックス (`_macos`, `_linux`) |
| yadm | o | o | alternate files (`##os.Darwin`) |
| dotbot | plugin | plugin | 外部プラグイン |
| rcm | tag | o | `tag-`/`host-` ディレクトリ |
| home-manager | o | o | Nix条件分岐 |
| dotter | o | o | `local.toml` でマシン固有変数 |
| toml-bombadil | o | o | プロファイル切り替え |

### A4. テンプレートエンジン

| ツール | エンジン | 変数展開 | 条件分岐 | ループ |
|---|---|:---:|:---:|:---:|
| chezmoi | Go `text/template` | o | o | o |
| GNU Stow | なし | - | - | - |
| tuckr | なし | - | - | - |
| yadm | Jinja2 (外部依存) | o | o | o |
| dotbot | なし | - | - | - |
| rcm | なし | - | - | - |
| home-manager | Nix言語 | o | o | o |
| dotter | Handlebars | o | o | o |
| toml-bombadil | Tera (Jinja2互換) | o | o | o |

### A5. シークレット管理

| ツール | 1Password | Bitwarden | age | GPG | git-crypt | その他 |
|---|:---:|:---:|:---:|:---:|:---:|---|
| chezmoi | o | o | o | o | - | gopass, pass, LastPass, Vault, KeePassXC, 任意コマンド |
| GNU Stow | - | - | - | - | - | なし |
| tuckr | - | - | - | - | - | 独自暗号化 (WIP) |
| yadm | - | - | - | o | o | OpenSSL, transcrypt |
| dotbot | - | - | plugin | - | plugin | |
| rcm | - | - | - | - | - | なし |
| home-manager | - | - | agenix | - | - | sops-nix |
| dotter | - | - | - | - | - | なし |
| toml-bombadil | - | - | - | o | - | |

### A6. スクリプト実行 (Hooks)

| ツール | Pre hooks | Post hooks | Run-once | 条件付き実行 |
|---|:---:|:---:|:---:|:---:|
| chezmoi | o | o | o | o (onchange) |
| GNU Stow | - | - | - | - |
| tuckr | o | o | - | - |
| yadm | o | o | - | bootstrap |
| dotbot | - | - | - | shell directive |
| rcm | o | o | - | - |
| home-manager | activation | activation | - | - |
| dotter | - | - | - | - |
| toml-bombadil | o | o | - | - |

### A7. 学習コスト

| ツール | 学習コスト | 設定の複雑さ | 備考 |
|---|:---:|:---:|---|
| chezmoi | 3/5 | 3/5 | 概念は独特だがドキュメント充実 |
| GNU Stow | 1/5 | 1/5 | 最シンプル。コマンド2つで完結 |
| tuckr | 1/5 | 2/5 | Stow知識があればほぼゼロコスト |
| yadm | 2/5 | 2/5 | Git知識がそのまま活きる |
| dotbot | 2/5 | 2/5 | YAML設定は直感的 |
| rcm | 2/5 | 2/5 | Unix的で覚えやすい |
| home-manager | 5/5 | 5/5 | Nix言語の習得が大前提 |
| dotter | 2/5 | 2/5 | TOML + Handlebars |
| toml-bombadil | 2/5 | 3/5 | プロファイル概念の理解が必要 |

---

*調査日: 2026-03-15 / GitHub Stars は概算値*
*出典: 各ツールの公式 GitHub リポジトリ・ドキュメント (URL は本文中に記載)*
