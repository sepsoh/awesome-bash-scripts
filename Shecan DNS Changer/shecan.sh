#!/bin/bash
# See More github.com/sepsoh/awesome-bash-scripts


# Check if the user passed in the "start" argument
if [ "$1" = "start" ]; then
  # Backup the original resolv.conf file
  sudo cp /etc/resolv.conf /etc/resolv.conf.shecan.bak
  # Add the two DNS servers to resolv.conf
  echo "nameserver 178.22.122.100" | sudo tee /etc/resolv.conf > /dev/null
  echo "nameserver 185.51.200.2" | sudo tee -a /etc/resolv.conf > /dev/null
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
