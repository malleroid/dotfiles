const sensitivePathPatterns = [
  /\.pem$/,
  /\.key$/,
  /\.env$/,
  /\.env\./,
  /credentials\.yml\.enc$/,
  /(^|\/)\.?secrets\.(json|ya?ml|env|txt|csv|toml|ini|cfg|conf|properties)$/,
  /\.p12$/,
  /(^|\/)id_rsa/,
  /(^|\/)id_ed25519/,
]

const requiresConfirmation = [
  /(^|\s)gh\s+api\s+.*(--method|-X)\s*(DELETE|PATCH|POST|PUT)(\s|$)/,
  /(^|\s)gh\s+pr\s+create(\s|$)/,
  /(^|\s)gh\s+release\s+(create|delete|upload)(\s|$)/,
  /(^|\s)gh\s+repo\s+(archive|delete|rename|transfer|unarchive)(\s|$)/,
  /(^|\s)gh\s+run\s+rerun(\s|$)/,
  /(^|\s)gh\s+secret\s+(delete|set)(\s|$)/,
  /(^|\s)gh\s+variable\s+(delete|set)(\s|$)/,
  /(^|\s)gh\s+workflow\s+(disable|enable|run)(\s|$)/,
  /(^|\s)git\s+commit\s+.*--amend/,
  /(^|\s)git\s+commit\s+.*--allow-empty/,
  /(^|\s)git\s+commit\s+.*--no-verify/,
  /(^|\s)git\s+push(\s|$)/,
  /(^|\s)git\s+reset(\s|$)/,
]

const normalizePath = (path, root) => {
  if (!path) return ""
  const base = root.replace(/\/+$/, "")
  const absolute = path.startsWith("/") ? path : `${base}/${path}`
  const parts = []

  for (const part of absolute.split("/")) {
    if (!part || part === ".") continue
    if (part === "..") {
      parts.pop()
      continue
    }
    parts.push(part)
  }

  return `/${parts.join("/")}`
}

const isInside = (path, root) => {
  const normalizedPath = normalizePath(path, root)
  const normalizedRoot = normalizePath(root, root)
  return normalizedPath === normalizedRoot || normalizedPath.startsWith(`${normalizedRoot}/`)
}

const block = (message) => {
  throw new Error(message)
}

export const SafetyGuardsPlugin = async ({ worktree, directory }) => {
  const projectRoot = worktree || directory

  return {
    "tool.execute.before": async (input, output) => {
      const args = output.args || {}

      if (input.tool === "bash") {
        const command = args.command || ""
        if (!command) return

        if (/(^|\s)git\s+-C(\s|$)/.test(command)) {
          block(`Blocked: git -C is prohibited.\nCommand: ${command}\nRun the command from the target directory instead.`)
        }

        if (/(^|\s)gh\s+pr\s+merge(\s|$)/.test(command)) {
          block(`Blocked: gh pr merge is prohibited.\nCommand: ${command}\nMerge pull requests outside OpenCode, or change this guard intentionally.`)
        }

        if (/(^|\s)git\s+push\s+.*(-f(\s|$)|--force(\s|$))/.test(command)) {
          if (process.env.OPENCODE_CONFIRM_DANGEROUS_COMMAND === "1") return
          block(`Blocked: force push detected.\nCommand: ${command}\nAfter user approval, rerun with OPENCODE_CONFIRM_DANGEROUS_COMMAND=1.`)
        }

        if (requiresConfirmation.some((pattern) => pattern.test(command))) {
          if (process.env.OPENCODE_CONFIRM_DANGEROUS_COMMAND === "1") return
          block(`Blocked: command requires explicit confirmation.\nCommand: ${command}\nAfter user approval, rerun with OPENCODE_CONFIRM_DANGEROUS_COMMAND=1.`)
        }
      }

      const candidatePaths = [
        args.filePath,
        args.path,
        args.targetPath,
        args.oldPath,
        args.newPath,
      ].filter(Boolean)

      for (const path of candidatePaths) {
        if (sensitivePathPatterns.some((pattern) => pattern.test(path))) {
          block(`Blocked: sensitive file detected.\nPath: ${path}`)
        }

        if (projectRoot && !isInside(path, projectRoot)) {
          block(`Blocked: file operation outside project directory.\nPath: ${path}\nProject: ${projectRoot}`)
        }
      }
    },
  }
}
