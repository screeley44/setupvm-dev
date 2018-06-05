#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Installing Docker
if [ "$HOSTENV" == "centos" ]
then
  if [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "" ]
  then
    $SUDO yum install docker -y
  elif [ "$DOCKERVER" == "ce" ] 
  then
    $SUDO yum check-update
    $SUDO curl -fsSL https://get.docker.com/ | sh >/dev/null 2>&1 
  elif [ "$DOCKERVER" == "ce" ] 
  then
    $SUDO yum install docker-1.13.1 -y >/dev/null 2>&1   
  else
    $SUDO yum install docker-$DOCKERVER -y >/dev/null 2>&1
  fi
elif [ "$HOSTENV" == "rhel" ]
then
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
else
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
fi

