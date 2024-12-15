#!/bin/bash
# shellcheck source=/usr/bin/abs.lib.depcheck
source abs.lib.depcheck
repo="sepsoh/awesome-bash-scripts"
dependancies="\
curl,curl
unzip,unzip"

if ! depcheck_cmd_fromstr "$dependancies"; then
		exit $?
fi

function download_latest_release() {
  # download the latest zip file of repo in the /tmp then extract it.
  url="https://github.com/$repo/archive/refs/heads/main.zip"
  curl -L $url -o /tmp/awesome-bash-scripts.zip 1>/dev/null 2> /dev/null
  unzip /tmp/awesome-bash-scripts.zip -d /tmp 1>/dev/null 2> /dev/null

}

function update_tools(){
  bash /tmp/awesome-bash-scripts-main/install.sh
  rm /tmp/awesome-bash-scripts.zip
  rm -rf /tmp/awesome-bash-scripts-main
}


echo "Latest release for $repo: $latest_release"
echo "Downloading and processing the latest release..."
download_latest_release
echo "Updating ..."
update_tools
echo ""
echo "Updated Successfuly"

