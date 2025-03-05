if [ -n "$DEFINE_LIST_LIB" ];then
	return 0
fi

DEFINE_LIST_LIB=1

# scape_sed_special_chars(string_to_scape)
# Escapes special characters in a string for safe usage in sed commands.
# Parameters:
#   string_to_scape - The string containing characters to escape.
# Returns:
#   The input string with all sed special characters properly escaped.
function scape_sed_special_chars {
		string_to_scape="$1"
		echo "$(<<<"$string_to_scape" sed -e 's`[][\\/.*^$]`\\&`g')"
}

# remove_list_from_list(list, list_delimiter, remove_list, remove_list_delimiter)
# Removes all occurrences of elements in `remove_list` from `list`.
# Parameters:
#   list                  - The main list as a single string.
#   list_delimiter        - The delimiter separating elements in the main list.
#   remove_list           - The list of elements to remove, as a single string.
#   remove_list_delimiter - The delimiter separating elements in the remove list.
# Behavior:
#   Iterates through each element in `remove_list` and removes it from `list`.
#   Handles escaping of special characters in both lists for safety.
#   If `remove_list` is empty, the original `list` is echoed unchanged.
# Returns:
#   The updated list with elements from `remove_list` removed.
function remove_list_from_list {
		list="$1"
		delimiter_of_list="$2"
		remove_list="$3"
		delimiter_of_remove_list="$4"

		if [ -z "$remove_list" ];then
				echo "$list"
				return
		fi

		remove_list="$(scape_sed_special_chars $remove_list)"
		delimiter_of_list="$(scape_sed_special_chars $delimiter_of_list)"

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
		echo "$list"
}


