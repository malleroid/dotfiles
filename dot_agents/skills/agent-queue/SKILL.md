---
name: agent-queue
description: "エージェントにやらせる作業のキュー（private GitHub Project「Agent Queue」）を読み書きする。ユーザーが「キューに積んで」「あとでやらせたい」「キュー見て」「次やって」と言ったとき、作業中に別件を見つけて手放すとき、作業が判断待ち・外に出す手前で止まるときに使う"
---

エージェントにやらせる作業を、repo の外の 1 か所（private GitHub Project「Agent Queue」）で管理する。
セッションはどの repo からでも始まり、扱うのは **今いる repo の item だけ**。

## コマンド

`agent-queue <command>`。出力は JSON か 1 行の結果。`<id>` は `PVTI_...`。

| コマンド | 用途 |
|---|---|
| `list [--here \| --repo owner/repo \| --unscoped \| --all] [--open \| --status S]` | 一覧（既定は今の repo の Done 以外） |
| `show <id>` | 本文を含む 1 件 |
| `add <title> [--here \| --repo owner/repo \| --none] [--status S] [--jira KEY] < body` | 追加（既定は今の repo、Inbox） |
| `claim <id>` | 着手（In Progress + Claimed By） |
| `note <id> < text` | 本文の作業ログに追記 |
| `move <id> <status>` | レーン移動 |
| `edit <id> [--title] [--body-stdin] [--here \| --repo \| --none] [--jira KEY \| --no-jira]` | 整理 |
| `done <id>` | 完了 |

本文は `./tmp/` に書いてから `< ./tmp/<file>` で渡し、渡したら削除する。

## レーン

レーンは「次に手を動かすのは誰か」で決める。

| Status | 次に動く | 置くもの |
|---|---|---|
| Inbox | 誰も | 未整理。repo 未定でもよい |
| To Do | エージェント | 前提・やること・根拠・完了条件が揃っていて着手できる |
| In Progress | エージェント | 作業中 |
| Needs Decision | ユーザー | 判断待ち。決めることと選択肢を本文に書いてある |
| Needs Go-ahead | ユーザー | 手元の作業は終わり、残りは push / PR / 外部への投稿だけ |
| Waiting | 他の人・外部 | レビュー待ち、外部の出来事待ち |
| Done | 誰も | 完了 |

## 本文

```markdown
## 前提
## やること
## 根拠
（関連ファイル、Jira キー、URL）
## 完了条件
```

作業ログは `note` が末尾の `## 作業ログ` に追記する。新しいセッションが本文だけ読んで再開できるように書く。

## 規約

- **スコープ**: 触るのは今の repo の item だけ。他 repo・repo 未定（`--unscoped`）の item は、ユーザーが明示したときだけ扱う
- **1 セッション 1 item**: 作業中に見つけた別件は、この item の完了に要らなければ `add` して手放す
- **外に出す手前で止まる**: push・PR 作成・外部への投稿の前に `note` で状況を残し、`move <id> "Needs Go-ahead"` して止まる。ゴーはユーザーが出す
- **決まっていないことにぶつかったら**: 決めることと選択肢を `note` に書き、`move <id> "Needs Decision"` してセッションを終える
- **業務 repo の item**: 本文は Jira キー（`--jira`）と最小限のメモだけ。コード・社内情報・顧客情報は書かない。要件は Jira から読む
- **追加は確認してから**: `add` するタイトル・本文・repo・Status をユーザーに提示し、了承を得てから実行する

## 典型的な流れ

### 「キューに積んで」「あとでやらせたい」

1. 内容から title と本文を作る。repo が決まっていなければ `--none`、整理前なら Status は Inbox のまま
2. 提示して了承を得たら `add`

### 「キュー見て」「次やって」

1. `list --status "To Do"` で今の repo の To Do を取る。0 件なら `list` で他のレーンの状況だけ伝える
2. 着手する 1 件を `show` で読み、ユーザーに伝えて `claim`
3. 作業し、区切りごとに `note`
4. 終わったら、外に出す一歩が残っていれば `Needs Go-ahead`、残っていなければ `done`

### Inbox の整理（ユーザーが頼んだとき）

1. `list --all --status Inbox` で一覧を出す
2. item ごとに、repo の割り当て・本文の書き直し・To Do へ上げるか・捨てるかの案を出す
3. 承認されたものだけ `edit` / `move` / `done` で反映する
