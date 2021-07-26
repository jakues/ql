#!/bin/sh

#################################################
# Description	: Qlauncher commands ez         #
# Author		: Rill (jakueenak@gmail.com)    #
# Telegram		: t.me/pethot                   #
# Version		: beta                          #
#################################################

export ECMD="echo -e"
export COLOUR_RESET='\e[0m'
export aCOLOUR=(
		'\e[1;33m'	# Yellow
		'\e[1m'		# White
		'\e[1;32m'	# Green
		'\e[1;31m'  # Red
	)
export GREEN_BULLET="  [i] "
export GREEN_WARN="  [${aCOLOUR[2]}✓${COLOUR_RESET}] "
export RED_WARN="  [${aCOLOUR[3]}✗${COLOUR_RESET}] "
export ql="/opt/qlauncherV2/qlauncher.sh"
export ql_RUNNING="${ql} check | grep '"edgecore_alive":"true"'"

error() {
	${ECMD} "${RED_WARN}${aCOLOUR[3]}$1 ${COLOUR_RESET}"
	exit 1
}

# Need run as root user
if [[ $(id -u) -ne 0 ]] ; then
	error "This script need run as root !"
fi

start() {
	if [[ ! $(ql_RUNNING) ]] ; then
		${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Qlauncher isn't running${COLOUR_RESET}"
		systemctl start qlauncher || error "Failed to start qlauncher !"
		${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Qlauncher is now running.${COLOUR_RESET}"
		${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Please wait until the container alive${COLOUR_RESET}"
	else
		error "Failed to start ! Qlauncher already running"
	fi
	}

stop() {
	if [[ $(ql_RUNNING) ]] ; then
		${ECMD} "${GREEN_BULLET}${aCOLOUR[2]}Qlauncher is running${COLOUR_RESET}"
		systemctl stop qlauncher || error "Failed to stop qlauncher !"
		${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Qlauncher is now stopped.${COLOUR_RESET}"
	else
		error "Failed to stop ! Qlauncher already stopped"
	fi
	}

restart () {
	if [[ $(ql_RUNNING) ]] ; then
		systemctl restart qlauncher || error "Failed to restart qlauncher"
		${ECMD} "${GREEN_WARN}${aCOLOUR[2]}Restart qlauncher done.${COLOUR_RESET}"
	elif [[ ! $(ql_RUNNING) ]] ; then
		start
	fi
}

check() {
	export ql_check="2-26 28-68 90-114 116-136 138-160 162-183 185-205"
		for z in ${ql_check}
		do
			${ql} check | cut -c ${z}
		done
    }

status() {
	${ECMD} \
        ; ${ql} status \
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

port() {
	export MYIP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
	if [[ $(which nmap) == *"nmap"* ]] ; then
		nmap -p 32440-32449 $MYIP | lolcat
	else
		error "Please nmap first !"
	fi
	}

update() {
	export RPM=$(which yum)
	export APT=$(which apt-get)
	export dir_QR="/opt/.qlauncher-qr"
	export dir_qlcmd="/opt/.ql-cmd.sh"
	export repo_qlcmd="https://github.com/jakues/ql/raw/master/ql-cmd.sh"
		if [[ ! -z $RPM ]]; then
			yum update -y ; yum upgrade -y ; yum install epel-release wget net-tools qrencode ruby nmap dmidecode unzip -y || error "Update failed !"
		elif [[ ! -z $APT ]]; then
    		apt-get update -qq -y ; apt-get upgrade -qq -y ; apt-get install wget net-tools qrencode nmap dmidecode lolcat -qq -y || error "Update failed !"
		else
    		error "Check your OS !"
		fi
	wget -q ${repo_qlcmd} -O ${dir_qlcmd}
	chmod +x ${dir_qlcmd}
	${ECMD} "qapp://edge.binding?type=QL2&brand=POSEIDON&sn=$(cat /etc/machine-id)" > ${dir_QR} || error "Failed create qr code !"
	${ECMD} "alias Q='bash /opt/.ql-cmd.sh'" >> ${HOME}/.bash_aliases
	${ECMD} "alias ql='/opt/qlauncherV2/qlauncher.sh'" >> ${HOME}/.bash_aliases
	source .bashrc
}

hostname() {
	${ECMD} "${aCOLOUR[0]}		[i] The current hostname is : ${aCOLOUR[2]}$CUR_HOSTNAME\n${aCOLOUR[0]}"
	read -r -p "		[i] Enter new hostname : " NEW_HOSTNAME
	${ECMD} "${aCOLOUR[0]}"
	export CUR_HOSTNAME=$(cat /etc/hostname)
	hostnamectl set-hostname "${NEW_HOSTNAME}"
	sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
	sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
	read -p "		[i] Reboot now to change hostname ? [y/N]" -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			error "Please reboot manually"
		else
			${ECMD} "${COLOUR_RESET}"
			reboot
		fi
	}

change_hwsn() {
	${ECMD} ${aCOLOUR[0]}
	export CUR_HWSN=$(cat /etc/machine-id)
	${ECMD} "${aCOLOUR[0]}		[i] The current hwsn is : ${aCOLOUR[2]}$CUR_HWSN${aCOLOUR[0]}"
		read -r -p "		[i] Enter new hwsn : " SN
			${ECMD} ${SN} > /etc/qlauncher
			${ECMD} ${SN} > /etc/machine-id
	restart
	}

help() {
	${ECMD} "\n Usage: Q [OPTION]...\n"
	${ECMD} "  Main Usage :"
	${ECMD} "    -s, --start		start Qlauncher service"
	${ECMD} "    -c, --stop		stop Qlauncher service"
	${ECMD} "    -r, --restart	restart Qlauncher service"
	${ECMD} "    -i, --check		check Qlauncher tick"
	${ECMD} "    -l, --stat		show status container"
	${ECMD} "    -b, --bind		get Qlauncher QR Code"
	${ECMD} "\n  Miscellaneous :"
	${ECMD} "    -P			check port status using nmap"
	${ECMD} "    --update		update script"
	${ECMD} "    --hostname		change hostname"
	#${ECMD} "    -w, --about		about this script\n"
	${ECMD} "  Report this script to: <https://github.com/jakues/one-hit/issues>"
	${ECMD} "  Report Qlauncher bugs to: <https://github.com/poseidon-network/qlauncher-linux/issues>"
	${ECMD} "  Qlauncher github: <https://github.com/poseidon-network/qlauncher-linux>"
	${ECMD} "  Poseidon Network home page: <https://poseidon.network/>\n"
	}

null() {
	${ECMD} "\nUsage: Q [OPTION]...\n"
	${ECMD} "Try 'Q --help' for more information.\n"
	}


case "$1" in
	-s|--start)
		start
;;
	-c|--stop)
		stop
;;
	-r|--restart)
	restart
;;
	-i|--check)
		check | lolcat
;;
	-l|--stat)
		status | lolcat
;;
	-b|--bind)
		bind
;;
	-P)
		port
;;
	--update)
		update
;;
	--hostname)
		hostname
;;
	--sn)
		change_hwsn
;;
	--help)
		help | lolcat
;;
	*)
		null | lolcat
;;
esac
