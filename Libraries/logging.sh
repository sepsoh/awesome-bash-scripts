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

# set_log_lvl(string_lvl)
# Sets the current logging level based on a string input.
# Parameters:
#   lvl - The log level to set ("debug", "info", "warning", "error", "critical").
# Behavior:
#   Updates the CURRENT_LOG_LVL variable to match the corresponding numeric log level.
#   If an invalid level is passed, no changes are made, and the function exits silently.
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


# log_lvl_to_color(log_lvl)
# Converts a numeric log level to its corresponding color code.
# Parameters:
#   lvl - The numeric log level to convert.
# Returns:
#   The color code associated with the provided log level.
# Behavior:
#   Prints the appropriate color for the given log level to stdout.
#   If the log level is invalid, no output is produced.
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


# log(lvl, msg, dst=&1)
# Logs a message if the current logging level is less than or equal to the provided log level.
# Parameters:
#   lvl - The numeric log level of the message (LOG_LVL_DEBUG, LOG_LVL_INFO, etc.).
#   msg - The message to log.
#   dst - (Optional) The file descriptor to log to (default: stdout).
# Behavior:
#   Logs the message to the specified destination if CURRENT_LOG_LVL <= lvl.
#   The log message is color-coded and includes a timestamp.
#   To remote the timestamp from the message 'DATE_FMT=""'
function log() {
		lvl="$1"
		msg="$2"
		dst="$3"
		print_color=$(log_lvl_to_color $lvl)

		if [ -z "$dst" ];then
				dst="$DEFAULT_LOG_DST"
		fi


		if [[ $CURRENT_LOG_LVL -le $lvl ]];then
				printf "$print_color%s %s$Color_Off\n" "$(date +"$DATE_FMT")" "$msg" >&$dst
		fi
}
