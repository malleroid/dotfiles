# Losslessly normalize the GitHub Releases API response for Claude Code.
#
# Input:  JSON array from the GitHub Releases API
# Param:  --arg cutoff <ISO8601 UTC>   keep only versions published at/after this time
# Output: [ { version, date, published_at, url, change_count, bugfix_only, changes[] } ]
#
# Invariant: keep every CHANGELOG bullet — never drop anything here.
# Classification, prioritization, and translation are the skill's (LLM) job, not this filter's.
[ .[]
  | select(.draft == false and .prerelease == false)
  | select(.published_at >= $cutoff)
  | { version: .tag_name,
      date: (.published_at[0:10]),
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
