#! /bin/bash
# Some automation to setting up OSE/K8 VM's


INTERNALHOST=$1
SUDO=$2
GOYUM=$3
ISCLOUD=$4
ZONE=$5
AWSKEY=$6
AWSSECRET=$7
RHNUSER=$8
RHNPASS=$9

if ([ "$SUDO" == "" ] && [ "$ISCLOUD" == "" ] && [ "$GOYUM" == ""]) || ([ "$SUDO" == "help" ])
then
  echo "No parameters passed in, all are required at this time"
  echo ""
  echo ""
  echo "USAGE:"
  echo "  SetUpVM.sh <internal host> <sudo or root> <Y(go1.4) or N(go1.6)> <aws or local> <optional: aws zone i.e. us-west-2a> <aws access key id> <aws access secret key>"
  echo ""
  echo "  param1 = internal hostname (on local vm your hostname, i.e. k8dev.rhs,  on cloud your aws internal hostname like ip-172-30-0-46.us-west-2.compute.internal)"
  echo ""
  echo "  param2 = sudo if you are not root or running cloud, otherwise enter root or any other value"
  echo ""
  echo "  param3 = Y or N "
  echo "       (Y = just use whatever golang version yum installs, typically 1.4)"
  echo "       (N = use 1.6 version)"
  echo ""
  echo "  param4 = aws or any other non aws value (i.e. no, none, local)"
  echo ""
  echo "  param5 = required if param3 is aws.  aws zone - us-west-2a or us-east-1c, etc..."
  echo ""
  echo "  param6 = aws key"
  echo ""
  echo "  param7 = aws secret"
  echo ""
  echo "  param8 = rhn-user"
  echo ""
  echo "  param9 = rhn-password"
  echo ""
  echo " example:  "
  echo "      SetUpVM.sh ip-172-30-0-46.us-west-2.compute.internal sudo N aws us-west-2a MYKEY MYSECRET" 
  echo "                             --> means we are not root, " 
  echo "                                 we want 1.6 golang, " 
  echo "                                 and we are doing aws cloud"
  echo "      SetUpVM.sh k8dev.rhs sudo Y local--> means we are not root so need sudo, " 
  echo "                                 we want 1.4 golang, " 
  echo "                                 and we are not doing aws cloud"
  exit 1
fi

if [ "$SUDO" == "" ] || [ "$SUDO" == "sudo" ]
then
  # do nothing
  echo ""
else
  # change to blank because another value was entered
  SUDO=""
fi

if [ "$ISCLOUD" == "aws" ]
then
  if [ "$AWSKEY" == "" ] || [ "$AWSSECRET" == "" ]
  then
    echo "You must pass in your AWS KEY and SECRET when using aws"
    exit 1
  fi
fi

if [ "$ZONE" == "" ]
then
  ZONE="us-west-2a"
fi

REGION=${ZONE%?}


DEFAULT_BLOCK="/dev/vdb"
VG="docker-vg" 
yval1="y"
yval2="Y"

cm1='PS1="[\\u@\\h \\W\$(git branch 2> /dev/null'
cm2=" | sed -n 's/^* \(.*\)/ (\1)/p')]"
cm3='\\\$ "'

cm11=
cm12=

