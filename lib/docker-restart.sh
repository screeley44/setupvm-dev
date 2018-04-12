#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Restart Docker
echo " ... ... Restarting Docker"
$SUDO groupadd docker >/dev/null 2>&1
$SUDO gpasswd -a ${USER} docker >/dev/null 2>&1
$SUDO systemctl stop docker >/dev/null 2>&1
$SUDO rm -rf /var/lib/docker/* >/dev/null 2>&1
$SUDO systemctl restart docker >/dev/null 2>&1
$SUDO systemctl enable docker >/dev/null 2>&1
