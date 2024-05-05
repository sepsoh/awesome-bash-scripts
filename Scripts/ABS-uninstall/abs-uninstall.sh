#!/bin/bash

#Request sudo permission.
sudo ls >/dev/null

# Set the s directorie
scripts_dir="/usr/bin"

# Find all scripts in the scripts directory
script_files=$(find "$scripts_dir" -type f -name "abs.*")
file_count=$(echo "$script_files" | wc -l)

if [ -n "$script_files" ]; then
    echo "We found "$file_count" abs scripts to remove."
    read -p "Do you want to continue? [y/N] " flag 

    if [ "$flag" != "y" ] && [ "$flag" != "Y" ]; then
        echo Abort.
        exit 0
    fi
else
    echo "We couldn't locate any ABS scripts."
    exit 0
fi

IFS=$'\n';
for script in $script_files; do
    sudo rm -f "$script"
    echo "deleted : "$(basename "$script")""
done

echo "All of your ABS scripts have been deleted."


