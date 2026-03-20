return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      local npairs = require("nvim-autopairs")

      npairs.setup({
        check_ts = true, -- Enable treesitter integration
        ts_config = {
          lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
          javascript = { "template_string" }, -- Don't add pairs in javascript template_string
          java = false, -- Don't check treesitter on java
        },

        -- Disable for certain filetypes
        disable_filetype = { "TelescopePrompt", "vim" },

        -- Disable when recording or executing a macro
        disable_in_macro = true,

        -- Disable when inserting after a word character
        disable_in_visualblock = false,

        -- Disable when moving inside text
        disable_in_replace_mode = true,

        -- Add spaces between parentheses
        -- (|) -> ( | )
        enable_moveright = true,

        -- Use treesitter to check for a pair
        enable_check_bracket_line = true,

        -- Don't add pairs if it's already has a close pair in the same line
        enable_bracket_in_quote = true,

        -- Move right past closing pair when typing closing character
        -- Example: typing ) when next char is )
        -- Before: (hello|)
        -- After: (hello)|
        enable_afterquote = true,

        -- Map <CR> to confirm completion and auto-insert pairs
        map_cr = false, -- We handle this in blink.cmp

        -- Map <BS> to delete pairs
        map_bs = true,

        -- Map <C-h> to delete pairs (same as <BS>)
        map_c_h = false,

        -- Map <C-w> to delete a pair if possible
        map_c_w = false,
      })

      -- Integration with blink.cmp
      -- This will insert `()` after selecting a function/method item
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("blink.cmp")

      -- Add parentheses after selecting function or method item
      cmp.on_accept = function(item)
        -- Check if the item is a function or method
        if item.kind == "Function" or item.kind == "Method" then
          -- Trigger autopairs
          cmp_autopairs.on_confirm_done()(item)
        end
      end
    end,
  },
}
