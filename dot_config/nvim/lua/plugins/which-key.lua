return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")

      wk.setup({
        preset = "modern",
        delay = 200, -- Delay before showing the popup (ms)

        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },

        win = {
          border = "rounded",
          padding = { 1, 2 },
        },
      })

      -- Register key mappings with descriptions
      wk.add({
        -- Leader key groups
        { "<leader>f", group = "Find" },
        { "<leader>ff", desc = "Find files" },
        { "<leader>fg", desc = "Live grep" },
        { "<leader>fb", desc = "Find buffers" },
        { "<leader>fh", desc = "Help tags" },

        { "<leader>e", desc = "Toggle Explorer" },

        { "<leader>g", group = "Git" },
        { "<leader>gs", desc = "Git status" },

        { "<leader>h", group = "Hunk" },
        { "<leader>hs", desc = "Stage hunk" },
        { "<leader>hr", desc = "Reset hunk" },
        { "<leader>hS", desc = "Stage buffer" },
        { "<leader>hu", desc = "Undo stage hunk" },
        { "<leader>hR", desc = "Reset buffer" },
        { "<leader>hp", desc = "Preview hunk" },
        { "<leader>hb", desc = "Blame line" },
        { "<leader>hd", desc = "Diff this" },

        { "<leader>c", group = "Code" },
        { "<leader>ca", desc = "Code action" },

        { "<leader>r", group = "Refactor" },
        { "<leader>rn", desc = "Rename" },

        { "<leader>f", desc = "Format", mode = { "n", "v" } },

        -- LSP Goto operations
        { "g", group = "Goto" },
        { "gd", desc = "Go to definition" },
        { "gi", desc = "Go to implementation" },
        { "gr", desc = "Find references" },

        -- Comment operations
        { "gc", group = "Comment" },
        { "gcc", desc = "Toggle line comment" },
        { "gbc", desc = "Toggle block comment" },
        { "gc", desc = "Comment", mode = "v" },
        { "gb", desc = "Block comment", mode = "v" },

        -- Other important keys
        { "K", desc = "Hover documentation" },
        { "]c", desc = "Next hunk" },
        { "[c", desc = "Previous hunk" },

        -- Visual mode specific
        { mode = "v", { "gc", desc = "Comment selection" } },
        { mode = "v", { "gb", desc = "Block comment selection" } },
      })
    end,
  },
}
