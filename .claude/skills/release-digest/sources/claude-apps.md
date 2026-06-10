# Source spec: Claude Apps

- **対象**: claude.ai / Claude Desktop / Cowork / mobile (iOS・Android) / Claude for Microsoft 365 / Claude in Chrome
- **単位**: 日付（1 日付セクション = 1 メッセージ）
- **ヘッダー**: `*Claude Apps* — <date> · <<url>|原文>`（ページにエントリ単位のアンカーは無いので記事 URL のまま）
- **正規化スキーマの追加フィールド**: `unit`（= 日付）。`changes[]` の各要素は「太字タイトル + 説明パラグラフ（複数行、サブ箇条書き含む）」のブロック。

## レンダリング規則

ヘッダーに続けて、`changes[]` の各エントリを次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🆕 **大型リリース・新モデル** — モデルローンチ、新プロダクト（Cowork GA・Claude Design 等）
2. 🖥 **アプリ機能** — Desktop / mobile / web の機能追加・変更（interactive apps 等）
3. 🔌 **連携・コネクタ** — connectors / integrations / MCP 連携
4. 🏢 **エンタープライズ/管理** — custom roles・RBAC・compliance・analytics・admin 機能（優先度は下げるが**落とさず**載せる）
5. 📝 **その他**

各行の書き方:

- エントリの太字タイトルを日本語タイトル（太字）に訳し、説明パラグラフを 1〜2 行に要約する。
- エントリ内のサブ箇条書き（Cowork GA の機能列挙など）は、重要なら 1 行ずつ、軽微なら ` / ` 区切りで親行の要約に畳んでよい（**内容は省略しない**）。
- ブログ/サポート記事への参照リンクはタイトルのリンク先として 1 本残す。
- bugfix 概念は基本無いので、末尾の全列挙は不要。
