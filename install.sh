#!/bin/bash

OLD_IFS="$IFS"

#all of packages get "abs" prefix, including Libraries
GLOBAL_PREFIX="abs"
DESTINATION_DIR="/usr/bin"
#list of tuples of (source_directory,prefix)
INSTALL_SOURCES_DELIM=","
INSTALL_SOURCES="\
Scripts${INSTALL_SOURCES_DELIM}
Libraries${INSTALL_SOURCES_DELIM}lib"

#maybe this should be a library too!
#abs_install(source_dir, destination_dir, name_prefix)
abs_install(){
		# Set the source and destination directories
		source_dir="$1"
		destination_dir="$2"
		prefix="$3"

		prefix_of_package=""
		if [ -z $prefix ];then
				prefix_of_package="$GLOBAL_PREFIX."
		else
				prefix_of_package="$GLOBAL_PREFIX.$prefix."
		fi

		# Find all scripts in the source directory and its subdirectories
		script_files=$(find "$source_dir" -type f -name "*.sh")


		OLD_IFS="$IFS"
		IFS=$'\n';
		for script in $script_files; do
			new_name="${prefix_of_package}$(basename "$script" .sh)"
			sudo cp -p "$script" "$destination_dir/$new_name";
			chmod +x "$destination_dir/$new_name";
			echo "installed : $new_name" 
		done
		IFS=$OLD_IFS


}

for src in $INSTALL_SOURCES;do
		dir=$(echo $src | cut -d $INSTALL_SOURCES_DELIM -f 1)
		prefix=$(echo $src | cut -d $INSTALL_SOURCES_DELIM -f 2)
		echo installing $dir with prefix $prefix in $DESTINATION_DIR
		abs_install "$dir" "$DESTINATION_DIR" "$prefix"
done

echo ""
echo "Awesome Bash Scripts Successfully Installed."
echo "You can use the abs.script_name command to run the scripts or type [abs.] and press tab to see the list of scripts."
