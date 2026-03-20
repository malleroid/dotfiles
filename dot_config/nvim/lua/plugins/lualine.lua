return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto", -- Automatically matches your colorscheme (tokyonight)
          icons_enabled = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "neo-tree" },
            winbar = {},
          },
          always_divide_middle = true,
          globalstatus = true, -- Single statusline for all windows
        },

        sections = {
          -- Left side
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            "diff",
            {
              "diagnostics",
              sources = { "nvim_lsp" },
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
          },
          lualine_c = {
            {
              "filename",
              path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
              symbols = {
                modified = "[+]",
                readonly = "[-]",
                unnamed = "[No Name]",
              },
            },
          },

          -- Right side
          lualine_x = {
            {
              -- Show active LSP servers
              function()
                local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
                if #buf_clients == 0 then
                  return ""
                end

                local buf_client_names = {}
                for _, client in pairs(buf_clients) do
                  table.insert(buf_client_names, client.name)
                end

                return "[" .. table.concat(buf_client_names, ", ") .. "]"
              end,
              icon = "",
            },
            "encoding",
            "fileformat",
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },

        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },

        tabline = {},
        extensions = { "neo-tree", "lazy" },
      })
    end,
  },
}
