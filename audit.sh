#!/bin/bash
#	Import key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
#	Add software repository
apt install apt-transport-https
echo 'Acquire::Languages "none";' | tee /etc/apt/apt.conf.d/99disable-translations
#	Adding the repository
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | tee /etc/apt/sources.list.d/cisofy-lynis.list
#	Install lynis
apt-get install lynis -y
#	Update lynis
lynis update check