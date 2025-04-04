#!/bin/bash

# shellcheck source=/usr/bin/abs.lib.depcheck
source abs.lib.depcheck
#used to push and pop IFS
OLD_IFS=$IFS

ESSENTIAL_DEPENDANCIES_CMD="\
inetutils-ping,ping
iproute2,ip
dnsutils,nslookup
isc-dhcp-client,dhclient\
"

WIFI_DEPENDANCIES_CMD="\
network-manager,NetworkManager
awesome bash scripts binary modules,abs.bin.TryToConnectToAccessPoint
awesome bash scripts binary modules,abs.bin.NetworkManager-GetAllAccessPoints
awesome bash scripts binary modules,abs.bin.GetAllWifiDevices\
"

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
INTERACTIVE_MODE=0


HELP="\
Internet problem fixer\\n\
Options:\n\
\t-v\t\t\t\tverbose\n\
\t-d\t\t\t\tdebug: redirect the used commands to stdout\n\
\t-n\t\t\t\tno fix: don't try to fix ( eliminate the requirement for the script to be root )\n\
\t-i INTERFACE_NAMES\t\tinclude interface: troubleshoot the provided interfaces only if used. -x will be ignored\n\
\t-I \t\t\t\tinteractive mode: if not set user won't be asked for input and will not be prompted for anything\n\
\t-x INTERFACE_NAMES\t\texclude interface: ignore the provided interfaces\n\
\t-p PING_OPTION=VALUE,..\t\tpass arbitrary switches to pings used in the script, seperated by ',' and wrappen in double qoutes '\"'\n\
\t\t*reserved switches: (-A, -I, -c, -W) there are other switches to set arbitrary value for -c, -W\n\
\t-W TIMEOUT\t\t\tset value for -W switch of ping\n\
\t-c COUNT\t\t\tset value for -c switch of ping\n\
\n\
Usage Examples:\n\
\t$0 -i eth0,wlan0\ttroubleshoot only eth0 and wlan0 interfaces\n\
\t$0 -n -i eth0\t\tshow the current states of eth0\n\
\t$0 -x tun0,lo\t\tignore tun0 and lo\n\
\t$0 -p \"-t=64,-r\"\tput -t 64 -r before other ping switches (like ping YOUR_SWITCHES SCRIPT_SCWITCHES DESTINATION)
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
DEFAULT_EXCLUDED_INTERFACES="\
lo${INTERFACE_LIST_DELIMITER}docker0${INTERFACE_LIST_DELIMITER}neko-tun${INTERFACE_LIST_DELIMITER}tun0\
"
EXCLUDED_INTERFACES=""
#-i --interface input
INCLUDED_INTERFACES=""

RELIABLE_DNS_SERVER1="8.8.8.8"
RELIABLE_DNS_SERVER2="8.8.4.4"

#used to seperate the output of some function from another
LINE_DELIMITER="--------------------------"

#_log levels
#10-40 and 60-90 are reserved for the future use
DEFAULT_LOG_LVL=0
VERBOSE_LOG_LVL=50
DEBUG_LOG_LVL=100


#renamed to _CURRENT_LOG_LVL to resolve conflict with abs.lib.logging
_CURRENT_LOG_LVL=$DEFAULT_LOG_LVL

#COMMANDNAME_SWITCHES are used along each COMMANDNAME, this is portability (to test if different switches work on current machine)
#init_COMMANDNAME_switches will be called at the start of the script and fill COMMANDNAME_SWITCHES
#these switches are currently assumed to work for ping: -c, -I, -W
#switches that will be used if availbale: -A
PING_SWITCHES=""

#assumed global variables typically to test things when an actual valid one is not availbale
ASSUMED_RELIABLE_IP="127.0.0.1"
#WARNING! ASSUMED_RELIABLE_IP must be reachable via ASSUMED_AVAILABLE_INTERFACE_NAME
ASSUMED_AVAILABLE_INTERFACE_NAME="lo"

#renamed to _log to resolve conflict with abs.lib.logging
function _log {
	local string="$1"
	local _log_level="$2"
	
	
	#should be dynamic based on the switches
	#like a user sometimes wants to send all of errors over a socket(s) and have the states shown in a terminal
	local dest=1

	if [[ $_CURRENT_LOG_LVL -ge $_log_level ]];then
			echo -e "$string">&$dest
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
		local interface_name="$1"
		ip route | grep -E "^default" | grep "$interface_name" | grep -o -E "$IPV4_REGEX" | tr $'\n' ' '
}

