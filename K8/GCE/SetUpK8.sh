#! /bin/bash
# Some automation to setting up OSE/K8 VM's
# For RHEL Type Environments

SCRIPT_HOME="$(realpath $(dirname $0))"
CONFIG_HOME=""

if [ -f "$SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$SCRIPT_HOME
elif [ -f "$K8_SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$K8_SCRIPT_HOME
else
  CONFIG_HOME="/root/setupvm-dev/K8/GCE"
fi

source $CONFIG_HOME/setupvm.config
SUDO=""


#Perform Basic Host Configuration
source $CONFIG_HOME/../../lib/host-config.sh

# Install Centos base software
if [ "$HOSTENV" == "rhel" ]
then
  source $CONFIG_HOME/../../lib/rhsm.sh
fi

# Install base software
if [ "$HOSTENV" == "centos" ]
then
  source $CONFIG_HOME/../../lib/yum-centos-install.sh
elif [ "$HOSTENV" == "rhel" ]
then
  source $CONFIG_HOME/../../lib/yum-rhel-install.sh
else
  echo "Unsupported Operating System [HOSTENV - centos or rhel] you have $HOSTENV"
  exit 1 
fi

# Install core software (go, etcd, docker, etc...)
source $CONFIG_HOME/../../lib/install-go.sh
source $CONFIG_HOME/../../lib/install-etcd.sh
source $CONFIG_HOME/../../lib/docker-base.sh

# restart docker
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

# Ansible
if [ "$INSTALL_ANSIBLE" == "Y" ]
then
  source $CONFIG_HOME/../../lib/install-ansible.sh
fi

# Post Install
source $CONFIG_HOME/../../lib/post-install.sh


  # This is a common issue I've run into 
  # export PATH=$PATH:$GOPATH/bin; go get -u github.com/cloudflare/cfssl/cmd/...


echo ""
echo " *********************************************** "
echo "" 
echo "     Script Complete!  K8 $HOSTENV Setup Completed on host $HOSTNAME!"
echo ""
echo " *********************************************** "
