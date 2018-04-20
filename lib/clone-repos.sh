#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$SKIPSOURCECLONE" == "N" ]
then
  if [ "$APP_TYPE" == "origin" ] || [ "$SETUP_TYPE" == "origin" ]
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

  echo " ... ... Cloning support repos in /root"
  cd /root
  rm -rf containerized-data-importer
  git clone https://github.com/kubevirt/containerized-data-importer.git >/dev/null 2>&1

  if [ ! -d "/root/setupvm-dev" ]
  then
    git clone https://github.com/screeley44/setupvm-dev.git >/dev/null 2>&1
  fi

  echo " ... ... Cloning CDI repo in $GOLANGPATH/go/src/github.com/kubevirt"
  cd $GOLANGPATH/go/src/github.com/kubevirt
  git clone https://github.com/kubevirt/containerized-data-importer.git >/dev/null 2>&1
  cd /root

  echo " ... ... Cloning kubevirt in $GOLANGPATH"
  cd $GOLANGPATH
  git clone https://github.com/kubevirt/kubevirt-ansible.git >/dev/null 2>&1

  echo " ... ... Cloning openshift-ansible in $GOLANGPATH"
  cd $GOLANGPATH
  git clone https://github.com/openshift/openshift-ansible.git >/dev/null 2>&1 
fi
