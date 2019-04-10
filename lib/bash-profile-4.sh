#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # Creating and Updating Profiles
  if [ "$SUDO" == "sudo" ] 
  then  
    cd /home/$USER
  else
    cd ~
  fi
  mv .bash_profile .bash_profile_bck

  echo "# .bash_profile" > .bash_profile
  echo "" >> .bash_profile
  echo "# Get the aliases and functions" >> .bash_profile
  echo "if [ -f ~/.bashrc ]; then" >> .bash_profile
  echo "      . ~/.bashrc" >> .bash_profile
  echo "fi" >> .bash_profile
  echo "" >> .bash_profile
  echo "# User specific environment and startup programs" >> .bash_profile
  echo "" >> .bash_profile
  echo "#git stuff" >> .bash_profile
  echo "export $cm1$cm2$cm3" >> .bash_profile
  echo "" >> .bash_profile

  echo "# .bashrc" > newbashrc
  echo "# User specific aliases and functions" >> newbashrc
  echo "alias rm='rm -i'" >> newbashrc
  echo "alias cp='cp -i'" >> newbashrc
  echo "alias mv='mv -i'" >> newbashrc
  echo "" >> newbashrc
  echo "#git stuff" >> .newbashrc
  echo "export $cm1$cm2$cm3" >> newbashrc
  echo "" >> newbashrc
  echo "# Source global definitions" >> newbashrc
  echo "if [ -f /etc/bashrc ]; then" >> newbashrc
  echo "        . /etc/bashrc" >> newbashrc
  echo "fi" >> newbashrc

  echo "export OPENSHIFT_INSTALL_BASE_DOMAIN=$HOSTED_ZONE" >> newbashrc
  echo "export OPENSHIFT_INSTALL_BASE_DOMAIN=$HOSTED_ZONE" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_CLUSTER_NAME=$CLUSTER_NAME" >> newbashrc
  echo "export OPENSHIFT_INSTALL_CLUSTER_NAME=$CLUSTER_NAME" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_PLATFORM=$ISCLOUD" >> newbashrc
  echo "export OPENSHIFT_INSTALL_PLATFORM=$ISCLOUD" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_EMAIL_ADDRESS=$EMAIL" >> newbashrc
  echo "export OPENSHIFT_INSTALL_EMAIL_ADDRESS=$EMAIL" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_PASSWORD=$INSTALL_PASSWORD" >> newbashrc
  echo "export OPENSHIFT_INSTALL_PASSWORD=$INSTALL_PASSWORD" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_AWS_REGION=$ZONE" >> newbashrc
  echo "export OPENSHIFT_INSTALL_AWS_REGION=$ZONE" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH=$SSHPATH" >> newbashrc
  echo "export OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH=$SSHPATH" >> .bash_profile
  echo "export OPENSHIFT_INSTALL_PULL_SECRET=$SSHPATH" >> newbashrc
  echo "export OPENSHIFT_INSTALL_PULL_SECRET=$SSHPATH" >> .bash_profile
  #echo "export AWS_PROFILE=$INSTALL_PASSWORD" >> newbashrc
  #echo "export AWS_PROFILE=$INSTALL_PASSWORD" >> .bash_profile


  echo "" >> newbashrc
  echo "#go environment" >> newbashrc
  echo "export GOPATH=$GOLANGPATH/go" >> newbashrc
  echo "GOPATH1=/usr/local/go" >> newbashrc
  echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
  #echo "export KUBECONFIG=/root/$CLUSTER_NAME/auth/kubeconfig" >> newbashrc
  echo "" >> newbashrc
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH

  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/sbin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> newbashrc
  echo "" >> newbashrc
  echo "export PATH" >> newbashrc

  echo "" >> .bash_profile
  echo "#go environment" >> .bash_profile
  echo "export GOPATH=$GOLANGPATH/go" >> .bash_profile
  echo "GOPATH1=/usr/local/go" >> .bash_profile
  echo "GO_BIN_PATH=/usr/local/go/bin" >> .bash_profile
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH
  echo "" >> .bash_profile
  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/sbin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> .bash_profile
  echo "" >> .bash_profile
  echo "export PATH" >> .bash_profile

  $SUDO cp newbashrc /root/.bashrc

  # Create 4.0 config
  cd ~
  echo "export OPENSHIFT_INSTALL_BASE_DOMAIN=$HOSTED_ZONE" > mycluster.cfg
  echo "export OPENSHIFT_INSTALL_CLUSTER_NAME=$CLUSTER_NAME" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_PLATFORM=$ISCLOUD" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_EMAIL_ADDRESS=$EMAIL" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_PASSWORD=$INSTALL_PASSWORD" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_AWS_REGION=$ZONE" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH=$SSHPATH" >> mycluster.cfg
  echo "export OPENSHIFT_INSTALL_PULL_SECRET=$PULLSECRET" >> mycluster.cfg
