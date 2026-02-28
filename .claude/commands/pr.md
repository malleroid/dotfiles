---
allowed-tools: Bash(git branch *), Bash(git log *), Bash(git diff *), Bash(git push *), Bash(git remote *), Bash(gh pr create *), Bash(gh pr list *), Bash(gh repo view *)
description: "ブランチを push して PR を作成する。引数: [base-branch] [preview]"
---

## Arguments

Arguments: $ARGUMENTS

以下のルールで引数を解釈する:
- `preview` という単語が含まれる場合 → preview モード（description 生成のみ、push・PR 作成なし）
- `preview` 以外の単語がある場合 → それを base branch として使用
- base branch の指定がない場合 → `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` で取得したデフォルトブランチを使用

例:
- `/pr` → auto-detect base, full flow
- `/pr preview` → auto-detect base, preview のみ
- `/pr preview develop` → develop を base に指定, preview のみ
- `/pr develop` → develop を base に指定, full flow

## Context

- Current branch: !`git branch --show-current`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Recent commits: !`git log --oneline -20`

## Your task

### Step 1: base branch の確定と情報収集

Arguments から base branch を特定する。指定がなければ Context の Default branch を使用する（取得できていなければ `main` をフォールバックとする）。

base branch 確定後、以下を実行して情報を収集する:

1. `git log --oneline origin/<base>..HEAD` でブランチ上のコミット一覧を取得する
2. `git diff origin/<base>...HEAD` で差分を取得する
3. PR template を探す: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`, `pull_request_template.md` を Read ツールで順に試し、最初に見つかったものを使用する
4. `gh pr list --state merged --limit 5 --json number,title,body` で最近マージされた PR のスタイルを取得する

### Step 2: PR title と description の生成

以下の優先順位で description を作成する:

1. **PR template** がある場合 → そのセクション構成に従って埋める
2. **Recent merged PRs** のスタイル（文体・粒度・構成）を参考にする
3. どちらもない場合 → 変更内容・目的・影響範囲を簡潔にまとめる

PR title は commits の内容から簡潔に1行で生成する。

description の末尾に「Generated with Claude Code」などの AI ツール帰属フッターを含めないこと。

生成した base branch・title・description をユーザーに提示する。

### Step 3: 分岐

- preview モードの場合 → ここで終了する
- preview モードでない場合 → ユーザーに確認を取る。修正を求められた場合は修正して再確認する

### Step 4: push と PR 作成

承認後、複数のツールを1レスポンスで呼び出すこと:

1. `git push -u origin HEAD` でブランチを push する
2. 以下のコマンドで PR を作成する:
   ```
   gh pr create -a @me --base <base-branch> --title "<title>" --body "<description>"
   ```
3. 作成された PR の URL をユーザーに伝える
