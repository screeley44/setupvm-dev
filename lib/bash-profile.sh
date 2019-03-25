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


  # Export file
  echo "# Some K8 exports" >> newbashrc 
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
  fi
  if [ "$ISCLOUD" == "gce" ]
  then
    echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export NUM_NODES=$KUBEUP_NUM_NODES" >> newbashrc
    echo "export KUBE_GCE_INSTANCE_PREFIX=$KUBEUP_NODES_PREFIX" >> newbashrc
    echo "export KUBE_GCE_ZONE=$ZONE" >> newbashrc
    echo "export NODE_INSTANCE_PREFIX=$KUBEUP_NODES_PREFIX" >> newbashrc
  fi
  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> newbashrc
  echo "export ALLOW_SECURITY_CONTEXT=true" >> newbashrc
  echo "export ALLOW_PRIVILEGED=true" >> newbashrc
  echo "export LOG_LEVEL=5" >> newbashrc
  echo "export KUBE_ENABLE_CLUSTER_DNS=$KUBE_ENABLE_CLUSTER_DNS" >> newbashrc
  echo "export KUBE_DEFAULT_STORAGE_CLASS=$DEFAULT_STORAGECLASS" >> newbashrc
  echo "export ENABLE_DEFAULT_STORAGE_CLASS=$DEFAULT_STORAGECLASS" >> newbashrc
  echo "export ENABLE_HOSTPATH_PROVISIONER=$ENABLE_HOSTPATH" >> newbashrc
  echo "export ZONE=$ZONE" >> newbashrc
  echo "" >> newbashrc
  echo "# Cinder Env Vars" >> newbashrc
  echo "export OS_AUTH_TYPE=$COS_AUTH_TYPE" >> newbashrc
  echo "export CINDERCLIENT_BYPASS_URL=$CCINDERCLIENT_BYPASS_URL" >> newbashrc
  echo "export OS_PROJECT_ID=$COS_PROJECT_ID" >> newbashrc
  echo "export OS_VOLUME_API_VERSION=$COS_VOLUME_API_VERSION" >> newbashrc
  echo "export KOPS_CLUSTER_NAME=$KOPS_CLUSTERNAME.$HOSTED_ZONE" >> newbashrc
  echo "export KOPS_STATE_STORE=$S3_KOPS$BUCKET_NAME" >> newbashrc

  echo "# Some K8 exports" >> .bash_profile 
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> .bash_profile
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> .bash_profile
  fi
  if [ "$ISCLOUD" == "gce" ]
  then
    echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export NUM_NODES=$KUBEUP_NUM_NODES" >> .bash_profile
    echo "export KUBE_GCE_INSTANCE_PREFIX=$KUBEUP_NODES_PREFIX" >> .bash_profile
    echo "export KUBE_GCE_ZONE=$ZONE" >> .bash_profile
    echo "export NODE_INSTANCE_PREFIX=$KUBEUP_NODES_PREFIX" >> .bash_profile
  fi

  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> .bash_profile
  echo "export ALLOW_SECURITY_CONTEXT=true" >> .bash_profile
  echo "export ALLOW_PRIVILEGED=true" >> .bash_profile
  echo "export LOG_LEVEL=5" >> .bash_profile
  echo "export KUBE_ENABLE_CLUSTER_DNS=$KUBE_ENABLE_CLUSTER_DNS" >> .bash_profile
  echo "export KUBE_DEFAULT_STORAGE_CLASS=$DEFAULT_STORAGECLASS" >> .bash_profile
  echo "export ENABLE_DEFAULT_STORAGE_CLASS=$DEFAULT_STORAGECLASS" >> .bash_profile
  echo "export ENABLE_HOSTPATH_PROVISIONER=$ENABLE_HOSTPATH" >> .bash_profile
  echo "export ZONE=$ZONE" >> .bash_profile
  echo "" >> .bash_profile
  echo "# Cinder Env Vars" >> .bash_profile
  echo "export OS_AUTH_TYPE=$COS_AUTH_TYPE" >> .bash_profile
  echo "export CINDERCLIENT_BYPASS_URL=$CCINDERCLIENT_BYPASS_URL" >> .bash_profile
  echo "export OS_PROJECT_ID=$COS_PROJECT_ID" >> .bash_profile
  echo "export OS_VOLUME_API_VERSION=$COS_VOLUME_API_VERSION" >> .bash_profile
  echo "export KOPS_CLUSTER_NAME=$KOPS_CLUSTERNAME.$HOST_ZONE" >> .bash_profile
  echo "export KOPS_STATE_STORE=$S3_KOPS$BUCKET_NAME" >> .bash_profile

  if [ "$FEATURE_GATES" == "" ]
  then
    echo " ... ... No Alpha Features Enabled"
  else
    echo " ... ... Enabled Alpha Feature Gates $FEATURE_GATES"
    echo "export FEATURE_GATES=$FEATURE_GATES" >> newbashrc
    echo "export FEATURE_GATES=$FEATURE_GATES" >> .bash_profile
    echo "export KUBE_FEATURE_GATES=$FEATURE_GATES" >> newbashrc
    echo "export KUBE_FEATURE_GATES=$FEATURE_GATES" >> .bash_profile
  fi

#  if [ "$SETUP_TYPE" == "installer" ]
#  then
#    echo "export OPENSHIFT_INSTALL_BASE_DOMAIN=$DOMAIN" >> newbashrc
#    echo "export OPENSHIFT_INSTALL_BASE_DOMAIN=$DOMAIN" >> bash_profile


#OPENSHIFT_INSTALL_CLUSTER_NAME=screeley-test
#OPENSHIFT_INSTALL_PLATFORM=aws

  echo "" >> newbashrc
  echo "#go environment" >> newbashrc
  echo "export GOPATH=$GOLANGPATH/go" >> newbashrc
  echo "GOPATH1=/usr/local/go" >> newbashrc
  echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
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
