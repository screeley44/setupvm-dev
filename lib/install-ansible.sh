#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # Ansible
  if [ "$INSTALL_ANSIBLE" == "yes" ]
  then
    if [ "$HOSTENV" == "fedora" ]
    then
      echo "Installing latest ansible..."
      if [ -d "/usr/share/ansible" ]; then $SUDO rm -rf /usr/share/ansible; fi
      if [ -d "/usr/share/ansible_plugins" ]; then $SUDO rm -rf /usr/share/ansible_plugins; fi
      echo ""
      $SUDO rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
      $SUDO yum install ansible -y> /dev/null
    fi

    if [ "$HOSTENV" == "centos" ]
    then
      echo "Installing latest ansible..."
      yum install epel-release -y> /dev/null
      yum --enablerepo=epel-testing install ansible -y
    fi
  fi 

