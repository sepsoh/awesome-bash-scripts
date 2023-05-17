#!/bin/bash
# See More github.com/sepsoh/awesome-bash-scripts

# init vars
DNS1=178.22.122.100
DNS2=185.51.200.2
declare -a old_dns

#  check system os
if [[ $(uname) == "Darwin" ]]; then
    SYSTEM_OS=Mac
    echo "This is a Mac."
else
    SYSTEM_OS=Linux
    echo "This is not a Mac."
fi



#--------------------
#--------mac---------
#--------------------


if [ "$SYSTEM_OS" = "Mac" ]; then
  SERVICE=Wi-Fi
  case "$1" in
    start)
      echo "Setting DNS..."
      IFS=' ' read -r -a old_dns <<< "$(networksetup -getdnsservers $SERVICE)"
      networksetup -setdnsservers $SERVICE $DNS1 $DNS2
      sudo dscacheutil -flushcache
      sudo killall -HUP mDNSResponder
      echo "cache flushed"
      echo "Successfully shecan started."
    ;;
    stop)
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
      ;;
    *)
        echo "Invalid argument. Usage: sudo $0 {start|stop}"
  esac
  exit
fi


#--------------------
#-------linux--------
#--------------------


# Check if the user passed in the "start" argument
if [ "$1" = "start" ]; then
  # Backup the original resolv.conf file
  sudo cp /etc/resolv.conf /etc/resolv.conf.shecan.bak
  # Add the two DNS servers to resolv.conf
  echo "nameserver $DNS1" | sudo tee /etc/resolv.conf > /dev/null
  echo "nameserver $DNS2" | sudo tee -a /etc/resolv.conf > /dev/null
  echo "Successfully shecan started."
elif [ "$1" = "stop" ]; then
  # Restore the original resolv.conf file
  sudo cp /etc/resolv.conf.shecan.bak /etc/resolv.conf
  echo "Successfully shecan stopped."
  # Restart the NetworkManager service
  sudo systemctl restart NetworkManager
elif [ -z "$1" ]; then
  # No argument was passed, print help message
  echo "Usage: sudo ./shecan.sh [start/stop]"
else
  # Invalid argument was passed, print help message
  echo "Invalid argument. Usage: sudo ./shecan.sh [start/stop]"
fi
