#!/bin/bash

#terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#runtime flags/configs
VERBOSE_FLAG=0
REDIRECT_DEST="/dev/null"
PING_COUNT="4"
TIMEOUT="1"
INTERFACE_CHANGE_STATE_SLEEP="1"
DHCP_COMPLETION_SLEEP="10"

HELP="-v verbose flag"

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
HTTPS_STATE=-1
HTTP_STATE=-1

#used to see if the condition of the interface has improved
LAST_INTERFACE_STATE=-1
LAST_PRIVATE_IP_STATE=-1
LAST_LAN_STATE=-1
LAST_INTRANET_STATE=-1
LAST_INTERNET_STATE=-1

#interfaces that are expected to be able to reach internet
TARGET_INTERFACES=""
#script runs for the first target and after the fix can run for the other
CURRENT_INTERFACE=""

#used to seperate the output of some function from another
LINE_DELIMITER="--------------------------"

#get functions:
function get_all_interfaces {
		ip addr | grep -E "[[:digit:]]+: [[:alnum:]]+" | cut -f2 -d' ' | sed -e "s/://g" | uniq | tr $'\n' ' '
}
#used to provide needed data such as interface list
function get_interfaces_with_default_gw {
#interfaces used to get to the internet
		ip route | grep -E "^default .* dev" | grep -o -E "dev [[:alnum:]]+" | cut -f2 -d ' ' | uniq | tr $'\n' ' ' 
}

function get_default_gws_of_interface {
#default gateways of interface
		interface_name="$1"
		ip route | grep -E "^default" | grep $interface_name | grep -o -E "$IPV4_REGEX" | tr $'\n' ' '
}

function get_interface_ipv4s {
		interface_name="$1"
		ip -o addr | grep $interface_name | grep -o -E "$IPV4_REGEX$IPV4_NETMASK_REGEX" | cut -f1 -d "/" | tr $'\n' ' '
}


#check functions:
#used to check if a certain functionality of the device properly
function check_if_interface_ip_is_static {
		interface_name="$1"
		interface_ip="$2"
		ip -o addr | grep "$interface_name" | grep "$interface_ip" | grep "dynamic"
		#0 on finding the work dynamic
		#1 on not finding it 
		return $?

}
function check_internet_connectivity {
		interface_name="$1"
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest=$INTERNET_DOMAINS
		else
				ping_dest=$INTERNET_IPV4S
		fi

		echo -e ${BLUE}[*] checking internet connectivity for $interface_name${NC}
		IFS=","
		for host in $ping_dest;do
				if ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						INTERNET_STATE=1
						return 0
				fi
		done
		

		echo -e ${RED}[-] $interface_name can\'t reach the internet${NC}
		INTERNET_STATE=0
		return 1
}
function check_intranet_connectivity {
		interface_name="$1"
		ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest=$INTRANET_DOMAINS
		else
				ping_dest=$INTRANET_DOMAINS
		fi

		echo -e ${BLUE}[*] checking intranet connectivity for $interface_name${NC}
		IFS=","
		for host in $ping_dest;do
				if ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						return 0
				fi
		done
		
		echo -e ${RED}[-] $interface_name can\'t reach the intranet${NC}
		INTRANET_STATE=0
		INTERNET_STATE=0
		return 1
} 
function check_lan_connectivity {
#ping default gateway
		interface_name="$1"
		default_gws=$(get_default_gws_of_interface $interface_name)
		echo -e ${BLUE}[*] checking LAN connectivity for $interface_name${NC}
		

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
		echo -e ${RED}[-] $interface_name can\'t reach it\'t LAN${NC}
		return 1
}
function check_dns {
#need to check what dns client is present and use that
#so this function need to call one of the check_dns_nslookup, check_dns_host, check_dns_dig, etc
		#is not used currently
		interface_name="$1"

		echo -e ${BLUE}[*] checking DNS${NC}
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
		echo -e ${RED}[-] DNS doesn\'t work${NC}
		DNS_STATE=0
		return 1
}

