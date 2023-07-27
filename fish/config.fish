# ssh agent
set SSH_AGENT_FILE "$HOME/.ssh/ssh_agent"
test -f $SSH_AGENT_FILE; and source $SSH_AGENT_FILE > /dev/null 2>&1
if not ssh-add -l > /dev/null 2>&1
  if not ps -ef | grep -v grep | grep ssh-agent
    ssh-agent -c > $SSH_AGENT_FILE 2>&1
  end
  source $SSH_AGENT_FILE > /dev/null 2>&1
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    source (nodenv init -|psub)
    source (rbenv init -|psub)
end

# fish_vi_key_bindings
fish_default_key_bindings

# add homebrew path
fish_add_path /opt/homebrew/bin

set fish_function_path $fish_function_path "/usr/share/powerline/bindings/fish"

# ruby
set -Ux RUBYOPT '-W:deprecated'

# date
set -g theme_display_date yes
set -g theme_date_format "+%F %H:%M"

# time
set -g theme_display_cmd_duration yes

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

# abbreviations import
source ~/.config/fish/abbreviations.fish
if test (uname) = "Darwin"
  # ssh key load from apple key chain
  ssh-add --apple-load-keychain

  source ~/.config/fish/abbreviations_macos.fish
end
