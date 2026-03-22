return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "biome", stop_after_first = true },
        typescript = { "biome", stop_after_first = true },
        javascriptreact = { "biome", stop_after_first = true },
        typescriptreact = { "biome", stop_after_first = true },
        json = { "biome", stop_after_first = true },
        css = { "biome", stop_after_first = true },
        python = { "ruff_format" },
        lua = { "stylua" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      formatters = {
        shfmt = {
          append_args = { "-i", "2" },
        },
      },
    },
  },
}
