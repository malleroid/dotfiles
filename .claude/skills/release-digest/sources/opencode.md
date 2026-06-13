# Source spec: opencode

- **対象**: opencode（sst/opencode、OSS の agentic コーディングツール）。Core / TUI / Desktop / Web 等のコンポーネント横断。
- **単位**: version（1 リリース = 1 メッセージ）
- **ヘッダー**: `*opencode <version>* — <date> · <<url>|原文>`
- **正規化スキーマの追加フィールド**: `version` / `published_at`。`changes[]` の各要素は `[Component/Category] <本文>`（Component=Core/Desktop 等、Category=Improvements/Bugfixes）。素プロースのリリースは本文全体が 1 要素。

## レンダリング規則

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🔧 **機能** — 新機能・新コマンド・新オプション・新モデル対応・既存機能の能力追加
2. 🔁 **挙動変更** — 既存挙動 / デフォルト / 設定キーの変更
3. 🛡 **セキュリティ/権限** — 権限・認証・MCP の trust / credentials
4. 💻 **環境固有** — 特定 OS / Desktop / プラットフォーム（Linux launcher 等）限定
5. ⚡ **パフォーマンス** — 速度・検索・リソース
6. 🐛 **その他 bugfix** — 上記以外の修正。要約なし 1 行訳で**全件列挙**（` / ` 区切り可）

各行の書き方:

- **トピック 1〜5**: 日本語タイトル（太字）＋必要なら 1〜2 行要約。コマンド名・設定キー（`/goal`・`references` 等）は英語のまま。`(@contributor)` 表記は省いてよい。
- **トピック 7（その他 bugfix）**: 1 行訳で全件列挙。
- ソースの Component（Core/Desktop 等）と Category（Improvements/Bugfixes）は分類ヒント。Category と配置トピックが食い違う場合はトピック規則を優先（`[…/Bugfixes]` でも内容が権限なら 🛡）。
