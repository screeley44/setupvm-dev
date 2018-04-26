#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # source testfiles.sh
  echo " ... ... Copying Dev Configs to Working Dir"
  $SUDO cp /root/setupvm-dev/CNV/Origin/config-ocp.sh $KUBEPATH
  $SUDO cp /root/setupvm-dev/CNV/Origin/aws-hosts /root
  $SUDO cp /root/setupvm-dev/CNV/yaml/* $KUBEPATH/dev-configs/cinder
  $SUDO cp /root/setupvm-dev/yaml/aws/* $KUBEPATH/dev-configs/aws
  $SUDO cp /root/setupvm-dev/yaml/gce/* $KUBEPATH/dev-configs/gce
  $SUDO cp /root/setupvm-dev/yaml/hostpath/* $KUBEPATH/dev-configs/hostpath
  $SUDO cp -R /root/setupvm-dev/CNV/AWS/yaml/* $KUBEPATH/dev-configs/cnv/aws
  $SUDO cp -R /root/setupvm-dev/CNV/LocalVM/yaml/* $KUBEPATH/dev-configs/cnv/local
  $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/data-importer
  $SUDO cp /root/containerized-data-importer/manifests/importer/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/controller/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $KUBEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/test/images/* $KUBEPATH/dev-configs/cdi
  
  $SUDO cp /root/setupvm-dev/CNV/Origin/config-ocp.sh $OSEPATH
  $SUDO cp /root/setupvm-dev/CNV/Origin/aws-hosts /root
  $SUDO cp /root/setupvm-dev/CNV/yaml/* $OSEPATH/dev-configs/cinder
  $SUDO cp /root/setupvm-dev/yaml/aws/* $OSEPATH/dev-configs/aws
  $SUDO cp /root/setupvm-dev/yaml/gce/* $OSEPATH/dev-configs/gce
  $SUDO cp /root/setupvm-dev/yaml/hostpath/* $OSEPATH/dev-configs/hostpath
  $SUDO cp -R /root/setupvm-dev/CNV/AWS/yaml/* $OSEPATH/dev-configs/cnv/aws
  $SUDO cp -R /root/setupvm-dev/CNV/LocalVM/yaml/* $OSEPATH/dev-configs/cnv/local
  $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/data-importer
  $SUDO cp /root/containerized-data-importer/manifests/importer/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/controller/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/manifests/example/* $OSEPATH/dev-configs/cdi
  $SUDO cp /root/containerized-data-importer/test/images/* $OSEPATH/dev-configs/cdi

  $SUDO cp /root/setupvm-dev/host-files/* /root

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
