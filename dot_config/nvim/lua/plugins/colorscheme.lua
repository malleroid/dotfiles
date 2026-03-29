return {
  {
    "malleroid/emerald-synth.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme emerald-synth]])
    end,
  },
}
