---
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(git commit *)
description: "staged の変更からコミットメッセージを生成してコミットする。引数に 'preview' を渡すとメッセージ生成のみ行う"
---

## Context

- Current branch: !`git branch --show-current`
- Staged changes: !`git diff --cached`
- Staged files: !`git status --short`
- Recent commits (style reference): !`git log --oneline -20`
- Commit template: !`git config commit.template 2>/dev/null | xargs cat 2>/dev/null || echo "(未設定)"`

## Commit message rules

**Conventional Commits** に従うこと: https://www.conventionalcommits.org/

```
<emoji> <type>[optional scope]: <description>

[optional body]
```

- `type`: `feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore` / `perf` / `ci` / `build` / `revert`
- `emoji`: **Commit template** のルールを参照。`type` に対応する絵文字を先頭に付ける
- `description`: 命令形・現在形で記述（日本語可）
- body: 変更の背景・理由が必要な場合のみ記述

**Recent commits のスタイル**（emoji の使い方・文体・粒度）を優先して参考にすること。

## Your task

Arguments: $ARGUMENTS

1. staged changes が空の場合は「ステージされた変更がありません」と伝えて終了する
2. 上記ルールに従ったコミットメッセージを生成し、ユーザーに提示する
3. Arguments が `preview` の場合はここで終了する
4. Arguments が `preview` でない場合はユーザーに確認を取り、承認されたらコミットを実行する。修正を求められた場合はメッセージを修正して再度確認する

コミット実行時は複数のツールを1レスポンスで呼び出すこと。`git commit -m` を使い、body がある場合は `-m` を複数指定すること。
