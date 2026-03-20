-- Neovim basic options
-- Plugin-independent core editor settings

-- ========================================
-- Display Settings
-- ========================================

-- Enable 24-bit RGB color in the TUI
-- Required for modern colorschemes
vim.opt.termguicolors = true

-- Show line numbers
vim.opt.number = true

-- Show relative line numbers
-- Useful for motion commands: 5j to jump 5 lines down, etc.
vim.opt.relativenumber = true

-- Highlight the current line
vim.opt.cursorline = true

-- Command line height
vim.opt.cmdheight = 1

-- Don't wrap lines at screen edge
vim.opt.wrap = false

-- Always show sign column (for git, LSP diagnostics, etc.)
vim.opt.signcolumn = "yes"

-- ========================================
-- Editing Settings
-- ========================================

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Set tab width to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

-- Auto indent
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Sync clipboard with OS
vim.opt.clipboard = "unnamedplus"

-- Enable mouse support
vim.opt.mouse = "a"

-- ========================================
-- Search Settings
-- ========================================

-- Case-insensitive search
vim.opt.ignorecase = true

-- Case-sensitive when search contains uppercase
vim.opt.smartcase = true

-- Highlight search results
vim.opt.hlsearch = true

-- Incremental search (search as you type)
vim.opt.incsearch = true

-- ========================================
-- File & Backup Settings
-- ========================================

-- Don't create swap files
vim.opt.swapfile = false

-- Don't create backup files
vim.opt.backup = false

-- Enable persistent undo
vim.opt.undofile = true

-- ========================================
-- Performance Settings
-- ========================================

-- Faster update time (default: 4000ms)
-- Improves git signs and LSP diagnostics responsiveness
vim.opt.updatetime = 250

-- Time to wait for mapped sequence
vim.opt.timeoutlen = 300

-- ========================================
-- Misc
-- ========================================

-- Split windows to right/below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Completion menu height
vim.opt.pumheight = 10

-- Scroll offset (keep cursor away from edge)
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
