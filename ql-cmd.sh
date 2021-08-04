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
export ql="/opt/qlauncherV2/qlauncher.sh"
export ql_RUNNING="${ql} check | grep '"edgecore_alive":"true"'"
export ql_STOPPED="${ql} check | grep '"edgecore_alive":""'"
export repo_QL="https://get.qlauncher.poseidon.network/install.sh"

error() {
    ${PRIN} "%b\\n" " ${CROSS} $1"
    exit
}

soedo() {
	# Need run as root user
	${PRIN} " %b %s ... " "${INFO}" "Detect root"
	if [[ $(id -u) -ne 0 ]] ; then
		${SLP}
		${PRIN} "%b\\n" "${CROSS}"
		error "This script need run as root !"
	fi
	${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

inet() {
	${PRIN} " %b %s ... " "${INFO}" "Detect connections"
	if [[ $(ping -q -c 1 -W 1 8.8.8.8) ]] ; then 
		${SLP}
		${PRIN} "%b\\n" "${TICK}"
	else 
		${SLP}
		${PRIN} "%b\\n" "${CROSS}"
		error "No internet connections !"
	fi
}

ql_instd() {
# Detect qlauncher installed
${PRIN} " %b %s ... " "${INFO}" "Qlauncher installed"
if [ -z /opt/qlauncherV2 ] ; then
	${SLP}
	${PRIN} "%b\\n" "${CROSS}"
	curl -sSL https://github.com/jakues/ql/raw/master/ql-install.sh | bash || error "Failed to install !"
fi
${SLP}
${PRIN} "%b\\n" "${TICK}"
}

start() {
	${PRIN} " %b %s ... " "${INFO}" "Detect qlauncher status"
		if [[ "$(systemctl is-active qlauncher)" == *"failed"* ]] ; then
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${PRIN} " %b %s ... " "${INFO}" "Starting qlauncher"
			systemctl start qlauncher || error "Failed to start qlauncher"
			${PRIN} "%b\\n" "${DONE}"
		else
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${PRIN} " %b %s " "${INFO}" "Qlauncher is running"
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			error "Failed to start qlauncher !"
		fi
	}

stop() {
	${PRIN} " %b %s ... " "${INFO}" "Detect qlauncher status"
		if [[ "$(systemctl is-active qlauncher)" == *"active"* ]] ; then
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${PRIN} " %b %s ... " "${INFO}" "Stopping qlauncher"
			systemctl stop qlauncher || error "Failed to stop qlauncher"
			${PRIN} "%b\\n" "${DONE}"
		else
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${PRIN} " %b %s " "${INFO}" "Qlauncher isn't running"
			${SLP}
			${PRIN} "%b\\n" "${CROSS}"
			error "Failed to stop qlauncher !"
		fi
	}

restart () {
	${PRIN} " %b %s ... " "${INFO}" "Detect qlauncher status"
		if [[ "$(systemctl is-active qlauncher)" == *"active"* ]] ; then
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${PRIN} " %b %s ... " "${INFO}" "Restarting qlauncher"
			systemctl restart qlauncher || error "Failed to restart qlauncher"
			${PRIN} "%b\\n" "${DONE}"
		elif [[ ! ${ql_RUNNING} ]] ; then
			start
		fi
}

check() {
	export ql_check="2-26 28-68 90-114 116-136 138-160 162-183 185-205"
	${ECMD}
		for z in ${ql_check} ; do
			${ql} check | cut -c ${z}
		done
	${ECMD}
    }

status() {
	${ECMD}
    ${ql} status
    ${ECMD}
}

bind() {
	export dir_QR="/opt/.qlauncher-qr"
	${ECMD} "qapp://edge.binding?type=QL2&brand=POSEIDON&sn=$(cat /etc/machine-id)" > ${dir_QR} || error "Failed create qr code !"
	${ECMD} "\nScan this QR code to bind your device with QQQ App\n" | lolcat
	qrencode -t ANSIUTF8 < "${dir_QR}"
	${ECMD} "\nFor more information open this URL on your browser :" | lolcat
	${ql} bind | awk -s '{print $9}' | lolcat
	${ECMD}
}

log() {
    export dir_qlog="/opt/qlauncherV2/log/qlauncher.log"
    export dir_alog="/opt/qlauncherV2/log/agent.log"
    export qlog="${HOME}/ql.log"
    cat ${dir_qlog} >> ${qlog}
    cat ${dir_alog} >> ${qlog}
	${PRIN} " %b %s \n" "${INFO}" "Qlauncher log :"
    tail ${dir_qlog} | lolcat
	${PRIN} " %b %s \n" "${INFO}" "Agent log :"
    tail ${dir_alog} | lolcat
    read -p " [?] Upload log to bashupload.com ? [y/N]" -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			error "Please screnshoot this log to admin !"
		else
            curl -f https://bashupload.com/ -T ${qlog} || curl https://bashupload.com/ -T ${qlog} || error "Failed to upload !"
			${PRIN} " %b %s \n" "${INFO}" "Please send this log to admin !"
		fi
}

inst() {
	if [ -d /opt/qlauncherV2 ]; then
		error "Qlauncher already installed !"
	else
        ${PRIN} " %b %s\n" "${INFO}" "Qlauncher not installed !"
        ${PRIN} " %b %s ... " "${INFO}" "Installing"
		curl -sfL ${repo_QL} | sh - || error "Failed install qlauncher ! Check the system requirements."
		${PRIN} "%b\\n" "${TICK}"
	fi
}

unst() {
	if [ -d /opt/qlauncherV2 ]; then
		${ql} stop || error "Failed to stop qlauncher !"
		${ql} uninstall || error "Failed to uninstall qlauncher !"
        ${PRIN} " %b %s ... " "${INFO}" "Uninstalling qlauncher"
		${PRIN} "%b\\n" "${TICK}"
	else
		error "Qlauncher not installed !"
	fi
}

reinst() {
	if [ -d /opt/qlauncherV2 ]; then
		${ql} stop || error "Failed to stop qlauncher !"
		${ql} uninstall || error "Failed to uninstall qlauncher !"
		rm -rf /opt/qlauncherV2 || error "Failed to remove qlauncher directory"
		curl -sfL ${repo_QL} | sh - || error "Failed to install qlauncher !"
		${PRIN} " %b %s ... " "${INFO}" "Reinstalling qlauncher"
        ${PRIN} "%b\\n" "${TICK}"
	else
        ${PRIN} " %b %s\n" "${INFO}" "Qlauncher not installed !"
		curl -sfL ${repo_QL} | sh - || error "Failed install qlauncher ! Check the system requirements."
        ${PRIN} " %b %s ... " "${INFO}" "Installing qlauncher"
		${PRIN} "%b\\n" "${TICK}"
	fi
}

port() {
	export MYIP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
	${PRIN} " %b %s ... " "${INFO}" "Detect nmap"
		if [[ $(which nmap) == *"nmap"* ]] ; then
			${SLP}
			${PRIN} "%b\\n" "${TICK}"
			${ECMD}
			nmap -p 32440-32449 $MYIP | lolcat
		else
			${SLP}
			${PRIN} "%b\\n" "${CROSS}"
			error "Please install nmap !"
		fi
	}

pull() {
	export img="docker-registry.poseidon.network/qlauncher-sysinfo-x86:0.6.6 docker-registry.poseidon.network/qservice-ipfs-cluster-x86:1.10.0 docker-registry.poseidon.network/qservice-v2ray:0.0.5 docker.io/ipfs/go-ipfs:v0.7.0 docker.io/library/telegraf:1.19-alpine docker.io/rancher/pause:3.1"
		for p in ${img} ; do
			crictl pull ${img} || error "Failed pull image !"
		done
}

update() {
	export RPM=$(which yum)
	export APT=$(which apt-get)
	export dir_QR="/opt/.qlauncher-qr"
	export dir_qlcmd="/opt/.ql-cmd.sh"
	export repo_qlcmd="https://github.com/jakues/ql/raw/master/ql-cmd.sh"
	${PRIN} " %b %s ... " "${INFO}" "Detect package manager"
		if [[ ! -z ${RPM} ]] ; then
		    ${SLP}
	        ${PRIN} "%b\\n" "${TICK}"
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
		elif [[ ! -z ${APT} ]] ; then
			${SLP}
	        ${PRIN} "%b\\n" "${TICK}"
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
		else
    		${SLP}
	        ${PRIN} "%b\\n" "${CROSS}"
			error "Operation failed !"
		fi
	wget -q ${repo_qlcmd} -O ${dir_ql} || error "Failed download ql-cmd.sh !"
    chmod +x ${dir_ql} || error "Failed change permission"
	${ECMD} "qapp://edge.binding?type=QL2&brand=POSEIDON&sn=$(cat /etc/machine-id)" > ${dir_QR} || error "Failed create qr code !"
}

hostname() {
    export CUR_HOSTNAME=$(cat /etc/hostname)
    ${PRIN} " %b %s" "${INFO}" "Current hostname is : ${CUR_HOSTNAME}"
    read -r -p "  [i] Enter new hostname : " NEW_HOSTNAME
    ${ECMD}
	hostnamectl set-hostname "${NEW_HOSTNAME}"
	sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
	sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
	read -p "  [?] Reboot now to change hostname ? [y/N]" -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			error "Please reboot manually !"
		else
			${ECMD}
			reboot
		fi
	}

change_hwsn() {
	export CUR_HWSN=$(cat /etc/machine-id)
	${ECMD} "  [i] The current hwsn is : ${CUR_HWSN}"
		read -r -p "  [i] Enter new hwsn : " SN
			${ECMD} ${SN} > /etc/qlauncher
			${ECMD} ${SN} > /etc/machine-id
		restart
	}

help() {
	${ECMD} "\n Usage: ql [OPTION]...\n"
	${ECMD} "  Main Usage :"
	${ECMD} "    -s, --start		start Qlauncher service"
	${ECMD} "    -c, --stop		stop Qlauncher service"
	${ECMD} "    -r, --restart	restart Qlauncher service"
	${ECMD} "    -i, --check		check Qlauncher tick"
	${ECMD} "    -l, --stat		show status container"
	${ECMD} "    -b, --bind		get Qlauncher QR Code"
    ${ECMD} "    --log		get Qlauncher logs"
	${ECMD} "    --install		install qlauncher"
	${ECMD} "    --uninstall		uninstall qlauncher"
	${ECMD} "    --reinstall		reinstall qlauncher"
	${ECMD} "\n  Miscellaneous :"
	${ECMD} "    -P			check port status using nmap"
	${ECMD} "    --pull		pull Qlauncher image manual"
	${ECMD} "    --update		update script"
	${ECMD} "    --hostname		change hostname"
	${ECMD} "\n  Report this script to: <https://github.com/jakues/ql/issues>"
	${ECMD} "  Report Qlauncher bugs to: <https://github.com/poseidon-network/qlauncher-linux/issues>"
	${ECMD} "  Qlauncher github: <https://github.com/poseidon-network/qlauncher-linux>"
	${ECMD} "  Poseidon Network home page: <https://poseidon.network/>\n"
	}

null() {
	${ECMD} "\nUsage: ql [OPTION]...\n"
	${ECMD} "Try 'ql --help' for more information.\n"
	}


case "$1" in
	-s|--start)
		soedo ; inet ; ql_instd ; start
;;
	-c|--stop)
		soedo ; inet ; ql_instd ; stop
;;
	-r|--restart)
		soedo ; inet ; ql_instd ; restart
;;
	-i|--check)
		soedo ; inet ; ql_instd ; check | lolcat
;;
	-l|--stat)
		soedo ; inet ; ql_instd ; status | lolcat
;;
	-b|--bind)
		soedo ; inet ; ql_instd ; bind
;;
    --log)
        soedo ; inet ; ql_instd ; log
;;
	--install)
		soedo ; inet ; ql_instd ; inst
;;
	--uninstall)
		soedo ; inet ; ql_instd ; unst
;;
	--reinstall)
		soedo ; inet ; ql_instd ; reinst
;;
	-P)
		soedo ; inet ; ql_instd ; port
;;
	--pull)
		soedo ; inet ; ql_instd ; pull
;;
	--update)
		soedo ; inet ; ql_instd ; update
;;
	--hostname)
		soedo ; inet ; ql_instd ; hostname
;;
	--sn)
		soedo ; inet ; ql_instd ; change_hwsn
;;
	--help)
		help | lolcat
;;
	*)
		null | lolcat
;;
esac
