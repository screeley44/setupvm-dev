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
    $SUDO yum update >/dev/null 2>&1
    $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
    $SUDO yum install docker-ce -y >/dev/null 2>&1
    # $SUDO yum check-update
    # $SUDO curl -fsSL https://get.docker.com/ | sh >/dev/null 2>&1 
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
    $SUDO dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    $SUDO dnf install --nobest --allowerasing docker-ce  
  elif [ "$DOCKERVER" == "podman" ] 
  then
    $SUDO yum check-update
    $SUDO dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    $SUDO yum install docker -y   
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

