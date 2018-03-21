#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Installing Docker
echo ""
echo "Installing Docker ..."
echo ""
if [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "" ]
then
  echo " ... installing default docker from enabled repos..."
  $SUDO yum install docker -y
elif [ "$DOCKERVER" == "ce" ] 
then
  echo " ... installing latest docker ce release"
  $SUDO yum check-update
  $SUDO curl -fsSL https://get.docker.com/ | sh    
else
  echo " ... installing Docker version $DOCKERVER"
  $SUDO yum install docker-$DOCKERVER -y
fi