CreateProfiles()
{
  # Lastly - this came up on Main AWS Account - but not on Sub Account
  # $SUDO openssl genrsa -out /tmp/serviceaccount.key 2048
  # $SUDO KUBE_API_ARGS="--service_account_key_file=/tmp/serviceaccount.key"
  # $SUDO KUBE_CONTROLLER_MANAGER_ARGS="--service_account_private_key_file=/tmp/serviceaccount.key"
  # $SUDO openssl genrsa -out /tmp/kube-serviceaccount.key 2048
  # $SUDO KUBE_API_ARGS="--service_account_key_file=/tmp/kube-serviceaccount.key"
  # $SUDO KUBE_CONTROLLER_MANAGER_ARGS="--service_account_private_key_file=/tmp/kube-serviceaccount.key"


  cd /home/$USER
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


  # removing this from the config-k8.sh script
  # as it doesn't transfer terminals - so need all terminal
  # processes to get this
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> .bash_profile 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
    # echo "export CLOUD_CONFIG=/home/$USER/.aws/config" >> .bash_profile
    echo "export KUBE_AWS_ZONE=$ZONE" >> .bash_profile
    echo "export AWS_DEFAULT_REGION=$REGION" >> .bash_profile
    echo "export KUBE_AWS_REGION=$REGION" >> .bash_profile
    echo "export AWS_REGION=$REGION" >> .bash_profile
    echo "export NUM_NODES=1" >> .bash_profile
    echo "export MASTER_SIZE=t2.large" >> .bash_profile
    echo "export NODE_SIZE=t2.large" >> .bash_profile
    echo "export AWS_S3_REGION=$REGION" >> .bash_profile
    echo "export AWS_S3_BUCKET=aos-storage-dev" >> .bash_profile
    echo "export INSTANCE_PREFIX=k8s" >> .bash_profile
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> .bash_profile
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> .bash_profile
    # echo "export KUBE_API_ARGS='--service_account_key_file=/tmp/serviceaccount.key'" >> .bash_profile
    # echo "export KUBE_CONTROLLER_MANAGER_ARGS='--service_account_private_key_file=/tmp/serviceaccount.key'" >> .bash_profile

    $SUDO echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> newbashrc 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
    # echo "export CLOUD_CONFIG=/etc/cloud/cloud.cfg" >> newbashrc
    echo "export KUBE_AWS_ZONE=$ZONE" >> newbashrc
    echo "export AWS_DEFAULT_REGION=$REGION" >> newbashrc
    echo "export KUBE_AWS_REGION=$REGION" >> newbashrc
    echo "export AWS_REGION=$REGION" >> newbashrc
    echo "export NUM_NODES=1" >> newbashrc
    echo "export MASTER_SIZE=t2.large" >> newbashrc
    echo "export NODE_SIZE=t2.large" >> newbashrc
    echo "export AWS_S3_REGION=$REGION" >> newbashrc
    echo "export AWS_S3_BUCKET=aos-storage-dev" >> newbashrc
    echo "export INSTANCE_PREFIX=k8s" >> newbashrc
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
    # echo "export KUBE_API_ARGS='--service_account_key_file=/tmp/serviceaccount.key'" >> newbashrc
    # echo "export KUBE_CONTROLLER_MANAGER_ARGS='--service_account_private_key_file=/tmp/serviceaccount.key'" >> newbashrc

    echo "" >> newbashrc
    echo "#go environment" >> newbashrc
    echo "export GOPATH=/home/$USER/go" >> newbashrc
    echo "GOPATH1=/usr/local/go" >> newbashrc
    echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
    echo "" >> newbashrc
    echo "PATH=$PATH:$HOME/bin:/usr/local/go/bin:/home/$USER/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:/home/$USER/go/src/github.com/kubernetes/_output/local/bin/linux/amd64" >> newbashrc
    echo "" >> newbashrc
    echo "export PATH" >> newbashrc
  fi

  echo "" >> .bash_profile
  echo "#go environment" >> .bash_profile
  echo "export GOPATH=/home/$USER/go" >> .bash_profile
  echo "GOPATH1=/usr/local/go" >> .bash_profile
  echo "GO_BIN_PATH=/usr/local/go/bin" >> .bash_profile
  echo "" >> .bash_profile
  echo "PATH=$PATH:$HOME/bin:/usr/local/go/bin:/home/$USER/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:/home/$USER/go/src/github.com/kubernetes/_output/local/bin/linux/amd64" >> .bash_profile
  echo "" >> .bash_profile
  echo "export PATH" >> .bash_profile


  $SUDO cp .bash_profile /root
  $SUDO cp newbashrc /root/.bashrc
}

