#!/bin/bash
repo="sepsoh/awesome-bash-scripts"

# Check for required tools
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but it's not installed. Aborting."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is required but it's not installed. Aborting."; exit 1; }

function download_latest_release() {
  # download the latest zip file of repo in the /tmp then extract it.
  url="https://github.com/$repo/archive/refs/heads/main.zip"
  curl -L $url -o /tmp/awesome-bash-scripts.zip 1>/dev/null 2> /dev/null
  unzip /tmp/awesome-bash-scripts.zip -d /tmp 1>/dev/null 2> /dev/null

}

function update_tools() {

  # Check if /tmp/awesome-bash-scripts-main exists
  if [[ ! -d "/tmp/awesome-bash-scripts-main" ]]; then
    echo "Error: Directory /tmp/awesome-bash-scripts-main not found."
    echo "Please ensure the directory exists or provide the correct path."
    return 1  # Indicate failure
  fi

  # Change directory to /tmp/awesome-bash-scripts-main
  cd "/tmp/awesome-bash-scripts-main" || {
    echo "Error: Failed to change directory to /tmp/awesome-bash-scripts-main."
    return 1
  }

  # Execute install.sh (assuming it's located within the directory)
  ./install.sh || {
    echo "Error: install.sh execution failed."
    return 1
  }

  # Remove temporary directory and ZIP file (if needed)
  # Consider keeping the directory if tools are used frequently
  # rm -rf "/tmp/awesome-bash-scripts-main"  # Optional cleanup
  rm "/tmp/awesome-bash-scripts.zip"  # Optional cleanup

  echo "Update completed successfully."
}

echo "Latest release for $repo: $latest_release"
echo "Downloading and processing the latest release..."
download_latest_release
echo "Updating ..."
update_tools
echo ""
echo "Updated Successfuly"

