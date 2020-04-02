#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
apt-get update > /dev/null
echo -e "${RED}Setting SSH params${NC}"

#	doing config file backup
cp /etc/ssh/sshd_config /etc/ssh/$(date +%s)_backup.sshd_config

#	Copy over issue file (MOTD)
cp ./issue /etc/issue
cp ./issue /etc/issue.net

# 	disalllow root logins
sed -i 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config

#       Disconnect Idle Sessions
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/g' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/g' /etc/ssh/sshd_config

#	Disable X11Forwarding
sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config

#Ubuntu 16.04 special, disable weak elliptic curves
sed -i 's|HostKey /etc/ssh/ssh_host_ecdsa_key|#HostKey /etc/ssh/ssh_host_ecdsa_key|g' /etc/ssh/sshd_config

#	Set Banner and MOTD
awk '{sub(/#Banner/,"Banner /etc/issue.net #")}1' /etc/ssh/sshd_config > tmp
mv tmp /etc/ssh/sshd_config
apt-get install figlet -y > /dev/null
cp /etc/update-motd.d/00-header /etc/update-motd.d/$(date +%s)_backup.00-header || cp /etc/update-motd.d/10-uname /etc/update-motd.d/$(date +%s)_backup.10-uname && echo "figlet "No Trespassing"" >> /etc/update-motd.d/10-uname
test -f /etc/update-motd.d/10-uname || echo "figlet "No Trespassing"" >> /etc/update-motd.d/00-header
#	Hoskpey preferences
echo -e "HostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key\n" >> /etc/ssh/sshd_config

#	Change Default Ciphers and Algorithms
echo -e "KexAlgorithms curve25519-sha256@libssh.org\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config

#	Regenerate Moduli
echo -e  "${RED}Regenerating Moduli, will take some time${NC}"
ssh-keygen -G moduli-2048.candidates -b 2048
ssh-keygen -T moduli-2048 -f moduli-2048.candidates
cp moduli-2048 /etc/ssh/moduli 
rm moduli-2048

#	Install f2b
echo -e "${RED}Installing fail2ban${NC}"
apt-get install fail2ban -y > /dev/null
if [[ $(lsb_release -rs) = "16.04" ]]
	then cp /etc/fail2ban/jail.conf /etc/fail2ban/$(date +%s)_backup.1604.jail.conf | cp ./jail.1604 /etc/fail2ban/jail.conf
	else	
	cp /etc/fail2ban/jail.conf /etc/fail2ban/$(date +%s)_backup.jail.conf
	cp ./jail.conf /etc/fail2ban/jail.conf
fi

echo -e "${RED}Restarting fail2ban service${NC}"
service fail2ban restart

#	Test sshd config
#echo "Testing SSH config"
#sshd -t 

#	reload sshd service
echo -e  "${RED}Reloading sshd service${NC}"
systemctl reload sshd

#	Get sshd audit python script
#	Just check that all is fine and "green"
wget https://raw.githubusercontent.com/arthepsy/ssh-audit/master/ssh-audit.py
python ./ssh-audit.py localhost

#	installing ClamAV
apt-get install clamav clamav-freshclam clamav-daemon -y > /dev/null

#	installing rkhunet
apt-get install rkhunter -y > /dev/null
echo -e "0 0 * * * rkhunter --update\n0 1 * * * rkhunter --check" >> /var/spool/cron/crontabs/root
rkhunter --propupd
echo -e "${RED}rkhunter: Who shoud receive warning emails:${NC}"
read rkhunet_warning_mail
echo -e "MAIL-ON-WARNING="\"${rkhunet_warning_mail}"\"" >> /etc/rkhunter.conf

# Unattended upgrades
apt-get install unattended-upgrades -y >> /dev/null
cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/$(date +%s)_backup.50unattended-upgrades
cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/$(date +%s)_backup.20auto-upgrades

# Need to use tee via pipe to output into multiple files
echo -e "APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Download-Upgradeable-Packages "1";\nAPT::Periodic::AutocleanInterval "7";\nAPT::Periodic::Unattended-Upgrade "1";" | tee /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/20auto-upgrades > /dev/null

#	Get apticron
apt-get install apticron -y >> /dev/null
cp /etc/apticron/apticron.conf /etc/apticron/$(date +%s)_backup.apticron.conf
sed -i 's/EMAIL="root"/#EMAIL="root"/g' /etc/apticron/apticron.conf
echo -e "${RED}Apticron: Email receiver(-s):${NC}"
read apticron_email
echo -e "${RED}Apticron: Custom FROM:${NC}"
read apticron_from
echo -e "EMAIL="\"${apticron_email}"\"\nCUSTOM_FROM="\"${apticron_from}"\"" >> /etc/apticron/apticron.conf
#	Personal pref, i like my notification at the start of hour
sed -i 's|[1-59]|0|g' /etc/cron.d/apticron
echo -e "${RED}You all set!\nRun audit.sh\nWhen done delete this dir${NC}"