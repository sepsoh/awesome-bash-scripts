#!/bin/bash

#goto switches

#terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#runtime flags/configs
REDIRECT_DEST="/dev/null"
PING_COUNT="4"
TIMEOUT="1"
INTERFACE_CHANGE_STATE_SLEEP="1"
DHCP_COMPLETION_SLEEP="10"
TRY_TO_FIX=1

HELP="\
Internet problem fixer\\n\
Options:\n\
\t-v, --verbose\tverbose\n\
\t-d, --debug\tdebug: redirects the used commands to stdout\n\
\t-n, --no-fix\tdon't try to fix ( eliminate the requirement for the script to be root )\n\
\t-i, --interface 
"

#google dns primary and secondary, example.com, google.com
INTERNET_IPV4S=("8.8.8.8" "8.8.4.4" "93.184.215.14" "142.250.184.206")
INTERNET_DOMAINS=("google.com" "example.com" "github.com")
#shecan.ir, shecan primary and secondary dns, shatel.ir
INTRANET_IPV4S=("88.135.36.244" "178.22.122.100" "178.22.122.100" "85.15.17.13")
INTRANET_DOMAINS=("shecan.ir" "shatel.ir")


#regex strings
IPV4_REGEX="([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}"
IPV4_NETMASK_REGEX="/[[:digit:]]{1,2}"

#state flags (-1 not checked 0 doesnt work 1 works )
#is for the $CURRENT_INTERFACE
#need to keep track of after each function call and echo accordingly
#if a state goes downward warn the user ( like interanet works and then doesnt work ) and ask to send a feedback
INTERFACE_STATE=-1
#indicates if the private ip is usable (dhcp lease may have expired)
PRIVATE_IP_STATE=-1
LAN_STATE=-1
INTRANET_STATE=-1
INTERNET_STATE=-1
DNS_STATE=-1

#used to see if the condition of the interface has improved
LAST_INTERFACE_STATE=-1
LAST_PRIVATE_IP_STATE=-1
LAST_LAN_STATE=-1
LAST_INTRANET_STATE=-1
LAST_INTERNET_STATE=-1
LAST_DNS_STATE=-1

#the delimiter for all interface lists:
# 	-all get functions provide the list of asked interfaces with the delimiter being $INTERFACE_LIST_DELIMITER
# 	-all switches that accept a list of interfaces as argument use the $INTERFACE_LIST_DELIMITER
# 	-all loops in interface lists should set IFS to $INTERFACE_LIST_DELIMITER
INTERFACE_LIST_DELIMITER=","
#interfaces that are expected to be able to reach internet
TARGET_INTERFACES=""
#script runs for the first target and after the fix can run for the other
CURRENT_INTERFACE=""
#-x --exclude input
IGNORED_INTERFACES=""
#-i --interface input
INCLUDED_INTERFACES=""

RELIABLE_DNS_SERVER1="8.8.8.8"
RELIABLE_DNS_SERVER2="8.8.4.4"

#used to seperate the output of some function from another
LINE_DELIMITER="--------------------------"

#log levels
#10-40 and 60-90 are reserved for the future use
DEFAULT_LOG_LVL=0
VERBOSE_LOG_LVL=50
DEBUG_LOG_LVL=100

CURRENT_LOG_LVL=DEFAULT_LOG_LVL


function log {
 	string="$1"
	log_level="$2"
	
	#should be dynamic based on the switches
	#like a user sometimes wants to send all of errors over a socket(s) and have the states shown in a terminal
	dest=1

	if [[ $CURRENT_LOG_LVL -ge $log_level ]];then
			echo -e $string>&$dest
	fi
}

#get functions:
function get_all_interfaces {
		ip addr | grep -E "[[:digit:]]+: [[:alnum:]]+" | cut -f2 -d' ' | sed -e "s/://g" | uniq | tr $'\n' "$INTERFACE_LIST_DELIMITER"
}
#used to provide needed data such as interface list
function get_interfaces_with_default_gw {
#interfaces used to get to the internet
		ip route | grep -E "^default .* dev" | grep -o -E "dev [[:alnum:]]+" | cut -f2 -d ' ' | uniq | tr $'\n' "$INTERFACE_LIST_DELIMITER"
}

function get_default_gws_of_interface {
#default gateways of interface
		interface_name="$1"
		ip route | grep -E "^default" | grep $interface_name | grep -o -E "$IPV4_REGEX" | tr $'\n' ' '
}

