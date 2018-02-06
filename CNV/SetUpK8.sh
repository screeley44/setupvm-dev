#! /bin/bash
# Some automation to setting up OSE/K8 VM's


source setupvm.config
SUDO=""


# User and Path analysis
DEFAULT_BLOCK="/dev/vdb"
VG="docker-vg" 
yval1="y"
yval2="Y"

cm1='PS1="[\\u@\\h \\W\$(git branch 2> /dev/null'
cm2=" | sed -n 's/^* \(.*\)/ (\1)/p')]"
cm3='\\\$ "'

cm11=
cm12=
OSEPATH=""
KUBEPATH=""
GOLANGPATH=""


if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-k8-existing" ]
then
  # determine if using defaults or values
  # for paths
  if [ "$USER" == "ec2-user" ]
  then
    SUDO="sudo"
  elif [ "$USER" == "centos" ]
  then
    SUDO="sudo"
  elif [ "$USER" == "root" ]
  then
    SUDO=""
  else
    SUDO="sudo"
  fi

  KUBEDEFAULT=""
  if [[ -z "$KUBEWORKDIR" ]]
  then
    if [ "$USER" == "ec2-user" ]
    then
      KUBEPATH="/home/ec2-user"
    elif [ "$USER" == "root" ]
    then
      KUBEPATH="/root"  
    elif [ "$USER" == "centos" ]
    then
      KUBEPATH="/home/centos"  
    else
      KUBEPATH=~
    fi
    echo "Setting Kube Working Directory to $KUBEPATH"
  else
    KUBEPATH=$KUBEWORKDIR
    echo "Setting Kube Working Directory to $KUBEPATH"
  fi

  GODEFAULT=""
  if [[ -z "$SOURCEDIR" ]]
  then
    if [ "$USER" == "ec2-user" ]
    then
      GOLANGPATH="/home/ec2-user"
    elif [ "$USER" == "root" ]
    then
      GOLANGPATH="/root" 
    elif [ "$USER" == "centos" ]
    then
      GOLANGPATH="/home/centos"   
    else
      GOLANGPATH=~
    fi
    echo "Setting GOLANG Default (GOPATH) Working Directory to $GOLANGPATH/go"
    GODEFAULT="yes"
  else
    GOLANGPATH=$SOURCEDIR
    echo "Setting GOLANG (GOPATH) Working Directory to $GOLANGPATH/go"
  fi
  echo ""


  if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $GOLANGPATH
  else
    $SUDO mkdir -p $GOLANGPATH
    $SUDO chmod -R 777 $GOLANGPATH
  fi


  if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $KUBEPATH
  else
    $SUDO mkdir -p $KUBEPATH
    $SUDO chmod -R 777 $KUBEPATH
  fi

  echo ""
  echo "...Creating Directory Structure for: $USER"
  echo "... ... Creating directory structure and workspace..."
  echo ""
  if [ "$GODEFAULT" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $GOLANGPATH/go/src/k8s.io
  else
    $SUDO mkdir -p $GOLANGPATH/go/src/k8s.io
    $SUDO chmod -R 777 $GOLANGPATH
  fi

  if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $GOLANGPATH/dev-configs
    mkdir -p $GOLANGPATH/dev-configs/aws
    mkdir -p $GOLANGPATH/dev-configs/gce
    mkdir -p $GOLANGPATH/dev-configs/nfs
    mkdir -p $GOLANGPATH/dev-configs/glusterfs
  else
    $SUDO mkdir -p $GOLANGPATH/dev-configs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/aws
    $SUDO mkdir -p $GOLANGPATH/dev-configs/gce
    $SUDO mkdir -p $GOLANGPATH/dev-configs/nfs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/glusterfs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cinder
    $SUDO chmod -R 777 $GOLANGPATH
  fi


  if [ "$KUBEDEFAULT" == "yes" ] || [ "$KUBEPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/root" ] || [ "$KUBEPATH" == "/home/centos" ] || [[ "$KUBEPATH" =~ /home ]] 
  then
    mkdir -p $KUBEPATH/dev-configs
    mkdir -p $KUBEPATH/dev-configs/aws
    mkdir -p $KUBEPATH/dev-configs/gce
    mkdir -p $KUBEPATH/dev-configs/nfs
    mkdir -p $KUBEPATH/dev-configs/glusterfs
    mkdir -p $KUBEPATH/dev-configs/cinder
  else
    $SUDO mkdir -p $KUBEPATH/dev-configs
    $SUDO mkdir -p $KUBEPATH/dev-configs/aws
    $SUDO mkdir -p $KUBEPATH/dev-configs/gce
    $SUDO mkdir -p $KUBEPATH/dev-configs/nfs
    $SUDO mkdir -p $KUBEPATH/dev-configs/glusterfs
    $SUDO mkdir -p $KUBEPATH/dev-configs/cinder
    $SUDO chmod -R 777 $KUBEPATH
  fi
fi

# Install K8 Stuff
# Docker, golang, etc...
echo ""
echo ""
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-k8-existing" ]
then
  echo ""
  echo "Installing Kubernetes Setup..."
  echo "...Installing various software..."
  echo ""
  yum install -y wget gcc python-virtualenv git net-tools unzip bash-completion telnet kexec-tools sos psacct> /dev/null


  # Install Go and do other config
  # 1.6.1, 1.7.3, etc...
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

  # Install etcd
  if rpm -qa | grep etcd >/dev/null 2>&1
  then
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
        echo "installing default etcd per rhel repo configuration..."
        $SUDO yum remove etcd -y> /dev/null
        $SUDO rm -rf /usr/bin/etcd
        $SUDO yum install etcd -y> /dev/null
      else
        echo "installing specific etcd version - etcd-v$ETCD_VER..."
        $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz
        $SUDO rm -rf /usr/bin/etcd
        $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz
        $SUDO cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin
      fi
    fi
  else
    if [ "$ETCD_VER" == "default" ] || [ "$ETCD_VER" == "" ]
    then
      echo "installing default etcd per rhel repo configuration..."
      $SUDO yum remove etcd -y> /dev/null
      $SUDO rm -rf /usr/bin/etcd
      $SUDO yum install etcd -y> /dev/null
    else
      echo "installing specific etcd version - etcd-v$ETCD_VER..."
      $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz
      $SUDO rm -rf /usr/bin/etcd
      $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz
      $SUDO cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin
    fi
  fi

  echo ""
  if [ "$SKIPSOURCECLONE" == "no" ]
  then
    cd $GOLANGPATH/go/src/k8s.io
    rm -rf kubernetes
    echo "...Cloning Kubernetes in $GOLANGPATH"
    echo ""
    git clone https://github.com/kubernetes/kubernetes.git
  fi

  if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
  then 
    # TODO: fix this, just want to run sudo if needed
    # can't get this to work the way I want so doing 2nd approach for now
    # and will come back - for now just removing the function test_docker
    echo "Editing local-up-cluster.sh"
    sed -i '/function test_docker/,+6d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
    sed -i '/test_docker/d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
  
    # making sure we also have --cloud-config working
    sed -i '/^# You may need to run this as root to allow kubelet to open docker/a CLOUD_CONFIG=${CLOUD_CONFIG:-\"\"}' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
    sed -i '/      --cloud-provider=/a\ \ \ \ \ \ --cloud-config=\"${CLOUD_CONFIG}\" \\' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
  fi


  # Installing Docker
  echo ""
  echo "Installing Docker ..."
  echo ""
  $SUDO yum check-update
  $SUDO curl -fsSL https://get.docker.com/ | sh

  # Restart Docker
  echo "...Restarting Docker"
  $SUDO groupadd docker
  $SUDO gpasswd -a ${USER} docker
  $SUDO systemctl stop docker
  $SUDO rm -rf /var/lib/docker/*
  $SUDO systemctl restart docker
  $SUDO systemctl enable docker

  
  # Creating and Updating Profiles
  echo ""
  echo "Creating Profiles and Exports..."
  echo ""
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
  echo "# Source global definitions" >> newbashrc
  echo "if [ -f /etc/bashrc ]; then" >> newbashrc
  echo "        . /etc/bashrc" >> newbashrc
  echo "fi" >> newbashrc


  # Export file
  echo "# Some K8 exports" >> newbashrc 
  #echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> newbashrc
  #echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> newbashrc
  echo "export ALLOW_SECURITY_CONTEXT=true" >> newbashrc
  echo "export ALLOW_PRIVILEGED=true" >> newbashrc
  echo "export LOG_LEVEL=5" >> newbashrc
  echo "export KUBE_DEFAULT_STORAGE_CLASS=false" >> newbashrc
  echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
  echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
  echo "export ZONE=$ZONE" >> newbashrc

  echo "# Some K8 exports" >> .bash_profile 
  #echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> .bash_profile
  #echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> .bash_profile
  echo "export ALLOW_SECURITY_CONTEXT=true" >> .bash_profile
  echo "export ALLOW_PRIVILEGED=true" >> .bash_profile
  echo "export LOG_LEVEL=5" >> .bash_profile
  echo "export KUBE_DEFAULT_STORAGE_CLASS=false" >> .bash_profile
  echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> .bash_profile
  echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> .bash_profile
  echo "export ZONE=$ZONE" >> .bash_profile

  if [ "$FEATURE_GATES" == "" ]
  then
    echo "No Alpha Features Enabled..."
  else
    echo ""
    echo "Enabled Alpha Feature Gates $FEATURE_GATES"
    echo "export FEATURE_GATES=$FEATURE_GATES" >> newbashrc
    echo "Enabled Alpha Feature Gates $FEATURE_GATES"
    echo "export FEATURE_GATES=$FEATURE_GATES" >> .bash_profile
    echo ""  
  fi

  echo "" >> newbashrc
  echo ""
  echo "#go environment" >> newbashrc
  echo "export GOPATH=$GOLANGPATH/go" >> newbashrc
  echo "GOPATH1=/usr/local/go" >> newbashrc
  echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
  echo "" >> newbashrc
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH

  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:/usr/local/sbin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> newbashrc
  echo "" >> newbashrc
  echo "export PATH" >> newbashrc

  echo "" >> .bash_profile
  echo ""
  echo "#go environment" >> .bash_profile
  echo "export GOPATH=$GOLANGPATH/go" >> .bash_profile
  echo "GOPATH1=/usr/local/go" >> .bash_profile
  echo "GO_BIN_PATH=/usr/local/go/bin" >> .bash_profile
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH
  echo "" >> .bash_profile
  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:/usr/local/sbin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> .bash_profile
  echo "" >> .bash_profile
  echo "export PATH" >> .bash_profile

  $SUDO cp .bash_profile /root
  $SUDO cp newbashrc /root/.bashrc



  echo ""
  echo " *********************************************** "
  echo "" 
  echo "     Kubernetes Setup Completed!"
  echo ""
  echo " *********************************************** "


fi

