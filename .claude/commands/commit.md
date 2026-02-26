---
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(git commit *), Bash(git config *), Read
description: "staged の変更からコミットメッセージを生成してコミットする。引数に 'preview' を渡すとメッセージ生成のみ行う"
---

## Context

- Current branch: !`git branch --show-current`
- Staged changes: !`git diff --cached`
- Staged files: !`git status --short`
- Recent commits (style reference): !`git log --oneline -20`
- Commit template path: !`git config commit.template`

## Commit message rules

フォーマット・emoji・文体・粒度は **Commit template** と **Recent commits** を最優先で参考にすること。

description と body の書き方は Conventional Commits（https://www.conventionalcommits.org/）に準拠する:

- **description**: 命令形・現在形で変更を簡潔に要約する（日本語可）
- **body**: description の後に空行を入れ、変更の背景・理由を記述する。必要な場合のみ
- `Co-Authored-By` トレーラーは **付けない**

## Your task

Arguments: $ARGUMENTS

1. staged changes が空の場合は「ステージされた変更がありません」と伝えて終了する
2. Commit template path が空でなければ Read ツールでそのファイルを読み、コミットフォーマットを把握する
3. 上記ルールに従ったコミットメッセージを生成し、ユーザーに提示する
4. Arguments が `preview` の場合はここで終了する
5. Arguments が `preview` でない場合は AskUserQuestion ツールで確認する（選択肢:「コミットする」「修正する」）。承認されたらコミットを実行し、修正を求められた場合はメッセージを修正して再度 AskUserQuestion で確認する

コミット実行時は複数のツールを1レスポンスで呼び出すこと。`git commit -m` を使い、body がある場合は `-m` を複数指定すること。
