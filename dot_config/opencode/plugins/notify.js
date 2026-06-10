export const NotifyPlugin = async () => {
  const notify = (message) => {
    if (process.env.OPENCODE_NOTIFY_DRY_RUN === "1") {
      console.log(message)
      return
    }

    if (typeof Bun === "undefined") return
    Bun.spawn(["say", message], {
      stdout: "ignore",
      stderr: "ignore",
    })
  }

  const paneLabel = () => {
    if (!process.env.ZELLIJ_PANE_ID) return ""
    const session = process.env.ZELLIJ_SESSION_NAME || "zellij"
    const fallback = `${session} pane${process.env.ZELLIJ_PANE_ID} `
    if (typeof Bun === "undefined") return fallback

    try {
      const result = Bun.spawnSync(["zellij", "action", "list-panes", "-t", "-j"], {
        stdout: "pipe",
        stderr: "ignore",
      })
      if (!result.success) return fallback

      const panes = JSON.parse(new TextDecoder().decode(result.stdout))
      const pane = panes.find(
        (item) => !item.is_plugin && item.id === Number(process.env.ZELLIJ_PANE_ID),
      )
      if (!pane) return fallback

      const label = `${session} ${pane.tab_name} ${pane.title}`.replace(/\s+/g, " ").trim()
      return label ? `${label} ` : fallback
    } catch {
      return fallback
    }
  }

  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        notify(`${paneLabel()}check`)
      }

      if (event.type === "session.idle") {
        notify(`${paneLabel()}complete`)
      }
    },
  }
}
