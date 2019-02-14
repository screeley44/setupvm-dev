#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "centos" ]
then  
  echo " ... ... Installing base software for CentOS ... this will take several minutes"
  yum install -y wget gcc python-virtualenv git net-tools unzip bash-completion telnet kexec-tools sos psacct NetworkManager >/dev/null 2>&1

  # enable NetworkManager
  systemctl enable NetworkManager >/dev/null 2>&1
  systemctl restart NetworkManager >/dev/null 2>&1

  # install pip
  yum install epel-release -y
  yum install python-pip -y


  # krb5-devel - been reported that this is needed for OCP
  if [ "$APP_TYPE" == "origin" ]
  then
    if [ "$OCPVERSION" == "3.7" ] && [ "$HOSTENV" == "rhel" ]
    then
      $SUDO yum install krb5-devel -y >/dev/null 2>&1
    fi
    if [ "$OCPVERSION" == "3.9" ] && [ "$HOSTENV" == "rhel" ]
    then
      $SUDO yum install krb5-devel -y >/dev/null 2>&1
    fi
  fi

  echo " ... ... performing yum update"
  $SUDO yum update -y >/dev/null 2>&1
  if [ "$APP_TYPE" == "Origin" ]
  then
      echo "... ... Installing openshift utils for DEV setup type..."
      $SUDO yum install atomic-openshift-utils -y >/dev/null 2>&1
  fi
fi
