function jira-csv-apply -d "Apply labels to issues from a CSV with a new_labels column"
    argparse 'a/apply' 'r/reopen-via=' 'c/close-via=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: jira-csv-apply FILE [--apply]"
        echo "       jira-csv-apply FILE --reopen-via TRANSITION --close-via TRANSITION [--apply]"
        echo ""
        echo "Read a CSV that has at least a 'Key' (or 'KEY') column and a"
        echo "'new_labels' column, and append the comma-separated labels in"
        echo "new_labels to each issue via 'jira issue edit -l ...'."
        echo ""
        echo "Empty new_labels rows are skipped."
        echo "Use a leading minus (e.g. -old-label) to remove a label (jira-cli syntax)."
        echo ""
        echo "Args:"
        echo "  FILE                   CSV file (extra columns are ignored)"
        echo ""
        echo "Options:"
        echo "  -a, --apply            Actually apply (default: dry-run)"
        echo "  -r, --reopen-via NAME  Transition name to move out of a terminal state"
        echo "                         before editing (e.g. 'review')"
        echo "  -c, --close-via NAME   Transition name to move back to the terminal state"
        echo "                         after editing (e.g. 'to close')"
        echo "  -h, --help             Show this help"
        echo ""
        echo "When --reopen-via and --close-via are both given, each issue is"
        echo "transitioned with --reopen-via, the labels are edited, then it is"
        echo "transitioned back with --close-via — even if the edit fails, the"
        echo "close-back is still attempted to avoid leaving issues mid-state."
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

    if not type -q python3
        echo "Error: python3 is required" >&2
        return 1
    end

    set -l dry_run yes
    set -q _flag_apply; and set dry_run no

    set -l via_mode no
    if set -q _flag_reopen_via; and set -q _flag_close_via
        set via_mode yes
    else if set -q _flag_reopen_via; or set -q _flag_close_via
        echo "Error: --reopen-via and --close-via must be used together" >&2
        return 1
    end

    set -l pairs (python3 -c '
import csv, sys
path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    fields = [c.strip() for c in (reader.fieldnames or [])]
    def find(*candidates):
        lc = [c.lower() for c in fields]
        for cand in candidates:
            if cand in lc:
                return fields[lc.index(cand)]
        return None
    key_col = find("key", "issue key")
    new_col = find("new_labels", "new labels")
    if not key_col or not new_col:
        sys.stderr.write(f"Error: CSV needs Key and new_labels columns. Found: {fields}\n")
        sys.exit(2)
    for row in reader:
        key = (row.get(key_col) or "").strip()
        new = (row.get(new_col) or "").strip()
        if key and new:
            print(f"{key}\t{new}")
' $file)

    if test $status -ne 0
        return 1
    end

    set -l queued 0
    set -l applied 0
    set -l failed 0
    set -l skipped 0

    if test (count $pairs) -eq 0
        echo "No rows with new_labels found."
        return 0
    end

    for pair in $pairs
        set -l parts (string split -m 1 \t -- $pair)
        set -l key $parts[1]
        set -l new_labels $parts[2]

        set -l labels
        for raw in (string split ',' -- $new_labels)
            set -l trimmed (string trim -- $raw)
            test -z "$trimmed"; and continue
            set -a labels $trimmed
        end

        if test (count $labels) -eq 0
            set skipped (math $skipped + 1)
            continue
        end

        set -l edit_args $key
        for l in $labels
            set -a edit_args -l $l
        end

        if test "$dry_run" = yes
            if test "$via_mode" = yes
                echo "[dry-run] jira issue move $key '$_flag_reopen_via'"
                echo "[dry-run] jira issue edit $edit_args --no-input"
                echo "[dry-run] jira issue move $key '$_flag_close_via'"
            else
                echo "[dry-run] jira issue edit $edit_args --no-input"
            end
            set queued (math $queued + 1)
            continue
        end

        if test "$via_mode" = yes
            if not jira issue move $key "$_flag_reopen_via"
                echo "Failed (reopen): $key — issue not transitioned, skipping edit" >&2
                set failed (math $failed + 1)
                continue
            end

            set -l edit_ok 1
            jira issue edit $edit_args --no-input
            or set edit_ok 0

            if not jira issue move $key "$_flag_close_via"
                echo "WARNING: $key left in reopened state — close-back transition failed" >&2
                set failed (math $failed + 1)
                continue
            end

            if test $edit_ok -eq 1
                set applied (math $applied + 1)
            else
                echo "Edit failed (state restored): $key" >&2
                set failed (math $failed + 1)
            end
        else
            if jira issue edit $edit_args --no-input
                set applied (math $applied + 1)
            else
                set failed (math $failed + 1)
                echo "Failed: $key" >&2
            end
        end
    end

    echo ""
    if test "$dry_run" = yes
        echo "Dry-run: would update $queued issues, skipped $skipped."
        echo "Re-run with --apply to execute."
    else
        echo "Applied: $applied, failed: $failed, skipped: $skipped."
    end
end