function get_interface_ipv4s {
		local interface_name="$1"
		ip -o addr | grep -E "^[[:digit:]]+: $interface_name" | grep -o -E "$IPV4_REGEX$IPV4_NETMASK_REGEX" | cut -f1 -d "/" | tr $'\n' ' '
}


function check_internet_connectivity {
		local interface_name="$1"
		local ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTERNET_DOMAINS[@]}"
		else
				ping_dest="${INTERNET_IPV4S[@]}"
		fi

		_log "${BLUE}[*] checking internet connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		_log "ping destintaion:$ping_dest" $DEBUG_LOG_LVL

		OLD_IFS=$IFS
		IFS=" "
		for host in ${ping_dest[@]};do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT -I "$interface_name" $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						INTERNET_STATE=1
						return 0
				fi
		done
		IFS=$OLD_IFS
		

		_log "${RED}[-] $interface_name can't reach the internet${NC}" $VERBOSE_LOG_LVL

		INTERNET_STATE=0
		return 1
}
function check_intranet_connectivity {
		local interface_name="$1"
		local ping_dest=""
		if [[ $DNS_STATE = 1 ]];then
				ping_dest="${INTRANET_DOMAINS[@]}"
		else
				ping_dest="${INTRANET_IPV4S[@]}"
		fi

		_log "${BLUE}[*] checking intranet connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		_log "ping dest:$ping_dest" $DEBUG_LOG_LVL

		OLD_IFS=$IFS
		IFS=" "
		for host in ${ping_dest[@]};do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT -I "$interface_name" $host>&$REDIRECT_DEST;then
						INTERFACE_STATE=1
						PRIVATE_IP_STATE=1
						LAN_STATE=1
						INTRANET_STATE=1
						return 0
				fi
		done
		IFS=$OLD_IFS
		
		_log "${RED}[-] $interface_name can't reach the intranet${NC}" $VERBOSE_LOG_LVL
		INTRANET_STATE=0
		INTERNET_STATE=0
		return 1
} 
function check_lan_connectivity {
#ping default gateway
		local interface_name="$1"
		local default_gws
		default_gws=$(get_default_gws_of_interface "$interface_name")

		_log "${BLUE}[*] checking LAN connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		_log "gateways of $interface_name: $default_gws" $DEBUG_LOG_LVL

		
		OLD_IFS=$IFS
		IFS=" "
		for host in $default_gws;do
				if ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT -I "$interface_name" $host>&$REDIRECT_DEST;then
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
		
		_log "${RED}[-] $interface_name can't reach it't LAN${NC}" $VERBOSE_LOG_LVL
		return 1
}
function check_dns {
#need to check what dns client is present and use that
#so this function need to call one of the check_dns_nslookup, check_dns_host, check_dns_dig, etc
		#is not used currently
		local interface_name="$1"

		_log "${BLUE}[*] checking DNS${NC}" $VERBOSE_LOG_LVL

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

		_log "${RED}[-] DNS doesn't work${NC}" $VERBOSE_LOG_LVL
		DNS_STATE=0
		return 1
}

function check_interface_self_connectivity {
		local interface_name="$1"
		local interface_ips
		interface_ips=$(get_interface_ipv4s "$interface_name")
		
		_log "${BLUE}[*] checking interface self connectivity for $interface_name${NC}" $VERBOSE_LOG_LVL
		_log "interface ips of $interface_name: $interface_ips" $DEBUG_LOG_LVL

		OLD_IFS=$IFS
		IFS=$' '
		for ip in $interface_ips;do
				ping $PING_SWITCHES -W $TIMEOUT -c $PING_COUNT -I "$interface_name" $ip >&$REDIRECT_DEST
				errno=$?
				if [[ $errno != 0 ]];then
						_log "${RED}[-] $ip is not  reachable via $interface_name${NC}" $VERBOSE_LOG_LVL
						#if interface can't ping itself it cant reach anything
						set_network_states 0
						return 1
				fi
		done
		IFS=$OLD_IFS
						
		INTERFACE_STATE=1
		return 0
}

