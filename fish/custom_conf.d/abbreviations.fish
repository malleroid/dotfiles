# abbrs
abbr -a aba 'abbr -a'
abbr -a abe 'abbr -e'
abbr -a abs 'abbr -s'

# bundler
abbr -a be 'TZ="JST-9" bundle exec'
abbr -a bi 'bundle install'

# yarn
abbr -a y 'yarn'

# docker
abbr -a d 'docker'
abbr -a da 'docker attach'
abbr -a dc 'docker compose'
abbr -a dce 'docker compose exec'
abbr -a dcl 'docker compose logs'
abbr -a dcltf 'docker compose logs -tf'
abbr -a dcr 'docker compose restart'
abbr -a de 'docker exec'
abbr -a di 'docker image'
abbr -a dia 'docker image -a'
abbr -a dl 'docker logs'
abbr -a dv 'docker volume'

# lazydocker
abbr -a lad 'lazydocker'

# git
abbr -a g 'git'
abbr -a gad 'git add'
abbr -a gada 'git add -A'
abbr -a gadp 'git add -p'
abbr -a gam 'git commit --amend'
abbr -a gamd 'git commit --amend --date='
abbr -a gfix 'git commit --amend --no-edit'
abbr -a gb 'git branch'
abbr -a gba 'git branch -a'
abbr -a gbd 'git branch -D'
abbr -a gbr 'git branch -r'
abbr -a gbv 'git branch -vv'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gco 'git checkout'
abbr -a gcur 'git symbolic-ref --short HEAD'
abbr -a gd 'git diff'
abbr -a gdc 'git diff --cached'
abbr -a gf 'git fetch'
abbr -a gfp 'git fetch --prune'
abbr -a ggr 'git grep'
abbr -a gl 'git log'
abbr -a glo 'git log --oneline'
abbr -a gll 'git reflog'
abbr -a gmg 'git merge'
abbr -a gmgff 'git merge --ff-only'
abbr -a gmgno 'git merge --no-ff'
abbr -a gopen 'git push -u origin HEAD'
abbr -a gp 'git pull'
abbr -a gpff 'git pull --ff-only'
abbr -a gpick 'git cherry-pick'
abbr -a gps 'git push'
abbr -a gpsd 'git push origin --delete'
abbr -a graph 'git log --graph --date=short --decorate=short --pretty="format:%C(green)%h %C(reset)%cd %C(blue)%cn %C(red)%d %C(reset)%s"'
abbr -a grb 'git rebase'
abbr -a grba 'git rebase --abort'
abbr -a grbi 'git rebase -i HEAD~'
abbr -a grbc 'git rebase --continue'
abbr -a grbd 'git rebase HEAD~1 --committer-date-is-author-date'
abbr -a gs 'git switch'
abbr -a gsc 'git switch -c'
abbr -a gss 'git status'
abbr -a gst 'git stash'
abbr -a gstl 'git stash list'
abbr -a gsta 'git stash apply'
abbr -a gstd 'git stash drop'
abbr -a gstp 'git stash pop'
abbr -a gsts 'git stash save'
abbr -a gstu 'git stash save -u'

# gitui
abbr -a tig 'gitui'

# eza
abbr -a ls 'eza'
abbr -a ll 'eza --icons -alhig'
abbr -a llt 'eza --icons -alhigTL='

# duf
abbr -a df 'duf'

# glances
abbr -a top 'glances'

# httpie
abbr -a curl 'http'

# gping
abbr -a ping 'gping'

# shell
abbr -a c 'clear'
abbr -a gr 'grep --color=auto'

if test (uname) = 'Darwin'
  abbr -a reload 'exec /opt/homebrew/bin/fish -l'
else
  abbr -a reload 'exec /usr/bin/fish -l'
end

# terraform
abbr -a tf 'terraform'

# secure
abbr -a mv 'mv -i'
abbr -a rm 'rm -i'
abbr -a cp 'cp -i'
