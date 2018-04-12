#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Installing Docker
if [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "" ]
then
  $SUDO yum install docker -y
elif [ "$DOCKERVER" == "ce" ] 
then
  $SUDO yum check-update
  $SUDO curl -fsSL https://get.docker.com/ | sh >/dev/null 2>&1    
else
  $SUDO yum install docker-$DOCKERVER -y >/dev/null 2>&1
fi

