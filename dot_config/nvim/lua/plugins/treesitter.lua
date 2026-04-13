return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
      local parsers = {
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
      }

      -- Install parsers (install is idempotent and async)
      local nts = require("nvim-treesitter")
      nts.install(parsers)

      -- Start treesitter highlighting on FileType (replaces highlight = { enable = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterStart", {}),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            pcall(vim.treesitter.start, args.buf, lang)
            -- Indentation based on treesitter
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
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
