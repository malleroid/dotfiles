function jira-create -d "Create a single Jira issue via jira-cli"
    argparse 'e/epic=' 's/summary=' 'b/body=' 'p/project=' 't/type=' 'y/priority=' 'h/help' 'dry-run' -- $argv
    or begin
        echo "Usage: jira-create -p PROJECT -e EPIC -t TYPE -y PRIORITY -s SUMMARY [-b BODY] [--dry-run]" >&2
        return 1
    end

    if set -q _flag_help
        echo "jira-create - Create a single Jira issue via jira-cli"
        echo ""
        echo "Usage:"
        echo "  jira-create -p PROJECT -e EPIC -t TYPE -y PRIORITY -s SUMMARY [options]"
        echo ""
        echo "Required:"
        echo "  -p, --project   Project key (e.g. MYPROJ)"
        echo "  -e, --epic      Parent Epic key (e.g. MYPROJ-123)"
        echo "  -t, --type      Issue type (e.g. Story, Bug, Task)"
        echo "  -y, --priority  Priority (e.g. High, Medium, Low)"
        echo "  -s, --summary   Issue summary"
        echo ""
        echo "Optional:"
        echo "  -b, --body      Issue description (empty if omitted)"
        echo "      --dry-run   Print command without executing"
        echo "  -h, --help      Show this help"
        return 0
    end

    set -l missing
    set -q _flag_project; or set -a missing "--project (-p)"
    set -q _flag_epic; or set -a missing "--epic (-e)"
    set -q _flag_type; or set -a missing "--type (-t)"
    set -q _flag_priority; or set -a missing "--priority (-y)"
    set -q _flag_summary; or set -a missing "--summary (-s)"

    if test (count $missing) -gt 0
        echo "Error: missing required options: $missing" >&2
        return 1
    end

    set -l cmd jira issue create \
        -p "$_flag_project" \
        -t "$_flag_type" \
        -P "$_flag_epic" \
        -s "$_flag_summary" \
        -y "$_flag_priority" \
        --no-input

    if set -q _flag_body; and test -n "$_flag_body"
        set -a cmd -b "$_flag_body"
    end

    if set -q _flag_dry_run
        echo "[dry-run] $cmd"
        return 0
    end

    echo "Creating: $_flag_summary"
    $cmd
end