function check_daemon {
	local daemon="$1"
	local do_prompt="$2"
	local confirm='n'

	if ! systemctl is-active "$daemon" &>$REDIRECT_DEST;then
			_log "${YELLOW}[!] $daemon is not running${NC}" "$_CURRENT_LOG_LVL" 
		if [[ $do_prompt -ne 0 ]];then
			_log "start and enable?[y/N]" "$_CURRENT_LOG_LVL"
			read -r confirm
		fi

		start_success=1 #err code
		if [ "$confirm" = 'y' ] || [ "$confirm" = 'Y' ];then
			sudo systemctl enable --now "$daemon" &>$REDIRECT_DEST
			start_success=$?
		fi

		if [[ $do_prompt -ne 0 ]] && [[ $start_success -eq 0 ]];then
			_log "${GREEN}[+] $daemon successfully started${NC}" "$_CURRENT_LOG_LVL"
		else
			_log "${RED}[-] failed to start $daemon ${NC}" "$_CURRENT_LOG_LVL"
		fi
	fi

	systemctl is-active "$daemon" &>$REDIRECT_DEST
	return $?
}

# check_daemon_* functions check if daemons needed for a certain feature are running or not
# Parameters: 
# 	do_prompt: if set to 1 then prompt the user to start and enable the daemon if not running
# Returns:
# 	non-zero on error

# checks for NetworkManager, iwd || wpa_supplicant
function check_daemon_wireless_support {
	local do_prompt="$1"

	check_daemon "NetworkManager" "$do_prompt"
	local networkmanager_status=$?
	
	if [[ $networkmanager_status -ne 0 ]];then
		_log "networkmanager_status=$networkmanager_status" "$DEBUG_LOG_LVL"
		return $networkmanager_status
	fi

	
	#why i called check_daemon two times for each of the iwd and wpa_supplicant?
	#answer: iwd and wpa_supplicant conflict with each other and should not be running both at the same time, 
	# 	 - so if either of them are running we don't need to do anything 
	# 	 	(note that the first check_daemon for each daemon are called with $do_prompt off, so we are only checking if they are active)
	# 	 - if non of them are active we try to start only one of them
	#output of the following two check_daemon's will be shown when we determine which of them are installed
	check_daemon "iwd" "" >/dev/null
	local iwd_status=$?

	check_daemon "wpa_supplicant" "" >/dev/null
	local wpa_supplicant_status=$?

	#if both are non-zero, then both failed (errcode != 0)
	if ((iwd_status && wpa_supplicant_status));then
		if type iwctl &>$REDIRECT_DEST;then
			check_daemon "iwd" "$do_prompt"
			iwd_status=$?
		elif type wpa_supplicant &>$REDIRECT_DEST;then
			check_daemon "wpa_supplicant" "$do_prompt"
			wpa_supplicant_status=$?
		else
			_log "${RED}[-] neither of iwd or wpa_supplicant are installed, at least one of them is needed for wifi support" "$_CURRENT_LOG_LVL"
		fi
	fi

	_log "iwd_status=$iwd_status, wpa_supplicant_status=$wpa_supplicant_status" "$DEBUG_LOG_LVL"
	
	if [[ $iwd_status -ne 0 ]] && [[ $wpa_supplicant_status -ne 0 ]];then
		return 1
	fi

	return 0

}

function echo_state {
		local state="$1"
		local msg="$2"

		#interface
		if [[ $state = 1 ]];then
				_log "${GREEN}[+] $msg${NC}" $DEFAULT_LOG_LVL
		elif [[ $state = -1 ]];then
				_log "[?] $msg" $DEFAULT_LOG_LVL
		else
				_log "${RED}[-] $msg${NC}" $DEFAULT_LOG_LVL
		fi


}

function echo_network_states {
		local INTERFACE_MSG="network interface"
		local PRIVATE_IP_MSG="private ip usability"
		local LAN_MSG="LAN reachability"
		local DNS_MSG="DNS ( not currently interface dependent )"
		local INTRANET_MSG="Intranet reachability"
		local INTERNET_MSG="Internet reachability"

		_log "${YELLOW}$LINE_DELIMITER${NC}" $DEFAULT_LOG_LVL
		_log "current network stats of $CURRENT_INTERFACE:" $DEFAULT_LOG_LVL

		#interface
		echo_state "$INTERFACE_STATE" "$INTERFACE_MSG"

		#private ip
		echo_state "$PRIVATE_IP_STATE" "$PRIVATE_IP_MSG"

		#LAN
		echo_state "$LAN_STATE" "$LAN_MSG"

		#DNS
		echo_state "$DNS_STATE" "$DNS_MSG"

		#Intranet
		echo_state "$INTRANET_STATE" "$INTRANET_MSG"
		
		#Internet
		echo_state "$INTERNET_STATE" "$INTERNET_MSG"
		
		_log "${YELLOW}$LINE_DELIMITER${NC}" $DEFAULT_LOG_LVL
}

