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
  CONFIG_HOME="/root/setupvm-dev/K8/local"
fi

source $CONFIG_HOME/setupvm.config
SUDO=""


#Perform Basic Host Configuration
echo "... Configuring Host Env"
echo ""
source $CONFIG_HOME/../../lib/host-config.sh

# Configure RHSM if RHEL
if [ "$HOSTENV" == "rhel" ]
then
  echo "... Setting up RHSM"
  echo ""
  source $CONFIG_HOME/../../lib/rhsm.sh
fi

# Install base software
if [ "$HOSTENV" == "centos" ]
then
  echo "... Installing CentOS Base Software"
  echo ""
  source $CONFIG_HOME/../../lib/yum-centos-install.sh
elif [ "$HOSTENV" == "rhel" ]
then
  echo "... Installing RHEL Base Software"
  echo ""
  source $CONFIG_HOME/../../lib/yum-rhel-install.sh
else
  echo "!!!! Unsupported Operating System [HOSTENV - centos or rhel] !!!!"
  exit 1 
fi

# Install core software (go, etcd, docker, etc...)
echo "... Installing Host PreReqs"
echo ""
echo " ... ... Installing Go-$GOVERSION"
echo ""
source $CONFIG_HOME/../../lib/install-go.sh
echo " ... ... Installing etcd-$ETCD_VER"
echo ""
source $CONFIG_HOME/../../lib/install-etcd.sh
echo " ... ... Installing Docker-$DOCKER_VER"
echo ""
source $CONFIG_HOME/../../lib/docker-base.sh

# restart docker
source $CONFIG_HOME/../../lib/docker-restart.sh
echo ""

# Clone Repos
echo " ...Cloning Repos"
echo ""
source $CONFIG_HOME/../../lib/clone-repos.sh

# Create Profiles
echo " ...Setting Bash Environment"
echo ""
source $CONFIG_HOME/../../lib/bash-profile.sh

# Cloud Config
if [  "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
then
  echo " ... Performing Cloud Configurations"
  echo ""
  source $CONFIG_HOME/../../lib/cloud-config.sh
fi

# Ansible
if [ "$INSTALL_ANSIBLE" == "Y" ]
then
  echo " ...Installing Ansible"
  echo ""
  source $CONFIG_HOME/../../lib/install-ansible.sh
fi

# Post Install
echo " ...Performing Post Configurations"
echo ""
source $CONFIG_HOME/../../lib/post-install.sh


  # This is a common issue I've run into 
  # export PATH=$PATH:$GOPATH/bin; go get -u github.com/cloudflare/cfssl/cmd/...


echo ""
echo " *********************************************** "
echo "" 
echo "     Script Complete!  K8 CentOS Setup Completed on host $HOSTNAME!"
echo ""
echo " *********************************************** "
