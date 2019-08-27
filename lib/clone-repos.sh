#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
then
  
  echo " ... ... Cloning openshift/installer in $GOLANGPATH/go/src/github.com/openshift"
  cd $GOLANGPATH/go/src/github.com/openshift
  rm -rf installer
  git clone https://github.com/openshift/installer.git >/dev/null 2>&1
  echo ""
  
  if [ "$INSTALLER_VERSION" == "latest" ]
  then
    echo " ... ... Downloading latest openshift installer"
    cd ~
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/$INSTALLER_TAR
    tar -xzf $INSTALLER_TAR >/dev/null 2>&1
    chmod +x openshift-install
    mkdir -p ~/$CLUSTER_NAME
  elif [ "$INSTALLER_VERSION" == "nightly" ]
    echo " ... ... Downloading latest openshift installer"
    cd ~
    wget https://openshift-release-artifacts.svc.ci.openshift.org/$INSTALLER_VERSION/$INSTALLER_TAR
    tar -xzf $INSTALLER_TAR >/dev/null 2>&1
    chmod +x openshift-install
    mkdir -p ~/$CLUSTER_NAME
  else
    echo " ... ... Downloading version $INSTALLER_VERSION openshift installer"
    cd ~
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$INSTALLER_VERSION/$INSTALLER_TAR
    tar -xzf $INSTALLER_TAR >/dev/null 2>&1
    chmod +x openshift-install
    mkdir -p ~/$CLUSTER_NAME
  fi
fi

if [ "$SKIPSOURCECLONE" == "N" ]
then
  if [ "$APP_TYPE" == "origin" ] || [ "$SETUP_TYPE" == "origin" ] || [ "$CLONEK8S" == "N" ]
  then
    echo " ... ... Skipping Kubernetes Clone"
  else
    if [ "$FAST_CLONE" == "N" ]
    then
      cd $GOLANGPATH/go/src/k8s.io
      rm -rf kubernetes
      echo " ... ... Cloning Kubernetes in $GOLANGPATH"
      git clone https://github.com/kubernetes/kubernetes.git >/dev/null 2>&1
    else
     # TODO: suggestion from Jon to avoid long clone operations
      kubDir="$GOLANGPATH/go/src/k8s.io/kubernetes"
      if [ -d $kubeDir ]
      then
        cd $GOLANGPATH/go/src/k8s.io
        rm -rf kubernetes
      fi
      mkdir -p $kubDir
      curl -sSL https://github.com/kubernetes/kubernetes/archive/master.tar.gz | tar xvz --strip-components 1 -C $kubDir >/dev/null 2>&1
    fi
  fi

  if [ "$APP_TYPE" == "origin" ] || [ "$SETUP_TYPE" == "origin" ]
  then
    if [ "$CLONEOCP" == "N" ]
    then
      echo " ... ... Skipping OpenShift-Origin Clone"
    else
      if [ "$FAST_CLONE" == "N" ]
      then
        echo " ... ... Cloning OpenShift in $GOLANGPATH"
        cd $GOLANGPATH/go/src/github.com/openshift
        rm -rf origin
        git clone https://github.com/openshift/origin.git >/dev/null 2>&1
      else
        oseDir="$GOLANGPATH/go/src/github.com/openshift"
        if [ -d $oseDir ]
        then
          cd $GOLANGPATH/go/src/github.com/openshift
          rm -rf origin
        fi
        mkdir -p $oseDir
        curl -sSL https://github.com/openshift/origin/archive/master.tar.gz | tar xvz --strip-components 1 -C $oseDir >/dev/null 2>&1
      fi
    fi
  fi

  echo " ... ... Cloning support repos in /root"
  cd /root
  rm -rf containerized-data-importer
  git clone https://github.com/kubevirt/containerized-data-importer.git >/dev/null 2>&1

  if [ ! -d "/root/setupvm-dev" ]
  then
    git clone https://github.com/screeley44/setupvm-dev.git >/dev/null 2>&1
  fi

  echo " ... ... Cloning CDI repo in $GOLANGPATH/go/src/github.com/kubevirt"
  cd $GOLANGPATH/go/src/kubevirt.io
  git clone https://github.com/kubevirt/containerized-data-importer.git >/dev/null 2>&1
  cd /root

  echo " ... ... Cloning kubevirt in $GOLANGPATH"
  cd $GOLANGPATH
  git clone https://github.com/kubevirt/kubevirt-ansible.git >/dev/null 2>&1

  echo " ... ... Cloning openshift-ansible in $GOLANGPATH"
  cd $GOLANGPATH
  git clone https://github.com/openshift/openshift-ansible.git >/dev/null 2>&1 

  echo " ... ... Cloing AWS Service Operator in $GOLANGPATH/go/src/github.com/awslabs"
  cd $GOLANGPATH/go/src/github.com/
  mkdir -p awslabs
  cd awslabs
  git clone https://github.com/awslabs/aws-service-operator.git

fi
