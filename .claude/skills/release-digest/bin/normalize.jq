# Losslessly normalize the GitHub Releases API response for Claude Code.
#
# Input:  JSON array from the GitHub Releases API
# Param:  --arg cutoff <YYYY-MM-DD>   keep versions whose published_at, in JST, is >= this date
# Output: [ { version, date, published_at, url, change_count, bugfix_only, changes[] } ]
#
# Invariant: keep every CHANGELOG bullet — never drop anything here.
# Classification, prioritization, and translation are the skill's (LLM) job, not this filter's.
[ .[]
  | select(.draft == false and .prerelease == false)
  | select((.published_at | fromdateiso8601 + 32400 | gmtime | strftime("%Y-%m-%d")) >= $cutoff)
  | { version: .tag_name,
      date: (.published_at | fromdateiso8601 + 32400 | gmtime | strftime("%Y-%m-%d")),
      published_at: .published_at,
      url: .html_url
    }
    + ( ( .body
          | split("\n")
          | map(select(startswith("- ")))
          | map(sub("^- "; "")) ) as $c
        | { change_count: ($c | length),
            bugfix_only: ($c == ["Bug fixes and reliability improvements"]),
            changes: $c } )
]
