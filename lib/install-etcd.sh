#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # Install etcd
  if rpm -qa | grep etcd >/dev/null 2>&1
  then
    echo ""
    echo ""
    echo " --- etcd version info ---"
    etcd --version
    echo " -------------------------"
    echo ""
    echo "etcd is already installed...do you want to fresh install anyway with your specified version from setupvm.config? (y/n)"
    read isaccepted3
    if [ "$isaccepted3" == "$yval1" ] || [ "$isaccepted3" == "$yval2" ]
    then
      if [ "$ETCD_VER" == "default" ] || [ "$ETCD_VER" == "" ]
      then
        $SUDO yum remove etcd -y> /dev/null
        $SUDO rm -rf /usr/bin/etcd
        $SUDO yum install etcd -y> /dev/null
      else
        $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null
        $SUDO rm -rf /usr/bin/etcd
        $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null
        $SUDO cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin
      fi
    fi
  else
    if [ "$ETCD_VER" == "default" ] || [ "$ETCD_VER" == "" ]
    then
      $SUDO yum remove etcd -y> /dev/null
      $SUDO rm -rf /usr/bin/etcd
      $SUDO yum install etcd -y> /dev/null
    else
      $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null
      $SUDO rm -rf /usr/bin/etcd
      $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null
      $SUDO cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin
    fi
  fi