CreateConfigs()
{
  echo "...creating config-k8.sh"
  cd /home/$USER
  echo "$SUDO cp /home/$USER/go/src/github.com/kubernetes/_output/local/bin/linux/amd64/kube*  /usr/bin" > config-k8.sh
  echo "" >> config-k8.sh
  echo ""

  echo ""
  echo "/home/$USER/go/src/github.com/kubernetes/cluster/kubectl.sh config set-cluster local --server=http://127.0.0.1:8080 --insecure-skip-tls-verify=true" >> config-k8.sh
  echo "/home/$USER/go/src/github.com/kubernetes/cluster/kubectl.sh config set-context local --cluster=local" >> config-k8.sh
  echo "/home/$USER/go/src/github.com/kubernetes/cluster/kubectl.sh config use-context local" >> config-k8.sh
  chmod +x config-k8.sh

  echo ""
  echo "...creating config-ose.sh"
  echo "chmod +r /home/$USER/openshift.local.config/master/admin.kubeconfig" > config-ose.sh
  echo "oadm groups new myclusteradmingroup admin --config=/home/$USER/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-cluster-role-to-group cluster-admin myclusteradmingroup --config=/home/$USER/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-scc-to-group privileged myclusteradmingroup --config=/home/$USER/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  chmod +x config-ose.sh
  echo ""


  echo "...creating start-ose.sh"
  mkdir data
  echo "$SUDO rm -rf /usr/bin/kube*" > start-ose.sh
  echo "openshift start --write-config=/home/$USER/openshift.local.config --public-master=$INTERNALHOST --volume-dir=/home/$USER/data --loglevel=4  &> openshift.log" >> start-ose.sh
  echo "sed -i '/  apiLevels: null/a \ \ apiServerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/aws/aws.conf\"\n\ \ controllerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/aws/aws.conf\"' /home/$USER/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
  echo "echo \"kubeletArguments:\" >> /home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
  echo "echo \"  cloud-provider:\" >> /home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
  echo "echo \"    - \\\"aws\\\"\" >> /home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
  echo "echo \"  cloud-config:\" >> /home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
  echo "echo \"    - \\\"/etc/aws/aws.conf\\\"\" >> /home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
  echo "" >> start-ose.sh
  echo "openshift start --master-config=/home/$USER/openshift.local.config/master/master-config.yaml --node-config=/home/$USER/openshift.local.config/node-$INTERNALHOST/node-config.yaml --loglevel=4 &> openshift.log" >> start-ose.sh
  #echo "openshift start --public-master=$INTERNALHOST --volume-dir=/home/$USER/data --loglevel=4  &> openshift.log" >> start-ose.sh
  chmod +x start-ose.sh
  echo ""
  
  echo "...creating stop-ose.sh"
  echo "pkill -x openshift" > stop-ose.sh
  echo "$SUDO docker ps | awk 'index(\$NF,"k8s_")==1 { print \$1 }' | xargs -l -r $SUDO docker stop" >> stop-ose.sh
  echo "mount | grep "openshift.local.volumes" | awk '{ print \$3}' | xargs -l -r sudo umount" >> stop-ose.sh
  echo "mount | grep "nfs1.rhs" | awk '{ print $3}' | xargs -l -r sudo umount" >> stop-ose.sh
  echo "cd /home/$USER/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64; sudo rm -rf openshift.local.*" >> stop-ose.sh
  echo "cd /home/$USER; sudo rm -rf openshift.local.*" >> stop-ose.sh
  chmod +x stop-ose.sh
  echo ""
  
  if [ "$ISCLOUD" == "aws" ]
  then
    cd /home/$USER
    echo "...creating aws cli input"
    echo "$AWSKEY" > myconf.txt
    echo "$AWSSECRET" >> myconf.txt
    echo "$ZONE" >> myconf.txt
    echo "json" >> myconf.txt
    echo ""
  fi

}

