#! /bin/bash
# Some automation to setting up OSE/K8 VM's
# For RHEL Environments

SCRIPT_HOME="$(realpath $(dirname $0))"
CONFIG_HOME=""

if [ -f "$SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$SCRIPT_HOME
elif [ -f "$K8_SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$K8_SCRIPT_HOME
else
  CONFIG_HOME="/root/setupvm-dev/Origin"
fi

source $CONFIG_HOME/setupvm.config
SUDO=""

DoBlock()
{
  $SUDO lsblk
  echo "Based on output above, what block device should the registry be set up on?"
  read block_device
  if [ "$block_device" == "" ]
  then
    echo "no block device entered, default $DEFAULT_BLOCK will be used"
    $SUDO sh -c "echo 'DEVS=$DEFAULT_BLOCK' >> /etc/sysconfig/docker-storage-setup"
    $SUDO sh -c "echo 'VG=$VG' >> /etc/sysconfig/docker-storage-setup"
  else
    echo "block device /dev/$block_device will be used, is this acceptable? (y/n)"
    read isaccepted
    if [ "$isaccepted" == "$yval1" ] || [ "$isaccepted" == "$yval2" ]
    then
      $SUDO sh -c "echo 'DEVS=/dev/$block_device' >> /etc/sysconfig/docker-storage-setup"
      $SUDO sh -c "echo 'VG=$VG' >> /etc/sysconfig/docker-storage-setup"
      echo "docker-storage-setup file updated"
    else
      echo "Let's try again..."
      echo ""
      DoBlock
    fi
  fi
}

#Perform Basic Host Configuration
source $CONFIG_HOME/../../lib/host-config.sh

#RHSM
source $CONFIG_HOME/../../lib/rhsm.sh


# Install RHEL base software
source $CONFIG_HOME/../../lib/yum-rhel-install.sh

# Install core software (go, etcd, docker, etc...)
source $CONFIG_HOME/../../lib/install-go.sh
source $CONFIG_HOME/../../lib/install-etcd.sh
source $CONFIG_HOME/../../lib/docker-base.sh

if [ "$APP_TYPE" == "origin" ] && [ "$HOSTENV" == "rhel" ]
then
  source $CONFIG_HOME/../../lib/docker-registry.sh
fi
source $CONFIG_HOME/../../lib/docker-restart.sh


# Clone Repos
source $CONFIG_HOME/../../lib/clone-repos.sh

# Create Profiles
source $CONFIG_HOME/../../lib/bash-profile.sh

# Cloud Config
if [  "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
then
  source $CONFIG_HOME/../../lib/cloud-config.sh
fi

# Post Install
source $CONFIG_HOME/../../lib/post-install.sh


  # This is a common issue I've run into 
  # export PATH=$PATH:$GOPATH/bin; go get -u github.com/cloudflare/cfssl/cmd/...


echo ""
echo " *********************************************** "
echo "" 
echo "     Script Complete!  Origin RHEL Setup Completed on host $HOSTNAME!"
echo ""
echo " *********************************************** "


