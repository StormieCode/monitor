#!/bin/bash

DATA=$(curl -s -L $LINK \
  -H 'User-Agent: Mozilla/5.0' \
  -H "Cookie: key=$COOKIE_KEY")

send_alert () {
  local webhook="$1"
  local message="$2"

  curl -s -X POST "$webhook" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"@everyone\\n$message\"}"
}

echo "$DATA" | jq -c '.[]' | while read -r game; do
  plrs=$(echo "$game" | jq -r '.plrs')
  max=$(echo "$game" | jq -r '.maxPlayers')
  name=$(echo "$game" | jq -r '.Name')
  creator=$(echo "$game" | jq -r '.creator // "Unknown"')
  id=$(echo "$game" | jq -r '.id')
  jobs=$(echo "$game" | jq -r '
    if (.jobidsArray | length) > 0
    then (.jobidsArray | map("• `" + . + "`") | join("\n"))
    else "• None"
    end
  ')

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

  if [[ "$plrs" -ge 1000 ]]; then
    send_alert "$DISCORD_WEBHOOK_1000" "$MESSAGE"

  elif [[ "$plrs" -ge 300 ]]; then
    send_alert "$DISCORD_WEBHOOK_300" "$MESSAGE"

  elif [[ "$plrs" -ge 400 ]]; then
    send_alert "$DISCORD_WEBHOOK_400" "$MESSAGE"

  elif [[ "$plrs" -ge 200 ]]; then
    send_alert "$DISCORD_WEBHOOK_200" "$MESSAGE"

  elif [[ "$plrs" -ge 500 ]]; then
    send_alert "$DISCORD_WEBHOOK_500" "$MESSAGE"
  fi
done

echo "Script started at $(date)"
echo "Sleeping before request..."
echo "Fetching data..."
echo "Data fetched, checking games..."
echo "Checking: $name ($plrs players)"
curl -s -X POST "$DISCORD_WEBHOOK_200" \
  -H "Content-Type: application/json" \
  -d '{"content":"@everyone ✅ Test alert from GitHub Actions"}'

