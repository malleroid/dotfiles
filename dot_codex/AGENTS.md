# Global AGENTS for Codex CLI

## Security

- Never generate, add, print, or share files matching: `*.pem`, `*.key`, `*.env`, `.env.*`, `config/credentials.yml.enc`, `*secrets*`, `*.p12`, `id_rsa*`, `id_ed25519*`.
- Do not run shell commands that create, modify, delete, or move files outside the current repository without explicit user approval.
- Do not run network-fetching commands such as `curl` or `wget` without explicit user approval.
- Do not push confidential or personal data to public repositories.
- Prefer relative paths in shell commands when operating on repository files.
- Do not chain shell commands with `&&`, `||`, or `;` unless there is no practical alternative. Use separate tool calls so approvals and audit trails stay precise.
- Avoid `git -C <path>`; run commands from the target directory instead so command-prefix matching stays reliable.
- Do not use `/tmp` or `$TMPDIR` for scratch files by default. If temporary files are needed, keep them under the current repository, such as `./tmp/`.

## Environment

- Assume `fish` shell is the default shell environment on this machine.

## Code Review

- Codex terminology note:
  - Use `agent` for role/configuration concepts (for example `[agents.reviewer]` in `config.toml`).
  - Use `sub-agent` for child threads spawned during multi-agent workflows.
- When doing code review:
  - If multi-agent is enabled and a reviewer role is configured, delegate review tasks to that reviewer agent role.
  - If no reviewer role is configured, perform the review in the current thread.
- Keep review feedback focused on code health and actionable findings.

## Web Access

- Use live web search when the user explicitly asks for current information, or when the answer depends on information that may have changed recently.
- Start Codex with `--search` when live web search is required.
- Prefer official sources for product, API, library, legal, financial, or operational facts.
- Do not use shell-based network fetch commands such as `curl` or `wget` without explicit user approval.
- For page interaction, debugging, or browser-observable behavior, prefer configured MCP/browser tools such as Chrome DevTools or Playwright over ad-hoc shell fetches.

## MCP Usage Guidance

- Use Context7 when generating implementation that depends on fast-moving library APIs.
- Prefer Context7 for frameworks like Next.js, React, and Cloudflare Workers.
- Skip Context7 for generic algorithm or design discussions.
- Avoid duplicate calls to the same library docs to reduce rate-limit pressure.

## Repository Overrides

- Use repository-level `AGENTS.md` for project-specific workflow, branching, CI, and compliance rules.