CreateTestYamlEC2()
{
  cd /home/$USER/dev-configs
  echo "apiVersion: v1" > busybox-ebs.yaml
  echo "kind: Pod" >> busybox-ebs.yaml
  echo "metadata:"  >> busybox-ebs.yaml
  echo "  name: aws-ebs-bb-pod1"  >> busybox-ebs.yaml
  echo "spec:"  >> busybox-ebs.yaml
  echo "  containers:"  >> busybox-ebs.yaml
  echo "  - name: aws-ebs-bb-pod1"  >> busybox-ebs.yaml
  echo "    image: busybox"  >> busybox-ebs.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-ebs.yaml
  echo "    volumeMounts:"  >> busybox-ebs.yaml
  echo "    - mountPath: /usr/share/busybox"  >> busybox-ebs.yaml
  echo "      name: ebsvol"  >> busybox-ebs.yaml
  echo "  volumes:"  >> busybox-ebs.yaml
  echo "  - name: ebsvol"  >> busybox-ebs.yaml
  echo "    awsElasticBlockStore:"  >> busybox-ebs.yaml
  echo "      volumeID: vol-96ab0224"  >> busybox-ebs.yaml
  echo "      fsType: ext4"  >> busybox-ebs.yaml

  echo "apiVersion: v1" > ebs-pv.yaml
  echo "kind: PersistentVolume" >> ebs-pv.yaml
  echo "metadata:" >> ebs-pv.yaml
  echo " name: pv-ebs" >> ebs-pv.yaml
  echo "spec:" >> ebs-pv.yaml
  echo " capacity:" >> ebs-pv.yaml
  echo "   storage: 1Gi" >> ebs-pv.yaml
  echo " accessModes:" >> ebs-pv.yaml
  echo "   - ReadWriteOnce" >> ebs-pv.yaml
  echo " awsElasticBlockStore:" >> ebs-pv.yaml
  echo "   volumeID: vol-469b10f4" >> ebs-pv.yaml
  echo "   fsType: ext4" >> ebs-pv.yaml


  echo "apiVersion: v1" > ebs-pvc.yaml
  echo "kind: PersistentVolumeClaim" >> ebs-pvc.yaml
  echo "metadata:" >> ebs-pvc.yaml
  echo " name: ebs-claim" >> ebs-pvc.yaml
  echo "spec:" >> ebs-pvc.yaml
  echo " accessModes:" >> ebs-pvc.yaml
  echo "  - ReadWriteOnce" >> ebs-pvc.yaml
  echo " resources:" >> ebs-pvc.yaml
  echo "   requests:" >> ebs-pvc.yaml
  echo "     storage: 1Gi" >> ebs-pvc.yaml

  echo "apiVersion: v1" > busybox-ebs-pvc.yaml
  echo "kind: Pod" >> busybox-ebs-pvc.yaml
  echo "metadata:" >> busybox-ebs-pvc.yaml
  echo "  name: aws-ebs-bb-pod2" >> busybox-ebs-pvc.yaml
  echo "spec:" >> busybox-ebs-pvc.yaml
  echo "  containers:" >> busybox-ebs-pvc.yaml
  echo "  - name: aws-ebs-bb-pod2" >> busybox-ebs-pvc.yaml
  echo "    image: busybox" >> busybox-ebs-pvc.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-ebs-pvc.yaml
  echo "    volumeMounts:" >> busybox-ebs-pvc.yaml
  echo "    - mountPath: /usr/share/busybox" >> busybox-ebs-pvc.yaml
  echo "      name: ebsvol" >> busybox-ebs-pvc.yaml
  echo "  volumes:" >> busybox-ebs-pvc.yaml
  echo "    - name: ebsvol" >> busybox-ebs-pvc.yaml
  echo "      persistentVolumeClaim:" >> busybox-ebs-pvc.yaml
  echo "        claimName: ebs-claim" >> busybox-ebs-pvc.yaml




}

