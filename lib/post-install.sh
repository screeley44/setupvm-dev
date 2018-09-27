#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # source testfiles.sh
  BASESRC=$BASH_SOURCE
  BASEDIR=`dirname $BASH_SOURCE`
  echo " ... ... Copying Dev Configs to Working Dir"
  echo " ... ... ... Base Dir is $BASEDIR"
  $SUDO cp $BASEDIR/../CNV/Origin/config-ocp.sh $KUBEPATH
  #$SUDO cp $BASEDIR/../CNV/Origin/aws-hosts /root
  $SUDO cp $BASEDIR/../CNV/yaml/* $KUBEPATH/dev-configs/cinder
  $SUDO cp $BASEDIR/../yaml/aws/* $KUBEPATH/dev-configs/aws
  $SUDO cp $BASEDIR/../yaml/gce/* $KUBEPATH/dev-configs/gce
  $SUDO cp $BASEDIR/../yaml/hostpath/* $KUBEPATH/dev-configs/hostpath
  $SUDO cp $BASEDIR/../yaml/nfs/* $KUBEPATH/dev-configs/nfs
  $SUDO cp -R $BASEDIR/../CNV/* $KUBEPATH/dev-configs/cnv/aws
  $SUDO cp -R $BASEDIR/../CNV/LocalVM/yaml/* $KUBEPATH/dev-configs/cnv/local
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/data-importer
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/generated/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $KUBEPATH/dev-configs/cdi
  $SUDO cp $BASEDIR/../yaml/cdi/* $KUBEPATH/dev-configs/cdi
  
  $SUDO cp $BASEDIR/../CNV/Origin/config-ocp.sh $OSEPATH
  #$SUDO cp $BASEDIR/../CNV/Origin/aws-hosts /root
  $SUDO cp $BASEDIR/../CNV/yaml/* $OSEPATH/dev-configs/cinder
  $SUDO cp $BASEDIR/../yaml/aws/* $OSEPATH/dev-configs/aws
  $SUDO cp $BASEDIR/../yaml/gce/* $OSEPATH/dev-configs/gce
  $SUDO cp $BASEDIR/../yaml/hostpath/* $OSEPATH/dev-configs/hostpath
  $SUDO cp $BASEDIR/../yaml/nfs/* $OSEPATH/dev-configs/nfs
  $SUDO cp -R $BASEDIR/../CNV/* $OSEPATH/dev-configs/cnv/aws
  $SUDO cp -R $BASEDIR/../CNV/LocalVM/yaml/* $OSEPATH/dev-configs/cnv/local
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/data-importer
  # $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/generated/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $OSEPATH/dev-configs/cdi
  $SUDO cp $BASEDIR/../yaml/cdi/* $OSEPATH/dev-configs/cdi

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

  if [ "$CUSTOM_OCP_REPO" == "Y" ] && [ "$HOSTENV" == "rhel" ]
  then
    echo " ... ... Using custom OCP repo, disabling ose-$OCPVERSION-rpms repo"
    $SUDO subscription-manager repos --disable="rhel-7-server-ose-$OCPVERSION-rpms"
  fi
