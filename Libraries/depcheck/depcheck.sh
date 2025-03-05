if [ -n "$DEFINE_DEPCHECK_LIB" ];then
	return 0
fi

DEFINE_DEPCHECK_LIB=1

# shellcheck source=/usr/bin/abs.lib.logging
source abs.lib.logging



DEP_ATTR_DELIM=","
DEP_NAME_POS=1
DEP_CMD_POS=2

function _dep_attr_extract(){
		dep="$1"
		pos="$2"
		delim="${3:-$DEP_ATTR_DELIM}"
		echo $dep | cut -f${pos} -d"$delim"
}

# Function: depcheck_cmd
# Description:
#   Reads dependencies from a file and checks if each dependency is available in the system using 'type'.
#   Each line should include both the package name of the dependancy and the command to test for availablility
#   Each entry should be in the format of (name${delim}cmd) ->--default delim----> (name,cmd)
#   Use this function if the dependancy provides a command, if not, use depcheck_lib()
# Parameters:
#   $1 - Filename containing dependencies.
#   $2 - Dependency attribute delimiter (default:',').
function depcheck_cmd(){
		filename="$1"
		dep_attr_delim="${2:-$DEP_ATTR_DELIM}"

		deps=""
		if ! deps=$(cat "$filename" 2> /dev/null);then
				log $LOG_LVL_ERROR "[$0]: can't read file: $filename"
				return 1
		fi

		while read -r line;do
				cmd="$(_dep_attr_extract "$line" "$DEP_CMD_POS" "$dep_attr_delim")"
				log $LOG_LVL_DEBUG "[$0]: checking cmd $cmd"

				if ! type $cmd &>/dev/null;then
						log "$LOG_LVL_ERROR" "[$0]: missing dependancy : $(_dep_attr_extract "$line" "$DEP_NAME_POS" "$dep_attr_delim")"
						IFS="$OLD_IFS"
						return 1
				fi

		done <<<"$deps"

		return 0
}

# Function: depcheck_cmd_fromstr
# Description:
#   Reads dependencies from a string and checks if each dependency is available in the system using 'type'.
#   Each line should include both the package name of the dependancy and the command to test for availablility
#   Each entry should be in the format of (name${delim}cmd) ->--default delim----> (name,cmd)
#   Use this function if the dependancy provides a command, if not, use depcheck_lib()
# Parameters:
#   $1 - Dependencies string.
#   $2 - Dependency attribute delimiter (default:',').
function depcheck_cmd_fromstr(){
		deps="$1"
		dep_attr_delim="${2:-$DEP_ATTR_DELIM}"

		while read -r line;do
				cmd="$(_dep_attr_extract "$line" "$DEP_CMD_POS" "$dep_attr_delim")"
				log $LOG_LVL_DEBUG "[$0]: checking cmd $cmd"

				if ! type $cmd &>/dev/null;then
						log "$LOG_LVL_ERROR" "[$0]: missing dependancy : $(_dep_attr_extract "$line" "$DEP_NAME_POS" "$dep_attr_delim")"
						IFS="$OLD_IFS"
						return 1
				fi

		done <<<"$deps"

		return 0
}

#TODO
function depcheck_lib(){
		log $CURRENT_LOG_LVL "not implemented yet"
		return 1
}
