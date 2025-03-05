#!/bin/bash

# shellcheck source=/usr/bin/abs.lib.logging
source abs.lib.logging


_apt_install(){
	sudo apt install $@ -y
	return $?
}

_apt_update(){
	sudo apt update
	return $?
}

_apt-get_install(){
	sudo apt-get install $@ -y
	return $?
}

_apt-get_update(){
	sudo apt-get update
	return $?
}

_dpkg_install(){
	return
}


_dpkg_update(){
	return
}

_pacman_install(){
	sudo pacman -S $@ --noconfirm
	return $?
}

_pacman_update(){
	sudo pacman -Sy --noconfirm
	return $?
}

_yum_install(){
	return
}

_yum_update(){
	return
}

_dnf_install(){
	return
}

_dnf_update(){
	return
}

# _package_manager_func_to_use()
# Echos the function name to use for installing packages on this machine 
# Echos nothing on error 
# Return Value:
# 0 on success, 1 on error
_package_manager_func_to_use(){
	if type apt &>/dev/null;then
		echo _apt
	elif type apt-get &>/dev/null;then
		echo _apt-get
	elif type dpkg &>/dev/null;then
		echo _dpkg
	elif type pacman &>/dev/null;then
		echo _pacman
	elif type rpm &>/dev/null;then
		#not yet implemented
		echo ''
		return 1
	elif type dnf &>/dev/null;then
		#not yet implemented
		echo ''
		return 1
	else
		echo ''
		return 1
	fi
	return 0
}

# installpkg(package_name1, package_name2, ...)
# Installs the provided package names 
# Parameters:
#   package_name: Name of the package to be installed on the machine 
# Return value:
#   1 if _package_manager_func_to_use fails, your package manager's error code otherwise
installpkg(){
	package_manager_func=$(_package_manager_func_to_use)

	if [ -z "$package_manager_func" ];then
		log $LOG_LVL_CRITICAL "your package manager is not supported"
		return 1
	fi

	log $LOG_LVL_DEBUG "using $package_manager_func to install packages"
	${package_manager_func}_update
	${package_manager_func}_install $@
	return $?
}

installpkg "$@"
