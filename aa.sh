#!/bin/bash
previous_state="uninitialized"

# set -x

while true; do
  source .lock_screen_cfg
  start_time=$(date +%s)
  current_date=$(date -u +'%Y-%m-%d %H:%M:%S')

  locked_screen=$(ddcctl -d 1 | grep "Failed to poll")
  active_app=$(osascript -e 'tell application "System Events" to get name of application processes whose frontmost is true')
  active_tab_url=$(osascript -e 'tell application "System Events" to if (name of first application process whose frontmost is true) is "Arc" then tell application "Arc" to get URL of active tab of window 1')
  active_domain=$(echo "$active_tab_url" | awk -F/ '{print $3}')
  echo $active_domain
  if [ "${CLOCKOUT:-0}" -eq 1 ]; then
    python hr.py clock-out
  fi

  if [ "${CLOCKIN:-0}" -eq 1 ]; then
    python hr.py clock-in
  fi

  if [ -n "$locked_screen" ]; then
    # Verificar si el estado anterior era locked_screen
      if [ "$previous_state" != "locked" ] && [ "${CLOCK:-0}" -eq 1 ]; then
        python hr.py clock-out
      fi
    echo "Locked screen!"
    previous_state="locked"
    curl \
      -X POST 'https://api.tinybird.co/v0/events?name=events&wait=false' \
      -H "Authorization: Bearer $LOCKED_TB_TOKEN" \
      -d "{\"timestamp\":\"$current_date\",\"status\":\"locked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\",\"domains\":[\"$active_domain\"]}" \
      &
  else
    echo "Okay Let's Go!"
      if [ "$previous_state" != "unlocked" ] && [ "${CLOCK:-0}" -eq 1 ]; then
        python hr.py clock-in
      fi
    previous_state="unlocked"
    curl \
      -X POST 'https://api.tinybird.co/v0/events?name=events&wait=false' \
      -H "Authorization: Bearer $LOCKED_TB_TOKEN" \
      -d "{\"timestamp\":\"$current_date\",\"status\":\"unlocked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\",\"domains\":[\"$active_domain\"]}" \
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

