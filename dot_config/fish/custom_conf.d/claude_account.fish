# Switch the Claude Code OAuth token per repository.
#
# How it works:
#   1. Source ~/.config/fish/claude_account.local.fish if present
#      (the real mapping is kept in a separate file, off the public dotfiles).
#   2. Resolve the account name via __claude_account_for_path on every PWD change.
#   3. If the account differs from the previous one, fetch the token from the
#      macOS Keychain and export it as CLAUDE_CODE_OAUTH_TOKEN.
#
# Setup:
#   cp ~/.config/fish/claude_account.local.fish.example \
#      ~/.config/fish/claude_account.local.fish
#   # Edit it to write the mapping.
#
#   claude setup-token   # personal Max
#   security add-generic-password -U -s claude-personal -a $USER -w '<token>'
#   claude logout; claude login   # work Team
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
    # Export so child processes (e.g. Claude Code statusLine) can read it.
    set -gx CLAUDE_ACCOUNT "$target"
    set -l token (security find-generic-password -s "claude-$target" -a "$USER" -w 2>/dev/null)
    if test -n "$token"
        set -gx CLAUDE_CODE_OAUTH_TOKEN "$token"
    else
        # No Keychain item: drop the env var and fall back to the claude login Keychain.
        set -e CLAUDE_CODE_OAUTH_TOKEN
    end
end

__claude_account_switch
