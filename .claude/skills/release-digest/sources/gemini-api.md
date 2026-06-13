# Source spec: Gemini API

- **単位**: 日付（1 日付 = 1 メッセージ）
- **ヘッダー**: `*Gemini API* — <date> · <<url>|原文>`（url は日付アンカー付き deep-link）
- **正規化スキーマの追加フィールド**: なし（共通スキーマのみ）。`changes[]` の各要素は top-level 箇条書き 1 件（ネストはサブ箇条書きとして同一要素内に保持）。

## レンダリング規則

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）。**deprecation/shutdown が最上位**:

1. 🚨 **破壊的変更・deprecation・shutdown** — モデル shutdown・廃止予告・API スキーマの非互換変更。**shutdown/移行期限は太字で強調**。
2. 🆕 **新モデル** — Gemini 系モデルのローンチ / GA。capabilities は 1 項目に集約。
3. 🔧 **API 機能・パラメータ** — 新 API・新パラメータ・既存機能の追加（File Search・Webhooks・Managed Agents 等）
4. ☁️ **プラットフォーム展開** — Vertex AI / AI Studio との関係、SDK、地域展開
5. 💰 **料金・レート制限**
6. 📝 **その他**

各行の書き方:

- 日本語タイトル（太字）＋ 1〜2 行の補足要約。モデル名・API 名（`gemini-3.5-flash` 等）は英語のまま。
- 内容が deprecation/shutdown なら、見出し上のラベルに関わらず 🚨 へ置く。
