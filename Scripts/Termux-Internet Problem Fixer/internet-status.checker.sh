#!/bin/bash

#used to push and pop IFS
OLD_IFS=$IFS

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

HELP="\
Internet status checker\\n\
Options:\n\
\t-v\tverbose\n\
\t-d\tdebug: redirects the used commands to stdout\n\
\t-p PING_OPTION=VALUE,..\tpass arbitrary switches to pings used in the script, seperated by ',' and wrappen in double qoutes '\"'\n\
\t\treserved switches: (-A, -I, -c, -W) there are other switches to set arbitrary value for -c, -W\n\
\t-W TIMEOUT\tset value for -W switch of ping\n\
\t-c COUNT\tset value for -c switch of ping\n\
\t-i INTERFACE_IP\tset value for interface ip, interface self connectivity won't be checked if not set\n\
\t-g GATEWAY_IP\tset value for gateway ip, if lan connectivity won't be checked if not set\n\
\n\
Usage Examples:\n\
\t$0 -p \"-t=64,-r\"\tput -t 64 -r before other ping switches
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

#used to seperate the output of some function from another
LINE_DELIMITER="--------------------------"

#log levels
#10-40 and 60-90 are reserved for the future use
DEFAULT_LOG_LVL=0
VERBOSE_LOG_LVL=50
DEBUG_LOG_LVL=100

CURRENT_LOG_LVL=$DEFAULT_LOG_LVL

#COMMANDNAME_SWITCHES are used along each COMMANDNAME, this is portability (to test if different switches work on current machine)
#init_COMMANDNAME_switches will be called at the start of the script and fill COMMANDNAME_SWITCHES
#these switches are currently assumed to work for ping: -c, -I, -W
#switches that will be used if availbale: -A
PING_SWITCHES=""

#assumed global variables typically to test things when an actual valid one is not availbale
ASSUMED_RELIABLE_IP="127.0.0.1"


INTERFACE_IP=""
GATEWAY_IP=""

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


function check_internet_connectivity {
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTERNET_DOMAINS[@]}"
		else
				ping_dest="${INTERNET_IPV4S[@]}"
		fi

		log "${BLUE}[*] checking internet connectivity${NC}" $VERBOSE_LOG_LVL
		log "ping destintaion:$ping_dest" $DEBUG_LOG_LVL

		OLD_IFS=$IFS
		IFS=" "
		for host in ${ping_dest[@]};do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						INTERNET_STATE=1
						return 0
				fi
		done
		IFS=$OLD_IFS
		

		log "${RED}[-]can't reach the internet${NC}" $VERBOSE_LOG_LVL

		INTERNET_STATE=0
		return 1
}
function check_intranet_connectivity {
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTRANET_DOMAINS[@]}"
		else
				ping_dest="${INTRANET_IPV4S[@]}"
		fi

		log "${BLUE}[*] checking intranet connectivity for ${NC}" $VERBOSE_LOG_LVL
		log "ping dest:$ping_dest" $DEBUG_LOG_LVL

		OLD_IFS=$IFS
		IFS=" "
		for host in ${ping_dest[@]};do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						return 0
				fi
		done
		IFS=$OLD_IFS
		
		log "${RED}[-]can't reach the intranet${NC}" $VERBOSE_LOG_LVL
		INTRANET_STATE=0
		INTERNET_STATE=0
		return 1
} 
function check_lan_connectivity {
#ping default gateway
		log "${BLUE}[*] checking LAN connectivity for ${NC}" $VERBOSE_LOG_LVL
	
		OLD_IFS=$IFS
		IFS=" "
		for host in $default_gws;do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						return 0
				fi
		done
		IFS=$OLD_IFS
		
		PRIVATE_IP_STATE=0
		LAN_STATE=0
		INTRANET_STATE=0
		INTERNET_STATE=0
		
		log "${RED}[-]can't reach it't LAN${NC}" $VERBOSE_LOG_LVL
		return 1
}
function check_dns {
#need to check what dns client is present and use that
#so this function need to call one of the check_dns_nslookup, check_dns_host, check_dns_dig, etc
		#is not used currently
		log "${BLUE}[*] checking DNS${NC}" $VERBOSE_LOG_LVL

		OLD_IFS=$IFS
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
		IFS=$OLD_IFS

		log "${RED}[-] DNS doesn't work${NC}" $VERBOSE_LOG_LVL
		DNS_STATE=0
		return 1
}

function check_interface_self_connectivity {
		log "${BLUE}[*] checking interface self connectivity${NC}" $VERBOSE_LOG_LVL

		OLD_IFS=$IFS
		IFS=$' '
		for ip in $interface_ips;do
				ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT $ip >&$REDIRECT_DEST
				errno=$?
				if [[ $errno != 0 ]];then
						log "${RED}[-] $ip is not  reachable${NC}" $VERBOSE_LOG_LVL
						#if interface can't ping itself it cant reach anything
						set_network_states 0
						return 1
				fi
		done
		IFS=$OLD_IFS
						
		INTERFACE_STATE=1
		return 0
}
function check_network_states_and_display {
		INTERFACE_MSG="network interface"
		PRIVATE_IP_MSG="private ip usability"
		LAN_MSG="LAN reachability"
		DNS_MSG="DNS ( not currently interface dependent )"
		INTRANET_MSG="Intranet reachability"
		INTERNET_MSG="Internet reachability"

		log "${YELLOW}$LINE_DELIMITER${NC}" $DEFAULT_LOG_LVL
		log "current network stats :" $DEFAULT_LOG_LVL

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

function check_all_and_update_status {
		errno=0
		if ! [ -z $INTERFACE_IP ];then
				check_interface_self_connectivity 
		fi
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		if ! [ -z $GATEWAY_IP ];then
				check_lan_connectivity 
		fi
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		#protocols must be checked as soon as lan seems to be connected
		#we won't return of the protocol is not available
		check_dns 
		errno=$?

		check_intranet_connectivity 
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		check_internet_connectivity 
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
}



function handle_args {

		while getopts "vdhp:W:c:i:g:" name;do
					case $name in
					v)
							CURRENT_LOG_LVL=$VERBOSE_LOG_LVL;;
					d)
							CURRENT_LOG_LVL=$DEBUG_LOG_LVL;;
					h)
							echo -e $HELP
							exit 1;;
					p) 		
							PING_SWITCHES=$(echo $OPTARG | tr '=' ' ' | tr ',' ' ');;
					W) 		
							TIMEOUT=$OPTARG;;
					c) 		
							PING_COUNT=$OPTARG;;
					i)
							INTERFACE_IP=$OPTARG;;
					g)
							GATEWAY_IP=$OPTARG;;
					?)    
							echo -e $HELP
							exit 1;;
					esac
		done

}

function init_ping_switches {
		#-A Adaptive ping
		if ping -c 1 -A $ASSUMED_RELIABLE_IP >&$REDIRECT_DEST;then
				PING_SWITCHES=$PING_SWITCHES" -A "
		else
				log "${BLUE} -A is not available for ping, the script will slow down drastically${NC}" $VERBOSE_LOG_LVL
		fi

		log "ping options: $PING_SWITCHES" $DEBUG_LOG_LVL
 }

function main {
		handle_args $@

		
		init_ping_switches

		if [[ $CURRENT_LOG_LVL -ge $DEBUG_LOG_LVL ]];then
				REDIRECT_DEST="1"
		fi
	
		#resetting the states for the current iteration
		
		check_all_and_update_status
		check_network_states_and_display
		
}

main $@



