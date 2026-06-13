# Source spec: xAI / Grok

- **対象**: xAI Grok の開発者向け API release notes（モデル・API 機能。消費者向け x.ai/news は取得不可で対象外）。
- **単位**: 日付（1 日付 = 1 メッセージ。同日複数エントリは 1 メッセージに併記）
- **ヘッダー**: `*xAI / Grok* — <date> · <<url>|原文>`（url はエントリ単位アンカー付き）
- **`changes[]` の形**: 各要素は `<title>\n<description>`（description は箇条書き・リンク込み）。

## レンダリング規則

ヘッダーに続けて、各エントリを次の**トピック**へ分類し、この順で見出しを立てて列挙する（該当 0 件の見出しは省略）。**deprecation/retire が最上位**:

1. 🚨 **破壊的変更・deprecation・retire** — API/モデルの廃止予告・非互換変更。期限は太字で強調。
2. 🆕 **新モデル** — Grok モデルのローンチ（`Grok 4.20`・Grok Voice・Grok Build 等）。
3. 🔧 **API 機能・パラメータ** — 新 API・新パラメータ・既存機能の追加（STT/TTS・Web Search・Files API・Batch・Context Compaction・WebSocket・Imagine 等）。
4. ☁️ **プラットフォーム展開** — SDK・外部連携。
5. 💰 **料金・レート制限**。
6. 📝 **その他**。

各行の書き方:

- 日本語タイトル（太字）＋ 1〜2 行要約。モデル名・パラメータ名（`smart_turn` / `image_file_id` 等）は英語のまま。
- 注意: ソースは月見出しに当年の年を持たないため、年は「Last updated」から推定する。年境界付近では稀に年がずれ得る点に留意（致命的でなければそのまま）。
