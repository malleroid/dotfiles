# Source spec: Kiro

- **対象**: Kiro（AWS の agentic IDE）。CLI / IDE / Web / Models / General のカテゴリで配信。
- **単位**: エントリ（1 リリース = 1 メッセージ。各エントリは固有タイトル＋ teaser を持つ）
- **ヘッダー**: `*Kiro · <Category>* <JP タイトル> — <date> · <<url>|原文>`
- **正規化スキーマの追加フィールド**: `category`（CLI/IDE/Web/Models/General）、`title`。`changes[]` は teaser 段落 1 件（長いエントリは末尾が `...`＝詳細はリンク先）。

## レンダリング規則

各エントリを 1 ブロックとして、`date` 降順で列挙する。エントリ自体が 1 つのリリース単位なので、エントリ内をトピック分割する必要はない（カテゴリがラベル）。

- ヘッダー: `*Kiro · <Category>* <タイトルを日本語化>` ＋ `— <date> · <<url>|原文>`。タイトルのカテゴリ接頭辞（`CLI:` 等）は Category ラベルと重複するので省いてよい。バージョン番号（`IDE 0.12.333` 等）は残す。
- 本文: teaser を 1〜2 行の日本語に要約。teaser が実質空（`...` のみ）の場合はタイトルのみで可。
- 製品名・コマンド名（`/goal` / `/rewind` 等）は英語のまま。

マーク:

- 💰 **プラン・料金**: 新プラン・価格（例: Kiro Pro Max）。
- 🚨 **breaking / deprecation**: 廃止・非互換変更。
- ⚠️ **注意**: 知らないとハマる挙動変更。
