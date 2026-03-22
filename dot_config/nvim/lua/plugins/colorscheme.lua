return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      colors = {
        -- Ghostty Cyberdyne palette
        bg = "#151144",
        bg_alt = "#080808",
        bg_highlight = "#454d96",
        fg = "#00ff92",
        grey = "#2e2e2e",
        blue = "#0071cf",
        green = "#00c172",
        cyan = "#6bffdd",
        red = "#ff8373",
        yellow = "#d2a700",
        magenta = "#ff90fe",
        pink = "#ffb2fe",
        orange = "#ffc4be",
        purple = "#e6e7fe",
      },
    },
    config = function(_, opts)
      require("cyberdream").setup(opts)
      vim.cmd([[colorscheme cyberdream]])
    end,
  },
}
