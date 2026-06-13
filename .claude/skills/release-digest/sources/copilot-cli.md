# Source spec: GitHub Copilot CLI

- **対象**: GitHub Copilot CLI（`github/copilot-cli`、ターミナルのコーディングエージェント）。
- **単位**: version（1 リリース = 1 メッセージ。prerelease は除外）
- **ヘッダー**: `*Copilot CLI <version>* — <date> · <<url>|原文>`
- **正規化スキーマの追加フィールド**: `version` / `published_at`。`changes[]` の各要素は `[Category] <本文>`（Category=Added/Improved/Fixed 等。ラベル無し形式の版は素のまま）。

## レンダリング規則

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🔧 **機能** — 新機能・新スラッシュコマンド・新設定・新モデル/プロバイダ対応・既存機能の能力追加
2. 🔁 **挙動変更** — 既存挙動 / デフォルト / 設定の変更
3. 🛡 **セキュリティ/権限** — 権限・認証・proxy・allow-all(YOLO) 等
4. 💻 **環境固有** — 特定 OS / 端末（terminal multiplexer・proxy 等）限定
5. ⚡ **パフォーマンス**
6. 🐛 **その他 bugfix** — 上記以外の修正。要約なし 1 行訳で**全件列挙**（` / ` 区切り可）

各行の書き方:

- **トピック 1〜5**: 日本語タイトル（太字）＋必要なら 1〜2 行要約。スラッシュコマンド・設定名（`/agents` / `statusLine.command` 等）は英語のまま。
- **トピック 7（その他 bugfix）**: 1 行訳で全件列挙。
- ソースの Category（Added/Improved/Fixed）は分類ヒント。Category と配置トピックが食い違う場合はトピック規則を優先。
