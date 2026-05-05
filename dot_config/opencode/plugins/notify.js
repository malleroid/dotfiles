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
    return `${session} pane${process.env.ZELLIJ_PANE_ID} `
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
