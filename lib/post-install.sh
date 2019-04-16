#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  # source testfiles.sh
  BASESRC=$BASH_SOURCE
  BASEDIR=`dirname $BASH_SOURCE`
  echo " ... ... Copying Dev Configs to Working Dir"
  echo " ... ... ... Base Dir is $BASEDIR"

  # Kubernetes Dev Path
  $SUDO cp -R $BASEDIR/../yaml/ $KUBEPATH/dev-configs/

  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    echo " ... ... ... not copying CDI manifests"
  else
    $SUDO cp /root/containerized-data-importer/manifests/generated/* $KUBEPATH/dev-configs/cdi
    $SUDO cp /root/containerized-data-importer/manifests/example/* $KUBEPATH/dev-configs/cdi
  fi
  
  # OpenShift Dev Path
  $SUDO cp -R $BASEDIR/../yaml/ $OSEPATH/dev-configs/

  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    echo " ... ... ... not copying CDI manifests"
  else
    $SUDO cp /root/containerized-data-importer/manifests/generated/* $OSEPATH/dev-configs/cdi
    $SUDO cp /root/containerized-data-importer/manifests/example/* $OSEPATH/dev-configs/cdi
  fi
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


  # 4.0 create install-config.yaml
  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    if [ "$IS_FOR_AMI" == "N" ]
    then
      echo " ... ... Creating install-config.yaml"
      cID=$( uuidgen )
      sshK=$( cat $SSHPATH )
      pS=$( cat $PULLSECRETPATH )
      echo " ... ... ... uuid = $cID"
      cd ~/$CLUSTER_NAME
      echo "apiVersion: v1beta4" > install-config.yaml
      echo "baseDomain: $HOSTED_ZONE" >> install-config.yaml

      # not sure I need this anymore - keeping for now
      # echo "clusterID: $cID" >> install-config.yaml

      echo "compute:" >> install-config.yaml
      echo "- name: worker" >> install-config.yaml
      echo "  platform: {}" >> install-config.yaml
      echo "  replicas: $WORKER_COUNT" >> install-config.yaml
      echo "controlPlane:" >> install-config.yaml
      echo "  name: master" >> install-config.yaml
      echo "  platform: {}" >> install-config.yaml
      echo "  replicas: $MASTER_COUNT" >> install-config.yaml
      # echo "machines:" >> install-config.yaml
      # echo "- name: master" >> install-config.yaml
      # echo "  platform: {}" >> install-config.yaml
      # echo "  replicas: $MASTER_COUNT" >> install-config.yaml
      # echo "- name: worker" >> install-config.yaml
      # echo "  platform:" >> install-config.yaml
      # echo "    $ISCLOUD:" >> install-config.yaml
      # echo "      rootVolume:" >> install-config.yaml
      # echo "        iops: 4000" >> install-config.yaml
      # echo "        size: $ROOTSIZE" >> install-config.yaml
      # echo "        type: io1" >> install-config.yaml
      # echo "      type: c5.9xlarge" >> install-config.yaml
      # echo "  replicas: $WORKER_COUNT" >> install-config.yaml

      echo "metadata:" >> install-config.yaml
      echo "  creationTimestamp: null" >> install-config.yaml
      echo "  name: $CLUSTER_NAME" >> install-config.yaml
      echo "networking:" >> install-config.yaml
      echo "  clusterNetworks:" >> install-config.yaml
      echo "  - cidr: 10.128.0.0/14" >> install-config.yaml
      echo "    hostSubnetLength: 9" >> install-config.yaml
      echo "  serviceCIDR: 172.30.0.0/16" >> install-config.yaml
      echo "  type: OpenshiftSDN" >> install-config.yaml
      echo "platform:" >> install-config.yaml
      echo "  $ISCLOUD:" >> install-config.yaml
      echo "    region: us-east-1" >> install-config.yaml
      echo "    vpcCIDRBlock: 10.0.0.0/16" >> install-config.yaml
      echo "pullSecret: '$pS'" >> install-config.yaml
      echo "sshKey: \"$sshK\"" >> install-config.yaml
      echo " ... ... ... install-config.yaml created!"
      echo ""
      cp install-config.yaml ../install-config-$CLUSTER_NAME.yaml
    fi
  fi

  # 4.0 install OC CLI
  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    cd ~
    $SUDO wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz >/dev/null 2>&1
    $SUDO rm -rf /usr/local/bin/oc		
    $SUDO tar -C /usr/local/bin -xzf oc.tar.gz >/dev/null 2>&1
  fi
  
  #4.0 install KUBECTL CLI
  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    cd ~
    $SUDO curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl >/dev/null 2>&1
    #$SUDO curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl >/dev/null 2>&1
    $SUDO chmod +x ./kubectl
    $SUDO rm -rf /usr/local/bin/kubectl		
    $SUDO mv ./kubectl /usr/local/bin/kubectl >/dev/null 2>&1
  fi



  # restart docker
  if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
  then
    echo ""
  else
    echo " ... ... Restarting Docker"
    systemctl restart docker >/dev/null 2>&1
  fi

  #if [ "$CUSTOM_OCP_REPO" == "Y" ] && [ "$HOSTENV" == "rhel" ]
  #then
  #  echo " ... ... Using custom OCP repo, disabling ose-$OCPVERSION-rpms repo"
  #  $SUDO subscription-manager repos --disable="rhel-7-server-ose-$OCPVERSION-rpms"
  #fi
