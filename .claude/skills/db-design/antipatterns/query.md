# クエリのアンチパターン

### フィア・オブ・ジ・アンノウン（恐怖のunknown）
**目的:** 欠けている値（NULL）を扱いたい
**アンチパターン:** NULL を一般値として扱う、または「値なし」を `0` や `''` で代替する
**検出シグナル:**
- `WHERE col = NULL` または `WHERE col != NULL`（`IS NULL` / `IS NOT NULL` を使うべき）
- `NOT IN (subquery)` でサブクエリに NULL が含まれる可能性がある
- `0` や空文字 `''` で「値なし」を表現している列

**問題:**
- NULL は三値論理（TRUE / FALSE / UNKNOWN）の第三値。`NULL = NULL` の評価結果は UNKNOWN であり、条件式が一致しない
- `COUNT(col)` は NULL を無視するが `COUNT(*)` はカウントする — 意図しない集計ズレが起きる
- `NOT IN` のサブクエリが NULL を返すと結果が常に空になる（UNKNOWN の伝播）
- `0` や `''` で代替すると「ゼロ」と「未入力」の区別が不可能になる

**解決策:**
- `IS NULL` / `IS NOT NULL` を使う
- `COALESCE(col, default)` でデフォルト値を返す
- `NULLIF(col, value)` で特定値を NULL に変換する
- NULL セーフな等値比較（SQL 標準: `IS NOT DISTINCT FROM`、MySQL: `<=>`）を使う
- `NOT IN` の代わりに `NOT EXISTS` を使い NULL の混入を回避する

**例外:** 「値が存在しない」という意味を明確に持たせる場合は NULL が正しい選択

---

### アンビギュアスグループ（曖昧なグループ）
**目的:** グループ内で最大値を持つ行を取得したい
**アンチパターン:** GROUP BY に含まれない非集約列を SELECT に含める
**検出シグナル:**
- `SELECT a, b, MAX(c) FROM t GROUP BY a`（`b` が非集約列）
- MySQL で `ONLY_FULL_GROUP_BY` を無効化している設定（`sql_mode` から除外）

**問題:**
- SQL 標準では GROUP BY に含まれない非集約列を SELECT することは禁止されている
- PostgreSQL・MySQL 5.7.5 以降（`ONLY_FULL_GROUP_BY` デフォルト有効）ではエラーになる
- 旧 MySQL や一部 DB で許容される場合も、返される行は不定であり結果が信頼できない

**解決策（優先順位順）:**

1. **ウィンドウ関数**（最もシンプル）
   ```sql
   SELECT *, ROW_NUMBER() OVER (PARTITION BY a ORDER BY c DESC) AS rn
   FROM t
   ```
   外側で `WHERE rn = 1` で最大値行を取得

2. **相関サブクエリ**
   ```sql
   SELECT * FROM t WHERE c = (SELECT MAX(c) FROM t t2 WHERE t2.a = t.a)
   ```

3. **導出テーブル + JOIN**
   ```sql
   SELECT t.* FROM t
   JOIN (SELECT a, MAX(c) AS max_c FROM t GROUP BY a) m
   ON t.a = m.a AND t.c = m.max_c
   ```

---

### ランダムセレクション
**目的:** ランダムに1行を取得したい
**アンチパターン:** `ORDER BY RAND()` / `ORDER BY RANDOM()` を使う
**検出シグナル:**
- `ORDER BY RAND()` / `ORDER BY RANDOM()` + `LIMIT`
- ランダム取得のたびにクエリが遅いという報告

**問題:**
- 全行にランダム値を生成してからソートするため、`LIMIT 1` をつけても全行スキャンが発生する
- テーブルが大きいほど線形にパフォーマンスが劣化する

**解決策（優先順位順）:**

1. **`TABLESAMPLE`**（DB が対応している場合）
   ブロックレベルサンプリングで高速。`ORDER BY RANDOM()` より大幅に速い

2. **ランダムオフセット法**（2クエリ、汎用）
   `COUNT(*)` で総行数を取得 → アプリ側でランダムオフセットを生成 → `LIMIT 1 OFFSET ?`

