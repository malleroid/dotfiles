# Neovim 設定 現状監査

> 監査日: 2026-03-22
> Neovim: v0.11.6 / プラグインマネージャ: lazy.nvim / カラースキーム: tokyonight-night

## 構成

```
dot_config/nvim/
├── init.lua              # options → lazy の順で読み込み
├── lazy-lock.json        # 19 プラグインのロックファイル
└── lua/
    ├── config/
    │   ├── lazy.lua      # lazy.nvim bootstrap + setup
    │   └── options.lua   # エディタ基本設定 (termguicolors, number, indent, clipboard 等)
    └── plugins/
        ├── autopairs.lua   # nvim-autopairs (blink.cmp 連携)
        ├── blink-cmp.lua   # 補完 (blink.cmp + friendly-snippets)
        ├── colorscheme.lua # tokyonight
        ├── comment.lua     # Comment.nvim + ts-context-commentstring
        ├── gitsigns.lua    # Git 差分表示・hunk 操作
        ├── lsp.lua         # nvim-lspconfig (11 サーバー)
        ├── lualine.lua     # ステータスライン
        ├── neo-tree.lua    # ファイルエクスプローラ
        ├── telescope.lua   # ファジーファインダー
        ├── treesitter.lua  # シンタックスハイライト + context
        ├── which-key.lua   # キーマップヘルプ
        └── yazi.lua        # yazi ファイルマネージャ連携
```

## プラグイン一覧 (20個)

| カテゴリ | プラグイン | 用途 |
|---------|----------|------|
| UI | tokyonight.nvim | カラースキーム |
| UI | lualine.nvim | ステータスライン |
| UI | nvim-web-devicons | アイコン |
| UI | which-key.nvim | キーマップガイド |
| ファイル操作 | neo-tree.nvim (+ nui.nvim, plenary.nvim) | ファイルツリー |
| ファイル操作 | yazi.nvim | yazi ファイルマネージャ連携 |
| 検索 | telescope.nvim (+ plenary.nvim) | ファジーファインダー |
| LSP | nvim-lspconfig | LSP クライアント設定 |
| 補完 | blink.cmp + friendly-snippets | 自動補完・スニペット |
| 編集支援 | nvim-autopairs | 括弧自動補完 |
| 編集支援 | Comment.nvim + nvim-ts-context-commentstring | コメントトグル |
| Git | gitsigns.nvim | Git 差分・hunk 操作 |
| Treesitter | nvim-treesitter + nvim-treesitter-context | 構文解析・ハイライト |

## 設定されている LSP サーバー

copilot, vtsls, pyright, rust_analyzer, gopls, lua_ls, ruby_lsp, html, cssls, jsonls, terraformls

## キーマップ (主要)

| キー | 機能 | 定義元 |
|------|------|--------|
| `<Space>ff` | ファイル検索 | telescope.lua |
| `<Space>fg` | live grep | telescope.lua |
| `<Space>fb` | バッファ一覧 | telescope.lua |
| `<Space>fh` | ヘルプタグ | telescope.lua |
| `<Space>-` | yazi (現在のファイル) | yazi.lua |
| `<Space>cw` | yazi (作業ディレクトリ) | yazi.lua |
| `Ctrl+Up` | yazi セッション再開 | yazi.lua |
| `<Space>e` | Neo-tree トグル | neo-tree.lua |
| `<Space>gs` | Git status (Neo-tree) | neo-tree.lua |
| `<Space>bf` | Buffers (Neo-tree) | neo-tree.lua |
| `gd` | 定義へジャンプ | lsp.lua |
| `gi` | 実装へジャンプ | lsp.lua |
| `gr` | 参照一覧 | lsp.lua |
| `K` | ホバードキュメント | lsp.lua |
| `<Space>ca` | コードアクション | lsp.lua |
| `<Space>rn` | リネーム | lsp.lua |
| `<Space>f` | フォーマット | lsp.lua |
| `<Space>hs` | Stage hunk | gitsigns.lua |
| `<Space>hr` | Reset hunk | gitsigns.lua |
| `<Space>hS` | Stage buffer | gitsigns.lua |
| `<Space>hu` | Undo stage hunk | gitsigns.lua |
| `<Space>hR` | Reset buffer | gitsigns.lua |
| `<Space>hp` | Preview hunk | gitsigns.lua |
| `<Space>hb` | Blame line | gitsigns.lua |
| `<Space>hd` | Diff this | gitsigns.lua |
| `]c` / `[c` | 次/前の hunk | gitsigns.lua |
| `gcc` | 行コメントトグル | comment.lua |
| `gbc` | ブロックコメントトグル | comment.lua |
| `gc` (visual) | 選択範囲コメント | comment.lua |
| `<C-Space>` | Treesitter 選択開始/拡大 | treesitter.lua |
| `<BS>` | Treesitter 選択縮小 | treesitter.lua |

