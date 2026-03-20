return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Auto-install parsers for these languages
        ensure_installed = {
          "typescript",
          "javascript",
          "tsx",
          "python",
          "rust",
          "go",
          "lua",
          "ruby",
          "html",
          "css",
          "json",
          "terraform",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "bash",
        },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        auto_install = true,

        -- Highlighting
        highlight = {
          enable = true,
          -- Use vim syntax highlighting in addition to treesitter
          additional_vim_regex_highlighting = false,
        },

        -- Indentation
        indent = {
          enable = true,
        },

        -- Incremental selection
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-Space>",
            node_incremental = "<C-Space>",
            scope_incremental = false,
            node_decremental = "<BS>",
          },
        },
      })

      -- Configure treesitter-context (show current function/class at top)
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
        trim_scope = "outer",
        mode = "cursor",
      })
    end,
  },
}
