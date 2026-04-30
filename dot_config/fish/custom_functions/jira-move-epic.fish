function jira-move-epic -d "Move all issues from one epic to another via jira-cli"
    argparse 'f/from=' 't/to=' 'y/yes' 'h/help' 'dry-run' -- $argv
    or begin
        echo "Usage: jira-move-epic -f FROM_EPIC -t TO_EPIC [--dry-run] [-y]" >&2
        return 1
    end

    if set -q _flag_help
        echo "jira-move-epic - Move all issues under FROM_EPIC to TO_EPIC"
        echo ""
        echo "Usage:"
        echo "  jira-move-epic -f FROM_EPIC -t TO_EPIC [options]"
        echo ""
        echo "Required:"
        echo "  -f, --from   Source epic key (e.g. PROJ-123)"
        echo "  -t, --to     Target epic key (e.g. PROJ-456)"
        echo ""
        echo "Optional:"
        echo "      --dry-run   List issues that would be moved without changes"
        echo "  -y, --yes       Skip confirmation prompt"
        echo "  -h, --help      Show this help"
        return 0
    end

    set -l missing
    set -q _flag_from; or set -a missing "--from (-f)"
    set -q _flag_to; or set -a missing "--to (-t)"

    if test (count $missing) -gt 0
        echo "Error: missing required options: $missing" >&2
        return 1
    end

    if test "$_flag_from" = "$_flag_to"
        echo "Error: --from and --to must differ" >&2
        return 1
    end

    echo "Fetching issues under $_flag_from..."
    set -l rows (jira epic list "$_flag_from" --plain --no-headers --no-truncate --columns KEY,TYPE,STATUS,SUMMARY --paginate 0:100)

    set -l keys
    for row in $rows
        set -l parts (string split -m1 \t -- $row)
        if test -n "$parts[1]"
            set -a keys $parts[1]
        end
    end

    set -l total (count $keys)
    if test $total -eq 0
        echo "No issues found under $_flag_from. Nothing to do."
        return 0
    end

    echo ""
    echo "Issues under $_flag_from ($total):"
    for row in $rows
        echo "  $row"
    end
    echo ""

    if test $total -ge 100
        echo "Warning: hit pagination limit of 100. There may be more issues; rerun after this batch." >&2
    end

    set -l chunk_size 50

    if set -q _flag_dry_run
        echo "[dry-run] Would run:"
        set -l i 1
        while test $i -le $total
            set -l j (math "$i + $chunk_size - 1")
            test $j -gt $total; and set j $total
            echo "  jira epic add $_flag_to $keys[$i..$j]"
            set i (math $j + 1)
        end
        return 0
    end

    if not set -q _flag_yes
        read -l -P "Move $total issue(s) from $_flag_from to $_flag_to? [y/N] " confirm
        if not string match -rqi '^y(es)?$' -- $confirm
            echo "Aborted."
            return 1
        end
    end

    set -l moved 0
    set -l i 1
    while test $i -le $total
        set -l j (math "$i + $chunk_size - 1")
        test $j -gt $total; and set j $total
        set -l chunk $keys[$i..$j]
        echo "Adding "(count $chunk)" issue(s) to $_flag_to..."
        jira epic add "$_flag_to" $chunk
        or begin
            echo "Error: jira epic add failed at chunk starting $keys[$i]" >&2
            return 1
        end
        set moved (math $moved + (count $chunk))
        set i (math $j + 1)
    end

    echo "Done. Moved $moved issue(s) from $_flag_from to $_flag_to."
end
