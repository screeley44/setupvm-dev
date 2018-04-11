echo "#! /bin/bash" > rmt-docker.sh
echo "if [ \"$DOCKERVER\" == \"default\" ] || [ \"$DOCKERVER\" == \"\" ]" >> rmt-docker.sh
echo "then" >> rmt-docker.sh
echo "  yum install docker -y> /dev/null" >> rmt-docker.sh
echo "elif [ \"$DOCKERVER\" == \"ce\" ]" >> rmt-docker.sh 
echo "then" >> rmt-docker.sh
echo "  yum check-update> /dev/null" >> rmt-docker.sh
echo "  curl -fsSL https://get.docker.com/ | sh" >> rmt-docker.sh   
echo "else" >> rmt-docker.sh
echo "  yum install docker-$DOCKERVER -y> /dev/null" >> rmt-docker.sh
echo "fi" >> rmt-docker.sh

