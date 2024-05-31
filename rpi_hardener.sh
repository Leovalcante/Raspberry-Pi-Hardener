#!/bin/bash
set -u

# Colors
cNormal=$(tput sgr0)
cBlue=$(tput setaf 4)
cGreen=$(tput setaf 2)
cRed=$(tput setaf 1)

# Banner
echo "$cGreen   .~~.   .~~.
  '. \ ' ' / .'$cRed
   .~ .~~~..~.
  : .~.'~'.~. :  $cBlue             _   __               __                   $cRed
 ~ (   ) (   ) ~ $cBlue   _______  (_) / /  ___ ________/ /__ ___  ___ ____   $cRed
( : '~'.~.'~' : )$cBlue  / __/ _ \/ / / _ \/ _ \`/ __/ _  / -_) _ \/ -_) __/  $cRed
 ~ .~ (   ) ~. ~ $cBlue /_/ / .__/_/ /_//_/\_,_/_/  \_,_/\__/_//_/\__/_/      $cRed
  (  : '~' :  )  $cBlue    /_/                                                $cRed
   '~ .~~~. ~'
       '~'$cNormal
Raspberry Pi Hardner: remove unnecessary stuff and go headless
"

function removeBloatware {
	echo "${cBlue}Removing bloatwares${cNormal}"
	# https://raspberrypi.stackexchange.com/a/56562
	apt-mark auto libreoffice* 
	apt-mark auto wolfram-engine 
	apt-mark auto chromium*
	apt-mark auto firefox 
	apt-mark auto scratch2 
	apt-mark auto minecraft-pi  
	apt-mark auto sonic-pi  
	apt-mark auto dillo 
	apt-mark auto gpicview 
	apt-mark auto penguinspuzzle 
	apt-mark auto oracle-java8-jdk 
	apt-mark auto openjdk-7-jre 
	apt-mark auto oracle-java7-jdk  
	apt-mark auto openjdk-8-jre 
	apt-mark auto libx11-.* 
	apt-mark auto x11-*
	apt-mark auto triggerhappy 
	apt-mark auto anacron 
	apt-mark auto logrotate 
	apt-mark auto dphys-swapfile
	echo "${cGreen}Bloatwares removed!${cNormal}"
}
function disableServices {
	echo "${cBlue}Disabling services${cNormal}"
	# Disable IPv6
	echo "# Disable IPv6" | tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.all.disable_ipv6=1" | tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.default.disable_ipv6=1" | tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.lo.disable_ipv6=1" | tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.eth0.disable_ipv6 = 1" | tee -a /etc/sysctl.conf

	sed -i $'s/exit 0/service procps reload\\\nexit 0/g' /etc/rc.local

	# Disable boot splash screen
	echo "disable_splash=1" >> /boot/config.txt

	# Disable bluetooth
	echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt

	# Disable on board LEDs
	echo "dtparam=act_led_trigger=none" >> /boot/config.txt
	echo "dtparam=act_led_activelow=on" >> /boot/config.txt

	# Reduce pre-built boot delay
	echo "boot_delay=0" >> /boot/config.txt

	# Improve SD Card life
	echo "$(cat /boot/cmdline.txt)" "fastboot noswap ro" > /boot/cmdline.txt

	# Disable unused system services
	systemctl disable dphys-swapfile.service
	systemctl disable keyboard-setup.service
	systemctl disable apt-daily.service
	systemctl disable raspi-config.service
	systemctl disable triggerhappy.service
	systemctl disable avahi-daemon.service

	# Disable Logging Services
	systemctl disable bootlogs
	systemctl disable console-setup

	# Turn off HDMI
	/opt/vc/bin/tvservice -o

	echo "${cGreen}Services disabled${cNormal}"
}
function removeDesktopEnvironment {
	echo "${cBlue}Removing desktop environment${cNormal}"
	apt-mark auto xserver* 
	apt-mark auto lightdm*
	apt-mark auto raspberrypi-ui-mods
	apt-mark auto lxde*
	apt-mark auto desktop*
	apt-mark auto gnome*
	apt-mark auto gstreamer*
	apt-mark auto gtk*
	apt-mark auto hicolor-icon-theme*
	apt-mark auto lx*
	apt-mark auto mesa*
	apt-mark auto vlc*
	echo "${cGreen}Desktop environment removed${cNormal}"
}
function installSecurity {
	echo "${cBlue}Installing security software${cNormal}"
	# UFW
	apt install ufw -y

	yes | ufw enable 
	ufw allow from 192.168.1.0/24 to any port 22

	ufw status

	# Fail2Ban
	apt install fail2ban -y

	systemctl start fail2ban
	systemctl enable fail2ban

	touch /etc/fail2ban/jail.local
	echo "[sshd]" >> /etc/fail2ban/jail.local
	echo "enabled = true" >> /etc/fail2ban/jail.local
	echo "port = 22" >> /etc/fail2ban/jail.local
	echo "filter = sshd" >> /etc/fail2ban/jail.local
	echo "logpath = /var/log/auth.log" >> /etc/fail2ban/jail.local
	echo "maxretry = 3" >> /etc/fail2ban/jail.local

	systemctl restart fail2ban

	echo "${cGreen}Security software installed${cNormal}"
}

function main {
	# Check root 
	if [ "$EUID" -ne 0 ]
	then
		echo "${cRed}ERROR: Raspberry Pi Hardener MUST BE run as root"
		echo "\$ sudo ${0##*/} $cNormal"
		exit 1
	fi
	
	# Important note
	echo "${cRed}!!! ATTENTION !!!"
	echo -e "Before running this script ensure you've set a static IP address\nand enabled the SSH or VNC service via the raspi-config$cNormal"
	read -p "Do you want to continue? (y/N) " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then 
		exit 0
	fi

	initialDiskUsage=$(df / | grep '/dev/' | awk '{print $3}')

	# Update everything
	echo "${cBlue}Updating and upgrading current dependencies${cNormal}"
	sudo apt update -y
	sudo apt upgrade -y

	# Clean the system and go headless
	echo "${cBlue}Start cleaning processes${cNormal}"
	removeBloatware
	disableServices
	removeDesktopEnvironment

	# Install security measures
	installSecurity

	# Actually remove stuffs 
	echo "${cBlue}Removing stuffs${cNormal}"
	sudo apt autoremove -y
	sudo apt clean -y
	echo

	finalDiskUsage=$(df / | grep '/dev/' | awk '{print $3}')
	((freedSpace=initialDiskUsage-finalDiskUsage))
	echo "${cGreen}The procedure freed $(echo $freedSpace|numfmt --to=si)${cNormal}"
	echo

	# Reboot
	read -p "${cBlue}Press any key to reboot ${cNormal}" -n 1 -r 
	reboot
}

main