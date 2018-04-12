#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # Ansible
  if [ "$INSTALL_ANSIBLE" == "Y" ]
  then
    if [ "$HOSTENV" == "fedora" ]
    then
      if [ -d "/usr/share/ansible" ]; then $SUDO rm -rf /usr/share/ansible; fi
      if [ -d "/usr/share/ansible_plugins" ]; then $SUDO rm -rf /usr/share/ansible_plugins; fi
      echo ""
      $SUDO rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >/dev/null 2>&1
      $SUDO yum install ansible -y >/dev/null 2>&1
    fi

    if [ "$HOSTENV" == "centos" ]
    then
      yum install epel-release -y >/dev/null 2>&1
      yum --enablerepo=epel-testing install ansible -y >/dev/null 2>&1
    fi
  fi 

