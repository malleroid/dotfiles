#!/usr/bin/env bash
# Block shell syntax that can hide multiple commands, paths, or arguments.
#
# This is a heuristic speed-bump, not a sandbox. It deliberately does NOT
# catch every way to run hidden code or escape the repo; the following are
# known, accepted limitations and remain governed by CLAUDE.md rules:
#   - Inline execution via interpreters: `bash -c '...'`, `sh -c`, and other
#     languages (`python -c`, `node -e`, `perl -e`, `eval`, `source`).
#   - Here-documents fed to an interpreter (`bash <<EOF` runs the body).
#   - Wrapper prefixes that hide the interpreter (`env bash -c`, `xargs sh`,
#     `VAR=x bash -c`) and command substitution / base64-decoded pipelines.
#   - Here-doc terminators with characters outside [A-Za-z0-9_.-] may be
#     mis-parsed, causing the body scan to over-skip.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

block() {
  local reason="$1"
  echo "Blocked: prohibited shell syntax detected." >&2
  echo "Reason: $reason" >&2
  echo "Command: $COMMAND" >&2
  echo "Per CLAUDE.md security rules, split the operation into separate Bash tool calls." >&2
  exit 2
}

check_command() {
  local command="$1"
  local len=${#command}
  local i=0
  local c next prev
  local state="normal"
  local brace_content j d
  local q dc tc delim target line trimmed
  local heredoc_delims=()

  while [ "$i" -lt "$len" ]; do
    c="${command:i:1}"

    case "$state" in
      single)
        if [ "$c" = "'" ]; then
          state="normal"
        fi
        i=$((i + 1))
        continue
        ;;
      double)
        if [ "$c" = "\\" ]; then
          i=$((i + 2))
          continue
        fi
        if [ "$c" = '"' ]; then
          state="normal"
        fi
        i=$((i + 1))
        continue
        ;;
    esac

    case "$c" in
      "'")
        state="single"
        i=$((i + 1))
        continue
        ;;
      '"')
        state="double"
        i=$((i + 1))
        continue
        ;;
      "\\")
        i=$((i + 2))
        continue
        ;;
      $'\n')
        # A bare newline separates commands. Inside a here-document body it
        # does not, so when terminators are pending we skip the body lines
        # until each delimiter is matched.
        if [ "${#heredoc_delims[@]}" -eq 0 ]; then
          block "newline command separator is prohibited"
        fi
        i=$((i + 1))
        while [ "${#heredoc_delims[@]}" -gt 0 ] && [ "$i" -lt "$len" ]; do
          line=""
          while [ "$i" -lt "$len" ] && [ "${command:i:1}" != $'\n' ]; do
            line="${line}${command:i:1}"
            i=$((i + 1))
          done
          # <<- strips leading tabs from the terminator; allow leading
          # whitespace when matching to cover that case.
          trimmed="${line#"${line%%[![:space:]]*}"}"
          if [ "$line" = "${heredoc_delims[0]}" ] || [ "$trimmed" = "${heredoc_delims[0]}" ]; then
            heredoc_delims=("${heredoc_delims[@]:1}")
          fi
          if [ "$i" -lt "$len" ]; then
            i=$((i + 1))
          fi
        done
        continue
        ;;
      ";")
        block "semicolon command separator is prohibited"
        ;;
      "|")
        block "pipe and logical-or operators are prohibited"
        ;;
      "&")
        next="${command:i+1:1}"
        if [ "$next" = "&" ]; then
          block "logical-and operator is prohibited"
        fi
        prev=""
        if [ "$i" -gt 0 ]; then
          prev="${command:i-1:1}"
        fi
        # Allow fd-duplication / combined redirects (2>&1, >&2, <&-, &>file).
        # Any other & is a background-execution separator.
        if [[ "$next" != ">" && "$prev" != ">" && "$prev" != "<" ]]; then
          block "background execution (&) is prohibited"
        fi
        ;;
      "<")
        next="${command:i+1:1}"
        if [ "$next" = "(" ]; then
          block "process substitution is prohibited"
        fi
        if [ "$next" = "<" ]; then
          # Here-string (<<<) carries no body; skip the operator only.
          if [ "${command:i+2:1}" = "<" ]; then
            i=$((i + 3))
            continue
          fi
          # Here-document: capture the terminator word so newline handling
          # can skip its body. The rest of the opener line is still scanned.
          j=$((i + 2))
          if [ "${command:j:1}" = "-" ]; then
            j=$((j + 1))
          fi
          while [ "$j" -lt "$len" ] && [[ "${command:j:1}" =~ [[:space:]] ]]; do
            j=$((j + 1))
          done
          q=""
          case "${command:j:1}" in
            "'"|'"')
              q="${command:j:1}"
              j=$((j + 1))
              ;;
          esac
          delim=""
          while [ "$j" -lt "$len" ]; do
            dc="${command:j:1}"
            if [ -n "$q" ]; then
              if [ "$dc" = "$q" ]; then
                j=$((j + 1))
                break
              fi
            else
              case "$dc" in
                [A-Za-z0-9_]) ;;
                *) break ;;
              esac
            fi
            delim="${delim}${dc}"
            j=$((j + 1))
          done
          if [ -n "$delim" ]; then
            heredoc_delims+=("$delim")
          fi
          i="$j"
          continue
        fi
        ;;
      ">")
        next="${command:i+1:1}"
        if [ "$next" = "(" ]; then
          block "process substitution is prohibited"
        fi
        j=$((i + 1))
        if [ "${command:j:1}" = ">" ]; then
          j=$((j + 1))
        fi
        if [ "${command:j:1}" = "|" ]; then
          j=$((j + 1))
        fi
        # fd duplication such as >&2 is harmless; leave the fd to be scanned.
        if [ "${command:j:1}" = "&" ]; then
          i=$((j + 1))
          continue
        fi
        while [ "$j" -lt "$len" ] && [[ "${command:j:1}" =~ [[:space:]] ]]; do
          j=$((j + 1))
        done
        # Read the target verbatim, including quotes and $, so they can be
        # rejected below rather than silently skipped.
        target=""
        while [ "$j" -lt "$len" ]; do
          tc="${command:j:1}"
          case "$tc" in
            " "|$'\t'|$'\n'|";"|"|"|"&"|">"|"<") break ;;
          esac
          target="${target}${tc}"
          j=$((j + 1))
        done
        # Only a literal path inside the repository is allowed. Absolute,
        # home-relative, parent-escaping, or quoted / variable / command-
        # substitution targets cannot be resolved safely here, so reject them.
        case "$target" in
          /*|"~"*|../*|*/../*|*'"'*|*"'"*|*'$'*|*'`'*)
            block "redirect target must be a literal path inside the repository"
            ;;
        esac
        i="$j"
        continue
        ;;
      "{")
        prev=""
        if [ "$i" -gt 0 ]; then
          prev="${command:i-1:1}"
        fi

        # Skip parameter expansion such as ${var}. Empty {} is common in
        # commands like find -exec and is not brace expansion.
        if [ "$prev" = "$" ]; then
          i=$((i + 1))
          continue
        fi

        brace_content=""
        d=1
        j=$((i + 1))
        while [ "$j" -lt "$len" ]; do
          c="${command:j:1}"
          if [ "$c" = "\\" ]; then
            j=$((j + 2))
            continue
          fi
          if [ "$c" = "{" ]; then
            d=$((d + 1))
          elif [ "$c" = "}" ]; then
            d=$((d - 1))
            if [ "$d" -eq 0 ]; then
              break
            fi
          fi
          brace_content="${brace_content}${c}"
          j=$((j + 1))
        done

        if [ "$d" -eq 0 ]; then
          if [[ "$brace_content" == *","* || "$brace_content" == *".."* ]]; then
            block "brace expansion is prohibited"
          fi
          i=$((j + 1))
          continue
        fi
        ;;
    esac

    i=$((i + 1))
  done
}

check_command "$COMMAND"
exit 0
