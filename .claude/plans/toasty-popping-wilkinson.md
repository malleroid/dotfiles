# Skills 新規作成プラン: 設計・要件定義支援

## Context

設計・要件定義作業で繰り返し発生する「観点の漏れチェック」「代替案の構造化比較」「要件の整理・分類」を Skills 化する。CLAUDE.md に書くとコンテキストを常時消費するが、Skills なら必要時のみ展開される。

## 作成ファイル一覧（13ファイル）

```
.claude/skills/
├── design-review/
│   ├── SKILL.md                          # 設計レビュー本体
│   └── references/
│       ├── review-checklist.md           # 12観点チェックリスト
│       └── nfr-perspectives.md           # 非機能要件の観点（3 Skill 共有の正本）
├── alternatives-analysis/
│   ├── SKILL.md                          # 代替案分析本体
│   └── references/
│       ├── evaluation-axes.md            # 評価軸マスターリスト
│       └── adr-template.md              # 社内ADRテンプレート参照
└── requirements-structuring/
    ├── SKILL.md                          # 要件構造化本体
    └── references/
        ├── nfr-checklist.md              # NFRチェックリスト（nfr-perspectives.md を参照）
        ├── moscow-guide.md               # MoSCoW分類ガイド
        └── ambiguity-patterns.md         # 曖昧性検出パターン
```

## 各 Skill の設計

### 1. `design-review` — 設計レビュー

**frontmatter**:
```yaml
name: design-review
description: 設計ドキュメント・設計提案の構造化レビュー。12の観点から設計の健全性を評価する。設計レビュー、アーキテクチャレビュー、設計書の確認、設計の妥当性検証を行う場合に使用。
```

**フロー**:
1. 入力把握（設計ドキュメント or 会話中の設計内容）
2. コードベースがあれば既存コード・設定を確認
3. 12 観点それぞれを ✅/⚠️/❌/➖ で評価
4. サマリーテーブル + 詳細所見 + 総合判定（APPROVE / CONDITIONAL / REVISION）

**反ハルシネーション**: 確認済み/推測/要検証のプレフィックスを義務化

### 2. `alternatives-analysis` — 代替案分析

**frontmatter**:
```yaml
name: alternatives-analysis
description: 技術的な代替案の構造化比較分析。選択肢を評価軸ごとに比較し、ADRの「検討内容」セクションに対応した出力を生成する。代替案の比較、技術選定、アーキテクチャの選択肢検討、ADR作成時に使用。
tools: Read, Grep, Glob, Bash, WebSearch
```

**フロー**:
1. 代替案の整理
2. AskUserQuestion で評価軸と重み（高/中/低）を選択
3. コードベース調査 + WebSearch で根拠収集
4. 比較表（◎/○/△/✗）+ ADR「検討内容」「影響」セクション用出力

**反ハルシネーション**: 未確認の数値・スペックは全て「⚠️ 要検証」、出典URL必須

### 3. `requirements-structuring` — 要件構造化

**frontmatter**:
```yaml
name: requirements-structuring
description: 非構造化な入力（議事録、Confluenceコピー、口頭メモ）から要件を構造化する。機能要件・非機能要件・制約条件・前提条件・未決事項に分類し、MoSCoW優先度を仮付与する。要件定義、要件整理、議事録からの要件抽出に使用。
```

**フロー**:
1. 入力テキスト読み取り + コードベース確認
2. 要件抽出 → FR/NFR/制約/前提/未決に分類
3. MoSCoW 優先度を仮付与（最終判断は人間）
4. 曖昧性パターンマッチで ⚠️ フラグ
5. ステークホルダー向けサマリー生成

**反ハルシネーション**: 入力にない要件は追加しない。推測は「推測:」プレフィックス。数値目標は「要定義」

## Skill 間の連携

- `nfr-perspectives.md` を `design-review/references/` に正本配置、`requirements-structuring` から相対パス参照
- `alternatives-analysis` の出力は ADR テンプレートの「検討内容」「影響」セクションにそのままコピー可能
- 3 Skill とも `context: fork` なし（インライン実行）— 会話の設計議論コンテキストを活用するため

## 実装順序

1. 共有リファレンス作成（`nfr-perspectives.md`, `review-checklist.md`）
2. `design-review/SKILL.md`
3. `alternatives-analysis/` のリファレンス + SKILL.md
4. `requirements-structuring/` のリファレンス + SKILL.md

## 検証方法

- 各 Skill 作成後に `/design-review`, `/alternatives-analysis`, `/requirements-structuring` で手動起動を確認
- 自動発火: 設計に関する自然言語の質問で Claude が Skill を参照するか確認
- 出力フォーマットが設計通りか確認
