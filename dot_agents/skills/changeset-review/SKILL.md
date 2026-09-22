---
name: changeset-review
allowed-tools: Agent, SendMessage, TaskStop, Bash, Read
description: "コードレビューの実行。PR と PR 作成前のローカル変更の両方に対応する。ユーザーが「レビューして」「PR 見て」「この変更どう?」等でコードレビューを依頼したときに使用する。code-reviewer sub-agent を起動し、結果を HTML で出力させる。コード変更後に自動で起動してはいけない。"
---

# Changeset Review

コードレビューは `code-reviewer` sub-agent が行う。このスキルは**その起動と対話の手順だけ**を定義する。
レビュー基準・観点・出力フォーマットは agent 定義側にある。

## 最重要の禁止事項

**親コンテキストで差分を取得しない。** `git fetch` / `git diff` / `gh pr diff` / `gh pr view` を親で実行してはいけない。
ベースブランチの推測・指定もしない。agent が自分で全部やる。親が先に差分を見ると、

- コンテキストを無駄に消費する（このスキルの主目的が失われる）
- 親の解釈が prompt に混入し、agent の自律データ取得と食い違う

**ユーザーの原文メッセージをそのまま `prompt` に渡す。** 書き換え・補足・要約・解釈を加えない。
「どのブランチですか?」のような確認も原則しない（agent が `gh pr status` で判別する）。

## 起動

```
Agent(
  subagent_type: "code-reviewer",
  name: "review-<PR番号 または ブランチ名>",
  prompt: <ユーザーの原文そのまま>,
  model: <下記 tier 参照>
)
```

`name` は必須。後述の深掘り会話で `SendMessage` の宛先になる。

### tier

依頼文言が軽さを示す場合（「軽く」「さくっと」「ざっと」等）のみ `model: sonnet` を指定する。
それ以外は `model` を省略する（agent 定義の `model: inherit` に従う）。

**判断材料はユーザーの文言だけ。** 親が diff の規模を見て判断してはいけない（そのために差分を取るのは上記の禁止事項に反する）。

## 結果の提示

agent は **terminal サマリ**（判定・件数・Critical/Major の 1 行見出し・HTML パス）だけを返す。
指摘の全文・修正案・根拠は HTML にある。

1. agent が返したサマリを**そのまま**提示する。要約・取捨選択しない
2. HTML をブラウザで開く: `open <パス>`（macOS 以外は `xdg-open`）
3. 追加の解説を親から付け足さない。ユーザーが聞いてきたら深掘り（下記）に回す

`ReportFindings` は使わない。terminal では UI 上の利点が無く、スキーマに修正案の欄が無いため情報が落ちる。

## 深掘り会話

レビュー結果への追加質問・反論・確認は、**新規に agent を起動せず** `SendMessage` で同じ agent に送る。

```
SendMessage(to: "review-<PR番号|ブランチ>", message: <ユーザーの原文そのまま>)
```

agent はレビュー時の文脈と worktree を保持しているので、そのまま答えられる。ここでも原文を書き換えない。

## 検証モード（2 段目）

ユーザーが明示的に依頼した場合のみ（「検証込み」「しっかり」「裏取りして」等）実行する。
**親から提案・自動起動はしない。**

レビュー完了後、その指摘リスト**全文**を新規の `code-reviewer` に渡す。1 段目と同じ agent には送らない（独立性のため）。
指摘リストは書き換えずそのまま渡す。判定は CONFIRMED / PLAUSIBLE / REFUTED で返る。

## 後片付け

ユーザーがレビュー完了を明示したら（「レビュー終わり」「worktree 消していい」等）:

1. `SendMessage(to: <agent名>, message: "finish")` — これだけ送る
2. 後片付け完了の通知を待つ
3. `TaskStop(task_id: <agent名>)` で agent 自体を終了する

順序を守ること。先に `TaskStop` すると worktree が残る。

## worktree の扱い

レビュー目的の使い捨て worktree は、リポジトリに `scripts/local/worktree-config.sh` があっても
**plain `gwq add` で作る**（`worktree-new` は使わない）。read-only のレビューに provisioning は不要で、スロットも消費しない。

作成・削除は agent 自身が行う。親は関与しない。削除してよいのは agent がそのレビューのために作ったものだけで、
既存 worktree を再利用した場合は削除しない。
