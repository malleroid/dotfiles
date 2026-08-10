# \~/.claude/CLAUDE.md

## Security & Compliance 🛡️

### 🚫 Commit 禁止パターン

- `*.pem`
- `*.key`
- `*.env` / `.env.*`
- `config/credentials.yml.enc`
- `*secrets*`
- `*.p12`
- `id_rsa*` / `id_ed25519*`

> Claude はこれらに一致するファイルを **生成・追加・表示・共有しないこと**。

### ⛔ シェル操作の範囲制限

- Claude が実行するシェルコマンドは **現在の作業ディレクトリ（= このリポジトリ）内** に限定すること。
- 例外として、auto memory ディレクトリ `~/.claude/projects/<slug>/memory/` への書き込みのみ許可する。`~/.claude/plans/` 等それ以外の `~/.claude/` 配下への書き込みは禁止（plan は作業ディレクトリの `.claude/plans/` に保存すること）。
- 例外として、dotfiles リポジトリの `~/ghq/github.com/malleroid/dotfiles/dot_claude/CLAUDE.md` へのフィードバック追記を許可する（リポジトリ横断のフィードバック収集用）。
- リポジトリ外（上記例外を除く）のファイル・ディレクトリを作成／変更／削除／移動する操作は禁止。
- `curl` / `wget` など外部リクエストを発行するコマンドは事前確認なしに実行しない。
- Bash ツールでファイルパスを指定する際は **相対パス** を使うこと。
- Bash ツールでコマンドを連結（`&&`, `||`, `;`）しないこと。permissions.allow のパターンマッチが効かなくなるため。
  - 独立したコマンドは **並列の Bash tool call** で実行する。
  - 依存するコマンドは **順次別々の Bash tool call** で実行する。
  - パイプ `|` も可能な限り避け、Grep / Read 等の専用ツールで代替する（`jq` 等代替不可の場合を除く）。
- Bash ツールで brace expansion（`{a,b}`, `{1..10}` など）を使わないこと。単一コマンドに見えても複数のパスや引数へ展開され、リポジトリ外操作や permissions.allow の意図しない回避につながるため。
  - 複数の対象を扱う必要がある場合は、対象ごとに個別の Bash tool call に分ける。
- `/tmp` などリポジトリ外の一時ディレクトリを使用しないこと。一時ファイルが必要な場合は作業ディレクトリ内に `./tmp/` を作成して使用する。

### その他原則

1. 社外秘コード・個人情報を含むファイルは公開リポジトリへ push しない。
2. 会社／OSS／副業などの区分に応じた追加ルールは各リポジトリの CLAUDE.md で定義する。

---

## Shell & Environment 🐟

- すべての端末で **fish shell 5.x** を使用。
- dotfiles により `fish_add_path` 等を設定済み。Claude は fish 前提でコマンドを提示する。

### 🐳 開発環境は Docker コンテナ内

- ローカルマシンに言語ランタイム（Node.js, Ruby, Python 等）の開発環境はない。
- `npm`, `npx`, `yarn`, `pnpm`, `bundle`, `gem install`, `rails`, `rake`, `pip install`, `poetry`, `cargo build`, `cargo run`, `go build`, `go run` 等の言語固有コマンドを **ローカルで直接実行しないこと**。
- これらのコマンドが必要な場合は `docker compose exec` や `docker exec` 経由で実行する。
- 各リポジトリの `compose.yaml` / `Dockerfile` を確認し、適切なサービス名・コンテナ名を使うこと。
- 例外: `npm info`, `npm search`, `npm view`, `gem search` 等のレジストリ検索系コマンドはローカル実行可。

---

## Code Style (Placeholder) ✏️

<!-- 後日、共通スタイルを追加する場合に使用 -->

---

## AI Workflow 🤖

### コードレビュー