DoBlock()
{
  $SUDO lsblk
  echo "Based on output above, what block device should the registry be set up on?"
  read block_device
  if [ "$block_device" == "" ]
  then
    echo "no block device entered, default $DEFAULT_BLOCK will be used"
    $SUDO sh -c "echo 'DEVS=$DEFAULT_BLOCK' >> /etc/sysconfig/docker-storage-setup"
    $SUDO sh -c "echo 'VG=$VG' >> /etc/sysconfig/docker-storage-setup"
  else
    echo "block device /dev/$block_device will be used, is this acceptable? (y/n)"
    read isaccepted
    if [ "$isaccepted" == "$yval1" ] || [ "$isaccepted" == "$yval2" ]
    then
    $SUDO sh -c "echo 'DEVS=/dev/$block_device' >> /etc/sysconfig/docker-storage-setup"
    $SUDO sh -c "echo 'VG=$VG' >> /etc/sysconfig/docker-storage-setup"
      echo "docker-storage-setup file updated"
    else
      echo "Let's try again..."
      echo ""
      DoBlock
    fi
  fi
}

# ENTRY POINT
echo "About to install a single node development VM (local or cloud) for: "
echo "   - Kubernetes"
echo "   - OpenShift Origin"
echo ""
echo "This will install all prereqs including: "
echo "   -all RHEL prereq software from yum"
echo "   -golang1.4 or 1.6 and configure GOPATH"
echo "   -github source repos"
echo "   -if cloud - aws cli and configurations"
echo "   -working directory structures"
echo "   -sample yaml for aws"
echo "   -docker from yum and docker registry configuration"
echo "   -and misc tools and configuration scripts to help run the projects"
echo ""

# Subscription Manager Stuffs - for RHEL 7.X devices
echo "Setting up subscription services from RHEL..."
$SUDO subscription-manager register --username=$RHNUSER --password=$RHNPASS
$SUDO subscription-manager list --available | sed -n '/OpenShift Employee Subscription/,/Pool ID/p' | sed -n '/Pool ID/ s/.*\://p' | sed -e 's/^[ \t]*//' | xargs -i{} $SUDO subscription-manager attach --pool={}
$SUDO subscription-manager repos --disable="*"> /dev/null
$SUDO subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.1-rpms"> /dev/null
echo ""

# Install software
echo "...Installing wget, git, net-tools, bind-utils, iptables-services, bridge-utils, gcc, python-virtualenv, bash-completion telnet etcd unzip ... this will take several minutes"
$SUDO yum install wget git net-tools bind-utils iptables-services bridge-utils gcc python-virtualenv bash-completion telnet etcd unzip -y> /dev/null
$SUDO yum update -y> /dev/null
$SUDO yum install atomic-openshift-utils -y> /dev/null
echo ""

# Install Go and do other config
if [ "$GOYUM" == "y" ] || [ "$GOYUM" == "Y" ]
then
  echo "Installing go1.4..."
  $SUDO yum install go -y> /dev/null
else
  echo "Installing go1.6..."
  cd /home/$USER
  $SUDO wget https://storage.googleapis.com/golang/go1.6.1.linux-amd64.tar.gz
  $SUDO rm -rf /usr/local/go
  $SUDO tar -C /usr/local -xzf go1.6.1.linux-amd64.tar.gz
fi
echo ""


# Config .bash_profile and such
echo "Creating directory structure and workspace..."
echo ""
cd /home/$USER
mkdir go
cd go
mkdir src
cd src
mkdir github.com
cd github.com
echo "...Cloning Kubernetes, OpenShift Origin and Openshift Ansible"
echo ""
git clone https://github.com/kubernetes/kubernetes.git
mkdir openshift
cd openshift
git clone https://github.com/openshift/origin.git
cd /home/$USER
git clone https://github.com/openshift/openshift-ansible
echo ""
echo "...Creating bash_profile and configs for user: $USER"
CreateProfiles
CreateConfigs