function get_interface_ipv4s {
		interface_name="$1"
		ip -o addr | grep "^[[:digit:]]+: $interface_name" | grep -o -E "$IPV4_REGEX$IPV4_NETMASK_REGEX" | cut -f1 -d "/" | tr $'\n' ' '
}


function check_internet_connectivity {
		interface_name="$1"
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTERNET_DOMAINS[@]}"
		else
				ping_dest="${INTERNET_IPV4S[@]}"
		fi

		log "${BLUE}[*] checking internet connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL

		IFS=" "
		for host in ${ping_dest[@]};do
				if ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						INTERNET_STATE=1
						return 0
				fi
		done
		

		log "${RED}[-] $interface_name can't reach the internet${NC}" $VERBOSE_LOG_LVL

		INTERNET_STATE=0
		return 1
}
function check_intranet_connectivity {
		interface_name="$1"
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTRANET_DOMAINS[@]}"
		else
				ping_dest="${INTRANET_IPV4S[@]}"
		fi

		log "${BLUE}[*] checking intranet connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL

		IFS=" "
		for host in ${ping_dest[@]};do
				if ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						return 0
				fi
		done
		
		log "${RED}[-] $interface_name can't reach the intranet${NC}" $VERBOSE_LOG_LVL
		INTRANET_STATE=0
		INTERNET_STATE=0
		return 1
} 
function check_lan_connectivity {
#ping default gateway
		interface_name="$1"
		default_gws=$(get_default_gws_of_interface $interface_name)

		log "${BLUE}[*] checking LAN connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		
		for host in $default_gws;do
				if ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						return 0
				fi
		done
		
		PRIVATE_IP_STATE=0
		LAN_STATE=0
		INTRANET_STATE=0
		INTERNET_STATE=0
		
		log "${RED}[-] $interface_name can't reach it't LAN${NC}" $VERBOSE_LOG_LVL
		return 1
}
function check_dns {
#need to check what dns client is present and use that
#so this function need to call one of the check_dns_nslookup, check_dns_host, check_dns_dig, etc
		#is not used currently
		interface_name="$1"

		log "${BLUE}[*] checking DNS${NC}" $VERBOSE_LOG_LVL
		IFS=$","
		for domain in $INTERNET_DOMAINS;do
				if nslookup -timeout=$TIMEOUT $domain >&$REDIRECT_DEST;then
						#will uncomment these states after found a way
						#to do dns on the current interface, currently any interface might be used by nslookup
						#INTERFACE_STATE=1
						#PRIVATE_IP_STATE=1
						#LAN_STATE=1
						#INTRANET_STATE=1
						DNS_STATE=1
						return 0
				fi 
		done		
		log "${RED}[-] DNS doesn\'t work${NC}" $VERBOSE_LOG_LVL
		DNS_STATE=0
		return 1
}

