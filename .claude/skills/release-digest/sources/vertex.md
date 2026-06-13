# Source spec: Vertex AI

- **対象**: Generative AI on Vertex AI（Google Cloud）。Model Garden のモデル提供（Google・パートナー: Claude / Llama / Mistral / DeepSeek / GLM 等）、RAG Engine、Agent Engine、リージョン展開、料金など。
- **単位**: 日付（1 日付 = 1 メッセージ）
- **ヘッダー**: `*Vertex AI* — <date> · <<url>|原文>`（url は日付アンカー付き deep-link）
- **`changes[]` の形**: 各要素は `[Category] <本文>`。Category はソース付与（**Feature / Deprecated / Announcement / Change**）で、強い分類ヒント。

## レンダリング規則

ヘッダーに続けて、`changes[]` を次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）。**deprecation/retire が最上位**:

1. 🚨 **破壊的変更・deprecation・retire** — `[Deprecated]`、エンドポイント廃止・モデル retire・shutdown 日。**移行期限/shutdown 日は太字**。廃止エンドポイント表は「主要な置換先」を 1〜2 行に要約（全件は冗長なら代表例＋件数）。
2. 🆕 **新モデル** — Model Garden で利用可能になったモデル（Gemini / Veo / Imagen / Lyria / Claude / GLM / DeepSeek 等）。
3. 🔧 **機能・API** — RAG Engine・Agent Engine・Studio 等の新機能・新 API。
4. ☁️ **提供リージョン・基盤** — リージョン追加、サービング基盤（cohosting 等）。
5. 💰 **料金** — `[Change]` の価格改定・課金開始。
6. 📝 **その他**

各行の書き方:

- 日本語タイトル（太字）＋ 1〜2 行要約。モデル名・エンドポイント名（`gemini-2.5-flash-image` 等）は英語のまま。
- ソース Category とトピックが食い違う場合はトピック規則を優先（`[Announcement]` でも中身が retire 日なら 🚨）。
- 注: Claude / Gemini モデルの「Vertex で利用可能」告知は他ソースと重複し得るが、**dedup せず Vertex 視点で載せる**。
