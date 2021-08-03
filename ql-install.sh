#!/bin/bash

export PRIN="printf"
export ECMD="echo -e"
export CR='\e[0m'
export COL_LIGHT_GREEN='\e[1;32m'
export COL_LIGHT_RED='\e[1;31m'
export TICK="[${COL_LIGHT_GREEN}✓${CR}]"
export CROSS="[${COL_LIGHT_RED}✗${CR}]"
export INFO="[i]"
export DONE="${COL_LIGHT_GREEN} done !${CR}"
export SLP="sleep 0.69s"
export dir_QR="/opt/.qlauncher-qr"
export dir_ql="/usr/bin/ql"
export repo_QL="https://get.qlauncher.poseidon.network/install.sh"
export repo_qlcmd="https://github.com/jakues/ql/raw/master/ql-cmd.sh"
export MODELO=$(uname -m)

error() {
    ${PRIN} "$1 ${CROSS}"
    exit
}

tools_deb() {
    ${PRIN} " %b %s " "${INFO}" "Package Manager : apt-get"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # Update
    ${PRIN} " %b %s ... \n" "${INFO}" "Updating repo"
    	apt-get update -qq -y || error "Update failed !"
    ${PRIN} " %b %s " "${INFO}" "Update repo"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    # Upgrade
    ${PRIN} " %b %s ... \n" "${INFO}" "Upgrading packages"
    	apt-get upgrade -qq -y || error "Upgrade failed !"
    ${PRIN} " %b %s " "${INFO}" "Upgrade packages"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    # Install
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing packages"
    	apt-get install wget net-tools qrencode nmap dmidecode lolcat -qq -y || error "Install the requirements package failed !"
    ${PRIN} " %b %s " "${INFO}" "Install packages"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

tools_rpm() {
    ${PRIN} " %b %s " "${INFO}" "Package Manager : yum"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # Update
    ${PRIN} " %b %s ... \n" "${INFO}" "Updating repo"
    	yum update -y || error "Update failed !"
    ${PRIN} " %b %s " "${INFO}" "Update repo"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    # Upgrade
    ${PRIN} " %b %s ... \n" "${INFO}" "Upgrading packages"
    	yum upgrade -y || error "Upgrade failed !"
    ${PRIN} " %b %s " "${INFO}" "Upgrade packages"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    # Install
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing packages"
        yum install epel-release wget net-tools qrencode ruby nmap dmidecode lolcat -y || error "Install the requirements package failed !"
    ${PRIN} " %b %s " "${INFO}" "Install packages"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

req() {
    ${PRIN} " %b %s ... " "${INFO}" "Installing Requirements"
		${ECMD} "qapp://edge.binding?type=QL2&brand=POSEIDON&sn=$(cat /etc/machine-id)" > ${dir_QR} || error "Failed create qr code !"
		wget -q ${repo_qlcmd} -O ${dir_ql} || error "Failed download ql-cmd.sh !"
        chmod +x ${dir_ql} || error "Failed change permission"
	${PRIN} "%b" "${DONE}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

cgroupfs() {
	export CMDLINE_RASPBIAN="/boot/cmdline.txt"
	export CMDLINE_UBUNTU="/boot/firmware/cmdline.txt"
	export cgroup_cmd=$(sed -i -e 's/rootwait/cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 rootwait/')
    ${PRIN} " %b %s ... " "${INFO}" "Set cgroupfs"
        if $(cat /etc/os-release | grep debian | cut -b 69-) ; then
            if $(cat ${CMDLINE_RASPBIAN} | grep 'cgroup' > /dev/null) ; then
                error "Cgroup already enabled!"
            else
                ${cgroup_cmd} $CMDLINE_RASPBIAN || error "Failed modify cgroup !"
            fi
        elif $(cat /etc/os-release | grep ubuntu | cut -b 69-) ; then
            if $(cat ${CMDLINE_UBUNTU} | grep 'cgroup' > /dev/null) ; then
                error "Cgroup already enabled !"
            else
                ${cgroup_cmd} $CMDLINE_UBUNTU || error "Failed modify cgroup !"
            fi
        else
            error "Can't enable cgroup. Please enable manually !"
        fi
    ${PRIN} "%b\\n" "${TICK}"
}

reboot_rpi() {
	read -p "  [i] Reboot now to enable cgroup ? [y/N]" -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			error "Please reboot manually in order to activate cgroup !"
		else
			reboot
		fi
}

pkg() {
    ${PRIN} " %b %s ... " "${INFO}" "Detect package manager"
        if [[ ! -z $(which yum) ]] ; then
            ${SLP}
	        ${PRIN} "%b\\n" "${TICK}"
            tools_rpm
            req
        elif [[ ! -z $(which apt-get) ]] ; then
            ${SLP}
	        ${PRIN} "%b\\n" "${TICK}"
            tools_deb
            req
        else
            ${SLP}
	        ${PRIN} "%b\\n" "${CROSS}"
            error "Failed to install script !"
        fi
}

rpi() {
    pkg
    cgroupfs
    reboot_rpi
}

# Need run as root user
${PRIN} " %b %s ... " "${INFO}" "Detect root"
if [[ $(id -u) -ne 0 ]] ; then
	${SLP}
	${PRIN} "%b\\n" "${CROSS}"
	error "This script need run as root !"
fi
${SLP}
${PRIN} "%b\\n" "${TICK}"

# Detect qlauncher installed
${PRIN} " %b %s ... " "${INFO}" "Qlauncher installed"
if [ -z /opt/qlauncherV2 ] ; then
	${SLP}
	${PRIN} "%b\\n" "${CROSS}"
	curl -sfL ${repo_QL} | sh - || error "Failed to install !"
fi
${SLP}
${PRIN} "%b\\n" "${TICK}"

# Detect architecture and kick off
${PRIN} " %b %s ... " "${INFO}" "Detect architecture"
if [[ "${MODELO}" == *"x86_64"* ]] ; then
    ${SLP}
    ${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Architecture : x86_86"
    ${SLP}
    ${PRIN} "%b\\n" "${TICK}"
	pkg
elif [[ "$(tr -d '\0' < /proc/device-tree/model)" == *"Raspberry Pi"* ]] ; then
    ${SLP}
    ${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Architecture : raspberry pi"
	${SLP}
    ${PRIN} "%b\\n" "${TICK}"
	rpi
else
    ${SLP}
    ${PRIN} "%b\\n" "${CROSS}"
    ${PRIN} " %b %s " "${INFO}" "Architecture : unknown"
    ${SLP}
    ${PRIN} "%b\\n" "${CROSS}"
	error "Failed to install !"
fi