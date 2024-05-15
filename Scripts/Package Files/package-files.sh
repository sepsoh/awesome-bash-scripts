#!/bin/bash

# Function to convert bytes to human-readable format
function human_readable_size() {
  local size=$1
  local unit="B"
  if [ $size -gt 1024 ]; then
    size=$(echo "scale=0; $size / 1024" | bc)
    unit="KB"
  fi
  if [ $size -gt 1024 ]; then
    size=$(echo "scale=0; $size / 1024" | bc)
    unit="MB"
  fi
  if [ $size -gt 1024 ]; then
    size=$(echo "scale=0; $size / 1024" | bc)
    unit="GB"
  fi
  echo "$size $unit"
}

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
  echo "Error: Please provide a package name as an argument."
  exit 1
fi

# Get the package name
package_name=$1

# Construct the file path
file_path="/var/lib/dpkg/info/$package_name.list"

# Check if the file exists
if [ ! -f "$file_path" ]; then
  echo "Error: File '$file_path' does not exist."
  exit 1
fi

# Initialize variables
total_size=0
total_count=0

# Table header
printf "%-50s %15s\n" "File Path" "Size"
printf "%-50s %15s\n" "---------" "----"
# Loop through each file in the list file
while IFS= read -r filename; do
  # Check if the file exists and is a regular file
  if [ -f "$filename" ]; then
    # Get the file size
    file_size=$(stat -c "%s" "$filename")
    total_size=$((total_size + file_size))
    total_count=$((total_count + 1))

    # Call human_readable_size function for size calculation
    human_size=$(human_readable_size "$file_size")

    # Display file path and size in table format
    printf "%-50s %15s\n" "$filename" "$human_size"
  fi
done < "$file_path"

# total count and size
total_size_human=$(human_readable_size "$total_size")
printf "\n"
echo "$total_count files, $total_size_human used."
