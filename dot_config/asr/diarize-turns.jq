# Split speech.cpp `--diarize --timestamps` output into speaker turns.
#
# Adds to each region `dominant_speaker` (longest total speaking time) and
# `turns` ({speaker, start, end, text}), and at the top level all turns with
# consecutive same-speaker turns joined.
#
# Within a region:
#   1. A token goes to the speaker whose interval contains its midpoint (largest
#      overlap first), else to the nearest interval; ties go to the lower id.
#   2. A turn shorter than min_sec seconds is absorbed into a neighbour: the one
#      of the region's dominant speaker if only one is, else the longer one
#      (the previous on a tie).
#   3. A region left with one turn takes the dominant speaker.
# Override the threshold with `--argjson min_sec <seconds>`.

def min_sec: $ARGS.named.min_sec // 0.5;

def mid: (.start + .end) / 2;

def overlap($a; $b): ([$a.end, $b.end] | min) - ([$a.start, $b.start] | max);

def speaker_of($tok; $spk):
  ($tok | mid) as $m
  | [$spk[] | select(.start <= $m and $m <= .end)] as $hits
  | if ($hits | length) > 0 then
      $hits | max_by([overlap(.; $tok), -.speaker]) | .speaker
    elif ($spk | length) > 0 then
      $spk | min_by([(if $m < .start then .start - $m else $m - .end end), .speaker]) | .speaker
    else null end;

def dominant($spk):
  if ($spk | length) == 0 then null
  else
    $spk
    | group_by(.speaker)
    | map({speaker: .[0].speaker, time: (map(.end - .start) | add)})
    | max_by([.time, -.speaker])
    | .speaker
  end;

def join_turns:
  reduce .[] as $t ([];
    if length > 0 and .[-1].speaker == $t.speaker then
      .[-1].end = $t.end | .[-1].text += $t.text
    else
      . + [{speaker: $t.speaker, start: $t.start, end: $t.end, text: $t.text}]
    end);

def first_short: [range(0; length) as $i | select(.[$i].end - .[$i].start < min_sec) | $i] | first;

def absorb_short($dom):
  until(length <= 1 or first_short == null;
    first_short as $i
    | (if $i == 0 then 1
       elif $i == length - 1 then $i - 1
       elif .[$i - 1].speaker == $dom and .[$i + 1].speaker != $dom then $i - 1
       elif .[$i + 1].speaker == $dom and .[$i - 1].speaker != $dom then $i + 1
       elif (.[$i - 1].text | length) >= (.[$i + 1].text | length) then $i - 1
       else $i + 1 end) as $j
    | .[$i].speaker = .[$j].speaker
    | join_turns);

def single_to($dom):
  if length == 1 and $dom != null then .[0].speaker = $dom else . end;

(.regions // []) as $regions
| ($regions | map(.start)) as $starts
| ([(.tokens // [])[]
      | select(.text != "")
      | . as $tok
      | ($starts | bsearch($tok | mid)) as $i
      | (if $i >= 0 then $i else -2 - $i end) as $r
      | select($r >= 0 and ($tok | mid) <= $regions[$r].end)
      | {r: $r, start, end, text}]
    | group_by(.r)
    | map({key: (.[0].r | tostring), value: .})
    | from_entries) as $by_region
| .regions = [$regions | to_entries[]
    | .key as $r
    | .value
    | (.speakers // []) as $spk
    | dominant($spk) as $dom
    | . + {
        dominant_speaker: $dom,
        turns: ([($by_region[$r | tostring] // [])[] | . + {speaker: speaker_of(.; $spk)}]
          | join_turns
          | absorb_short($dom)
          | single_to($dom))
      }]
| .turns = ([.regions[].turns[]] | join_turns)
