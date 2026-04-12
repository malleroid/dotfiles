return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    config = function()
      require("colorizer").setup({
        user_default_options = {
          names = false,
          css = true,
          tailwind = true,
          mode = "virtualtext",
          virtualtext = "■",
          virtualtext_inline = true,
        },
      })
    end,
  },
}
