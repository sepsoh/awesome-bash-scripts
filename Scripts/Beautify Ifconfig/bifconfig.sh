#!/bin/bash
number_of_interfaces=$(ifconfig | grep "^[[:alpha:]]" | wc -l) # get number of interfaces
interfaces=$(ifconfig | grep "^[[:alpha:]]" | cut -f1 -d:) # get interfaces
ips=$(ifconfig  | grep "^\s" |  sed 's/ \{1,\}/\n/' | grep '^inet ' | cut -f2 -d' ') # get ips
netmasks=$(ifconfig  | grep "^\s" |  sed 's/ \{1,\}/\n/' | grep '^inet ' | cut -f5 -d' ') # get netmask
flags=$(ifconfig | grep "^[[:alpha:]]" | sed 's/\s//' | cut -f2 -d: | sed 's/  / /g' | awk '{print $1}' | cut -f2 -d=) # get flags

printf "%-16s %-15s %-15s %-40s\n" "interface" "IP" "netmask" "flags"
for n in $(seq 1 $number_of_interfaces)
do
    interface=$(echo $interfaces | sed 's/\s/\n/g' | head -$n | tail -1)
    ip=$(echo $ips | sed 's/\s/\n/g' | head -$n | tail -1)
    netmask=$(echo $netmasks | sed 's/\s/\n/g' | head -$n | tail -1)
    flag=$(echo $flags | sed 's/\s/\n/g' | head -$n | tail -1)
    printf "%-16s %-15s %-15s %-40s\n" "$interface" "$ip" "$netmask" "$flag"
done
