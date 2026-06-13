# Source spec: GitHub Changelog

- **対象**: GitHub プラットフォーム全体の changelog（Copilot / Actions / security / client apps / enterprise 等、AI ツールに限らない）。
- **単位**: item（1 投稿 = 1 項目）。**ただし出力は changelog-label でグルーピングする**（領域が広いため）。
- **正規化スキーマの追加フィールド**: `changelog_type`(Improvement/Retired/Release)、`labels`(copilot/actions 等)、`title`。`changes[]` はリード段落 1 件（詳細はリンク先）。

## レンダリング規則

このソースは「1 メッセージ」ではなく **1 ヘッダー + label 別セクション**で出す（他ソースと違い項目数が多く領域横断のため）:

```
*GitHub Changelog* — <最新date まで>
```

その下に、`labels` でグルーピングした見出しを立て、各項目を date 降順で列挙する。label の並びは**エンジニア関心度**で: `copilot` → `actions` → `security`/`code security` → `client apps`（CLI/Desktop）→ その他（`enterprise management tools` 等は下）。

各項目の行:

- `<type マーク> **<JP タイトル>** — <date> · <<url>|原文>` ＋ 1 行要約。
- **type マーク**: `Retired` → 🚨、`Release` → 🆕、`Improvement` → 🔧。内容が deprecation/廃止なら type に関わらず 🚨。
- 製品・機能名（`GITHUB_TOKEN` / `gh discussion` 等）は英語のまま。
- 1 項目が複数 label を持つ場合は最も主要な 1 つのセクションに置く（重複掲載しない。**ソース内**の重複回避であって他ソースとの dedup ではない）。
