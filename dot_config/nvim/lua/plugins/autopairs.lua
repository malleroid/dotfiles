return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        java = false,
      },
      disable_filetype = { "TelescopePrompt", "vim" },
      disable_in_macro = true,
      disable_in_visualblock = false,
      disable_in_replace_mode = true,
      enable_moveright = true,
      enable_check_bracket_line = true,
      enable_bracket_in_quote = true,
      enable_afterquote = true,
      map_cr = false,
      map_bs = true,
      map_c_h = false,
      map_c_w = false,
    },
  },
}
