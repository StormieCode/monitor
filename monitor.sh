#!/bin/bash
set +e  # Don't exit on first error

# -------------------------
# Safety checks
# -------------------------
if [[ -z "$LINK" ]]; then
  echo "FATAL: LINK is not set"
  exit 1
fi

if [[ -z "$COOKIE_KEY" ]]; then
  echo "FATAL: COOKIE_KEY is not set"
  exit 1
fi

# -------------------------
# Fetch data
# -------------------------
echo "Fetching data..."
DATA=$(curl -s -L "$LINK" \
  -H 'User-Agent: Mozilla/5.0' \
  -H "Cookie: key=$COOKIE_KEY")

echo "Data fetched. Checking games..."

# -------------------------
# Alert function with proper JSON escaping
# -------------------------
send_alert () {
  local webhook="$1"
  local message="$2"

  # Escape message safely for JSON
  escaped=$(jq -Rn --arg msg "$message" '{"content":$msg}')

  curl -s -X POST "$webhook" \
    -H "Content-Type: application/json" \
    -d "$escaped"
}

# -------------------------
# Process each game safely
# -------------------------
echo "$DATA" | jq -c '.[]? // empty' | while read -r game; do
  [[ -z "$game" ]] && continue

  plrs=$(echo "$game" | jq -r '.plrs // 0')
  max=$(echo "$game" | jq -r '.maxPlayers // 0')
  name=$(echo "$game" | jq -r '.Name // "Unknown"')
  creator=$(echo "$game" | jq -r '.creator // "Unknown"')
  id=$(echo "$game" | jq -r '.id // "N/A"')
  jobs=$(echo "$game" | jq -r '
    if (.jobidsArray | length) > 0
    then (.jobidsArray | map("• `" + . + "`") | join("\n"))
    else "• None"
    end
  ')

  echo "Checking: $name ($plrs players)"

  # Skip if below lowest threshold
  [[ "$plrs" -lt 200 ]] && continue

  MESSAGE="🚨 **Player Threshold Hit**
**$name**
👥 Players: $plrs/$max
👤 Creator: $creator
🆔 Game ID: $id
🧩 Job IDs:
$jobs
"

  # -------------------------
  # Threshold → webhook routing
  # -------------------------
  if [[ "$plrs" -ge 1000 ]]; then
    send_alert "$DISCORD_WEBHOOK1000" "$MESSAGE"

  elif [[ "$plrs" -ge 500 ]]; then
    send_alert "$DISCORD_WEBHOOK500" "$MESSAGE"

  elif [[ "$plrs" -ge 400 ]]; then
    send_alert "$DISCORD_WEBHOOK400" "$MESSAGE"

  elif [[ "$plrs" -ge 300 ]]; then
    send_alert "$DISCORD_WEBHOOK300" "$MESSAGE"

  elif [[ "$plrs" -ge 200 ]]; then
    send_alert "$DISCORD_WEBHOOK200" "$MESSAGE"
  fi
done
