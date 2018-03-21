#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Restart Docker
echo "...Restarting Docker"
$SUDO groupadd docker
$SUDO gpasswd -a ${USER} docker
$SUDO systemctl stop docker
$SUDO rm -rf /var/lib/docker/*
$SUDO systemctl restart docker
$SUDO systemctl enable docker
