# Source spec: Claude Platform (API)

- **単位**: 日付（1 日付セクション = 1 メッセージ）
- **ヘッダー**: `*Claude Platform (API)* — <date> · <<url>|原文>`
- **正規化スキーマの追加フィールド**: `unit`（= 日付）

## レンダリング規則

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）。**deprecation/retire が最上位**:

1. 🚨 **破壊的変更・deprecation・retire** — モデル廃止予告・retire 日・beta 廃止・非互換変更。**retire 日は太字で強調**。
2. 🆕 **新モデル** — Opus/Sonnet/Haiku 等のローンチ。**モデルの capabilities（context 長・出力・thinking・画像・effort 等）は 1 項目に集約**してバラさない。
3. 🔧 **API 機能・パラメータ・beta** — 新ツール・新パラメータ・beta header・GA 化・課金/レスポンス挙動の変更
4. ☁️ **プラットフォーム展開** — Bedrock / Vertex / Foundry / AWS、SDK 言語追加
5. 💰 **料金・レート制限**
6. 📝 **その他** — docs / console UI・軽微・Claude Code 等の相互掲載（**落とさず載せる**）

各行の書き方:

- 日本語タイトル（太字）＋ 1〜2 行の補足要約。
- bugfix 概念は基本無いので、末尾の全列挙は不要。
