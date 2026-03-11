---
allowed-tools: Read, AskUserQuestion
description: "SQLアンチパターン第2版をベースにDBスキーマのレビューと設計支援を行う"
---

## Reference files

> アンチパターン参照ファイル置き場: `antipatterns/` サブディレクトリ（プロジェクトルートからの相対パス）

- 論理設計: `.claude/skills/db-design/antipatterns/logical.md`
- 物理設計: `.claude/skills/db-design/antipatterns/physical.md`
- クエリ: `.claude/skills/db-design/antipatterns/query.md`
- アプリ層: `.claude/skills/db-design/antipatterns/app.md`
- 外部キー: `.claude/skills/db-design/antipatterns/fk.md`

## Your task

Arguments: $ARGUMENTS

### Step 0: モード判定と参照ファイルの選択

Arguments または提示された内容から入力の種類とモードを判定する:

| 入力の種類 | モード | 読み込むファイル |
|-----------|--------|----------------|
| DDL / スキーマ / ER図 | Review | logical + physical + fk |
| SQL クエリ | Review | query（+ 必要なら logical） |
| アプリケーションコード | Review | app |
| マイグレーションファイル | Review | logical + physical + fk |
| 要件・仕様 | Design | logical + physical |
| 指定なし / フルレビュー | Review | 全ファイル |

判定したら、該当するファイルを Read ツールで読み込む。

判定が難しい場合は AskUserQuestion で確認する。

判定後、**Review モード**または **Design モード**の手順に進む。

---

### Review モード

既存のスキーマ・DDL・クエリを受け取り、アンチパターンを検出して報告する。

#### Step 1: 対象の読み込み

提示された DDL・スキーマ・クエリを読み込む。ファイルパスが指定された場合は Read ツールで取得する。

レビュー対象が提示されていない場合は AskUserQuestion でレビュー対象（DDL・クエリ・ファイルパス等）を確認する。

#### Step 2: アンチパターンの照合

読み込んだ Reference files を参照し、各アンチパターンに照らして問題を検出する。

#### Step 3: 結果の報告

```
## DBレビュー結果

### 🔴 Critical（早急に対処すべき）
- **[アンチパターン名]** `テーブル名.列名`
  - 問題: <何が問題か>
  - 解決策: <具体的な修正方法>

### 🟡 Warning（改善を推奨）
- **[アンチパターン名]** `テーブル名.列名`
  - 問題: <何が問題か>
  - 解決策: <具体的な修正方法>

### 🔵 Info（状況次第で検討）
- **[アンチパターン名]** `テーブル名.列名`
  - 問題: <何が問題か>
  - 解決策: <具体的な修正方法>
  - 許容できる場合: <例外条件>

### ✅ 問題なし
<問題が見つからなかった観点があれば列挙>
```

**重大度の基準:**
- Critical: データ消失・セキュリティ・整合性破壊のリスク（例: SQLインジェクション、FK なし）
- Warning: パフォーマンス・保守性・スケーラビリティへの影響が大きい
- Info: 用途によっては許容されるが、意図を確認したいもの

---

### Design モード

要件を受け取り、アンチパターンを避けたスキーマ設計を提案する。

#### Step 1: 要件の確認

AskUserQuestion で以下を確認する（未明の場合のみ）:
- 主なエンティティと関係性
- 予想されるデータ量・アクセスパターン
- 使用する DB エンジン（MySQL / PostgreSQL 等）

#### Step 2: スキーマ設計

読み込んだ Reference files を参照しながら設計する。

#### Step 3: 設計案の提示

```
## スキーマ設計案

### テーブル構成
<テーブル一覧と役割>

### DDL
\`\`\`sql
<CREATE TABLE 文>
\`\`\`

### 設計の判断ポイント
- <なぜこの構造にしたか>
- <考慮したアンチパターンと回避方法>

### トレードオフ・代替案
- <状況によっては別の選択肢があれば>
```