function check_interface_self_connectivity {
		interface_name="$1"
		interface_ips=$(get_interface_ipv4s $interface_name)
		
		log "${BLUE}[*] checking interface self connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		IFS=$' '
		for ip in $interface_ips;do
				ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $ip >&$REDIRECT_DEST
				errno=$?
				if [[ $errno != 0 ]];then
						log "${RED}[-] $ip is not  reachable via $interface_name${NC}" $VERBOSE_LOG_LVL
						#if interface can't ping itself it cant reach anything
						set_network_states 0
						return 1
				fi
		done
						
		INTERFACE_STATE=1
		return 0
}
function check_network_states {
		INTERFACE_MSG="network interface"
		PRIVATE_IP_MSG="private ip usability"
		LAN_MSG="LAN reachability"
		DNS_MSG="DNS ( not currently interface dependent )"
		INTRANET_MSG="Intranet reachability"
		INTERNET_MSG="Internet reachability"

		log "${YELLOW}$LINE_DELIMITER${NC}" $DEFAULT_LOG_LVL
		log "current network stats of $CURRENT_INTERFACE:" $DEFAULT_LOG_LVL

		#interface
		if [[ $INTERFACE_STATE = 1 ]];then
				log "${GREEN}[+] $INTERFACE_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $INTERFACE_STATE = -1 ]];then
				log "[?] $INTERFACE_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $INTERFACE_MSG${NC}" $DEFAULT_LOG_LVL
		fi

		#private ip
		if [[ $PRIVATE_IP_STATE = 1 ]];then
				log "${GREEN}[+] $PRIVATE_IP_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $PRIVATE_IP_MSG = -1 ]];then
				log "[?] $PRIVATE_IP_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $PRIVATE_IP_MSG${NC}" $DEFAULT_LOG_LVL
		fi

		#LAN
		if [[ $LAN_STATE = 1 ]];then
				log "${GREEN}[+] $LAN_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $LAN_STATE = -1 ]];then
				log "[?] $LAN_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $LAN_MSG${NC}" $DEFAULT_LOG_LVL
		fi

		#DNS
		if [[ $DNS_STATE = 1 ]];then
				log "${GREEN}[+] $DNS_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $DNS_STATE = -1 ]];then
				log "[?] $DNS_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $DNS_MSG${NC}" $DEFAULT_LOG_LVL
		fi


		#Intranet
		if [[ $INTRANET_STATE = 1 ]];then
				log "${GREEN}[+] $INTRANET_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $INTRANET_STATE = -1 ]];then
				log "[?] $INTRANET_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $INTRANET_MSG${NC}" $DEFAULT_LOG_LVL
		fi
		
		#Internet
		if [[ $INTERNET_STATE = 1 ]];then
				log "${GREEN}[+] $INTERNET_MSG${NC}" $DEFAULT_LOG_LVL
		elif [[ $INTERNET_STATE = -1 ]];then
				log "[?] $INTERNET_MSG" $DEFAULT_LOG_LVL
		else
				log "${RED}[-] $INTERNET_MSG${NC}" $DEFAULT_LOG_LVL
		fi
		
		log "${YELLOW}$LINE_DELIMITER${NC}" $DEFAULT_LOG_LVL
}

function set_network_states {
		value=$1

		INTERFACE_STATE=$value
		PRIVATE_IP_MSG=$value
		LAN_STATE=$value
		DNS_STATE=$value
		INTRANET_STATE=$value
		INTERNET_STATE=$value
}

function check_all_on_interface {
		interface_name="$1"
		check_interface_self_connectivity $interface_name
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		check_lan_connectivity $interface_name
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		#protocols must be checked as soon as lan seems to be connected
		#we won't return of the protocol is not available
		check_dns $interface_name
		errno=$?

		check_intranet_connectivity $interface_name
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		check_internet_connectivity $interface_name
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
}




function restart_interface {

		
		interface_name="$1"
		log "${BLUE}[*] restarting interface $interface_name" $VERBOSE_LOG_LVL
		sudo ip link set $interface_name "down"
		errno=$?
		if [[ $errno != 0 ]];then
				log "${RED}failed to shutdown $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi		

		sudo ip link set $interface_name up
		errno=$?
		if [[ $errno != 0 ]];then
				log "${RED} failed to bring up $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi
	
		sleep $INTERFACE_CHANGE_STATE_SLEEP
}

function dhcp_renew {
		
		interface_name="$1"
		log "${BLUE}[*] renewing ip of $interface_name${NC}" $VERBOSE_LOG_LVL
		sudo dhclient -r $interface_name>&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				log "${RED}[-] failed to release ip of $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi		

		sudo dhclient -nw $interface_name>&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				log "${RED}[-] failed to renew ip of $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi

		sleep $DHCP_COMPLETION_SLEEP
}

function restart_and_renew_interface {
#this exist because we may need to set other attributes too, like mtu, ttl
		interface_name="$1"
		restart_interface $interface_name
		dhcp_renew $interface_name
}

function set_reliable_dns {
		log "${BLUE}[*] setting reliable dns${NC}" $VERBOSE_LOG_LVL

		sudo sh -c "echo nameserver $RELIABLE_DNS_SERVER1 > /etc/resolv.conf"
		sudo sh -c "echo nameserver $RELIABLE_DNS_SERVER2 > /etc/resolv.conf"
}

function try_to_fix_interface {
		interface_name="$1"
		if [[ $INTERFACE_STATE = 0 ]];then
				log "${BLUE}[*] restarting interface $interface_name${NC}" $VERBOSE_LOG_LVL
				restart_interface $interface_name
		fi
		if [[ $PRIVATE_IP_STATE = 0 ]];then
				dhcp_renew $interface_name
		fi
		if [[ $DNS_STATE = 0 ]];then
				set_reliable_dns
		fi


}

