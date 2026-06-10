# Source spec: Claude Code

- **単位**: version（1 version = 1 メッセージ）
- **ヘッダー**: `*Claude Code <version>* — <date> · <<url>|原文>`
- **正規化スキーマの追加フィールド**: `version` / `published_at` / `bugfix_only`

## レンダリング規則

### `bugfix_only: true` の version

最小 1 行のみ:

```
*Claude Code <version>* — <date> · <<url>|原文>  ／ bugfix のみ
```

### それ以外の version

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🔧 **機能** — 新機能・新コマンド・新オプション・既存機能の能力追加
2. 🔁 **挙動変更** — 既存の挙動 / デフォルト / 出力が変わるもの
3. 🛡 **セキュリティ/権限** — 権限・認証・サンドボックス・managed settings・deny/allow ルール
4. 💻 **環境固有** — 特定 OS / IDE / 端末（Windows・macOS・WSL・JetBrains・VS Code 等）限定
5. ⌨️ **入力/端末** — IME・キーボード・vim mode・端末描画・クリップボード
6. ⚡ **パフォーマンス** — 速度・レイテンシ・リソース消費
7. 🐛 **その他 bugfix** — 上記以外の一般的な修正

各行の書き方:

- **トピック 1〜6**: 日本語タイトル（太字）＋必要なら 1〜2 行の補足要約。
- **トピック 7（その他 bugfix）**: 要約なしの 1 行訳。**件数が多くても全件列挙**（長ければ ` / ` 区切り可）。
