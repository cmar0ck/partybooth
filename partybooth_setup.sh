#!/bin/bash

# This script is intended to run on a RPi3 with Raspbian (Jessie) installed 
# (https://www.raspberrypi.org/downloads/raspbian/)
#
# Photobooth Software: A.Dahlem, 2016 (https://twitter.com/alexdahlem)
# RPI Conversion: cmar0ck, 2017 (https://github.com/cmar0ck)


##################################################
# TODO: Fix Gallery upload			 #
##################################################


echo
echo "###############################"
echo "#      BASIC PREPARATIONS     #"
echo "###############################"
echo

read -p "Update repos + upgrade system? Continue (y/n)?" choice
case "$choice" in 
  y|Y ) sudo apt update && sudo apt dist-upgrade -y && sudo apt-get autoremove -y;;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

echo
echo "###############################"
echo "#   INSTALL COMMON SOFTWARE   #"
echo "###############################"
echo

echo "Installing apache2 + php5"
sudo apt install -y apache2 apache2-utils libapache2-mod-php5 php5 php-pear php5-xcache php5-curl php5-gd
echo

echo "Installing Firefox"
sudo apt install -y firefox-esr
echo

echo "Installing xdotool"
sudo apt install -y xdotool
echo

echo "Installing xbindkeys"
sudo apt install -y xbindkeys xbindkeys-config
xbindkeys --defaults > $HOME/.xbindkeysrc
echo "" | sudo tee -a ~/.xbindkeysrc
echo "Enabling shutdown on key press '0'"
echo '"sudo shutdown -h now"' | sudo tee -a ~/.xbindkeysrc
echo "  0" | sudo tee -a ~/.xbindkeysrc
echo "xbindkeys" | sudo tee -a ~/.config/lxsession/LXDE-pi/autostart
echo

echo "Installing Adafruit Retrogame tool (maps GPIO inputs to key presses)"
echo
echo "Make sure you have your buttons connected to the following GPIO positions (all on the RIGHT / EVEN side of the header in the UPPER HALF)"
echo
echo "Take Picture (Key '1'): PIN6(GND), PIN12(GPIO18)"
echo "Shutdown Pi  (Key '0'): PIN18(GPIO24), PIN20(GND)" 
echo
echo "If you want to add a reset button just solder it to the 'Run' headers on the RPi3 board (use with caution!)."
echo
read -p "IMPORTANT: Do NOT rebooot the system directly after Retrogame installation is done! (First complete the rest of this setup script!)" key
echo
cd
curl -O https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/retrogame.sh
sudo bash retrogame.sh
echo "# Here's the pin configuration for the Partybooth project (following BCM numbering convention)" | sudo tee /boot/retrogame.cfg
echo "# (left is the key to map, right its corresponding pin number):" | sudo tee -a /boot/retrogame.cfg
echo "" | sudo tee -a /boot/retrogame.cfg
echo "0         24  # Shutdown Partybooth" | sudo tee -a /boot/retrogame.cfg
echo "1         18  # Take Photo" | sudo tee -a /boot/retrogame.cfg
echo "" | sudo tee -a /boot/retrogame.cfg
rm retrogame.sh

echo
echo "###############################"
echo "#  INSTALL OPTIONAL SOFTWARE  #"
echo "###############################"
echo

read -p "Install TightVNC Server? Continue (y/n)?" choice
case "$choice" in 
  y|Y )	sudo apt install -y tightvncserver;
	vncserver;;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

echo
echo "###############################"
echo "#      EDIT CONFIG FILES      #"
echo "###############################"
echo

read -p "Enable RPi cam module hardware interface (and adjust other settings)? Continue (y/n)?" choice
case "$choice" in 
  y|Y ) read -p "Set '5 Interfacing options -> P1 Camera -> Enabled' in the following program" key;
	sudo raspi-config;;
	# Alternatively:
	#echo "" | sudo tee -a /boot/config.txt;
	#echo "# Enabling Cam" | sudo tee -a /boot/config.txt;
	#echo "start_x=1" | sudo tee -a /boot/config.txt;
	#echo "disable_camera_led=1" | sudo tee -a /boot/config.txt;;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

read -p "Enable custom V4L2 cam driver on boot (required to access RPi cam module in browser)? Continue (y/n)?" choice
case "$choice" in 
  y|Y )	echo "Adding cronjob..."; 
	(sudo crontab -l 2>/dev/null; echo "@reboot sudo modprobe bcm2835-v4l2") | sudo crontab - ;
	echo "DONE (Don't forget to reboot for the changes to take effect.)";
	echo;
	echo "Note: It might be useful to add a cooling fan to your RPi3 as it tends to get increasingly hot when accessing the bcm2835-v4l2 via browser.";
	echo;;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

read -p "Boot directly to Firefox (in fullscreen mode)? Continue (y/n)?" choice
case "$choice" in
  y|Y )	touch /home/pi/ff.sh;
	echo 'firefox -foreground -no-remote -new-window localhost & xdotool search --sync --onlyvisible --class "Firefox" windowactivate key F11 & xdotool search --sync --onlyvisible --class "Firefox" windowactivate key F5' | tee -a /home/pi/ff.sh;
	sudo chmod a+x /home/pi/ff.sh;
	echo "@sh /home/pi/ff.sh" | sudo tee -a ~/.config/lxsession/LXDE-pi/autostart;
	echo;
	echo "DONE (Don't forget to reboot for the changes to take effect.)";
	echo;;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

read -p "Disable RPi warning overlays ('Power Issue' / 'Overheating' icons, etc)? Continue (y/n)?" choice
case "$choice" in 
  y|Y )	echo "" | sudo tee -a /boot/config.txt; 
	echo "# Disabling warning overlays"; | sudo tee -a /boot/config.txt;
	echo "avoid_warnings=1" | sudo tee -a /boot/config.txt;
	echo;
	echo "DONE";;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

read -p "Enable USB tethering (to use mobile phone's internet connection)? Continue (y/n)?" choice
case "$choice" in 
  y|Y )	echo "" | sudo tee -a /etc/network/interfaces; 
	echo "# Enabling USB tethering" | sudo tee -a /etc/network/interfaces;
	echo "allow-hotplug usb0" | sudo tee -a /etc/network/interfaces;
	echo "iface usb0 inet dhcp" | sudo tee -a /etc/network/interfaces;
	echo;
	echo "DONE";;
  n|N ) echo "cancelling...";;
  * ) 	echo "invalid input";;
esac
echo

echo
echo "###############################"
echo "#      FIREFOX SPECIFICS      #"
echo "###############################"
echo

echo "Make Firefox start 'quietly' (so that it doesn't display naggy WebRTC confirmations, etc):"
echo
echo "Type 'about:config' in the address bar then set: "
echo 
echo "1. 'media.navigator.permission.disabled' -> 'true'"
echo
echo "2. 'browser.sessionstore.resume_from_crash' -> 'false'"
echo
echo "3. Install this addon: https://addons.mozilla.org/en-US/firefox/addon/disable-webrtc-overlay/" 
echo

echo
echo "ALL DONE!"
echo