コードレビューを行う場合は `code-reviewer` sub-agent を使うこと。レビュー基準・出力フォーマットの詳細はそちらに定義されている。
親コンテキストで差分取得（git fetch/diff, gh pr diff等）やベースブランチの推測を行わず、ユーザーの原文メッセージをそのまま sub-agent の prompt に渡すこと。リクエストの書き換え・補足・解釈を加えない。

追加ルール（tier と検証）:

- **軽量 tier**: 依頼文言が軽さを示す場合（「軽く」「さくっと」等）、Agent tool の model パラメータに sonnet を指定して起動する。判断材料はユーザーの文言のみ（親が diff を見て判断しない）
- **検証（batch verifier）**: ユーザーが明示的に依頼した場合のみ（「検証込み」「しっかり」等）、レビュー完了後にその指摘リスト全文を code-reviewer の検証モード（agent 定義参照）に渡して 2 段目を起動する。指摘リストは書き換えずそのまま渡す。親からの検証の提案・自動起動はしない
- **結果の提示**: code-reviewer の結果受領後、agent の構造化レポート（判定・概要・優先度別指摘・修正案含む）を要約・取捨選択せずテキストで提示する（ReportFindings は使わない: terminal では UI 利点がなく、スキーマに修正案欄がなく情報が落ちるため）
- **深掘り会話**: code-reviewer は name 付きで起動する（例: review-<PR番号|ブランチ>）。レビュー結果への追加質問・深掘りは新規起動せず SendMessage で同じ agent に原文のまま送る。検証モードは独立性のため常に新規起動する
- ユーザーがレビュー完了を明示したら（「レビュー終わり」「worktree 消していい」等）、SendMessage で `finish` とだけ伝えて agent に後片付けさせ、後片付け完了の通知を確認してから TaskStop（task_id に agent の name）で agent 自体も終了させる

### フィードバック自動収集

会話中に以下のシグナルを検知したら、dotfiles の CLAUDE.md 末尾「Learned Feedback」セクションに 1 行追記すること:

- ユーザーが tool 実行を拒否した（rejected）
- ユーザーが方針転換を指示した（「それじゃなくて」「やめて」「そうじゃない」等）
- ユーザーが非自明なアプローチを承認した（「それでいい」「perfect」等、成功パターンも記録）

書き込み先: `~/ghq/github.com/malleroid/dotfiles/dot_claude/CLAUDE.md`（絶対パス）
Edit ツールで「Learned Feedback」セクション末尾に追記する。

記録フォーマット: `- 簡潔な 1 行ルール`（日付不要、行動指針として読める形）
重複する学びは追加せず、既存エントリの補強に留める。

### worktree 運用（gwq / worktree-new）

worktree での作業を指示されたら、EnterWorktree の新規作成モード（`.claude/worktrees/` 配下に自動作成）は使わず、以下の手順にする:

1. worktree の作成（配置: `~/worktrees/<host>/<owner>/<repo>/<branch>`、gwq のデフォルト設定のまま）:
   - リポジトリに `scripts/local/worktree-config.sh` がある場合は `worktree-new [-b] <branch>` を使う（内部で gwq add し、リポジトリ固有の worktree セットアップまで行う）
   - 無いリポジトリでは従来どおり `gwq add` で作成する
   - **例外**: レビュー目的の使い捨て worktree は、config の有無に関わらず plain `gwq add` で作成する（read-only で provisioning 不要のため。手順の詳細は code-reviewer agent 定義側）
2. `EnterWorktree(path: <worktreeのパス>)` でセッションごと worktree に移動する（cd やセッション再起動はしない）
3. 元のリポジトリへ戻るときは `ExitWorktree(action: "keep")` を使う
4. **worktree の削除は自動で行わない**（途中作業の揮発防止）。削除はユーザーが明示的に指示したときに、config があるリポジトリでは `worktree-remove <branch>`、無いリポジトリでは `gwq remove` で行う
   - **例外**: レビュー目的でそのセッション（sub-agent 含む）自身が作成した worktree は、working tree が clean であることを確認した上で、ユーザーがレビュー完了を明示したときに `gwq remove` で削除する。既存 worktree を再利用した場合は削除しない

