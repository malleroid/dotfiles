return {
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("Comment").setup({
        -- Add a space between comment and the line
        padding = true,

        -- Whether the cursor should stay at its position
        sticky = true,

        -- Lines to be ignored while (un)comment
        ignore = "^$", -- Ignore empty lines

        -- LHS of toggle mappings in NORMAL mode
        toggler = {
          line = "gcc", -- Line-comment toggle keymap
          block = "gbc", -- Block-comment toggle keymap
        },

        -- LHS of operator-pending mappings in NORMAL and VISUAL mode
        opleader = {
          line = "gc", -- Line-comment keymap
          block = "gb", -- Block-comment keymap
        },

        -- LHS of extra mappings
        extra = {
          above = "gcO", -- Add comment on the line above
          below = "gco", -- Add comment on the line below
          eol = "gcA", -- Add comment at the end of line
        },

        -- Enable keybindings
        -- NOTE: If given `false` then the plugin won't create any mappings
        mappings = {
          basic = true,
          extra = true,
        },

        -- Function to call before (un)comment
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),

        -- Function to call after (un)comment
        post_hook = nil,
      })
    end,
  },
  {
    -- Treesitter integration for context-aware commenting
    "JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      enable_autocmd = false, -- We handle it via Comment.nvim pre_hook
    },
  },
}
