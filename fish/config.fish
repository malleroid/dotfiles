# custom config import
for file in ~/.config/fish/custom_conf.d/*.fish
    source $file
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    source (nodenv init -|psub)
    source (rbenv init -|psub)
end

# fish_vi_key_bindings
fish_default_key_bindings

set fish_function_path $fish_function_path "/usr/share/powerline/bindings/fish"

# path
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths

# ruby
set -Ux RUBYOPT '-W:deprecated'

# date
set -g theme_display_date yes
set -g theme_date_format "+%F %H:%M"

# time
set -g theme_display_cmd_duration yes

# editor
set -x VISUAL nvim
set -x EDITOR nvim

# git
set -g theme_display_git_master_branch yes

# header
set -g theme_title_display_user no
set -g theme_title_display_process yes
set -g theme_title_display_path no

# color
set -g theme_color_scheme dracula

# Starship
starship init fish | source

# z
set -U Z_CMD j

# the fuck
thefuck --alias | source

if test (uname) = "Darwin"
  # add homebrew path
  fish_add_path /opt/homebrew/bin

  # mysql client path
  # fish_add_path /opt/homebrew/opt/mysql-client/bin

  # set -gx LDFLAGS "-L/opt/homebrew/opt/mysql-client/lib"
  # set -gx CPPFLAGS "-I/opt/homebrew/opt/mysql-client/include"

  # set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/mysql-client/lib/pkgconfig"
end