# Install ec2 api tools and ruby
if [ "$ISCLOUD" == "aws" ]
then
  echo "Install ec2 api tools (aws cli)..."
  cd /home/$USER
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  $SUDO ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  echo "...configuring aws"
  aws configure < myconf.txt

  echo "...creating aws.conf file"  
  cd /etc
  # one way
  # $SUDO -s
  # then exit after??

  $SUDO mkdir aws
  $SUDO -i chmod -R 777 /etc/aws  
  cd /etc/aws
  echo "[Global]" > aws.conf
  echo "Zone = $ZONE" >> aws.conf
  cd /home/$USER
  echo ""
fi
echo ""

# TODO: don't need to do this, just a precaution at this point
echo "disabling SELinux and Firewalls for now..."
sudo setenforce 0
sudo iptables -F
echo "...Creating some K8 yaml file directory /home/$USER/dev-configs"
cd /home/$USER
mkdir dev-configs
cd dev-configs
CreateTestYamlEC2
# CreateTestYamlNFS

if [ "$ISCLOUD" == "aws" ]
then 
  # TODO: fix this, just want to run sudo if needed
  # can't get this to work the way I want so doing 2nd approach for now
  # and will come back - for now just removing the function test_docker
  echo "Editing local-up-cluster.sh"
  # sed -i "s/${DOCKER[@]} ps/sudo ${DOCKER[@]} ps/" /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh
  sed -i '/function test_docker/,+6d' /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh> /dev/null
  sed -i '/test_docker/d' /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh> /dev/null
  
  # making sure we also have --cloud-config working
  sed -i '/^# You may need to run this as root to allow kubelet to open docker/a CLOUD_CONFIG=${CLOUD_CONFIG:-\"\"}' /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh> /dev/null
  sed -i '/      --cloud-provider=/a\ \ \ \ \ \ --cloud-config=\"${CLOUD_CONFIG}\" \\' /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh> /dev/null

  # mv /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh /home/$USER/go/src/github.com/kubernetes/hack/local-up-cluster.sh.bck
  # cp /home/$USER/local-up-cluster.sh /home/$USER/go/src/github.com/kubernetes/hack/
fi

# Install Docker yum version
echo "...Installing Docker"
$SUDO yum install docker -y> /dev/null
echo ""

# Docker Registry Stuff
echo "...Updating the docker config file with insecure-registry"
$SUDO sed -i "s/OPTIONS='--selinux-enabled'/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker
echo ""

# Update the docker-storage-setup
DoBlock
echo ""

$SUDO cat /etc/sysconfig/docker-storage-setup
echo "...Running docker-storage-setup"
$SUDO docker-storage-setup
$SUDO lvs
echo ""

# Restart Docker
echo "...Restarting Docker"
$SUDO groupadd docker
$SUDO gpasswd -a ${USER} docker
$SUDO systemctl stop docker
$SUDO rm -rf /var/lib/docker/*
$SUDO systemctl restart docker


echo "PreReq SetUp Complete!!!!"
echo ""
echo "At this point we should be ready to run our build"
echo " BUT A FEW STEPS NEEDED "
echo " 1. you must logout of ssh and log back or 'sudo -s' "
echo "    this will pick up your .bash_profile and all your paths"
echo " 2. Now you can run the ./hack/local-up-cluster.sh to build and start K8"
echo "       or"
echo "    make clean build on OSE (make clean build)"
echo " 3. Finally, open a 2nd terminal and run the /home/$USER/config-k8.sh" 
echo "    script for K8 since it is already running"
echo "    If using OpenShift - need to run the /home/$USER/start-ose.sh script"
echo "    and then /home/$USER/config-ose.sh"
echo " 4. Now you should be able to interact and use kubectl or openshift as usual"
echo ""
echo "Environment: "
echo "  dev dir: /home/ec2-user/go/src/github.com  kubernetes | openshift/origin"
echo "  yaml dir: /home/ec2-user/dev-configs"
echo "  need sudo to interact with docker i.e. sudo docker ps unless you have already 'sudo -s'"


