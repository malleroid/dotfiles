local function field_under_cursor(line, delimiter)
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local field_start = (line:sub(1, col):match(".*()" .. delimiter) or 0) + 1
  local next_delimiter = line:sub(col):find(delimiter)
  local field_end = next_delimiter and (col + next_delimiter - 2) or #line

  return line:sub(field_start, field_end)
end

local function open_url_in_field(delimiter)
  local field = field_under_cursor(vim.api.nvim_get_current_line(), delimiter)
  local url = field:match("https?://[%w%-%._~:/%?#%[%]@!$&'()*+,;=%%]+")

  if url then
    vim.ui.open(url)
  else
    vim.notify("No URL in current field", vim.log.levels.WARN)
  end
end

local function setup_buffer_keymaps(bufnr, delimiter)
  vim.keymap.set("n", "<leader>ou", function()
    open_url_in_field(delimiter)
  end, { buffer = bufnr, desc = "Open URL in current field" })
end

return {
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
    opts = {
      parser = {
        delimiter = {
          ft = {
            csv = ",",
            tsv = "\t",
          },
          fallbacks = { ",", "\t", ";", "|" },
        },
      },
      view = {
        display_mode = "border",
        header_lnum = true,
        sticky_header = {
          enabled = true,
        },
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
      },
    },
    config = function(_, opts)
      require("csvview").setup(opts)

      local function enable_csvview(bufnr)
        vim.bo[bufnr].expandtab = false
        vim.wo.wrap = false
        vim.cmd("CsvViewEnable display_mode=border")
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function(args)
          enable_csvview(args.buf)
          setup_buffer_keymaps(args.buf, vim.bo[args.buf].filetype == "tsv" and "\t" or ",")
        end,
      })

      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.bo[bufnr].filetype
      if filetype == "csv" or filetype == "tsv" then
        enable_csvview(bufnr)
        setup_buffer_keymaps(bufnr, filetype == "tsv" and "\t" or ",")
      end
    end,
  },
}
