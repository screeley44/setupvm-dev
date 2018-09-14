#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # source testfiles.sh
  BASESRC=$BASH_SOURCE
  BASEDIR=`dirname $BASH_SOURCE`
  cd "$(git rev-parse --show-cdup)"
  echo " ... ... Copying Dev Configs to Working Dir"
  echo " ... ... ... Base Dir is $BASEDIR"
  $SUDO cp CNV/Origin/config-ocp.sh $KUBEPATH
  $SUDO cp CNV/Origin/aws-hosts /root
  $SUDO cp CNV/yaml/* $KUBEPATH/dev-configs/cinder
  $SUDO cp yaml/aws/* $KUBEPATH/dev-configs/aws
  $SUDO cp yaml/gce/* $KUBEPATH/dev-configs/gce
  $SUDO cp yaml/hostpath/* $KUBEPATH/dev-configs/hostpath
  $SUDO cp yaml/nfs/* $KUBEPATH/dev-configs/nfs
  $SUDO cp -R CNV/AWS/yaml/* $KUBEPATH/dev-configs/cnv/aws
  $SUDO cp -R CNV/LocalVM/yaml/* $KUBEPATH/dev-configs/cnv/local
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/data-importer
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/generated/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $KUBEPATH/dev-configs/cdi
  $SUDO cp yaml/cdi/* $KUBEPATH/dev-configs/cdi
  
  $SUDO cp CNV/Origin/config-ocp.sh $OSEPATH
  $SUDO cp CNV/Origin/aws-hosts /root
  $SUDO cp yaml/* $OSEPATH/dev-configs/cinder
  $SUDO cp yaml/aws/* $OSEPATH/dev-configs/aws
  $SUDO cp yaml/gce/* $OSEPATH/dev-configs/gce
  $SUDO cp yaml/hostpath/* $OSEPATH/dev-configs/hostpath
  $SUDO cp yaml/nfs/* $OSEPATH/dev-configs/nfs
  $SUDO cp -R CNV/AWS/yaml/* $OSEPATH/dev-configs/cnv/aws
  $SUDO cp -R CNV/LocalVM/yaml/* $OSEPATH/dev-configs/cnv/local
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/data-importer
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/generated/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $OSEPATH/dev-configs/cdi
  $SUDO cp yaml/cdi/* $OSEPATH/dev-configs/cdi

  $SUDO cp host-files/* /root

  # security stuff
  if [ "$HOSTENV" == "centos" ]
  then
    echo " ... ... Disable security features"
    $SUDO systemctl disable firewalld >/dev/null 2>&1
    $SUDO systemctl stop firewalld >/dev/null 2>&1
    $SUDO iptables -F
    $SUDO setenforce 0
  else
    $SUDO setenforce 0
    $SUDO iptables -F
  fi

  # restart docker
  echo " ... ... Restarting Docker"
  systemctl restart docker >/dev/null 2>&1
