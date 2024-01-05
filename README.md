# ubuntu-server-setup-sshserver
Initial server setup, config and secure openssh, fail2ban, auditd and self signed cert.

This creates a strong ed25519 key.
Make sure you replace usernames, computer names and IP's in the script.

Fail2ban and auditd are both configured to protect ssh.

The self signed cert is created in /etc/ssl/selfsigned 
  it should contain both a .key and .crt file

Comments on the script explain the rest. Tested on Ubuntu and Debian servers.