function set_network_states {
		local value=$1

		INTERFACE_STATE=$value
		PRIVATE_IP_MSG=$value
		LAN_STATE=$value
		DNS_STATE=$value
		INTRANET_STATE=$value
		INTERNET_STATE=$value
}

function check_all_on_interface {
		local interface_name="$1"
		check_interface_self_connectivity "$interface_name"
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		check_lan_connectivity "$interface_name"
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		#protocols must be checked as soon as lan seems to be connected
		#we won't return of the protocol is not available
		check_dns "$interface_name"
		errno=$?

		check_intranet_connectivity "$interface_name"
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
		check_internet_connectivity "$interface_name"
		errno=$?
		if [[ $errno != 0 ]];then
				return 1 	
		fi
}




function restart_interface {

		
		local interface_name="$1"
		_log "${BLUE}[*] restarting interface $interface_name${NC}" $VERBOSE_LOG_LVL
		sudo ip link set "$interface_name" "down"
		errno=$?
		if [[ $errno != 0 ]];then
				_log "${RED}failed to shutdown $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi		

		sudo ip link set "$interface_name" up
		errno=$?
		if [[ $errno != 0 ]];then
				_log "${RED} failed to bring up $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi
	
		sleep $INTERFACE_CHANGE_STATE_SLEEP
}


function dhcp_renew {
		
		local interface_name="$1"
		_log "${BLUE}[*] renewing ip of $interface_name${NC}" $VERBOSE_LOG_LVL
		sudo dhclient -r "$interface_name">&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				_log "${RED}[-] failed to release ip of $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi		

		sudo dhclient -nw "$interface_name">&$REDIRECT_DEST
		errno=$?
		if [[ $errno != 0 ]];then
				_log "${RED}[-] failed to renew ip of $interface_name${NC}" $VERBOSE_LOG_LVL
				return 1
		fi

		sleep $DHCP_COMPLETION_SLEEP
}

function restart_and_renew_interface {
#this exist because we may need to set other attributes too, like mtu, ttl
		local interface_name="$1"
		restart_interface "$interface_name"
		dhcp_renew "$interface_name"
}

function restart_and_renew_all_interfaces {
	TARGET_INTERFACES="$(get_all_interfaces)"
	TARGET_INTERFACES="$(remove_list_from_list "$TARGET_INTERFACES" "$INTERFACE_LIST_DELIMITER" "$EXCLUDED_INTERFACES" "$INTERFACE_LIST_DELIMITER")"
	_log "targeted interfaces: $TARGET_INTERFACES" $DEBUG_LOG_LVL

	OLD_IFS=$IFS
	IFS="$INTERFACE_LIST_DELIMITER"
	for interface in $TARGET_INTERFACES;do
			restart_and_renew_interface "$interface"
	done
	IFS=$OLD_IFS
}

function set_reliable_dns {
		_log "${BLUE}[*] setting reliable dns${NC}" $VERBOSE_LOG_LVL

		sudo sh -c "echo nameserver $RELIABLE_DNS_SERVER1 > /etc/resolv.conf"
		sudo sh -c "echo nameserver $RELIABLE_DNS_SERVER2 > /etc/resolv.conf"
}

function try_to_fix_interface_wired {
		local interface_name="$1"

		if [[ $INTERFACE_STATE = 0 ]];then
				_log "${BLUE}[*] restarting interface $interface_name${NC}" $VERBOSE_LOG_LVL
				restart_interface "$interface_name"
		fi
		if [[ $PRIVATE_IP_STATE = 0 ]];then
				dhcp_renew "$interface_name"
		fi
}

