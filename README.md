<h1 align="center">Qlauncher Ez Setup</h1>

This scripts automates the installation process for [Qlauncher](https://github.com/poseidon-network/qlauncher-linux).
It automatically downloads and installs the following packages:

* docker
* net-tools
* lolcat 😋
* qrencode
* latest qlauncher


# [ Prerequisites ]
The installation scripts require the following:

* The machine operating system Ubuntu 20.04 LTS on x86.
* For raspberry pi 4B with operating system :
	* [Raspberry Pi OS](https://downloads.raspberrypi.org/raspios_lite_armhf_latest)
	* [DietPi](https://dietpi.com/downloads/images/DietPi_RPi-ARMv6-Buster.7z)
	* [Ubuntu server 32 bit](https://ubuntu.com/download/raspberry-pi)
* Run as **root** user.
* Package `curl` installed.


# [ Install ]
* Use this command to install Qlauncher
    * `sudo su`
	* `curl -sSL https://github.com/jakues/ql/raw/master/ql-install.sh | bash`
* Script usage
	* `Q --help`


# [ Uninstall ]
* Use this command to uninstall Qlauncher
	* `coming soon`
