# Global Instructions for GitHub Copilot CLI

## Security

- Never generate, add, print, or share files matching: `*.pem`, `*.key`, `*.env`, `.env.*`, `config/credentials.yml.enc`, `*secrets*`, `*.p12`, `id_rsa*`, `id_ed25519*`.
- Do not run shell commands that create, modify, delete, or move files outside the current repository without explicit user approval.
- Do not run network-fetching commands such as `curl` or `wget` without explicit user approval.
- Prefer configured web, browser, URL, or MCP tools over shell-based network fetching.
- Do not push confidential or personal data to public repositories.
- Prefer relative paths in shell commands when operating on repository files.
- Avoid chaining shell commands with `&&`, `||`, or `;` unless there is no practical alternative.
- Avoid shell brace expansion such as `{a,b}` or `{1..10}`. It can expand one-looking command into multiple paths or arguments and bypass command approval intent.
- Avoid `git -C <path>`; run commands from the target directory instead.
- Do not use `/tmp` or `$TMPDIR` for scratch files by default. If temporary files are needed, keep them under the current repository, such as `./tmp/`.

## Environment

- The user's interactive shell is fish.
- When suggesting commands for the user to run manually, prefer fish-compatible syntax.
- The CLI may execute commands through a POSIX shell such as bash. For commands the CLI runs itself, use portable POSIX shell syntax unless the user explicitly asks for fish-specific commands.
- Do not rely on fish-only constructs in executed shell commands unless the command is explicitly intended for the user's interactive fish session.

## Response Source Labels

- Every user-facing response (including short acknowledgements) must start with a source label on the first line.
- Labels:
  - 🔍 **investigated**: Main claims are backed by tools called in this turn (Read / Grep / Bash / WebFetch / Context7 etc.).
  - 💭 **inferred**: Based on training-data recall, logical inference, code generation, opinion, or simple acknowledgement. No tool calls in this turn, or tool results unrelated to the claims.
  - 🔍💭 **mixed**: Both. Append an inline marker (🔍 / 💭) to each individual claim so the reader can tell them apart.
- Decision flow:
  1. Did this turn call any tools? No → 💭. Yes → step 2.
  2. Are the main claims backed by tool results? All → 🔍. Some → 🔍💭 (inline markers required). Unrelated → 💭.
  3. Anywhere the response includes opinion, recommendation, or synthesized code, mark that part 💭.
- Example (mixed):

  ```
  🔍💭 mixed

  - `foo.ts` is 200 lines and exports `bar()` 🔍
  - Splitting it into `util/` would be cleaner 💭
  ```

- For pure 🔍 or 💭 responses, inline markers can be omitted.
- Responses without labels are not allowed. Turns that only run tools and emit no user-facing text do not need a label.
- The label is self-reported, not a guarantee — it helps the user calibrate trust quickly, but they should still verify when stakes are high.

## Code Review

- When doing code review, use the `reviewer` agent if it is available.
- Do not collect or rewrite review context in the parent session before invoking the reviewer agent. Pass the user request through directly.
- Keep review feedback focused on code health and actionable findings.
- Prioritize bugs, security risks, behavioral regressions, and missing tests.
- Present findings first, ordered by severity, with file and line references when available.
- If no issues are found, say so clearly and mention any residual testing gaps or risk.

## Planning

- Keep plan files inside the current repository, not under `$HOME/.copilot/`.
- Prefer `.copilot/plans/` for saved plans.
- Rename generated plan files to descriptive names after creation.

## Web Access

- Use web, URL, browser, or MCP tools when the user explicitly asks for current information or when the answer depends on facts that may have changed recently.
- Prefer official sources for product, API, library, legal, financial, or operational facts.
- For page interaction, debugging, or browser-observable behavior, prefer configured browser or MCP tools over ad-hoc shell fetches.

## MCP Usage

- Use configured MCP tools when they provide more reliable context than ad-hoc shell or web access.
- Use Context7 when implementation depends on fast-moving library APIs.
- Prefer Context7 for frameworks like Next.js, React, and Cloudflare Workers.
- Skip Context7 for generic algorithm or design discussions.
- Avoid duplicate calls to the same library docs to reduce rate-limit pressure.

## Repository Overrides

- Use repository-level `AGENTS.md`, `.github/copilot-instructions.md`, and `.github/instructions/**/*.instructions.md` for project-specific workflow, branching, CI, and compliance rules.
