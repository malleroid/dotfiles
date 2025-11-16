return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    -- priority = 1000: fastest colorscheme load
    priority = 1000,
    -- config: after loading the plugin, set the colorscheme
    config = function()
      -- style option: "storm", "moon", "night", "day"
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },
}
