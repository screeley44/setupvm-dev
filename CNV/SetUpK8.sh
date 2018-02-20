#! /bin/bash
# Some automation to setting up OSE/K8 VM's

K8_SCRIPT_HOME="$(realpath $(dirname $0))"
CONFIG_HOME=""

if [ -f "$SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$SCRIPT_HOME
elif [ -f "$K8_SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$K8_SCRIPT_HOME
else
  CONFIG_HOME="/root/setupvm-dev/CNV"
fi

source $CONFIG_HOME/setupvm.config
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


if [ "$SETUP_TYPE" == "k8-dev" ] || [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-ceph-k8" ] || [ "$SETUP_TYPE" == "cnv-k8-existing" ]
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
    $SUDO mkdir -p $GOLANGPATH/dev-configs/data-importer
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
    $SUDO mkdir -p $KUBEPATH/dev-configs/data-importer
    $SUDO chmod -R 777 $KUBEPATH
  fi
fi

# Install K8 Stuff
# Docker, golang, etc...
echo ""
echo ""
if [ "$SETUP_TYPE" == "k8-dev" ] || [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-k8" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ] || [ "$SETUP_TYPE" == "cnv-ceph-k8" ] || [ "$SETUP_TYPE" == "cnv-k8-existing" ]
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
    # TODO: suggestion from Jon to avoid long clone operations
    # kubDir="$GOLANGPATH/go/src/k8s.io/kubernetes"
    # mkdir -p $kubDir
    # curl -sSL https://github.com/kubernetes/kubernetes/archive/master.tar.gz | tar xvz --strip-components 1 -C $kubDir

    echo "...Cloning support repos in /root"
    cd /root
    rm -rf containerized-data-importer
    git clone https://github.com/kubevirt/containerized-data-importer.git

    if [ ! -d "/root/setupvm-dev" ]
    then
      git clone https://github.com/screeley44/setupvm-dev.git
    fi

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
  if [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "" ]
  then
    echo " ... installing default docker from enabled repos..."
    $SUDO yum install docker -y
  elif [ "$DOCKERVER" == "ce" ] 
  then
    echo " ... installing latest docker ce release"
    $SUDO yum check-update
    $SUDO curl -fsSL https://get.docker.com/ | sh    
  else
    echo " ... installing Docker version $DOCKERVER"
    $SUDO yum install docker-$DOCKERVER -y
  fi

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
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
  fi
  if [ "$ISCLOUD" == "gce" ]
  then
    echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
  fi
  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> newbashrc
  echo "export ALLOW_SECURITY_CONTEXT=true" >> newbashrc
  echo "export ALLOW_PRIVILEGED=true" >> newbashrc
  echo "export LOG_LEVEL=5" >> newbashrc
  echo "export KUBE_ENABLE_CLUSTER_DNS=$KUBE_ENABLE_CLUSTER_DNS" >> newbashrc
  echo "export KUBE_DEFAULT_STORAGE_CLASS=false" >> newbashrc
  echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
  echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
  echo "export ZONE=$ZONE" >> newbashrc

  echo "# Some K8 exports" >> .bash_profile 
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
  fi
  if [ "$ISCLOUD" == "gce" ]
  then
    echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
  fi
  echo "export HOSTNAME_OVERRIDE=$HOSTNAME" >> .bash_profile
  echo "export ALLOW_SECURITY_CONTEXT=true" >> .bash_profile
  echo "export ALLOW_PRIVILEGED=true" >> .bash_profile
  echo "export LOG_LEVEL=5" >> .bash_profile
  echo "export KUBE_ENABLE_CLUSTER_DNS=$KUBE_ENABLE_CLUSTER_DNS" >> newbashrc
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

  $SUDO cp newbashrc /root/.bashrc

  # source testfiles.sh
  $SUDO cp /root/setupvm-dev/CNV/yaml/* $KUBEPATH/dev-configs/cinder
  $SUDO cp /root/setupvm-dev/yaml/aws/* $KUBEPATH/dev-configs/aws
  $SUDO cp /root/setupvm-dev/yaml/gce/* $KUBEPATH/dev-configs/gce

  $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/data-importer
  
  if [ "$ISCLOUD" == "aws" ]
  then

    echo "Install ec2 api tools (aws cli)..."
    cd $GOLANGPATH
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    $SUDO ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    echo "...configuring aws"

    cd $GOLANGPATH
    echo "...creating aws cli input"
    echo "$AWSKEY" > myconf.txt
    echo "$AWSSECRET" >> myconf.txt
    echo "$ZONE" >> myconf.txt
    echo "json" >> myconf.txt
    echo ""
    aws configure < myconf.txt

    echo "...creating aws.conf file"  
    cd /etc
    $SUDO mkdir aws
    $SUDO chmod -R 777 /etc/aws  
    cd /etc/aws
    echo "[Global]" > aws.conf
    echo "Zone = $ZONE" >> aws.conf
    $SUDO mkdir -p /etc/kubernetes/cloud-config
    cp aws.conf /etc/kubernetes/cloud-config
  fi

  if [ "$ISCLOUD" == "gce" ]
  then
    cd /etc
    $SUDO mkdir -p gce
    $SUDO chmod -R 777 /etc/gce  
    cd /etc/gce
    echo "[Global]" > gce.conf
    echo "Zone = $ZONE" >> gce.conf
    cd $GOLANGPATH
    echo ""
  fi

  echo ""
  echo " *********************************************** "
  echo "" 
  echo "     Kubernetes Setup Completed on host $HOSTNAME!"
  echo ""
  echo " *********************************************** "


fi

