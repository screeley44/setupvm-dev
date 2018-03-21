#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "rhel" ]
then  
  echo "...Installing wget, git, net-tools, bind-utils, iptables-services, rpcbind, nfs-utils, glusterfs-client bridge-utils, gcc, python-virtualenv, bash-completion telnet unzip kexec-tools sos psacct ... this will take several minutes"
  until $SUDO yum install wget git net-tools bind-utils iptables-services rpcbind nfs-utils glusterfs-client bridge-utils gcc python-virtualenv bash-completion telnet unzip kexec-tools sos psacct -y> /dev/null; do echo "Failure installing utils Repos, retrying..."; sleep 8; done

  # krb5-devel - been reported that this is needed for OCP
  if [ "$APP_TYPE" == "origin" ]
  then
    if [ "$OCPVERSION" == "3.7" ] && [ "$HOSTENV" == "rhel" ]
    then
      $SUDO yum install krb5-devel -y> /dev/null
    fi
    if [ "$OCPVERSION" == "3.9" ] && [ "$HOSTENV" == "rhel" ]
    then
      $SUDO yum install krb5-devel -y> /dev/null
    fi
  fi

  echo "...performing yum update"
  $SUDO yum update -y> /dev/null
  if [ "$HOSTENV" == "rhel" ] && [ "$APP_TYPE" == "Origin" ]
  then
      echo "...Installing openshift utils for DEV setup type..."
      $SUDO yum install atomic-openshift-utils -y> /dev/null
  fi
  echo ""
  echo "  ************************************"
  echo "  *  YUM SOFTWARE INSTALLED FOR RHEL *"
  echo "  ************************************"
fi