function check_interface_self_connectivity {
		interface_name="$1"
		interface_ips=$(get_interface_ipv4s $interface_name)
		
		echo -e ${BLUE}[*] checking interface self connectivity for $interface_name${NC}
		IFS=$' '
		for ip in $interface_ips;do
				ping -W $TIMEOUT -c $PING_COUNT -I $interface_name $ip >&$REDIRECT_DEST
				errno=$?
				if [[ $errno != 0 ]];then
						echo -e ${RED}[-] $ip is not  reachable via $interface_name${NC}
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
		INTRANET_MSG="Intranet reachability"
		INTERNET_MSG="Internet reachability"

		echo -e ${YELLOW}$LINE_DELIMITER${NC}
		echo -e current network stats of $CURRENT_INTERFACE:

		#interface
		if [[ $INTERFACE_STATE = 1 ]];then
				echo -e ${GREEN}[+] $INTERFACE_MSG${NC}
		elif [[ $INTERFACE_STATE = -1 ]];then
				echo -e [?] $INTERFACE_MSG
		else
				echo -e ${RED}[-] $INTERFACE_MSG${NC}
		fi

		#private ip
		if [[ $PRIVATE_IP_STATE = 1 ]];then
				echo -e ${GREEN}[+] $PRIVATE_IP_MSG${NC}
		elif [[ $PRIVATE_IP_MSG = -1 ]];then
				echo -e [?] $PRIVATE_IP_MSG
		else
				echo -e ${RED}[-] $PRIVATE_IP_MSG${NC}
		fi

		#LAN
		if [[ $LAN_STATE = 1 ]];then
				echo -e ${GREEN}[+] $LAN_MSG${NC}
		elif [[ $LAN_STATE = -1 ]];then
				echo -e [?] $LAN_MSG
		else
				echo -e ${RED}[-] $LAN_MSG${NC}
		fi

		#Intranet
		if [[ $INTRANET_STATE = 1 ]];then
				echo -e ${GREEN}[+] $INTRANET_MSG${NC}
		elif [[ $INTRANET_STATE = -1 ]];then
				echo -e [?] $INTRANET_MSG
		else
				echo -e ${RED}[-] $INTRANET_MSG${NC}
		fi
		
		#Internet
		if [[ $INTERNET_STATE = 1 ]];then
				echo -e ${GREEN}[+] $INTERNET_MSG${NC}
		elif [[ $INTERNET_STATE = -1 ]];then
				echo -e [?] $INTERNET_MSG
		else
				echo -e ${RED}[-] $INTERNET_MSG${NC}
		fi
		
		echo -e ${YELLOW}$LINE_DELIMITER${NC}
}

function set_network_states {
		value=$1

		INTERFACE_STATE=$value
		PRIVATE_IP_MSG=$value
		LAN_STATE=$value
		INTRANET_STATE=$value
		INTERNET_STATE=$value
}

function init_states {
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

		#will uncomment after appropriate implementation of the function
		#check_intranet_connectivity $interface_name
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
		echo -e ${BLUE}[*] restarting interface $interface_name
		sudo ip link set $interface_name "down"
		errno=$?
		if [[ $errno != 0 ]];then
				echo -e ${RED}failed to shutdown $interface_name${NC}
				return 1
		fi		

		sudo ip link set $interface_name up
		errno=$?
		if [[ $errno != 0 ]];then
				echo ${RED} failed to bring up $interface_name${NC}
				return 1
		fi
	
		sleep $INTERFACE_CHANGE_STATE_SLEEP
}

function dhcp_renew {
		
		interface_name="$1"
		echo -e ${BLUE}[*] renewing ip of $interface_name${NC}
		sudo dhclient -r $interface_name>&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				echo -e ${RED}[-] failed to release ip of $interface_name${NC}
				return 1
		fi		

		sudo dhclient -nw $interface_name>&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				echo -e ${RED}[-] failed to renew ip of $interface_name${NC}
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

function try_to_fix_interface {
#uses $CURRENT_INTERFACE
		interface_name="$1"
		if [[ $INTERFACE_STATE = 0 ]];then
				echo -e ${BLUE}[*] restarting interface $interface_name${NC}
				restart_interface $interface_name
		fi
		if [[ $PRIVATE_IP_STATE = 0 ]];then
				dhcp_renew $interface_name
		fi


}

function handle_args {
		for arg in $@;do
				if [ "$arg" = "-v" ];then
						export VERBOSE_FLAG=1
				elif [ "$arg" = "-h" ];then
						echo -e $HELP
						exit 1
				fi				
		done
}

function did_interface_improve {
		
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
		LAST_INTRANET_STATE=$INTRANET_STATE
		LAST_INTERNET_STATE=$INTERNET_STATE
}

function main {
		handle_args $@
		TARGET_INTERFACES=$(get_interfaces_with_default_gw)

		if [ -z "$TARGET_INTERFACES" ];then
				#might want to add default gateway based on icmp scan?
				echo -e ${RED}[-] no interfaces to get to internet refreshing all interfaces${NC}
				IFS=" "
				for interface in $(get_all_interfaces);do
						restart_and_renew_interface $interface
				done

				TARGET_INTERFACES=$(get_interfaces_with_default_gw)
				if [ -z "$TARGET_INTERFACES" ];then
						echo -e ${RED}[-] no interfaces to get to internet exiting${NC}
						exit 1
				fi
				TARGET_INTERFACES=$(get_interfaces_with_default_gw)
				
		fi

		echo -e ${BLUE}[*] interfaces to troubleshoot: $TARGET_INTERFACES${NC}
		if [[ $VERBOSE_FLAG = 1 ]];then
				REDIRECT_DEST="1"
		fi
	
		IFS=" "
		for interface in $TARGET_INTERFACES;do


				#resetting the states for the current iteration
				set_network_states -1
				update_last_network_states
				while [[ $(did_interface_improve) = 1 ]];do
						echo -e ${BLUE}[*] troubleshooting $interface${NC}
						CURRENT_INTERFACE=$interface
						
						update_last_network_states
						init_states $interface
						
						try_to_fix_interface $interface
						check_network_states

				done		

		done
}

main $@



