# Global AGENTS for OpenCode

## Security

- Never generate, add, print, or share files matching: `*.pem`, `*.key`, `*.env`, `.env.*`, `config/credentials.yml.enc`, `*secrets*`, `*.p12`, `id_rsa*`, `id_ed25519*`.
- Do not run shell commands that create, modify, delete, or move files outside the current repository without explicit user approval.
- Do not run network-fetching commands such as `curl` or `wget` without explicit user approval.
- Do not push confidential or personal data to public repositories.
- Prefer relative paths in shell commands when operating on repository files.
- Do not chain shell commands with `&&`, `||`, or `;` unless there is no practical alternative.
- Avoid `git -C <path>`; run commands from the target directory instead.
- Do not use `/tmp` or `$TMPDIR` for scratch files by default. If temporary files are needed, keep them under the current repository, such as `./tmp/`.

## Environment

- Assume `fish` shell is the default shell environment on this machine.

## Code Review

- When doing code review, use a dedicated reviewer agent when available.
- Keep review feedback focused on code health and actionable findings.
- Present findings first, ordered by severity, with concrete file and line references.

## Web Access

- Use web search when the user explicitly asks for current information, or when the answer depends on information that may have changed recently.
- Prefer official sources for product, API, library, legal, financial, or operational facts.
- Do not use shell-based network fetch commands such as `curl` or `wget` without explicit user approval.
- For page interaction, debugging, or browser-observable behavior, prefer configured MCP/browser tools over ad-hoc shell fetches.

## MCP Usage Guidance

- Use Context7 when generating implementation that depends on fast-moving library APIs.
- Prefer Context7 for frameworks like Next.js, React, and Cloudflare Workers.
- Skip Context7 for generic algorithm or design discussions.
- Avoid duplicate calls to the same library docs to reduce rate-limit pressure.

## Repository Overrides

- Use repository-level `AGENTS.md` for project-specific workflow, branching, CI, and compliance rules.
