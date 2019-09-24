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
    if [ "$SETUP_TYPE" == "installer" ] || [ "$OCPVERSION" == "4.0" ]
    then
      echo " ... ... Installing and configuring pip and awscli"
      pip3 install awscli --upgrade >/dev/null 2>&1
      echo " ... ... ... awscli installed"
    fi

    if [ "$SETUP_TYPE" == "k8-dev" ] && [ "$HOSTENV" == "centos" ]
    then
      echo " ... ... Installing and configuring pip and awscli"
      #scl enable python27 bash
      source /opt/rh/python27/enable
      echo " ... ... ... upgrading pip"
      pip install --upgrade pip >/dev/null 2>&1
      echo " ... ... ... pip installed"
      pip3 install awscli --upgrade >/dev/null 2>&1
      echo " ... ... ... awscli installed"
    fi

    if [ "$SETUP_TYPE" == "k8-dev" ] && [ "$HOSTENV" == "rhel" ]
    then
      echo " ... ... Installing and configuring pip and awscli"
      pip3 install awscli --upgrade >/dev/null 2>&1
      echo " ... ... ... awscli installed"
    fi

    #echo " ... ... Installing awscli bundle"
    #cd $GOLANGPATH
    #curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" >/dev/null 2>&1
    #unzip awscli-bundle.zip >/dev/null 2>&1
    #$SUDO ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws >/dev/null 2>&1

    echo " ... ... Configuring aws cli"
    cd $GOLANGPATH
    echo "...creating aws cli input"
    echo "$AWSKEY" > myconf.txt
    echo "$AWSSECRET" >> myconf.txt
    echo "$ZONE" >> myconf.txt
    echo "json" >> myconf.txt
    aws configure < $GOLANGPATH/myconf.txt >/dev/null 2>&1

    echo " ... ... Creating aws.conf file"  
    cd /etc
    $SUDO mkdir aws
    $SUDO chmod -R 777 /etc/aws  
    cd /etc/aws
    if [ "$KOPS_CLUSTERNAME" == "" ]
    then
      # using local-up-cluster.sh
      echo "[Global]" > aws.conf
      echo "Zone = $ZONE" >> aws.conf
      $SUDO mkdir -p /etc/kubernetes/cloud-config
      cp aws.conf /etc/kubernetes/cloud-config

      echo " ... ... Creating aws.credentials file"   
      cd /etc/aws
      echo "[Global]" > aws.credentials
      echo "aws_access_key_id = $AWSKEY" >> aws.credentials
      echo "aws_secret_access_key = $AWSSECRET" >> aws.credentials
      cp aws.credentials /etc/kubernetes/cloud-config
    else
      # KOPS CLUSTERNAME
      echo "[default]" > aws.conf
      echo "Zone = $ZONE" >> aws.conf
      echo "region=$REGION" >> aws.conf
      $SUDO mkdir -p /etc/kubernetes/cloud-config
      cp aws.conf /etc/kubernetes/cloud-config

      echo " ... ... Creating aws.credentials file"   
      cd /etc/aws
      echo "[sysdeseng]" > aws.credentials
      echo "aws_access_key_id = $AWSKEY" >> aws.credentials
      echo "aws_secret_access_key = $AWSSECRET" >> aws.credentials
      cp aws.credentials /etc/kubernetes/cloud-config
    fi


    if [ "$SETUP_TYPE" == "k8-dev" ]
    then
      if [ "$BUCKET_NAME" == "" ]
      then
        echo " ... ... No Kops Config...skipping bucket creation"
      else
        echo " ... ... Creating Kops S3 bucket"
        aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
        #aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
      fi
    fi

    if [ "$SETUP_TYPE" == "k8-dev" ]
    then
      if [ "$BUCKET_NAME" == "" ]
      then
        echo " ... ... No Kops Config...skipping kops install"
      else
        echo " ... ... Creating Kops install"
        cd ~
        # wget https://github.com/kubernetes/kops/releases/download/1.15.0-alpha.1/kops-linux-amd64
        wget https://github.com/kubernetes/kops/releases/download/$KOPS_RELEASE/kops-linux-amd64 >/dev/null 2>&1
        chmod +x kops-linux-amd64
        mv kops-linux-amd64 /usr/local/bin/kops
      fi
    fi

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
