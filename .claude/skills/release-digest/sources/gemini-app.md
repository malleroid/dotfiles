# Source spec: Gemini App

- **対象**: 消費者向け Gemini アプリ（web / mobile / Live / Spark / Omni 等）。Claude Apps 相当。
- **単位**: 日付（1 日付 = 1 メッセージ）
- **ヘッダー**: `*Gemini App* — <date> · <<url>|原文>`（ページにエントリ単位アンカーは無いので記事 URL のまま）
- **正規化スキーマの追加フィールド**: なし。`changes[]` の各要素は 1 feature で、`<title>\nWhat: ...\nWhy: ...` 形式（ソースの What/Why をそのまま保持）。

## レンダリング規則

ヘッダーに続けて、各 feature を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）:

1. 🆕 **大型リリース・新モデル** — アプリ内モデルローンチ（3.5 Flash 等）・新プロダクト（Omni・Spark 等）
2. 📱 **アプリ機能** — Gemini アプリ / Live / mobile / web の機能追加・変更
3. 🔌 **連携・コネクタ** — connectors / 外部アプリ連携
4. 🏢 **プラン・サブスク・管理** — Google AI プラン（Ultra 等）・料金・エンタープライズ管理（優先度は下げるが**落とさず**載せる）
5. 📝 **その他**

各行の書き方:

- feature の英語タイトルを日本語タイトル（太字）に訳し、What/Why を 1〜2 行に要約する（What を主、Why は必要時のみ）。
- 製品名・モデル名（`Gemini Omni` / `3.5 Flash` 等）は英語のまま。
- bugfix 概念は基本無いので末尾の全列挙は不要。
