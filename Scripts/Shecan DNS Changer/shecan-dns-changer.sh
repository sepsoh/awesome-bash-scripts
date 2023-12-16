#!/bin/bash
# See More github.com/sepsoh/awesome-bash-scripts

# init vars
DNS1=178.22.122.100
DNS2=185.51.200.2
declare -a old_dns

#  check system os
if [[ $(uname) == "Darwin" ]]; then
    SYSTEM_OS=Mac
else
    SYSTEM_OS=Linux
fi

# Check if the user passed in the "start" or "stop" argument
if [ "$1" = "start" ] || [ "$1" = "stop" ]; then
  if [ "$SYSTEM_OS" = "Mac" ]; then
    SERVICE=Wi-Fi
    if [ "$1" = "start" ]; then
      echo "Setting DNS..."
      IFS=' ' read -r -a old_dns <<< "$(networksetup -getdnsservers $SERVICE)"
      networksetup -setdnsservers $SERVICE $DNS1 $DNS2
      sudo dscacheutil -flushcache
      sudo killall -HUP mDNSResponder
      echo "cache flushed"
      echo "Successfully shecan started."
    else # "$1" = "stop"
      echo "Resetting DNS..."
      if [ ${#old_dns[@]} -eq 0 ]; then
        networksetup -setdnsservers $SERVICE empty
      else
        networksetup -setdnsservers $SERVICE "${old_dns[@]}"
      fi
      sudo dscacheutil -flushcache
      sudo killall -HUP mDNSResponder
      echo "cache flushed"
      echo "Successfully shecan stopped."
    fi
  else # "$SYSTEM_OS" = "Linux"
    if [ "$1" = "start" ]; then
      sudo cp /etc/resolv.conf /etc/resolv.conf.shecan.bak
      echo "nameserver $DNS1" | sudo tee /etc/resolv.conf > /dev/null
      echo "nameserver $DNS2" | sudo tee -a /etc/resolv.conf > /dev/null
      echo "Successfully shecan started."
    else # "$1" = "stop"
      sudo cp /etc/resolv.conf.shecan.bak /etc/resolv.conf
      echo "Successfully shecan stopped."
      sudo systemctl restart NetworkManager
    fi
  fi
else
  # Invalid argument was passed, print help message
  echo "Invalid argument. Usage: sudo ./shecan.sh [start/stop]"
fi
