#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "rhel" ]
then  
  echo " ... ... Installing wget, git,  golang-bin gcc-c++ ... this will take several minutes"
  until $SUDO yum install wget git golang-bin gcc-c++ -y> /dev/null; do echo "Failure installing utils Repos, retrying..."; sleep 8; done

  echo " ... ... performing yum update"
  $SUDO yum update -y> /dev/null

  echo ""
  echo "  ************************************"
  echo "  *  YUM SOFTWARE INSTALLED FOR RHEL *"
  echo "  ************************************"
fi
