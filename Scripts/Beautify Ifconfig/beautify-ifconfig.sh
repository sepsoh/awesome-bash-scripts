#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
NC='\033[0m' # No Color

# Parse command-line arguments
use_color=false
for arg in "$@"; do
    case $arg in
        --color)
            use_color=true
            shift
            ;;
    esac
done

# Function to get color for interface
get_interface_color() {
    local interface="$1"
    
    # Match interface name patterns to colors
    if [[ $interface == docker* ]]; then
        echo -n "$LIGHTBLUE" # Sky blue for docker interfaces
    elif [[ $interface == eth* ]]; then
        echo -n "$GREEN" # Green for ethernet
    elif [[ $interface == wlan* || $interface == wlp* ]]; then
        echo -n "$YELLOW" # Yellow for wireless
    elif [[ $interface == lo ]]; then
        echo -n "$PURPLE" # Purple for loopback
    elif [[ $interface == enp* || $interface == ens* ]]; then
        echo -n "$CYAN" # Cyan for physical network cards
    elif [[ $interface == veth* || $interface == br* ]]; then
        echo -n "$RED" # Red for virtual interfaces and bridges
    else
        echo -n "$NC" # Default color
    fi
}

# Get data
number_of_interfaces=$(ifconfig | grep "^[[:alpha:]]" | wc -l) # get number of interfaces
interfaces=$(ifconfig | grep "^[[:alpha:]]" | cut -f1 -d:) # get interfaces
ips=$(ifconfig  | grep "^\s" |  sed 's/ \{1,\}/\n/' | grep '^inet ' | cut -f2 -d' ') # get ips
netmasks=$(ifconfig  | grep "^\s" |  sed 's/ \{1,\}/\n/' | grep '^inet ' | cut -f5 -d' ') # get netmask
flags=$(ifconfig | grep "^[[:alpha:]]" | sed 's/\s//' | cut -f2 -d: | sed 's/  / /g' | awk '{print $1}' | cut -f2 -d=) # get flags

# Print header
printf "%-16s %-15s %-15s %-40s\n" "interface" "IP" "netmask" "flags"

# Print data for each interface
if $use_color; then
    for n in $(seq 1 $number_of_interfaces)
    do
        interface=$(echo $interfaces | sed 's/\s/\n/g' | head -$n | tail -1)
        ip=$(echo $ips | sed 's/\s/\n/g' | head -$n | tail -1)
        netmask=$(echo $netmasks | sed 's/\s/\n/g' | head -$n | tail -1)
        flag=$(echo $flags | sed 's/\s/\n/g' | head -$n | tail -1)
        color=$(get_interface_color "$interface")
        printf "${color}%-16s %-15s %-15s %-40s${NC}\n" "$interface" "$ip" "$netmask" "$flag"
    done
else
    for n in $(seq 1 $number_of_interfaces)
    do
        interface=$(echo $interfaces | sed 's/\s/\n/g' | head -$n | tail -1)
        ip=$(echo $ips | sed 's/\s/\n/g' | head -$n | tail -1)
        netmask=$(echo $netmasks | sed 's/\s/\n/g' | head -$n | tail -1)
        flag=$(echo $flags | sed 's/\s/\n/g' | head -$n | tail -1)
        printf "%-16s %-15s %-15s %-40s\n" "$interface" "$ip" "$netmask" "$flag"
    done
fi
