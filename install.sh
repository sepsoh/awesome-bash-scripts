#!/bin/bash

# Set the source and destination directories
source_dir="Scripts"
destination_dir="/usr/bin"

# Find all scripts in the source directory and its subdirectories
script_files=$(find "$source_dir" -type f -name "*.sh")


IFS=$'\n';
for script in $script_files; do
    new_name="abs.$(basename "$script" .sh)"
    sudo chmod +x "$script";
    sudo cp -p "$script" "$destination_dir/$new_name";
    echo "installed : $new_name" 
done

echo ""
echo "Awesome Bash Scripts Successfully Installed."
echo "You can use the abs.script_name command to run the scripts or type [abs.] and press tab to see the list of scripts."