function handle_args {

		while getopts "vdhni:" name;do
					case $name in
					v)
							CURRENT_LOG_LVL=$VERBOSE_LOG_LVL;;
					d)
							CURRENT_LOG_LVL=$DEBUG_LOG_LVL;;
					h)
							echo -e $HELP
							exit 1;;
					n)
							TRY_TO_FIX=0;;
					i)
							INCLUDED_INTERFACES=$OPTARG;;
					?)    
							echo -e $HELP
							exit 1;;
					esac
		done

}

function did_interface_improve {
		
		if [[ $TRY_TO_FIX = 0 ]] && [[ $INTERFACE_STATE != -1 ]];then
				echo 0
				return
		fi
		if [[ $INTERFACE_STATE > $LAST_INTERFACE_STATE ]] || [[ $INTERFACE_STATE = -1 ]];then
				echo 1
				return
		fi
		if [[ $PRIVATE_IP_STATE > $LAST_PRIVATE_IP_STATE ]] || [[ $PRIVATE_IP_STATE = -1 ]];then
				echo 1 	
				return
		fi
		if [[ $LAN_STATE > $LAST_LAN_STATE ]] || [[ $LAN_STATE = -1 ]];then
				echo 1 	
				return
		fi
		if [[ $INTRANET_STATE > $LAST_INTRANET_STATE ]] || [[ $INTRANET_STATE = -1 ]];then
				echo 1 	
				return
		fi
		if [[ $INTERNET_STATE > $LAST_INTERNET_STATE ]] || [[ $INTERNET_STATE = -1 ]];then 	
				echo 1 	
				return
		fi
		echo 0	
		return
}

function update_last_network_states {
		LAST_INTERFACE_STATE=$INTERFACE_STATE
		LAST_PRIVATE_IP_STATE=$PRIVATE_IP_STATE
		LAST_LAN_STATE=$LAN_STATE
		LAST_DNS_STATE=$DNS_STATE
		LAST_INTRANET_STATE=$INTRANET_STATE
		LAST_INTERNET_STATE=$INTERNET_STATE
}


function determine_target_interfaces {

		if ! [ -z $INCLUDED_INTERFACES ];then
				TARGET_INTERFACES="$INCLUDED_INTERFACES"
				return
		fi

		TARGET_INTERFACES=$(get_interfaces_with_default_gw)

		if [ -z "$TARGET_INTERFACES" ];then
				if [[ $TRY_TO_FIX = 1 ]];then
						#might want to add default gateway based on icmp scan?
						log "${RED}[-] no interfaces to get to internet refreshing all interfaces${NC}" $DEFAULT_LOG_LVL
						IFS=$INTERFACE_LIST_DELIMITER
						for interface in $(get_all_interfaces);do
								restart_and_renew_interface $interface
						done

						TARGET_INTERFACES=$(get_interfaces_with_default_gw)
				fi
				if [ -z "$TARGET_INTERFACES" ];then
						log "${RED}[-] no interfaces to get to internet exiting${NC}" $DEFAULT_LOG_LVL
						exit 1
				fi
				TARGET_INTERFACES=$(get_interfaces_with_default_gw)
				
		fi


}

function main {
		handle_args $@

		if [[ $TRY_TO_FIX = 1 ]] && [[ $EUID != 0 ]];then
				exec sudo bash $0 $@
		fi

		determine_target_interfaces

		log "${YELLOW}[*] interfaces to troubleshoot: $TARGET_INTERFACES${NC}" $VERBOSE_LOG_LVL
		if [[ $CURRENT_LOG_LVL -ge $DEBUG_LOG_LVL ]];then
				REDIRECT_DEST="1"
		fi
	
		IFS=$INTERFACE_LIST_DELIMITER
		for interface in $TARGET_INTERFACES;do


				#resetting the states for the current iteration
				set_network_states -1
				update_last_network_states
				while [[ $(did_interface_improve) = 1 ]];do
						update_last_network_states
						log "${YELLOW}[*] troubleshooting $interface${NC}" $DEFAULT_LOG_LVL
						CURRENT_INTERFACE=$interface
						
						check_all_on_interface $interface
						check_network_states
						
						if [[ $TRY_TO_FIX = 1 ]];then
								try_to_fix_interface $interface
						fi

				done		

		done
}

main $@



