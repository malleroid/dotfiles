# Switch the Claude Code account per repository (account-agnostic engine).
#
# How it works:
#   1. Source ~/.config/fish/claude_account.local.fish if present (the real, machine-
#      specific policy is kept off the public dotfiles).
#   2. On every PWD change, resolve the account via __claude_account_for_path and its
#      auth method via __claude_account_auth_method ("login" or "token").
#   3. "login" accounts use the macOS Keychain login (claude auth login) with the env
#      token cleared. "token" accounts inject CLAUDE_CODE_OAUTH_TOKEN from Keychain item
#      claude-<account>. The DEFAULT (no policy / unmapped) is the keychain login.
#
# So the keychain-login account is THIS machine's default/full-scope account; only the
# accounts a policy marks "token" are switched via env. Policy is per-machine.
#
# Setup (per machine):
#   cp ~/.config/fish/claude_account.local.fish.example \
#      ~/.config/fish/claude_account.local.fish   # then edit the policy
#   claude auth login                              # the DEFAULT (login) account
#   # For each "token" account, log into THAT account FIRST, then mint its token:
#   #   claude auth login                          # <account>  (verify with /status!)
#   #   claude setup-token
#   #   security add-generic-password -U -s claude-<account> -a $USER -w
#   # GOTCHA: setup-token mints a token for the CURRENTLY logged-in account.
#   # Finish by logging back into the DEFAULT account so the keychain holds it.

if test -f "$HOME/.config/fish/claude_account.local.fish"
    source "$HOME/.config/fish/claude_account.local.fish"
end

function __claude_account_switch --on-variable PWD
    # Per-machine policy decides account + method. With no policy, fall back to the
    # keychain login (this machine's default full-scope account) and inject no token.
    set -l target ""
    if functions -q __claude_account_for_path
        set target (__claude_account_for_path "$PWD")
    end
    test "$__claude_current_account" = "$target"; and return
    set -g __claude_current_account "$target"
    # Export so child processes (e.g. Claude Code statusLine) can read it.
    set -gx CLAUDE_ACCOUNT (test -n "$target"; and echo "$target"; or echo keychain)

    # Default method = "login" (use the keychain login). A token is injected ONLY for
    # accounts the policy explicitly maps to "token".
    set -l method login
    if test -n "$target"; and functions -q __claude_account_auth_method
        set method (__claude_account_auth_method "$target")
    end

    if test "$method" = token
        set -l token (security find-generic-password -s "claude-$target" -a "$USER" -w 2>/dev/null)
        if test -n "$token"
            set -gx CLAUDE_CODE_OAUTH_TOKEN "$token"
        else
            # token account but no usable token: drop it, fall back to the keychain login.
            set -e CLAUDE_CODE_OAUTH_TOKEN
        end
    else
        # login method (or no policy): use the keychain login; never inject a token.
        set -e CLAUDE_CODE_OAUTH_TOKEN
    end
end

__claude_account_switch
