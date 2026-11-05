---
name: feedback-review
description: "Agent Feedback Inbox（private GitHub Project）に溜まった生のフィードバック事例を見直し、ユーザー承認を得たものだけを hook / lint / Skill / CLAUDE.md / memory へ昇格させる。ユーザーが /feedback-review を実行したときだけ使う"
---

Agent Feedback Inbox に記録された事例を見直し、ルールや仕組みへの昇格を判断する。
**判断するのはユーザー**。Claude は事例の整理と案の作成だけを行い、承認なしに何も反映しない。

## 使うコマンド

- `feedback-list [Inbox|Adopted|Rejected|all]`: 事例を JSON 配列で出す（既定は Inbox、archive 済みは出ない）
- `feedback-update <PVTI_id> [--title] [--body-stdin] [--status] [--destination] [--archive]`: 事例を更新する。Status の変更か archive で、通知 hook のキャッシュも消える

## Step 1: 事例を読む

1. `feedback-list` で Inbox の事例を取得する。0 件なら「見直す事例はありません」と伝えて終了する
2. dotfiles の `dot_claude/CLAUDE.md`（Learned Feedback を含む）を Read し、既存のルールと重なる事例を把握する

## Step 2: まとめて案を作る

似た事例をグループにまとめ、グループごとに次の案を作る。

- **採否**: 採用 / 不採用 / 保留（Inbox に残す）
  - 採用の目安: 同じ趣旨の事例が 2 件以上ある、または事例の中でユーザーが「覚えて」と明示している
  - 1 件だけで目安を満たさないものは、原則として保留を提案する
  - 既存ルールでカバー済みなら、不採用か既存ルールの補強を提案する
- **書き先**: 決定論的に強制できるものを優先する
  1. hook / lint（機械的に判定できる）
  2. skill（特定の作業手順に閉じる）
  3. CLAUDE.md（リポジトリ固有ならそのリポジトリ、横断ならグローバル）
  4. memory（そのプロジェクトでしか意味がない事実）
- **反映内容のドラフト**: ルールの文面、または hook / lint の仕様。事例 1 件の言い回しに引きずられず、グループ全体に通用する抽象度で書く

**公開リポジトリへの配慮**: dotfiles は PUBLIC。グローバル CLAUDE.md や skill に書く文面には、事例に含まれるリポジトリ名・コード・社内の固有名詞・発言の原文を入れない。

## Step 3: ユーザーに確認する

グループの一覧（事例数・案の要約）を先に提示し、AskUserQuestion でグループごとに確認する。

- 選択肢: 「案どおり採用」「不採用」「保留」。文面の修正は Other で受ける
- `preview` にドラフト全文と対象事例のタイトルを入れる
- 独立したグループは 1 回の AskUserQuestion にまとめてよい（最大 4 問）

## Step 4: 反映する

承認された内容だけを反映する。

- **CLAUDE.md / skill / memory**: Edit / Write で反映する
- **hook / lint**: 実装は別作業として扱う。仕様を提示し、ユーザーが着手を指示したら実装する
- 反映した事例: `feedback-update <id> --status Adopted --destination <書き先> --archive`
- 不採用の事例: `feedback-update <id> --status Rejected --archive`
- 保留の事例: 何もしない
- dotfiles への変更はコミットしない。commit skill か commit-split skill の実行をユーザーに促す

## Step 5: 結果を報告する

採用・不採用・保留の件数、変更したファイル、未着手の hook / lint の仕様を報告する。