3. **ID 範囲絞り込み**（1クエリ、高速）
   ```sql
   WHERE id >= FLOOR(RAND() * (SELECT MAX(id) FROM t)) LIMIT 1
   ```
   ※ ID に欠番が多い場合は分布が偏る可能性がある

4. **アプリ側でキー一覧取得後にランダム選択**
   小〜中規模テーブル向け。キー一覧をキャッシュすると効率的

**例外:** 小テーブル・低頻度アクセスでは `ORDER BY RAND()` で十分

---

### プアマンズ・サーチエンジン（貧者のサーチエンジン）
**目的:** 全文検索を行いたい
**アンチパターン:** `LIKE '%keyword%'` や `REGEXP` による中間一致検索
**検出シグナル:**
- `WHERE col LIKE '%keyword%'` の多用
- 検索クエリのたびにフルスキャンが発生している（EXPLAIN で Seq Scan）

**問題:**
- 中間一致（`%keyword%`）はインデックスを使えず全行スキャンが発生する
  （前方一致 `keyword%` ならインデックスが使えるが、用途が限られる）
- 大テーブルでは検索のたびにパフォーマンスが劣化する
- 日本語など分かち書きが必要な言語では LIKE 検索は特に不正確

**解決策（規模・要件で選択）:**

| 方式 | 向いている場面 |
|------|--------------|
| DB 内蔵の全文検索（FTS）| 追加インフラ不要。中規模まで。DB に検索を集約したい |
| 軽量サーチエンジン（Meilisearch / Typesense 等）| セットアップが容易。タイポ許容・日本語対応。中〜大規模 |
| 重量級サーチエンジン（Elasticsearch / OpenSearch）| 大規模・分散・複雑な集計が必要な場合 |

**例外:** 小テーブル・低頻度・前方一致で十分な検索

---

### スパゲッティクエリ
**目的:** SQL クエリの発行数を減らしたい
**アンチパターン:** 複雑な問題を1つの巨大 SQL で解決しようとする
**検出シグナル:**
- 多重 JOIN・深くネストしたサブクエリ・UNION の乱用
- JOIN 条件の漏れによる想定外の大量行数（デカルト積）
- クエリを読んでも何を取得しているか一見で分からない

**問題:**
- JOIN 条件が抜けると暗黙の CROSS JOIN（デカルト積）が発生し、結果行数が爆発的に増える
- 中間結果を確認できないためデバッグが困難
- スキーマ変更時の修正範囲が把握できない

**解決策:** CTE（共通テーブル式）で段階的に分解する

```sql
WITH base AS (
  SELECT ...          -- Step 1: 基本データ抽出
),
filtered AS (
  SELECT ... FROM base WHERE ...  -- Step 2: 絞り込み
)
SELECT ... FROM filtered JOIN ...  -- Step 3: 最終結合
```

- 各 CTE を独立して実行・検証できるため、問題の切り分けが容易
- 同じ中間結果を複数箇所で参照できる（サブクエリの重複を排除）

**例外:** EXPLAIN で確認した上で1クエリの方が明らかに実行計画が優れる場合

---

### インプリシットカラム（暗黙の列）
**目的:** タイプ量を減らしたい
**アンチパターン:** `SELECT *` や `INSERT INTO t VALUES (...)` で列名を省略する
**検出シグナル:**
- `SELECT *` を含む本番クエリ
- `INSERT INTO t VALUES (...)` で列名を省略している

**問題:**
- スキーマ変更（列追加・削除・順序変更）でアプリが壊れる
- `password_hash` / `api_key` などの機密列が意図せず返されるセキュリティリスク
- `SELECT *` はカバリングインデックス（Index-Only Scan）を妨げ、パフォーマンスが劣化する
- JOIN で複数テーブルを結合すると同名列が上書きされ、どのテーブルの値か不明になる
- `INSERT` で列順に依存したコードはカラム追加時にサイレントなバグを生む

**解決策:** 常に列名を明示する
```sql
-- NG
SELECT * FROM users;

-- OK
SELECT id, name, email FROM users;
```

**例外:** インタラクティブなデバッグ・探索クエリ（本番コードには含めない）
