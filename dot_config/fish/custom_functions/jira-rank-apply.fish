function jira-rank-apply -d "Reorder issues via Jira Agile rank API, in the order they appear in a file"
    argparse 'd/dry-run' 'c/config=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: jira-rank-apply FILE [--dry-run] [--config PATH]"
        echo ""
        echo "Re-rank issues so their relative order matches the order of keys in FILE."
        echo "FILE may be a CSV with a Key/KEY column, or a plain list of issue keys"
        echo "(one per line). The first key is used as the anchor and stays in place;"
        echo "the rest are ranked after it, preserving file order."
        echo ""
        echo "Uses PUT /rest/agile/1.0/issue/rank (max 50 issues per call), chaining"
        echo "each batch after the previous batch's last issue."
        echo ""
        echo "Auth:"
        echo "  server + login are read from jira-cli config"
        echo "  (\$JIRA_CONFIG_FILE, ~/.config/.jira/.config.yml, or ~/.jira/.config.yml)"
        echo "  the API token comes from \$JIRA_API_TOKEN, or macOS keychain"
        echo "  (service 'jira-cli', account = login) — resolved automatically"
        echo ""
        echo "Options:"
        echo "  -d, --dry-run     Print planned rank calls without sending them"
        echo "  -c, --config PATH Explicit jira-cli config path"
        echo "  -h, --help        Show this help"
        return 0
    end

    test (count $argv) -ge 1; or begin
        echo "Error: FILE is required" >&2
        return 1
    end
    set -l file $argv[1]
    test -r $file; or begin
        echo "Error: cannot read $file" >&2
        return 1
    end

    for tool in jq curl python3
        if not type -q $tool
            echo "Error: $tool is required" >&2
            return 1
        end
    end

    # --- resolve auth ---
    set -l base (_jira_rest_base $_flag_config); or return 1
    set -l parts (string split \t -- $base)
    set -l server $parts[1]
    set -l login $parts[2]
    set -l token $parts[3]

    # --- read ordered keys (CSV Key column, or plain key-per-line) ---
    set -l keys (python3 -c '
import csv, sys, re
path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as f:
    rows = list(csv.reader(f))
if not rows:
    sys.exit(0)
header = [c.strip().lower() for c in rows[0]]
key_idx = next((header.index(c) for c in ("key", "issue key") if c in header), None)
if key_idx is not None:
    for r in rows[1:]:
        if len(r) > key_idx:
            v = r[key_idx].strip()
            if v:
                print(v)
else:
    for r in rows:
        if r and re.match(r"^[A-Z][A-Z0-9]+-\d+$", r[0].strip()):
            print(r[0].strip())
' $file)

    if test $status -ne 0
        return 1
    end
    set -l n (count $keys)
    if test $n -lt 2
        echo "Error: need at least 2 keys to rank (got $n)" >&2
        return 1
    end

    echo "Server: $server"
    echo "Login:  $login"
    echo "Keys:   $n (anchor = $keys[1])"
    echo ""

    set -l endpoint "$server/rest/agile/1.0/issue/rank"
    set -l anchor $keys[1]
    set -l i 2
    set -l call 0
    set -l ranked 0

    while test $i -le $n
        set -l j (math "min($i + 49, $n)")
        set -l chunk $keys[$i..$j]
        set -l issues_json (printf '%s\n' $chunk | jq -R . | jq -sc .)
        set -l body (jq -nc --argjson issues "$issues_json" --arg after "$anchor" '{issues: $issues, rankAfterIssue: $after}')
        set call (math $call + 1)

        if set -q _flag_dry_run
            echo "[dry-run] call $call: rank "(count $chunk)" issues after $anchor"
            echo "          PUT $endpoint"
            echo "          body: $body"
        else
            set -l http (curl -s -o /dev/null -w '%{http_code}' -u "$login:$token" \
                -X PUT "$endpoint" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -d "$body")
            if test "$http" = 204
                echo "call $call: ranked "(count $chunk)" issues after $anchor (HTTP $http)"
                set ranked (math $ranked + (count $chunk))
            else
                echo "call $call: FAILED (HTTP $http) after $anchor" >&2
                echo "  body was: $body" >&2
                return 1
            end
        end

        set anchor $chunk[-1]
        set i (math $i + 50)
    end

    echo ""
    if set -q _flag_dry_run
        echo "Dry-run: $call call(s) planned for "(math $n - 1)" issues."
    else
        echo "Done: ranked $ranked issues in $call call(s)."
    end
end
