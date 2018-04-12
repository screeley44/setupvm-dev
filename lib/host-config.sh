#! /bin/bash
# Some automation to setting up OSE/K8 VM's


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

  OSEDEFAULT=""
  if [[ -z "$ORIGINWORKDIR" ]]
  then
    echo " ... ... No ORIGINWORKDIR present...setting default"
    OSEPATH="/etc/openshift-dev"
  else
    OSEPATH=$ORIGINWORKDIR
    echo " ... ... Setting Origin Working Directory to $OSEPATH"
  fi

  KUBEDEFAULT=""
  if [[ -z "$KUBEWORKDIR" ]]
  then
    echo " ... ... No KUBEWORKDIR present...setting default"
    KUBEPATH="/etc/kubernetes-dev"
  else
    KUBEPATH=$KUBEWORKDIR
    echo " ... ... Setting Kube Working Directory to $KUBEPATH"
  fi

  KUBEDEFAULT=""
  if [[ -z "$WORKDIR" ]]
  then
    echo " ... ... No WORKDIR present...skipping"
  else
    if [ "$APP_TYPE" == "kube" ]
    then
      KUBEPATH=$WORKDIR
      echo " ... ... Setting Kube Working Directory to $KUBEPATH"
    elif [ "$APP_TYPE" == "origin" ]
    then
      OSEPATH=$WORKDIR
      echo " ... ... Setting Origin Working Directory to $OSEPATH"
    elif [ "$APP_TYPE" == "dev" ]
    then
      OSEPATH=$WORKDIR/openshift-dev
      KUBEPATH=$WORKDIR/kubernetes-dev
      echo " ... ... Setting Origin Working Directory to $OSEPATH"
      echo " ... ... Setting Kubernetes Working Directory to $KUBEPATH"
    else
      echo " !!!! INVALID APP TYPE MAYBE?? !!!!!"
      exit 1
    fi    
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
    echo " ... ... Setting GOLANG Default (GOPATH) Working Directory to $GOLANGPATH/go"
    GODEFAULT="yes"
  else
    GOLANGPATH=$SOURCEDIR
    echo " ... ... Setting GOLANG (GOPATH) Working Directory to $GOLANGPATH/go"
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
    if [ "$KUBEPATH" == "" ]
    then
      echo " ... ... skipping chmod for KUBEPATH"
    else
      $SUDO mkdir -p $KUBEPATH
      $SUDO chmod -R 777 $KUBEPATH
    fi
  fi

  if [ "$OSEDEFAULt" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [[ "$OSEPATH" =~ /home ]] 
  then
    mkdir -p $OSEPATH
  else
    if [ "$OSEPATH" == "" ]
    then
      echo " ... ... skipping chmod for OSEPATH"
    else
      $SUDO mkdir -p $OSEPATH
      $SUDO chmod -R 777 $OSEPATH
    fi
  fi

  echo ""
  echo " ... ... Creating Directory Structure for: $USER"
  echo ""
  if [ "$GODEFAULT" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $GOLANGPATH/go/src/k8s.io
    mkdir -p $GOLANGPATH/go/src/github.com/kubevirt
    mkdir -p $GOLANGPATH/go/src/github.com/openshift
  else
    $SUDO mkdir -p $GOLANGPATH/go/src/k8s.io
    $SUDO mkdir -p $GOLANGPATH/go/src/github.com/kubevirt
    $SUDO mkdir -p $GOLANGPATH/go/src/github.com/openshift
    $SUDO chmod -R 777 $GOLANGPATH
  fi

  if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/home/centos" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
  then
    mkdir -p $GOLANGPATH/dev-configs
    mkdir -p $GOLANGPATH/dev-configs/aws
    mkdir -p $GOLANGPATH/dev-configs/gce
    mkdir -p $GOLANGPATH/dev-configs/hostpath
    mkdir -p $GOLANGPATH/dev-configs/nfs
    mkdir -p $GOLANGPATH/dev-configs/glusterfs
    mkdir -p $GOLANGPATH/dev-configs/cinder
    mkdir -p $GOLANGPATH/dev-configs/cnv/aws
    mkdir -p $GOLANGPATH/dev-configs/cnv/gce
    mkdir -p $GOLANGPATH/dev-configs/cnv/local
    mkdir -p $GOLANGPATH/dev-configs/cnv/data-importer
  else
    $SUDO mkdir -p $GOLANGPATH/dev-configs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/aws
    $SUDO mkdir -p $GOLANGPATH/dev-configs/gce
    $SUDO mkdir -p $GOLANGPATH/dev-configs/hostpath
    $SUDO mkdir -p $GOLANGPATH/dev-configs/nfs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/glusterfs
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cinder
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cnv/aws
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cnv/gce
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cnv/local
    $SUDO mkdir -p $GOLANGPATH/dev-configs/cnv/data-importer
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
    mkdir -p $KUBEPATH/dev-configs/hostpath
    mkdir -p $KUBEPATH/dev-configs/cnv/aws
    mkdir -p $KUBEPATH/dev-configs/cnv/gce
    mkdir -p $KUBEPATH/dev-configs/cnv/local
    mkdir -p $KUBEPATH/dev-configs/cnv/data-importer
  else
    $SUDO mkdir -p $KUBEPATH/dev-configs
    $SUDO mkdir -p $KUBEPATH/dev-configs/aws
    $SUDO mkdir -p $KUBEPATH/dev-configs/gce
    $SUDO mkdir -p $KUBEPATH/dev-configs/nfs
    $SUDO mkdir -p $KUBEPATH/dev-configs/glusterfs
    $SUDO mkdir -p $KUBEPATH/dev-configs/hostpath
    $SUDO mkdir -p $KUBEPATH/dev-configs/cinder
    $SUDO mkdir -p $KUBEPATH/dev-configs/cnv/aws
    $SUDO mkdir -p $KUBEPATH/dev-configs/cnv/gce
    $SUDO mkdir -p $KUBEPATH/dev-configs/cnv/local
    $SUDO mkdir -p $KUBEPATH/dev-configs/cnv/data-importer
    $SUDO chmod -R 777 $KUBEPATH
  fi

  if [ "$OSEDEFAULT" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [ "$OSEPATH" == "/home/centos" ] || [[ "$OSEPATH" =~ /home ]] 
  then
    mkdir -p $OSEPATH/dev-configs
    mkdir -p $OSEPATH/dev-configs/aws
    mkdir -p $OSEPATH/dev-configs/gce
    mkdir -p $OSEPATH/dev-configs/nfs
    mkdir -p $OSEPATH/dev-configs/glusterfs
    mkdir -p $OSEPATH/dev-configs/cinder
    mkdir -p $OSEPATH/dev-configs/hostpath
    mkdir -p $OSEPATH/dev-configs/cnv/aws
    mkdir -p $OSEPATH/dev-configs/cnv/gce
    mkdir -p $OSEPATH/dev-configs/cnv/local
    mkdir -p $OSEPATH/dev-configs/cnv/data-importer
  else
    if [ "$OSEPATH" == "" ]
    then
      echo "...skipping"
    else
    $SUDO mkdir -p $OSEPATH/dev-configs
    $SUDO mkdir -p $OSEPATH/dev-configs/aws
    $SUDO mkdir -p $OSEPATH/dev-configs/gce
    $SUDO mkdir -p $OSEPATH/dev-configs/nfs
    $SUDO mkdir -p $OSEPATH/dev-configs/glusterfs
    $SUDO mkdir -p $OSEPATH/dev-configs/hostpath
    $SUDO mkdir -p $OSEPATH/dev-configs/cinder
    $SUDO mkdir -p $OSEPATH/dev-configs/cnv/aws
    $SUDO mkdir -p $OSEPATH/dev-configs/cnv/gce
    $SUDO mkdir -p $OSEPATH/dev-configs/cnv/local
    $SUDO mkdir -p $OSEPATH/dev-configs/cnv/data-importer
    $SUDO chmod -R 777 $OSEPATH
    fi
  fi

  if [ ! -d "/var/run/libvirt" ]
  then
    mkdir -p /var/run/libvirt
  fi
  if [ ! -d "/var/run/kubevirt" ]
  then
    mkdir -p /var/run/kubevirt
  fi
  if [ ! -d "/var/run/kubevirt-private" ]
  then
    mkdir -p /var/run/kubevirt-private
  fi

  echo "" 
  echo " ... ... ...Configuration and Directory Setup Completed on host $HOSTNAME!"
  echo ""


