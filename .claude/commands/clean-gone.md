---
allowed-tools: Bash(git branch *), Bash(git worktree *), Bash(git fetch *)
description: リモートで削除済みのローカルブランチ（[gone]）とその worktree を一括削除する
---

## Context

- Branches with [gone] status: !`git fetch --prune 2>/dev/null; git branch -v | grep '\[gone\]'`
- Worktree list: !`git worktree list`

## Your task

1. `[gone]` ブランチが存在しない場合は「削除対象のブランチはありません」と伝えて終了する
2. 削除対象のブランチ一覧と、それぞれに紐づく worktree をユーザーに提示して確認を取る
3. 承認後、複数のツールを1レスポンスで呼び出して以下を実行する:
   - `[gone]` ブランチに紐づく worktree を `git worktree remove --force <path>` で削除（worktree がある場合のみ）
   - `git branch -D <branch>` でブランチを削除
4. 削除結果を報告する

ブランチ名先頭の `+` や `*` は除いて処理すること。
