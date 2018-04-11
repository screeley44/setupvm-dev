echo "#! /bin/bash" > rmt-docker-restart.sh
echo "groupadd docker" >> rmt-docker-restart.sh
echo "gpasswd -a ${USER} docker" >> rmt-docker-restart.sh
echo "systemctl stop docker" >> rmt-docker-restart.sh
echo "rm -rf /var/lib/docker/*" >> rmt-docker-restart.sh
echo "systemctl restart docker" >> rmt-docker-restart.sh
echo "systemctl enable docker" >> rmt-docker-restart.sh
