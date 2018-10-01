#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HOSTENV" == "rhel" ]
then  
  echo " ... ... Installing wget, git, net-tools, bind-utils, iptables-services, rpcbind, nfs-utils, glusterfs-client bridge-utils, gcc, python-virtualenv, bash-completion telnet unzip kexec-tools sos psacct krb5-devel rpm-build createrepo bc rsync file jq tito gpgme gpgme-devel libassuan libassuan-devel ... this will take several minutes"
  until $SUDO yum install wget git net-tools bind-utils iptables-services rpcbind nfs-utils glusterfs-client bridge-utils gcc python-virtualenv bash-completion telnet unzip kexec-tools sos psacct mercurial krb5-devel rpm-build createrepo bc rsync file bsdtar jq tito gpgme gpgme-devel libassuan libassuan-devel -y> /dev/null; do echo "Failure installing utils Repos, retrying..."; sleep 8; done

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

  echo " ... ... performing yum update"
  $SUDO yum update -y> /dev/null

  if [ "$HOSTENV" == "rhel" ] && [ "$APP_TYPE" == "origin" ]
  then
      if [ "$CUSTOM_OCP_REPO" == "Y" ]
      then
        echo " ... ... Installing ansible..."
        $SUDO yum install ansible -y> /dev/null
      else
        echo " ... ... Installing openshift utils for DEV setup type..."
        #$SUDO yum install atomic-openshift-utils -y> /dev/null
        $SUDO yum install openshift-ansible -y> /dev/null
      fi
  fi
  echo ""
  echo "  ************************************"
  echo "  *  YUM SOFTWARE INSTALLED FOR RHEL *"
  echo "  ************************************"
fi