function handle_args {

		while getopts "vdhni:Ix:p:W:c:f:" name;do
					case $name in
					v)
							_CURRENT_LOG_LVL=$VERBOSE_LOG_LVL;;
					d)
							_CURRENT_LOG_LVL=$DEBUG_LOG_LVL;;
					h)
							echo -e $HELP
							exit 1;;
					n)
							TRY_TO_FIX=0;;
					i)
							INCLUDED_INTERFACES="$OPTARG";;
					I)
							INTERACTIVE_MODE=1;;
					x)
							EXCLUDED_INTERFACES="$OPTARG";;
					p) 		
							PING_SWITCHES=$(echo "$OPTARG" | tr '=' ' ' | tr ',' ' ');;
					W) 		
							TIMEOUT="$OPTARG";;
					c) 		
							PING_COUNT="$OPTARG";;
					?)    
							echo -e $HELP
							exit 1;;
					esac
		done

}

function assign_default_value_args {
		if [ -z "$EXCLUDED_INTERFACES" ];then
			_log "${YELLOW}[!] the following interfaces are ignored by default, use -x to change: $DEFAULT_EXCLUDED_INTERFACES${NC}" $CURRENT_LOG_LVL
			EXCLUDED_INTERFACES="$DEFAULT_EXCLUDED_INTERFACES"
		fi
}

function is_current_interface_ok {
		if {
				[[ $INTERFACE_STATE = 1 ]] && 
				[[ $PRIVATE_IP_STATE = 1 ]] &&
				[[ $LAN_STATE = 1 ]] && 
				[[ $DNS_STATE = 1 ]] && 
				[[ $INTRANET_STATE = 1 ]] &&
				[[ $INTERNET_STATE = 1 ]]
		};then
				echo 1
		fi

		echo 0
}

