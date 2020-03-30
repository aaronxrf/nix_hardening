#!/bin/bash
echo "Setting SSH params"
#	doing config file backup
cp /etc/ssh/sshd_config /etc/ssh/backup.sshd_config
#	Copy over issue file (MOTD)
cp ~/nix_hardening/issue /etc/issue
cp ~/nix_hardening/issue /etc/issue.net
# 	disalllow root logins
sed -i 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config

#       Disconnect Idle Sessions
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/g' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/g' /etc/ssh/sshd_config

#	Disable X11Forwarding
sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config

#	Set Banner and MOTD
awk '{sub(/#Banner none/,"Banner /etc/issue.net")}1' /etc/ssh/sshd_config > tmp
mv tmp /etc/ssh/sshd_config
apt-get install figlet -y
cp /etc/update-motd.d/00-header /etc/update-motd.d/backup.00-header
echo "figlet "No Trespassing"" >> /etc/update-motd.d/00-header

#	Hoskpey preferences
echo -e "HostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key\n" >> /etc/ssh/sshd_config

#	Change Default Ciphers and Algorithms
echo -e "KexAlgorithms curve25519-sha256@libssh.org\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config

#	Install f2b
echo "Installing fail2ban"
apt-get install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/backup.jail.conf
cp ~/nix_hardening/jail.conf /etc/fail2ban/jail.conf
echo "Restarting fail2ban service"
service fail2ban restart


#	reload sshd service
sudo systemctl reload sshd

#	Get sshd audit python script
#	Just check that all is fine and "green"
wget https://raw.githubusercontent.com/arthepsy/ssh-audit/master/ssh-audit.py
python ./ssh-audit.py

