#!/usr/bin/env bash
# summarize-sessions.sh
# Processes merged Claude session JSONL files into a compact summary JSON.
# Run on the reporting host after merge-bundles.sh, before generating the report.
#
# Usage:
#   ./summarize-sessions.sh --since 2026-04-13 --until 2026-05-19 [--dir ~/.claude-merged]
#
# Output:
#   sessions-summary.json

set -euo pipefail

SINCE=""
UNTIL=""
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --since) SINCE="$2"; shift 2 ;;
    --until) UNTIL="$2"; shift 2 ;;
    --dir)   CLAUDE_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$SINCE" || -z "$UNTIL" ]]; then
  echo "Usage: $0 --since YYYY-MM-DD --until YYYY-MM-DD [--dir ~/.claude-merged]"
  exit 1
fi

PROJECTS_DIR="$CLAUDE_DIR/projects"
OUTPUT="sessions-summary.json"

echo "Summarizing sessions in $PROJECTS_DIR ($SINCE to $UNTIL)..."

since_epoch=$(date -d "$SINCE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$SINCE" +%s)
until_epoch=$(date -d "$UNTIL 23:59:59" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$UNTIL 23:59:59" +%s)

# Process each JSONL file with jq, emit one JSON object per session
tmpout=$(mktemp)

find "$PROJECTS_DIR" -name "*.jsonl" | sort | while read -r jsonl_file; do
  project=$(basename "$(dirname "$jsonl_file")" | sed 's/^-Users-[^-]*-//' | tr '-' '/')
  session_id=$(basename "$jsonl_file" .jsonl | cut -c1-8)

  # Get first timestamp
  first_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$jsonl_file" 2>/dev/null | head -1)
  [[ -z "$first_ts" ]] && continue

  msg_epoch=$(date -d "$first_ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${first_ts%%.*}" +%s 2>/dev/null || echo 0)
  [[ "$msg_epoch" -lt "$since_epoch" || "$msg_epoch" -gt "$until_epoch" ]] && continue

  session_date="${first_ts:0:10}"

  # Use jq to extract everything in one pass
  jq -c \
    --arg session_id "$session_id" \
    --arg date "$session_date" \
    --arg project "$project" \
    '
    # Collect all lines into an array
    [ inputs ] as $lines |

    # Human messages: role=user or type=user, content is string or text block
    ($lines | map(
      select(.role == "user" or .type == "user") |
      if .content | type == "string" then .content
      elif .content | type == "array" then
        (.content | map(select(.type == "text") | .text) | join(" "))
      else empty end |
      select(length > 0) |
      ltrimstr("\n") | rtrimstr("\n") |
      if length > 120 then .[0:120] + "…" else . end
    )) as $human_messages |

    # Skip /clear-only sessions
    ($human_messages | map(select(test("^\\s*/clear\\s*$") | not))) as $real_messages |
    if ($real_messages | length) == 0 then empty else . end |

    # Tool calls: extract from assistant messages
    ($lines | map(
      select(.role == "assistant" or .type == "assistant") |
      .content // [] |
      if type == "array" then .[] else . end |
      select(.type == "tool_use") |
      if .name == "Bash" then
        "Bash: " + ((.input.command // "") | split("\n")[0] | if length > 80 then .[0:80] + "…" else . end)
      elif .name == "Write" then
        "Write: " + (.input.file_path // "")
      elif .name == "Edit" then
        "Edit: " + (.input.file_path // "")
      elif .name == "Read" then
        "Read: " + (.input.file_path // "")
      elif .name == "Agent" then
        "Agent: " + (.input.description // .input.prompt // "" | if length > 60 then .[0:60] + "…" else . end)
      else
        .name
      end
    ) | unique) as $tool_calls |

    # Message counts
    ($lines | map(select(.role == "user" or .type == "user")) | length) as $human_count |
    ($lines | map(select(.role == "assistant" or .type == "assistant")) | length) as $assistant_count |

    # Last human message
    ($real_messages | last // "") as $last_message |

    {
      session_id: $session_id,
      date: $date,
      project: $project,
      message_count: { human: $human_count, assistant: $assistant_count },
      first_message: ($real_messages | first // ""),
      last_message: $last_message,
      human_messages: $real_messages,
      tool_calls: $tool_calls
    }
    ' --null-input --rawfile _unused /dev/null --slurpfile _lines "$jsonl_file" \
    "$jsonl_file" 2>/dev/null || true

done > "$tmpout"

# Wrap in array and add needs_investigation hint
jq -s '
  map(. + {
    needs_investigation: (
      # Flag sessions where content is hard to determine from messages alone
      (.human_messages | length) <= 1 or
      ((.first_message // "") | length) < 20 or
      ((.human_messages | map(length) | add // 0) < 100 and (.tool_calls | length) > 5) or
      (.first_message | test("^(hi|hello|ok|yes|no|thanks|sure|done|continue|proceed)"; "i")) or
      ((.human_messages | length) > 20 and (.tool_calls | length) == 0)
    )
  })
' "$tmpout" > "$OUTPUT"

rm -f "$tmpout"

total=$(jq 'length' "$OUTPUT")
flagged=$(jq '[.[] | select(.needs_investigation)] | length' "$OUTPUT")
echo "Done: $total sessions → $OUTPUT"
echo "Flagged for investigation: $flagged sessions"
echo ""
echo "Next: pass sessions-summary.json to claude-usage-report"
echo "Claude will review flagged sessions and may read raw JSONL for those only."
