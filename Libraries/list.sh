function scape_sed_special_chars {
		string_to_scape="$1"
		echo "$(<<<"$string_to_scape" sed -e 's`[][\\/.*^$]`\\&`g')"
}
#remove_list_from_list(list, list_delimiter, remove_list, remove_list_delimiter)
#removes remove_list from list and echoes the result
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


