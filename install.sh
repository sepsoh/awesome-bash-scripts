#!/bin/bash

OLD_IFS="$IFS"

#all of packages get "abs" prefix, including Libraries
GLOBAL_PREFIX="abs"
DESTINATION_DIR="/usr/bin"
#list of tuples of (source_directory,prefix)
INSTALL_SOURCES_DELIM=","

#each install source is in this format
#source_dir,prefix of installed file name,type of file (none for elf files),is optional to install
#if the 'is optional to install' is not zero length it should be interpreted as true, and it should be populated with 'Optional' keyword for better readability
INSTALL_SOURCES="\
Scripts${INSTALL_SOURCES_DELIM}${INSTALL_SOURCES_DELIM}.sh${INSTALL_SOURCES_DELIM}
Libraries${INSTALL_SOURCES_DELIM}lib${INSTALL_SOURCES_DELIM}.sh${INSTALL_SOURCES_DELIM}
Binary_Modules/bin/${INSTALL_SOURCES_DELIM}bin${INSTALL_SOURCES_DELIM}${INSTALL_SOURCES_DELIM}Optional
"

#maybe this should be a library too!
#abs_install(source_dir, destination_dir, name_prefix)
abs_install(){
		# Set the source and destination directories
		source_dir="$1"
		destination_dir="$2"
		prefix="$3"
		file_type="$4" #used as a regex, for example if .sh is passed all files matching *.sh will be installed from the source_dir

		prefix_of_package=""
		if [ -z $prefix ];then
				prefix_of_package="$GLOBAL_PREFIX."
		else
				prefix_of_package="$GLOBAL_PREFIX.$prefix."
		fi

		# Find all scripts in the source directory and its subdirectories
		script_files=$(find "$source_dir" -type f -name "*${file_type}")


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
		file_type=$(echo $src | cut -d $INSTALL_SOURCES_DELIM -f 3)
		is_optional=$(echo $src | cut -d $INSTALL_SOURCES_DELIM -f 4)
		confirm='y'
		if [ -n "$is_optional" ];then
			read -p "$dir is optional to install, install it? [Y/n]" -r confirm
		fi

		if [ "$confirm" = "n" ] || [ "$confirm" = "N" ];then
			echo "will not install $dir"
			continue
		fi

		echo installing $dir with prefix $prefix in $DESTINATION_DIR
		abs_install "$dir" "$DESTINATION_DIR" "$prefix" "$file_type"
done

echo ""
echo "Awesome Bash Scripts Successfully Installed."
echo "You can use the abs.script_name command to run the scripts or type [abs.] and press tab to see the list of scripts."
