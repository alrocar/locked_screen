#!/bin/bash
source .lock_screen_cfg

while true; do
  start_time=$(date +%s)
  current_date=$(date -u +'%Y-%m-%d %H:%M:%S')

  locked_screen=$(ddcctl -d 1 | grep "Failed to poll")
  active_app=$(osascript -e 'tell application "System Events" to get name of application processes whose frontmost is true')

  if [ -n "$locked_screen" ]; then
    echo "Locked screen!"
    curl \
      -X POST 'https://api.tinybird.co/v0/events?name=events&wait=false' \
      -H "Authorization: Bearer $LOCKED_TB_TOKEN" \
      -d "{\"timestamp\":\"$current_date\",\"status\":\"locked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\"}" \
      &
  else
    echo "Okay Let's Go!"
    curl \
      -X POST 'https://api.tinybird.co/v0/events?name=events&wait=false' \
      -H "Authorization: Bearer $LOCKED_TB_TOKEN" \
      -d "{\"timestamp\":\"$current_date\",\"status\":\"unlocked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\"}" \
      &
  fi

  end_time=$(date +%s)
  execution_time=$((end_time - start_time))
  next_start_time=$((start_time + LOCKED_SCREEN_SLEEP_TIME))
  sleep_time=$((next_start_time - end_time))

  if [ "$sleep_time" -gt 0 ]; then
    sleep $sleep_time
  else
    echo "Warning: Execution time exceeded sleep time"
  fi
done

