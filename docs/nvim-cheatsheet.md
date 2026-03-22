# Neovim チートシート

> カスタム設定反映済み (Leader=Space, tokyonight-night, lazy.nvim, blink.cmp, Neovim v0.11.6)

## 基本操作

### モード

| キー | モード | 用途 |
|---|---|---|
| `i` | Insert | テキスト入力 |
| `v` | Visual | 文字単位の選択 |
| `V` | Visual Line | 行単位の選択 |
| `Ctrl+V` | Visual Block | 矩形選択 |
| `Esc` | Normal | コマンド待ち受け |
| `:` | Command | コマンドライン |

---

## ファイル・バッファ操作

### Telescope (`<Space>f`)

| キー | 操作 |
|---|---|
| `<Space>ff` | ファイル検索 |
| `<Space>fg` | テキスト検索 (live grep) |
| `<Space>fb` | 開いているバッファ一覧 |
| `<Space>fh` | ヘルプタグ検索 |

#### Telescope 内の操作

| キー | 操作 |
|---|---|
| `Ctrl+J` | 次の候補 |
| `Ctrl+K` | 前の候補 |
| `Ctrl+Q` | クイックフィックスリストに送る |
| `Esc` | 閉じる |
| `Enter` | 選択して開く |

### Neo-tree

| キー | 操作 |
|---|---|
| `<Space>e` | ファイルツリー表示/非表示 |
| `<Space>gs` | Git ステータスビュー |
| `<Space>bf` | バッファビュー |

---

## LSP (コード操作)

### ジャンプ・参照

| キー | 操作 |
|---|---|
| `gd` | 定義へジャンプ |
| `gi` | 実装へジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバードキュメント (カーソル上の情報表示) |

### リファクタ

| キー | 操作 |
|---|---|
| `<Space>rn` | シンボルのリネーム |
| `<Space>ca` | コードアクション |
| `<Space>f` | フォーマット (非同期) |

### 設定済み LSP サーバー

copilot, vtsls (TS/JS), pyright, rust_analyzer, gopls, lua_ls, ruby_lsp, html, cssls, jsonls, terraformls

---

## 補完 (blink.cmp)

| キー | 操作 |
|---|---|
| `Ctrl+Space` | 補完メニュー表示 / ドキュメント表示切替 |
| `Ctrl+N` | 次の候補 |
| `Ctrl+P` | 前の候補 |
| `Enter` | 確定 |
| `Ctrl+E` | 補完を閉じる |
| `Tab` | スニペットの次のプレースホルダへ |
| `Shift+Tab` | スニペットの前のプレースホルダへ |

> 関数/メソッド補完時は括弧が自動挿入される (`auto_brackets`)
> ドキュメントは 200ms 後に自動表示

---

## Git 操作 (gitsigns)

### Hunk ナビゲーション

| キー | 操作 |
|---|---|
| `]c` | 次の変更箇所 (hunk) へ |
| `[c` | 前の変更箇所 (hunk) へ |

### Hunk 操作 (`<Space>h`)

| キー | 操作 |
|---|---|
| `<Space>hs` | 変更箇所をステージ |
| `<Space>hr` | 変更箇所をリセット (元に戻す) |
| `<Space>hS` | ファイル全体をステージ |
| `<Space>hu` | ステージを取り消し |
| `<Space>hR` | ファイル全体をリセット |
| `<Space>hp` | 変更箇所のプレビュー |
| `<Space>hb` | 行の blame 表示 |
| `<Space>hd` | 差分表示 (diffthis) |

---

## コメント (Comment.nvim)

### Normal モード

| キー | 操作 |
|---|---|
| `gcc` | 行コメントをトグル |
| `gbc` | ブロックコメントをトグル |
| `gcO` | 上の行にコメント追加 |
| `gco` | 下の行にコメント追加 |
| `gcA` | 行末にコメント追加 |

### Visual モード

| キー | 操作 |
|---|---|
| `gc` | 選択範囲を行コメントでトグル |
| `gb` | 選択範囲をブロックコメントでトグル |

> TSX/JSX 等では treesitter コンテキストに応じたコメント形式を自動選択

---

## Treesitter

### 選択の拡大・縮小

| キー | 操作 |
|---|---|
| `Ctrl+Space` | 選択開始 / 選択範囲を構文単位で拡大 |
| `Backspace` | 選択範囲を構文単位で縮小 |

> 画面上部に現在の関数/クラス名がコンテキスト表示される (treesitter-context, 最大3行)

---

## which-key

| キー | 操作 |
|---|---|
| `<Space>` を押して 200ms 待つ | 使えるキーマップの一覧表示 |

### 登録済みグループ

| プレフィクス | グループ名 |
|---|---|
| `<Space>f` | Find (検索) |
| `<Space>g` | Git |
| `<Space>h` | Hunk (Git 変更箇所) |
| `<Space>c` | Code |
| `<Space>r` | Refactor |
| `g` | Goto / Comment |

---

## プラグイン管理 (lazy.nvim)

```vim
:Lazy          " プラグインマネージャー画面
:Lazy sync     " プラグインの更新・インストール・クリーンアップ
:Lazy update   " プラグインの更新
:Lazy health   " ヘルスチェック
```

---

## エディタ設定メモ

- タブ幅: 2スペース
- 行番号: 相対行番号 (5j で5行下にジャンプ等)
- クリップボード: OS と同期 (`unnamedplus`)
- マウス: 有効
- スワップファイル: 無効 / undo ファイル: 有効 (永続 undo)
- 検索: 大文字小文字自動判別 (smartcase)
- ウィンドウ分割: 右/下に開く
