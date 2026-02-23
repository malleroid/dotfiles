---
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(git add *), Bash(git reset *), Bash(git commit *)
description: 全変更を意味的な単位に分割し、それぞれコミットメッセージを生成して順にコミットする
---

## Context

- Current branch: !`git branch --show-current`
- All changes (staged + unstaged): !`git diff HEAD`
- Changed files: !`git status --short`
- Recent commits (style reference): !`git log --oneline -20`
- Commit template: !`TMPL=$(git config commit.template 2>/dev/null); [ -n "$TMPL" ] && cat "$TMPL" || echo "(未設定)"`

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

### Step 1: 変更の分析と分割計画の提示

以下の観点で変更を意味的な単位に分割し、コミット計画を提示する:

- 変更の目的が異なるものは別コミットにする（例: バグ修正とリファクタが混在する場合）
- 関連するファイルは同一コミットにまとめる（例: 実装ファイルとそのテスト）
- 設定変更・ドキュメント更新は機能変更と分ける

**提示フォーマット:**

```
## コミット計画

### Commit 1: <proposed message>
- file_a.ts
- file_b.ts

### Commit 2: <proposed message>
- file_c.md
```

ファイル内の変更が複数の意味的単位に跨る場合は、計画内に以下を明記すること:
> ⚠️ `<filename>` はファイル内に異なる目的の変更が混在しています。`git add -p` で手動分割してください。

### Step 2: ユーザー確認

計画を提示してユーザーの承認を得る。修正を求められた場合は計画を修正して再度確認する。

### Step 3: コミット実行

承認後、計画の順番どおりに以下を繰り返す。各コミットの stage とコミット操作は複数のツールを1レスポンスで呼び出すこと:

1. `git reset HEAD <files>` で対象外ファイルをいったんアンステージ（必要な場合のみ）
2. `git add <files>` で対象ファイルをステージ
3. `git commit -m` でコミット（body がある場合は `-m` を複数指定）
4. 次のコミットへ

全コミット完了後、結果を要約して報告する。
