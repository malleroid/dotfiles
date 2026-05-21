function jira-epic-export -d "Export all child issues of an epic to CSV via search/jql (full pagination)"
    argparse 'q/jql=' 'o/output=' 'c/config=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: jira-epic-export EPIC [-o FILE]"
        echo "       jira-epic-export -q 'JQL' [-o FILE]"
        echo ""
        echo "Export issues to CSV (KEY,SUMMARY,LABELS) using GET /rest/api/3/search/jql"
        echo "with nextPageToken pagination, so it is not limited to 100 results."
        echo ""
        echo "Args:"
        echo "  EPIC               Epic key (uses 'parent = EPIC' JQL)"
        echo ""
        echo "Options:"
        echo "  -q, --jql JQL      Custom JQL (overrides EPIC arg)"
        echo "  -o, --output FILE  Output CSV path (default: ./epic-<EPIC>-<YYYYMMDD>.csv)"
        echo "  -c, --config PATH  Explicit jira-cli config path"
        echo "  -h, --help         Show this help"
        echo ""
        echo "Auth: server+login from jira-cli config; token from \$JIRA_API_TOKEN"
        echo "      or macOS keychain (service 'jira-cli', account = login)."
        return 0
    end

    for tool in jq curl python3
        if not type -q $tool
            echo "Error: $tool is required" >&2
            return 1
        end
    end

    set -l jql
    set -l label
    if set -q _flag_jql
        set jql $_flag_jql
        set label custom
    else
        test (count $argv) -ge 1; or begin
            echo "Error: EPIC key or --jql is required" >&2
            return 1
        end
        set jql "parent = $argv[1]"
        set label $argv[1]
    end

    set -l base (_jira_rest_base $_flag_config); or return 1
    set -l parts (string split \t -- $base)
    set -l server $parts[1]
    set -l login $parts[2]
    set -l token $parts[3]

    set -l output
    if set -q _flag_output
        set output $_flag_output
    else
        set output "epic-$label-"(date +%Y%m%d)".csv"
    end

    set -l endpoint "$server/rest/api/3/search/jql"
    set -l accum (mktemp -t jira-export.XXXXXX)
    set -l page_token ""
    set -l total 0

    while true
        set -l page (mktemp -t jira-page.XXXXXX)
        set -l curlargs -s -G "$endpoint" \
            --data-urlencode "jql=$jql" \
            --data-urlencode "fields=summary,labels" \
            --data-urlencode "maxResults=100" \
            -u "$login:$token" \
            -H "Accept: application/json"
        if test -n "$page_token"
            set curlargs $curlargs --data-urlencode "nextPageToken=$page_token"
        end

        curl $curlargs > $page

        if not jq -e '.issues' < $page >/dev/null 2>&1
            echo "Error: unexpected response from $endpoint" >&2
            jq -r '.errorMessages // [] | .[]' < $page >&2 2>/dev/null
            rm -f $page $accum
            return 1
        end

        jq -c '.issues[]?' < $page >> $accum
        set -l count (jq '.issues | length' < $page)
        set total (math $total + $count)
        set -l is_last (jq -r '.isLast // false' < $page)
        set page_token (jq -r '.nextPageToken // ""' < $page)
        rm -f $page

        printf '  fetched %d...\n' $total >&2

        if test "$is_last" = true; or test -z "$page_token"; or test "$page_token" = null
            break
        end
    end

    python3 -c '
import json, csv, sys
accum, out = sys.argv[1], sys.argv[2]
rows = []
with open(accum, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        o = json.loads(line)
        fields = o.get("fields") or {}
        summary = (fields.get("summary") or "").replace("\t"," ").replace("\n"," ").replace("\r"," ")
        labels = ",".join(fields.get("labels") or [])
        rows.append([o.get("key",""), summary, labels])
with open(out, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["KEY","SUMMARY","LABELS"])
    w.writerows(rows)
print(f"wrote {len(rows)} rows")
' $accum $output

    rm -f $accum
    echo "Exported $total issues -> $output"
end
