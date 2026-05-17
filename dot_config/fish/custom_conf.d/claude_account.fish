# Claude Code OAuth token を repo 単位で切り替える
#
# 仕組み:
#   1. ~/.config/fish/claude_account.local.fish があれば source
#      （実マッピングは public dotfiles に乗せたくないため別ファイル化）
#   2. PWD 変化のたびに __claude_account_for_path で account 名を解決
#   3. 直前と異なる account なら macOS Keychain からトークンを取得し
#      CLAUDE_CODE_OAUTH_TOKEN に export
#
# セットアップ:
#   cp ~/.config/fish/claude_account.local.fish.example \
#      ~/.config/fish/claude_account.local.fish
#   # 編集してマッピングを書く
#
#   claude setup-token   # 個人 Max
#   security add-generic-password -U -s claude-personal -a $USER -w '<token>'
#   claude logout; claude login   # 会社 Team
#   claude setup-token
#   security add-generic-password -U -s claude-work -a $USER -w '<token>'

if test -f "$HOME/.config/fish/claude_account.local.fish"
    source "$HOME/.config/fish/claude_account.local.fish"
end

function __claude_account_switch --on-variable PWD
    set -l target personal
    if functions -q __claude_account_for_path
        set target (__claude_account_for_path "$PWD")
    end
    test "$__claude_current_account" = "$target"; and return
    set -g __claude_current_account "$target"
    set -l token (security find-generic-password -s "claude-$target" -a "$USER" -w 2>/dev/null)
    if test -n "$token"
        set -gx CLAUDE_CODE_OAUTH_TOKEN "$token"
    else
        # Keychain item が無ければ env var を外して claude login の Keychain にフォールバック
        set -e CLAUDE_CODE_OAUTH_TOKEN
    end
end

__claude_account_switch
