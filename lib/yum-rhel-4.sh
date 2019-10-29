#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "rhel" ]
then  
  echo " ... ... Installing wget, git, gcc-c++ python3-pip ... this will take several minutes"
  until $SUDO yum install wget git gcc-c++ python3-pip jq yum-utils device-mapper-persistent-data lvm2 -y> /dev/null; do echo "Failure installing utils Repos, retrying..."; sleep 8; done


  echo " ... ... performing yum update"
  $SUDO yum update -y> /dev/null

  echo ""
  echo "  ************************************"
  echo "  *  YUM SOFTWARE INSTALLED FOR RHEL *"
  echo "  ************************************"
fi
