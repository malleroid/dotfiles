local wezterm = require 'wezterm';

local config = {};

config.color_scheme = "iceberg-dark";
config.window_background_opacity = 0.80;
config.scrollback_lines = 100000;

-- keys
config.keys = require("keybinds").keys;
config.key_tables = require("keybinds").key_tables;

return config;
