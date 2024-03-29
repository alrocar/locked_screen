#!/bin/bash
# I built this script for myself, I don't expect to work on any other computer than mine. You can try to tweak it to your needs if you want.
# see the script for the command line tools you need:
# - yabai: to get the current desktop
# - ddcctl: to check if external monitors are on or off
# - python: to run hr.py (clock-in/out to FactorialHR)
# - curl: traces are stored in a Tinybird workspace
# - osascript: to get the current application and browser (Arc) tab used

# The script sents a trace to Tinybird every 10 seconds indicating:
# if the external monitors are 'locked' or 'unlocked'
# the current active desktop space: 'personal' or 'work'
# the active_app, active_domain and url
# it clocks-in to FactorialHR when the monitors are unlocked and clocks-out when they are off
# Tinybird is used to build an analytical dashboard. The Tinybird project is not provided (yet)

previous_state="uninitialized"
brew services start yabai

# set -x

while true; do
  source .lock_screen_cfg
  start_time=$(date +%s)
  current_date=$(date -u +'%Y-%m-%d %H:%M:%S')

  locked_screen=$(ddcctl -d 1 | grep "Failed to poll")
  active_app=$(osascript -e 'tell application "System Events" to get name of application processes whose frontmost is true')
  active_tab_url=$(osascript -e 'tell application "System Events" to if (name of first application process whose frontmost is true) is "Arc" then tell application "Arc" to get URL of active tab of window 1')
  active_domain=$(echo "$active_tab_url" | awk -F/ '{print $3}')
  space=$(yabai -m query --spaces | jq -r '.[] | select(.["is-visible"] == true and .["has-focus"] == true) | .label')
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
      -d "{\"timestamp\":\"$current_date\",\"status\":\"locked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\",\"domains\":[\"$active_domain\"],\"tabs\":[\"$active_tab_url\"],\"space\":\"$space\"}" \
      &
  else
    # single=$(ddcctl -d 1 2>&1)
    # if [[ $single =~ "*found 0 external display*" ]]; then
      echo "Okay Let's Go!"
        if [ "$previous_state" != "unlocked" ] && [ "${CLOCK:-0}" -eq 1 ]; then
          python hr.py clock-in
        fi
      previous_state="unlocked"
      curl \
        -X POST 'https://api.tinybird.co/v0/events?name=events&wait=false' \
        -H "Authorization: Bearer $LOCKED_TB_TOKEN" \
        -d "{\"timestamp\":\"$current_date\",\"status\":\"unlocked\",\"user\":\"$LOCKED_SCREEN_USER\",\"duration\":$LOCKED_SCREEN_SLEEP_TIME,\"app\":\"$active_app\",\"domains\":[\"$active_domain\"],\"tabs\":[\"$active_tab_url\"],\"space\":\"$space\"}" \
        &
    # fi
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