補足:

- `EnterWorktree(path)` の条件は「そのパスが現リポジトリの `git worktree list` に載っていること」。gwq は内部で `git worktree add` を使うので満たされる
- gwq worktree 間の直接ホッピングは不可（`path` 同士の切替は `.claude/worktrees/` 配下限定）。一度 `ExitWorktree(keep)` で戻ってから次に入る

---

## 応答ラベリング 🏷️

すべてのユーザー向け応答（短い相槌も含む）の **先頭1行目** に、内容の根拠ラベルを付けること。

### ラベル種別

- 🔍 **調査済み**: このターンで実行した tool（Read / Grep / Bash / WebFetch / Context7 等）の結果に、主要な主張が裏付けられている
- 💭 **推論**: 学習データ・論理推論・コード生成・意見・相槌ベース。tool 実行なし、または結果と主張が無関係
- 🔍💭 **混合**: 両方を含む。主張ごとに行末 inline marker（🔍 / 💭）を付けて区別すること

### 判定フロー

1. このターンで tool を呼んだか?
   - No → 💭 確定
   - Yes → 2 へ
2. 主要な主張が tool 結果に基づくか?
   - 全て → 🔍
   - 一部 → 🔍💭（inline marker 必須）
   - 結果が主張と無関係 → 💭
3. 意見・推薦・コード生成（synthesizing）を含む箇所は 💭

### 出力形式の例

```
🔍💭 混合

- `foo.ts` は 200 行で `bar()` を export している 🔍
- util/ に切り出すのが綺麗 💭
```

純粋な 🔍 / 💭 の場合、inline marker は省略可。

### 注意

- 「ラベルなし応答」は禁止。ツール呼び出しのみで返答テキストが無いターンはラベル不要。
- 自己申告ラベルなので完全な保証ではないが、ユーザーが信頼度をキャリブレーションするための補助情報として機能させる。

---

## Repository-Specific Overrides (例示) 📝

```markdown
## If repo includes "github.com/your-company/"

# - default branch: main

# - branch naming: feature/JIRA-123-description

# - CI: GitHub Actions, secrets via OIDC
```

---

## Plan Mode

- プランファイルは `$HOME/.claude/plans/` ではなく、現在の作業ディレクトリの `.claude/plans/` に保存すること。
- 保存先例: `{作業ディレクトリ}/.claude/plans/{plan-name}.md`
- プランファイル作成後、自動生成されたランダム名を内容がわかる名前にリネームすること。

---

## Mintlify Index MCP

- ライブラリ固有の API を使うコード生成・実装時は `context` ツールを積極的に使うこと（Mintlify 収録の公式ドキュメントと Web 検索を横断し、出典付きで 1 コールで返る）
- 特に更新頻度の高いライブラリ（Next.js, React, Cloudflare Workers 等）では API シグネチャ確認に優先的に使うこと
- 汎用的なプログラミング質問（アルゴリズム、設計パターン等）では使わないこと
- `product` で対象製品を絞ること。`tokenBudget` は既定の 3000 を使い、複数論点にまたがる調査でのみ 6000 まで上げること
- 返ってきた出典 URL が要件と噛み合わない場合は WebFetch で一次情報を確認すること

---

## メンテナンス指針

- dotfiles 更新時にこのファイルも点検し、不要行を削除・新規禁止パターンを追加。
- ファイルサイズは **50 KB 未満** を目安に維持。大きくなる場合は各リポジトリ側へ移動。

---

## Learned Feedback

<!-- リポジトリ横断で自動収集されるフィードバック。手動編集も可。 -->
- 略称より意味が伝わる名前を優先する
- ユーザーの判断・意見を代弁する内容を書き込む前に、ドラフトを提示して確認を取る（Decision Log・議事録・メモリ等）
- コードコメントは最小限に: コードだけで困る場合のみ。設計経緯・skip理由等のrationaleはPR本文とgit blameに寄せる

