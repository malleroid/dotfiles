return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Configure GitHub Copilot LSP
      vim.lsp.config.copilot = {
        cmd = { "copilot-language-server", "--stdio" },
        filetypes = { "*" },
        root_dir = function()
          return vim.fn.getcwd()
        end,
        single_file_support = true,
        settings = {
          copilot = {
            enable = true,
            -- Request multiple suggestions
            inlineSuggest = {
              enable = true,
              count = 3,  -- Request 3 suggestions
            },
          },
        },
      }

      -- Configure Lua LSP with special settings
      vim.lsp.config.lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }

      -- Enable all language servers
      vim.lsp.enable({
        "copilot",         -- GitHub Copilot
        "vtsls",           -- TypeScript/JavaScript
        "pyright",         -- Python
        "rust_analyzer",   -- Rust
        "gopls",           -- Go
        "lua_ls",          -- Lua
        "ruby_lsp",        -- Ruby
        "html",            -- HTML
        "cssls",           -- CSS
        "jsonls",          -- JSON
        "terraformls",     -- Terraform
      })

      -- LSP Keymaps and Semantic Tokens
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local opts = { buffer = ev.buf }

          -- Enable semantic tokens if supported
          if client and client.server_capabilities.semanticTokensProvider then
            vim.lsp.semantic_tokens.start(ev.buf, client.id)
          end

          -- LSP Keymaps
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format { async = true }
          end, opts)
        end,
      })

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Diagnostic signs
      local signs = { Error = "✘", Warn = "▲", Hint = "⚑", Info = "»" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end
    end,
  },
}
