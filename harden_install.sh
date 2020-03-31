#!/bin/bash
apt-get update > /dev/null 2> ./errors.log

echo "Setting SSH params"

#	doing config file backup
cp /etc/ssh/sshd_config /etc/ssh/backup.sshd_config

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
apt-get install figlet -y
cp /etc/update-motd.d/00-header /etc/update-motd.d/backup.00-header
echo "figlet "No Trespassing"" >> /etc/update-motd.d/00-header

#	Hoskpey preferences
echo -e "HostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key\n" >> /etc/ssh/sshd_config

#	Change Default Ciphers and Algorithms
echo -e "KexAlgorithms curve25519-sha256@libssh.org\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config

#	Regenerate Moduli
echo "Regenerating Moduli, will take some time"
ssh-keygen -G moduli-2048.candidates -b 2048
ssh-keygen -T moduli-2048 -f moduli-2048.candidates
cp moduli-2048 /etc/ssh/moduli 
rm moduli-2048

#	Install f2b
echo "Installing fail2ban"
apt-get install fail2ban -y 2>> ./errors.log
if [[ $(lsb_release -rs) = "16.04" ]]
	then cp /etc/fail2ban/jail.conf /etc/fail2ban/backup.1604.jail.conf | cp ./jail.1604 /etc/fail2ban/jail.conf
	else	
	cp /etc/fail2ban/jail.conf /etc/fail2ban/backup.jail.conf
	cp ./jail.conf /etc/fail2ban/jail.conf
fi

echo "Restarting fail2ban service"
service fail2ban restart

#	Test sshd config
echo "Testing SSH config"
sshd -t 

#	reload sshd service
echo "Reloading sshd service"
systemctl reload sshd

#	Get sshd audit python script
#	Just check that all is fine and "green"
wget https://raw.githubusercontent.com/arthepsy/ssh-audit/master/ssh-audit.py
python ./ssh-audit.py localhost
