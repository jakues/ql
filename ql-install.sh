#!/bin/bash

#################################################
# Description	: Script to install Qlauncher   #
# Author		: Rill (jakueenak@gmail.com)    #
# Telegram		: t.me/pethot                   #
# Version		: beta                          #
#################################################



# Set var
export ECMD="echo -e"
export COLOUR_RESET='\e[0m'
export aCOLOUR=(
		'\e[1;33m'	# Yellow
		'\e[1m'		# Bold white
		'\e[1;32m'	# Green
		'\e[1;31m'  	# Red
	)
export GREEN_LINE="${aCOLOUR[0]}──────────────────────────────────────────────────────────${COLOUR_RESET}"
export GREEN_BULLET="  [i] "
export GREEN_WARN="  [${aCOLOUR[2]}✓${COLOUR_RESET}] "
export RED_WARN="  [${aCOLOUR[3]}✗${COLOUR_RESET}] "
export dir_QR="/opt/.qlauncher-qr"
export repo_QL="https://get.qlauncher.poseidon.network/install.sh"
export repo_qlcmd="https://github.com/jakues/ql/ql-cmd.sh"
export MODELO=$(uname -m)

error() {
	${ECMD} "${RED_WARN}${aCOLOUR[3]}$1 ${COLOUR_RESET}"
	exit 1
}

tools_deb() {
	${ECMD} "${GREEN_LINE}"
	${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Updating Package ..."
	${ECMD} "${GREEN_LINE}"
		apt-get update -qq -y || error "Update failed !"
		apt-get upgrade -qq -y || error "Upgrade failed !"
		apt-get install wget net-tools qrencode nmap dmidecode lolcat -qq -y || error "Install the requirements package failed !"
	${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Updating Package Done"
	}

tools_rpm() {
	${ECMD} "${GREEN_LINE}"
	${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Updating Package ..."
    ${ECMD} "${GREEN_LINE}"
		yum update -y || error "Update failed !"
		yum upgrade -y || error "Upgrade failed !"
		yum install epel-release wget net-tools qrencode ruby nmap dmidecode unzip -y || error "Install the requirements package failed !"
	${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Updating Package Done"
	}

req() {
    ${ECMD} "${GREEN_LINE}"
    ${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Installing Qlauncher ..."
    ${ECMD} "${GREEN_LINE}"
        curl -sfL ${repo_QL} | sh - || error "Failed install qlauncher ! maybe check the system requirements"
		${ECMD} "qapp://edge.binding?type=QL2&brand=POSEIDON&sn=$(cat /etc/machine-id)" > ${dir_QR} || error "Failed create qr code !"
		ln -s /usr/games/lolcat /usr/bin/lolcat || error "Failed linking lolcat !"
		wget -q ${repo_qlcmd} -O /opt/.ql-cmd.sh
		${ECMD} "alias Q='bash /opt/.ql-cmd.sh'" >> ${HOME}/.bash_aliases
	${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Installing Qlauncher Done"

reload() {
	systemctl enable qlauncher || error "Failed enabled qlauncher on boot !"
	systemctl start qlauncher || error "Failed start qlauncher !"
	systemctl daemon-reload || error "Failed restart daemon !"
	}

lolcat() {
	export repo_LOL="https://github.com/busyloop/lolcat/archive/master.zip"
	export dir_LOL="${HOME}/lolcat.zip"
	export dir_GEM="${HOME}/lolcat-master/bin"

	${ECMD} "${GREEN_LINE}"
    ${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Installing Lolcat ..."
    ${ECMD} "${GREEN_LINE}"
		wget -q ${repo_LOL} -O ${dir_LOL} || error "Check internet connections and try again !"
		unzip -q ${dir_LOL} || error "Failed extract with unzip !"
		gem install --bindir ${dir_GEM} lolcat || error "Failed install lolcat with ruby !"
		ln -s /usr/games/lolcat /usr/bin/lolcat || error "Failed linking lolcat !"
		rm -rf ${dir_LOL} lolcat-master || error "Remove failed !"
	${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Installing Lolcat Done"
	}

cgroupfs() {
	export CMDLINE_RASPBIAN="/boot/cmdline.txt"
	export CMDLINE_UBUNTU="/boot/firmware/cmdline.txt"
	export cgroup_cmd=$(sed -i -e 's/rootwait/cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 rootwait/')

	if $(cat /etc/os-release | grep debian | cut -b 69-) ; then
		if $(cat ${CMDLINE_RASPBIAN} | grep 'cgroup' >/dev/null) ; then
			error "Cgroup already enabled!"
		else
			${cgroup_cmd} $CMDLINE_RASPBIAN || error "Failed modify cgroup !"
        fi
	elif $(cat /etc/os-release | grep ubuntu | cut -b 69-) ; then
        if $(cat ${CMDLINE_UBUNTU} | grep 'cgroup' >/dev/null) ; then
			error "Cgroup already enabled !"
        else
        	${cgroup_cmd} $CMDLINE_UBUNTU || error "Failed modify cgroup !"
		fi
	else
		error "Can't enable cgroup. Please enable manually !"
	fi
	}

check_arch_rpi() {
	if [ "${MODELO}" != "armv7l" ]; then
		error "This script is only intended to run on ARM (armv7l) devices."
	elif [[ "${MODELO}" == *"aarch64"* ]] ; then
		${ECMD} "${RED_WARN}${aCOLOUR[3]}Currently Qlauncher doesn't support arm64.${COLOUR_RESET}"
	fi
	}

reboot_rpi() {
	read -p "  [i] Reboot now to enable cgroup ? [y/N]" -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			error "Please reboot manually in order to activate cgroup !"
		else
			${ECMD} "${COLOUR_RESET}"
			reboot
		fi
	}

rpm() {
	tools_rpm \
		; lolcat \
		; req \
	reload
	}

deb() {
	tools_deb \
		; req \
		; source .bashrc \
	reload
	}

x86() {
	export RPM=$(which yum)
	export APT=$(which apt-get)

	if [[ ! -z $RPM ]]; then
    	# Drop support for .rpm
		error "Failed to install ! Check your OS"
	elif [[ ! -z $APT ]]; then
    	deb
	else
		error "Failed to install ! Check your OS"
 	fi
	}

rpi() {
	check_arch_rpi \
		; tools_deb \
		; req \
		; reload \
		; cgroupfs \
	reboot_rpi
	}

# Need run as root user
if [[ $(id -u) -ne 0 ]] ; then
	error "This scripts need run as root"
fi

# Detect architecture and kick off
if [[ "${MODELO}" == *"x86_64"* ]] ; then
	x86
elif [[ "$(tr -d '\0' < /proc/device-tree/model)" == *"Raspberry Pi"* ]] ; then
	rpi
else
	error "Failed to install ! No architecture detected"
fi