function did_interface_improve {
			
		#if we don't try to fix the interface the states won't change
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

function scape_sed_special_chars {
		local string_to_scape="$1"
		echo "$(<<<"$string_to_scape" sed -e 's`[][\\/.*^$]`\\&`g')"
}

function remove_list_from_list {
		local list="$1"
		local delimiter_of_list="$2"
		local remove_list="$3"
		local delimiter_of_remove_list="$4"

		if [ -z "$remove_list" ];then
				echo "$list"
				return
		fi

		remove_list="$(scape_sed_special_chars "$remove_list")"
		delimiter_of_list="$(scape_sed_special_chars "$delimiter_of_list")"

		OLD_IFS=$IFS
		IFS="$delimiter_of_remove_list"
		for element in $remove_list;do
				list=$(sed -e "s/$element$delimiter_of_list//g" <<< $list)
				list=$(sed -e "s/$element//g" <<< $list)
		done
		IFS=$OLD_IFS

		#if list is empty
		if [ "$list" = "$delimiter_of_list" ];then
				return
		fi
		echo $list
}


function init_determine_target_interfaces {

		if [ -n "$INCLUDED_INTERFACES" ];then
				TARGET_INTERFACES="$INCLUDED_INTERFACES"
				_log "targeted interfaces: $TARGET_INTERFACES" $DEBUG_LOG_LVL
				return
		fi

		#this was initially a get_interfaces_with_default_gw call, but changed to get_all_interfaces call because:
		#1: wifi device may seem to be down because the system is using iwd
		#1-1: if we add wifi devices to TARGET_INTERFACES regardless of it's state, 
		#the later call on restart_and_renew_all_interfaces in main will probably be unreachable since there is always the wifi device in the TARGET_INTERFACES
		#2: if we don't add wifi device in this function, it would be unreliable since we want it to populate TARGET_INTERFACES correctly
		#3: testing all interfaces is way simpler than trying to figure out(reliably, since only this function manipulates TARGET_INTERFACES) what interfaces might be able to reach internet
		#TODO one negative side effect of this change is that any bridge interface will be included in TARGET_INTERFACES, maybe we can figure out what to do about this
		TARGET_INTERFACES="$(get_all_interfaces)"
		TARGET_INTERFACES="$(remove_list_from_list "$TARGET_INTERFACES" "$INTERFACE_LIST_DELIMITER" "$EXCLUDED_INTERFACES" "$INTERFACE_LIST_DELIMITER")"


		_log "targeted interfaces: $TARGET_INTERFACES" $DEBUG_LOG_LVL

}

function init_ping_switches {
		#-A Adaptive ping
		if ping -c 1 -A $ASSUMED_RELIABLE_IP >&$REDIRECT_DEST;then
				PING_SWITCHES=$PING_SWITCHES" -A "
		else
				_log "${BLUE} -A is not available for ping, the script will slow down drastically${NC}" $VERBOSE_LOG_LVL
		fi

		_log "ping options: $PING_SWITCHES" $DEBUG_LOG_LVL
}

#start of wifi support 

WIFI_DEV_PROPERTY_DELIM=","
WIFI_DEVS_DELIM=$'\n'
#NetworkManager device path,interface name
WIFI_DEVS=""


ACCESSPOINT_PROPERTY_DELIM=","
ACCESSPOINTS_DELIM=$'\n'
#NetworkManager device path,SSID,wpaflags
ACCESSPOINTS=""

function init_wifi_devs {
	WIFI_DEVS="$(abs.bin.GetAllWifiDevices --detailed 2>/dev/null)"
	_log "${BLUE}[*] found wifi devices:${NC}" $VERBOSE_LOG_LVL
	_log "${BLUE}[*] $WIFI_DEVS${NC}" $VERBOSE_LOG_LVL
}

function init_accesspoints {
	_log "${BLUE}[*] scanning for accesspoints${NC}" $_CURRENT_LOG_LVL
	ACCESSPOINTS="$(abs.bin.NetworkManager-GetAllAccessPoints --detailed 2>/dev/null)"
	_log "${BLUE}[*] found accesspoints:${NC}" $VERBOSE_LOG_LVL
	_log "${BLUE}[*] $ACCESSPOINTS:${NC}" $VERBOSE_LOG_LVL

	local found_ap_ssids=""

	IFS="$OLD_IFS"
	IFS="$ACCESSPOINTS_DELIM"
	for accesspoint in $ACCESSPOINTS;do
		found_ap_ssids="${found_ap_ssids} $(get_accesspoint_ssid "$accesspoint")"
	done
	_log "${BLUE}[*] found wifi accesspoints: $found_ap_ssids${NC}" $_CURRENT_LOG_LVL
}

function get_wifi_dev_interface_name {
	local wifi_dev="$1"
	echo "$wifi_dev" | cut -f 2 -d "$WIFI_DEV_PROPERTY_DELIM"
}

function get_wifi_dev_path {
	local wifi_dev="$1"
	echo "$wifi_dev" | cut -f 1 -d "$WIFI_DEV_PROPERTY_DELIM"
}

#nothing will be echoed if no device matches, it's responsibility of the caller to make sure the interface is wifi
function get_wifi_dev_from_interface_name {
	local interface_name="$1"

	OLD_IFS="$IFS"
	IFS="$WIFI_DEVS_DELIM"
	for device in $WIFI_DEVS; do
		if [ "$interface_name" = "$(get_wifi_dev_interface_name "$device")" ];then
			echo "$device"
			break
		fi
	done
	IFS="$OLD_IFS"
}

DENY_IS_WIFI=0
function is_wifi {
	if [[ $DENY_IS_WIFI -ne 0 ]];then
		return 1
	fi
	local interface_name="$1"

	errno=1

	OLD_IFS="$IFS"
	IFS="$WIFI_DEVS_DELIM"
	for wifi_dev in $WIFI_DEVS;do
		if [ "$(get_wifi_dev_interface_name "$wifi_dev")" = "$interface_name" ];then
			errno=0
		fi
	done
	IFS="$OLD_IFS"

	return $errno 
}

function get_accesspoint_path {
	local accesspoint="$1"
	echo "$accesspoint" | cut -f 1 -d "$ACCESSPOINT_PROPERTY_DELIM"
}


function get_accesspoint_ssid {
	local accesspoint="$1"
	echo "$accesspoint" | cut -f 2 -d "$ACCESSPOINT_PROPERTY_DELIM"
}


function try_to_fix_interface_wireless {
	local interface_name="$1"
	
	errno=1

	OLD_IFS="$IFS"
	IFS="$ACCESSPOINTS_DELIM"
	#try to connect to each accesspoint, if internet was availbale stop
	for accesspoint in $ACCESSPOINTS;do
		local device
		device="$(get_wifi_dev_from_interface_name "$interface_name")"
		abs.bin.TryToConnectToAccessPoint \
			--accesspoint_path $(get_accesspoint_path "$accesspoint" 2>/dev/null)\
			--device_path $(get_wifi_dev_path "$device" 2>/dev/null)\
			2>/dev/null
		errno=$?
		if [[ $errno -ne 0 ]];then
			continue
		fi
		_log "${BLUE}[*] connected to wireless network $(get_accesspoint_ssid "$accesspoint")${NC}" $_CURRENT_LOG_LVL
		if ! check_lan_connectivity "$interface_name" ;then
			dhcp_renew "$interface_name"
		fi
		if check_internet_connectivity "$interface_name" ;then
			errno=0
			# we don't care about other accesspoints if we reach the internet via the currrent one
			break
		fi
	done
	IFS="$OLD_IFS"

	return $errno
}
#end of wifi support


function try_to_fix_interface {
	local interface_name="$1"

	if is_wifi "$interface_name";then
		try_to_fix_interface_wireless "$interface_name"
		# try_to_fix_interface_wireless will call check_internet_connectivity, because it needs to know if the 
		# accesspoint it is currently connected to provides internet or not, so it can return 0 if internet connectivity is achived
		return $?
	else
		try_to_fix_interface_wired "$interface_name"
	fi

	#this applies to both wireless and wired interfaces
	if [[ $DNS_STATE = 0 ]];then
			set_reliable_dns
	fi
}


function main {
		
		#will assign default value of args when we ensured the script won't be called recursivly again, so each warning is shown once
		#so we call assign_default_value_args after the potential exec sudo bash $0 $@
		handle_args $@
		if [[ $TRY_TO_FIX = 1 ]] && [[ $EUID != 0 ]];then
				exec sudo bash "$0" $@
		fi
		assign_default_value_args

		if ! depcheck_cmd_fromstr "$ESSENTIAL_DEPENDANCIES_CMD"; then
			exit 1
		fi

		depcheck_cmd_fromstr "$WIFI_DEPENDANCIES_CMD"
		local wifi_dependancies_met=$?
		check_daemon_wireless_support $INTERACTIVE_MODE
		local wifi_daemons_running=$?

		if ((wifi_dependancies_met || wifi_daemons_running));then
			DENY_IS_WIFI=1
			_log "${YELLOW}[!] wifi support dependencies are not met, will treat wifi interfaces like wired interfaces${NC}" $_CURRENT_LOG_LVL
		fi
		


		#if there's a interface that has 'tun' in it, it's probably a tunnel interface, we advice the user to turn off the vpn
		if ip addr | grep tun >$REDIRECT_DEST;then
				_log "${YELLOW}[!] please turn off your vpn${NC}" $DEFAULT_LOG_LVL
		fi

		if [[ $DENY_IS_WIFI -eq 0 ]];then
			init_wifi_devs
			init_accesspoints
		fi
		init_determine_target_interfaces
		init_ping_switches

		#if no interface with default gateway found
		if [ -z "$TARGET_INTERFACES" ];then
				_log "${RED}[-] no interfaces to get to internet exiting${NC}" $DEFAULT_LOG_LVL
				exit 1
		fi


		_log "${YELLOW}[*] interfaces to troubleshoot: $TARGET_INTERFACES${NC}" $VERBOSE_LOG_LVL
		if [[ $_CURRENT_LOG_LVL -ge $DEBUG_LOG_LVL ]];then
				REDIRECT_DEST="1"
		fi
	
		OLD_IFS=$IFS
		IFS=$INTERFACE_LIST_DELIMITER
		for interface in $TARGET_INTERFACES;do

				#resetting the states for the current iteration
				set_network_states -1
				update_last_network_states
				while [[ $(did_interface_improve) = 1 ]] && [[ $(is_current_interface_ok) = 0 ]];do
						update_last_network_states
						_log "${YELLOW}[*] troubleshooting $interface${NC}" $DEFAULT_LOG_LVL
						CURRENT_INTERFACE=$interface
						
						check_all_on_interface "$interface"
						echo_network_states
						
						if [[ $TRY_TO_FIX = 1 ]] && [[ $INTERNET_STATE -ne 1 ]];then
								try_to_fix_interface "$interface"
						fi

				done		

				if [[ $INTERNET_STATE -eq 1 ]];then
					exit 0
				fi
		done
		IFS=$OLD_IFS
}

main $@