## 気になる点・改善候補

### 1. keymaps.lua が無い → ファイル作成済み、中身は未実装
`config/keymaps.lua` を作成し `init.lua` から読み込む構成にした。
以下の候補から必要なものを追加していく。

**ウィンドウ移動** (現状 `Ctrl+W` → `h/j/k/l` の2ストローク):

| キー | 操作 | 注意 |
|---|---|---|
| `Ctrl+H/J/K/L` | ウィンドウ間フォーカス移動 | Zellij `Cmd+H/J/K/L` との競合確認が必要 |

**バッファ切替** (現状コマンドか Telescope のみ):

| キー | 操作 |
|---|---|
| `Shift+H` / `Shift+L` | 前/次のバッファ |

**便利系**:

| キー | 操作 |
|---|---|
| `<Space>w` | 保存 (`:w`) |
| `<Space>q` | 閉じる (`:q`) |
| `Esc` (Normal) | 検索ハイライト解除 (`:noh`) |

**Visual モード操作**:

| キー | 操作 |
|---|---|
| `J` / `K` (Visual) | 選択行を上下に移動 |
| `<` / `>` (Visual) | インデント後も選択維持 |

### 2. ~~autopairs の blink.cmp 連携が壊れている可能性~~ → 解決済み
blink.cmp 連携コードを削除、blink.cmp 依存も除去。
補完時の括弧挿入は blink.cmp の `auto_brackets` が担当。

### 3. フォーマッタ / リンター不在
LSP の `buf.format` のみ。LSP がフォーマットをサポートしない言語 (Markdown, Shell 等) には
conform.nvim (フォーマッタ) や nvim-lint (リンター) の導入を検討。

### 4. デバッガ不在
nvim-dap 系プラグインが無い。デバッグが必要なら nvim-dap + nvim-dap-ui を検討。

### 5. Telescope に fzf-native 未導入
telescope-fzf-native.nvim を追加すると、大規模プロジェクトでの検索速度が改善する。

### 6. ウィンドウ / バッファ操作のキーマップ不足
`<C-h/j/k/l>` でウィンドウ移動、`<S-h/l>` でバッファ切替など、
基本的なナビゲーションキーマップが未設定。

### 7. ~~nvim-lspconfig が実質未使用の可能性~~ → 検証済み、必要
Neovim 0.11 以降の nvim-lspconfig は「データリポジトリ」として機能する。
`vim.lsp.enable("vtsls")` 等を呼ぶ際、nvim-lspconfig の `lsp/` ディレクトリにある
各サーバーのデフォルト設定 (cmd, filetypes, root_markers 等) が自動でマージされる。
外すと 11 サーバー分のボイラープレートを自分で書く必要があるため、外せない。
現在の使い方 (vim.lsp.config + vim.lsp.enable) は 0.11 の推奨パターンで正しい。

### 8. Comment.nvim が Neovim 組み込み機能と重複
Neovim 0.10 以降、`gcc` / `gc` によるコメントトグルが組み込みで提供されている。
Comment.nvim が必要なのは `ts-context-commentstring` 連携
(TSX/JSX 等でコメント形式を自動切替) のため。
TSX/JSX を扱わないなら外して組み込み機能に任せられる。
