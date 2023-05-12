#!/bin/bash
# See More github.com/sepsoh/awesome-bash-scripts



# Function to terminate the background processes
function cleanup() {
  printf "\nStopping Script...\n"
  kill %1 # Send SIGTERM to the first background process
  exit 0
}

# Register the cleanup function for SIGINT signal
trap cleanup SIGINT

start_time="$(date +%s)"

while true; do
  sleep 1200 # wait for 20 minutes
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    pmset displaysleepnow
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux and Unix-based systems
    if which xset >/dev/null; then
      xset dpms force off
    elif which vbetool >/dev/null; then
      sudo vbetool dpms off
    elif which slock >/dev/null; then
      slock
    fi
  fi
  sleep 20 # wait for 20 seconds
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    caffeinate -u -t 1
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux and Unix-based systems
    if which xset >/dev/null; then
      xset dpms force on
    elif which vbetool >/dev/null; then
      sudo vbetool dpms on
    elif which slock >/dev/null; then
      pkill slock
    fi
  fi
done &

while true; do
  # Move the cursor to the beginning of the line and clear the line
  printf "\r"
  tput el

  # Print the running time
  elapsed_time=$(( $(date +%s) - ${start_time} ))
  printf "Running time: %02d:%02d:%02d" $((elapsed_time/3600)) $((elapsed_time/60%60)) $((elapsed_time%60))

  # Read user input without disrupting the timer format
  read -t 1 -n 10000 discard || true
done
