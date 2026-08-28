#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path>" >&2
  exit 1
fi

search_path="$1"

if [ ! -d "$search_path" ]; then
  echo "Error: '$search_path' is not a valid directory." >&2
  exit 1
fi

context=""
first=true

while IFS= read -r file; do
  if [ "$first" = true ]; then
    first=false
  else
    context="${context}"$'\n\n'
  fi
  content=$(cat "$file")
  context="${context}${content}"
done < <(find "$search_path" -type f -name "*.md" | sort)

# Emit the payload with a JSON encoder rather than by hand: a CRLF checkout
# leaves a bare CR in the context, and a bare control character inside a JSON
# string is what "Unterminated string" is reporting.
if command -v perl >/dev/null 2>&1; then
  context="$context" perl -MJSON::PP -MEncode -e '
    print JSON::PP->new->ascii->encode({
      hookSpecificOutput => {
        hookEventName     => "SessionStart",
        additionalContext => decode_utf8($ENV{context}),
      }
    }), "\n";
  '
  exit
fi

# No perl: hand-rolled escape, backslash first. Misses the rarer control
# characters, but keeps the hook working where the encoder is unavailable.
escaped="$context"
escaped="${escaped//\\/\\\\}"
escaped="${escaped//\"/\\\"}"
escaped="${escaped//$'\t'/\\t}"
escaped="${escaped//$'\r'/\\r}"
escaped="${escaped//$'\n'/\\n}"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${escaped}"
  }
}
EOF
