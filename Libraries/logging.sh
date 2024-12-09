# shellcheck source=/usr/bin/abs.lib.colors
source abs.lib.colors
DATE_FMT="%Y-%m-%d %H:%M:%S"

LOG_LVL_DEBUG=0
LOG_LVL_INFO=10
LOG_LVL_WARNING=20
LOG_LVL_ERROR=30
LOG_LVL_CRITICAL=40

LOG_CLR_DEBUG=$Cyan
LOG_CLR_INFO=$White
LOG_CLR_WARNING=$Yellow
LOG_CLR_ERROR=$Red
LOG_CLR_CRITICAL=$BIRed



CURRENT_LOG_LVL=$LOG_LVL_INFO

DEFAULT_LOG_DST="1"

#set_log_lvl(string_lvl)
#either of "debug", "info", "warning", "error", "critical"
function set_log_lvl(){
		lvl="$1"
		case "$lvl" in

				"debug")
						CURRENT_LOG_LVL=$LOG_LVL_DEBUG
						;;

				"info")
						CURRENT_LOG_LVL=$LOG_LVL_INFO
						;;

				"warning")
						CURRENT_LOG_LVL=$LOG_LVL_WARNING
						;;

				"error")
						CURRENT_LOG_LVL=$LOG_LVL_ERROR
						;;


				"critical")
						CURRENT_LOG_LVL=$LOG_LVL_CRITICAL
						;;


				*)
						return
						;;
		esac


}


#_do_log(log_lvl)
#not meant to be called by the user
#converts the log level to the corresponding color
function log_lvl_to_color(){
		lvl="$1"

		print_color=""
		case "$lvl" in

				"$LOG_LVL_DEBUG")
						echo -E $LOG_CLR_DEBUG
						return	
						;;

				"$LOG_LVL_INFO")
						echo -E $LOG_CLR_INFO
						return	
						;;

				"$LOG_LVL_WARNING")
						echo -E $LOG_CLR_WARNING
						return	
						;;

				"$LOG_LVL_ERROR")
						echo -E $LOG_CLR_ERROR
						return
						;;


				"$LOG_LVL_CRITICAL")
						echo -E $LOG_CLR_CRITICAL
						return	
						;;


				*)
						return
						;;
		esac




}


#log(lvl,msg,dst=&1)
#logs the message if CURRENT_LOG_LVL <= lvl
function log() {
		lvl="$1"
		msg="$2"
		dst="$3"
		print_color=$(log_lvl_to_color $lvl)

		if [ -z "$dst" ];then
				dst="$DEFAULT_LOG_DST"
		fi


		if [[ $CURRENT_LOG_LVL -le $lvl ]];then
				printf "$print_color%s %s$Color_Off" "$(date +"$DATE_FMT")" "$msg" >&$dst
		fi
}
