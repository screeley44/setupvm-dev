#! /bin/bash
# Some automation to setting up OSE/K8 VM's

  if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
  then 
    # TODO: fix this, just want to run sudo if needed
    # can't get this to work the way I want so doing 2nd approach for now
    # and will come back - for now just removing the function test_docker
    sed -i '/function test_docker/,+6d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh >/dev/null 2>&1
    sed -i '/test_docker/d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh >/dev/null 2>&1
  
    # making sure we also have --cloud-config working
    sed -i '/^# You may need to run this as root to allow kubelet to open docker/a CLOUD_CONFIG=${CLOUD_CONFIG:-\"\"}' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh >/dev/null 2>&1
    sed -i '/      --cloud-provider=/a\ \ \ \ \ \ --cloud-config=\"${CLOUD_CONFIG}\" \\' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh >/dev/null 2>&1
  fi

  if [ "$ISCLOUD" == "aws" ]
  then
    echo " ... ... Installing awscli bundle"
    cd $GOLANGPATH
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" >/dev/null 2>&1
    unzip awscli-bundle.zip >/dev/null 2>&1
    $SUDO ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws >/dev/null 2>&1

    echo " ... ... Configuring aws cli"
    cd $GOLANGPATH
    echo "...creating aws cli input"
    echo "$AWSKEY" > myconf.txt
    echo "$AWSSECRET" >> myconf.txt
    echo "$ZONE" >> myconf.txt
    echo "json" >> myconf.txt
    /usr/local/bin/aws configure < myconf.txt >/dev/null 2>&1

    echo " ... ... Creating aws.conf file"  
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
  fi
