function jira-batch-create -d "Batch create Jira issues from a JSON file via jira-cli"
    argparse 'e/epic=' 'p/project=' 't/type=' 'y/priority=' 'h/help' 'dry-run' -- $argv
    or begin
        echo "Usage: jira-batch-create -p PROJECT -e EPIC -t TYPE -y PRIORITY tasks.json [--dry-run]" >&2
        return 1
    end

    if set -q _flag_help
        echo "jira-batch-create - Batch create Jira issues from a JSON file"
        echo ""
        echo "Usage:"
        echo "  jira-batch-create -p PROJECT -e EPIC -t TYPE -y PRIORITY tasks.json [options]"
        echo ""
        echo "Required:"
        echo "  -p, --project   Project key (e.g. MYPROJ)"
        echo "  -e, --epic      Parent Epic key (e.g. MYPROJ-123)"
        echo "  -t, --type      Default issue type (e.g. Story, Bug, Task)"
        echo "  -y, --priority  Default priority (e.g. High, Medium, Low)"
        echo "  tasks.json      Task definition JSON file"
        echo ""
        echo "Optional:"
        echo "      --dry-run   Print commands without executing"
        echo "  -h, --help      Show this help"
        echo ""
        echo "JSON format:"
        echo '  [{"summary": "...", "body": "...", "type": "...", "priority": "..."}]'
        echo '  type, priority are optional (falls back to CLI args)'
        return 0
    end

    set -l missing
    set -q _flag_project; or set -a missing "--project (-p)"
    set -q _flag_epic; or set -a missing "--epic (-e)"
    set -q _flag_type; or set -a missing "--type (-t)"
    set -q _flag_priority; or set -a missing "--priority (-y)"

    if test (count $missing) -gt 0
        echo "Error: missing required options: $missing" >&2
        return 1
    end

    set -l json_file $argv[1]
    if not test -f "$json_file"
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    end

    if not jq empty "$json_file" 2>/dev/null
        echo "Error: failed to parse JSON: $json_file" >&2
        return 1
    end

    set -l count (jq 'length' "$json_file")
    echo "Creating $count issues under $_flag_epic ..."
    echo ""

    set -l created 0
    set -l failed 0

    for i in (seq 0 (math $count - 1))
        set -l summary (jq -r ".[$i].summary" "$json_file")
        set -l body (jq -r ".[$i].body // \"\"" "$json_file")
        set -l type (jq -r ".[$i].type // \"\"" "$json_file")
        set -l priority (jq -r ".[$i].priority // \"\"" "$json_file")

        test -z "$type"; and set type $_flag_type
        test -z "$priority"; and set priority $_flag_priority

        set -l cmd jira issue create \
            -p "$_flag_project" \
            -t "$type" \
            -P "$_flag_epic" \
            -s "$summary" \
            -y "$priority" \
            --no-input

        if test -n "$body"
            set -a cmd -b "$body"
        end

        if set -q _flag_dry_run
            echo "[$i] [dry-run] $cmd"
            continue
        end

        echo "[$i] Creating: $summary"
        if $cmd
            set created (math $created + 1)
        else
            set failed (math $failed + 1)
            echo "    ^ Failed!" >&2
        end
        echo ""
    end

    if not set -q _flag_dry_run
        echo "Done: $created created, $failed failed"
    end
end
