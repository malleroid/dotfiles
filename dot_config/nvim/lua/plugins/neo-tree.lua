return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,

        default_component_configs = {
          git_status = {
            symbols = {
              added     = "✚",
              modified  = "✹",
              deleted   = "✖",
              renamed   = "➜",
              untracked = "★",
              ignored   = "◌",
              unstaged  = "✗",
              staged    = "✓",
              conflict  = "",
            },
          },
        },

        window = {
          position = "left",
          width = 30,
        },

        filesystem = {
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },

        git_status = {
          window = {
            position = "left",
          },
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
      vim.keymap.set("n", "<leader>gs", ":Neotree git_status<CR>", { desc = "Git status" })
      vim.keymap.set("n", "<leader>bf", ":Neotree buffers<CR>", { desc = "Buffers" })
    end,
  },
}
