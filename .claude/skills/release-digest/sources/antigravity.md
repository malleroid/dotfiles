# Source spec: Antigravity

- **対象**: Google Antigravity（agentic IDE）。**Engine**（エージェント/バックエンド）と **IDE**（エディタ）の 2 系統がある。
- **単位**: version（section 付き。`unit` は `engine 2.0.11` / `ide 2.0.4` の形）
- **ヘッダー**: `*Antigravity (Engine) <version>* — <date> · <<url>|原文>`（section を Engine / IDE と表記）
- **正規化スキーマの追加フィールド**: `version` / `section`（engine|ide）。`changes[]` 先頭は description（と差分があれば概要）、続いて `[Improvements]` / `[Fixes]` / `[Patches]` ラベル付きの各項目。ラベルは分類ヒント。

## レンダリング規則

各 version をヘッダー＋以下トピック順に列挙する（該当 0 件の見出しは省略）:

1. 🔧 **機能** — 新機能・新コマンド・新オプション・既存機能の能力追加
2. 🔁 **挙動変更** — 既存挙動 / デフォルトの変更
3. 🛡 **セキュリティ/権限** — permissions system・sandbox mode・secure mode・認証・アクセス制御
4. 💻 **環境固有** — 特定 OS / 環境（antivirus 干渉・インストール先 等）限定の変更
5. ⚡ **パフォーマンス**
6. 🐛 **その他 bugfix** — 上記以外の修正。要約なしの 1 行訳で**全件列挙**（` / ` 区切り可）

各行の書き方:

- トピック 1〜5 は日本語タイトル（太字）＋必要なら 1〜2 行要約。製品名・バージョン番号は英語のまま。
- ソースラベル（Improvements/Fixes/Patches）と配置トピックが食い違う場合はトピック規則を優先（例: `[Fixes]` でも内容が権限なら 🛡）。
- Engine と IDE は別 version＝別メッセージとして出す（dedup しない）。
