#!/bin/bash

# openssh server install and ufw config
# Script to set up a secure server environment with LAN restrictions if needed
# Self-signed SSL cert

# Ensure root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#adduser anewadminuser
#usermod -aG sudo anewadminuser

# Clean previous ssh server install and keys
purge openssh-server
rm -R /home/yourcurrentusername/.ssh
systemctl stop ssh

# Install SSH Server and Update and Restart
apt install haveged
apt install openssh-server -y
systemctl start ssh
systemctl enable ssh
mkdir -p /home/yourcurrentusername/.ssh
chmod 700 /home/yourcurrentusername/.ssh
ssh-keygen -t ed25519 -a 100 -f /home/yourcurrentusername/.ssh/id_ed25519
chmod 600 /home/yourcurrentusername/.ssh/id_ed25519
chmod 644 /home/yourcurrentusername/.ssh/id_ed25519.pub
cat /home/yourcurrentusername/.ssh/id_ed25519.pub >> /home/yourcurrentusername/.ssh/authorized_keys
chmod 600 /home/yourcurrentusername/.ssh/authorized_keys


# Update and Upgrade everything including snaps
apt update && apt upgrade && snap refresh

# Harden SSH Configuration
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PubkeyAcceptedKeyTypes ssh-ed25519' /etc/ssh/sshd_config

systemctl restart ssh

# verify ed25519 is configured properly
# ssh -i /path/to/ed25519/key yourcurrentusername@computernamehere


# firewall (ufw)
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp    # SSH port
ufw enable

# If you want to restrict access to the server from the LAN only
# Replace '192.168.1.0/24' with your actual LAN IP range
# ufw allow from 192.168.1.0/24 to any port 443

# Install and configure Fail2Ban
apt install fail2ban -y
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1d
EOF

systemctl restart fail2ban

# Install and configure Auditd for auditing system activities
apt install auditd -y

# Adding key audit rules (modify as needed for your environment)
cat > /etc/audit/rules.d/audit.rules << EOF
-w /etc/ssh/sshd_config -k sshd_config
EOF

systemctl restart auditd

# Generate a strong self-signed SSL certificate
mkdir /etc/ssl/selfsigned
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/selfsigned/selfsigned.key -out /etc/ssl/selfsigned/selfsigned.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

echo "Server security setup completed. Self-signed SSL certificate generated."
