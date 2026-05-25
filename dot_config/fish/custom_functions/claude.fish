function claude -d "Launch Claude Code, re-syncing the per-repo account token first"
    # Re-derive the account for the current directory at launch time, so a stale inherited
    # CLAUDE_CODE_OAUTH_TOKEN cannot leak the wrong account into the session.
    if functions -q __claude_account_switch
        set -e __claude_current_account
        __claude_account_switch
    end
    command claude $argv
end
