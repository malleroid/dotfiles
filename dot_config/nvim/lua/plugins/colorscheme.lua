return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        -- Align with Ghostty Cyberdyne palette
        colors.bg = "NONE"
        colors.bg_dark = "NONE"
        colors.bg_sidebar = "NONE"
        colors.bg_float = "NONE"
        colors.green = "#00c172"      -- Cyberdyne green
        colors.green1 = "#00ff92"     -- Cyberdyne foreground green
        colors.cyan = "#6bffdd"       -- Cyberdyne cyan
        colors.red = "#ff8373"        -- Cyberdyne red
        colors.yellow = "#d2a700"     -- Cyberdyne yellow
        colors.blue = "#0071cf"       -- Cyberdyne blue
        colors.magenta = "#ff90fe"    -- Cyberdyne magenta
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },
}
