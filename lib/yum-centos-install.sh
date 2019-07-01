#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "centos" ]
then  
  echo " ... ... Installing base software for CentOS ... this will take several minutes"
  yum install -y wget gcc python-virtualenv git net-tools unzip bash-completion telnet kexec-tools sos psacct NetworkManager jq >/dev/null 2>&1

  # enable NetworkManager
  systemctl enable NetworkManager >/dev/null 2>&1
  systemctl restart NetworkManager >/dev/null 2>&1

  # install pip
  yum install epel-release -y >/dev/null 2>&1
  yum install python36 python36-pip python36-devel -y >/dev/null 2>&1
  yum install jq -y >/dev/null 2>&1

  if [ "$SETUP_TYPE" == "k8-dev" ]
  then
    if [ "$BUCKET_NAME" == "" ]
    then
      echo " ... ... ... not installing kubectl"
    else
      echo " ... ... ... installing kubectl"
      echo "[kubernetes]" > /etc/yum.repos.d/kubernetes.repo
      echo "name=Kubernetes" >> /etc/yum.repos.d/kubernetes.repo
      echo "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64" >> /etc/yum.repos.d/kubernetes.repo
      echo "enabled=1" >> /etc/yum.repos.d/kubernetes.repo
      echo "gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
      echo "repo_gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
      echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
      yum install -y kubectl >/dev/null 2>&1
    fi
  fi

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
