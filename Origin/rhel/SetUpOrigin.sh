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
echo "................................."
echo "     Configuring Host Env"
echo "................................."
source $CONFIG_HOME/../../lib/host-config.sh
echo ""

#RHSM
echo "................................."
echo "      Setting up RHSM"
echo "................................."
source $CONFIG_HOME/../../lib/rhsm.sh
echo ""

# Install RHEL base software
echo "................................."
echo "... Installing RHEL Base Software"
echo "................................."
source $CONFIG_HOME/../../lib/yum-rhel-install.sh
echo ""

# Install core software (go, etcd, docker, etc...)
echo "................................."
echo "  Installing Host PreReqs"
echo "................................."
echo " ... ... Installing Go-$GOVERSION"
source $CONFIG_HOME/../../lib/install-go.sh
echo " ... ... Installing etcd-$ETCD_VER"
source $CONFIG_HOME/../../lib/install-etcd.sh
echo " ... ... Installing Docker-$DOCKERVER"
source $CONFIG_HOME/../../lib/docker-base.sh

if [ "$APP_TYPE" == "origin" ] && [ "$HOSTENV" == "rhel" ]
then
  echo " ... ... Configuring Registry"
  source $CONFIG_HOME/../../lib/docker-registry.sh
fi
source $CONFIG_HOME/../../lib/docker-restart.sh
echo ""

# Clone Repos
echo "................................."
echo "      Cloning Repos"
echo "................................."
source $CONFIG_HOME/../../lib/clone-repos.sh
echo ""

# Create Profiles
echo "................................."
echo "   Setting Bash Environment"
echo "................................."
source $CONFIG_HOME/../../lib/bash-profile.sh
echo ""

# Cloud Config
if [  "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
then
  echo "................................."
  echo " Performing Cloud Configurations"
  echo "................................."
  source $CONFIG_HOME/../../lib/cloud-config.sh
  echo ""
fi

# Post Install
echo "................................."
echo " Performing Post Configurations"
echo "................................."
source $CONFIG_HOME/../../lib/post-install.sh
echo ""

  # This is a common issue I've run into 
  # export PATH=$PATH:$GOPATH/bin; go get -u github.com/cloudflare/cfssl/cmd/...


echo ""
echo " *********************************************** "
echo "" 
echo "     Script Complete!  Origin RHEL Setup Completed on host $HOSTNAME!"
echo ""
echo " *********************************************** "


