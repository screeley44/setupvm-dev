#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # Install Go and do other config
  # 1.6.1, 1.7.3, etc...
  yum install wget -y> /dev/null
  if [ "$GOVERSION" == "yum" ] || [ "$GOVERSION" == "" ]
  then
    echo "Installing go1.X whatever version yum installs..."
    $SUDO yum install go -y> /dev/null
  else
    echo "Installing go$GOVERSION ..."
    cd ~
    $SUDO wget https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz
    $SUDO rm -rf /usr/local/go
    $SUDO rm -rf /bin/go		
    $SUDO tar -C /usr/local -xzf go$GOVERSION.linux-amd64.tar.gz
  fi

