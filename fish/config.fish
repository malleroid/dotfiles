# ssh agent
set SSH_AGENT_FILE "$HOME/.ssh/ssh_agent"
test -f $SSH_AGENT_FILE; and source $SSH_AGENT_FILE > /dev/null 2>&1
if not ssh-add -l > /dev/null 2>&1
  if not ps -ef | grep -v grep | grep ssh-agent
    ssh-agent -c > $SSH_AGENT_FILE 2>&1
  end
  source $SSH_AGENT_FILE > /dev/null 2>&1
  find $HOME/.ssh -name id_rsa | xargs ssh-add
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
end

# fish_vi_key_bindings
fish_default_key_bindings

set fish_function_path $fish_function_path "/usr/share/powerline/bindings/fish"

# fonts
powerline-setup

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
