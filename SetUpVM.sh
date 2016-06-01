#! /bin/bash
# Some automation to setting up OSE/K8 VM's


# INTERNALHOST=$1
# SUDO=$2
# GOYUM=$3
# ISCLOUD=$4
# ZONE=$5
# AWSKEY=$6
# AWSSECRET=$7
# RHNUSER=$8
# RHNPASS=$9
# ORIGINWORKDIR=$10
# KUBEWORKDIR=$11
# GOWORKDIR=$12

source setupvm.config


if ([ "$SUDO" == "" ] && [ "$ISCLOUD" == "" ] && [ "$GOYUM" == "" ]) || ([ "$SUDO" == "help" ])
then
  echo ""
  echo ""
  echo "USAGE:"
  echo "  edit/configure the setupvm.config script"
  echo ""
  echo " run the SetUpVM.sh script (you may need to chmod +x SetUpVM.sh ) "
  echo "  SetUpVM.sh "
  echo ""
  echo " Description of the setupvm.config parameters: "
  echo ""
  echo ""
  echo "   INTERNALHOST yourhostname i.e. ip-172-30-16-54.internal.amazonaws.com"
  echo "   SUDO sudo or root"
  echo "   GOYUM Y = install golang from yum typically will get 1.4 version, N = install 1.6 version"
  echo "   ISCLOUD = aws, gce or local"
  echo "   ZONE = if aws, then enter your aws zone i.e. us-west-2a"
  echo "   AWSKEY = the key value"
  echo "   AWSSECRET = the secret key value"
  echo "   RHNUSER = rhn support id - for use with subscription manager"
  echo "   RHNPASS = rhs support password - for use with subscription manager"
  echo "   ORIGINWORKDIR = where you want your OpenShift specific configs and workspace to be located - default is users home directory"
  echo "   KUBEWORKDIR = where you want your K8 specific configs and workspace to be located - default is users home directory"
  echo "   SOURCEDIR = where you want your cloned repos to live (GOPATH) default is home directory /go/src/github.com"
  exit 1
fi

echo ""

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
OSEPATH=""
KUBEPATH=""
GOLANGPATH=""

# determine if using defaults or values
# for paths
if [ "$USER" == "ec2-user" ]
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
  if [ "$USER" == "ec2-user" ]
  then
    OSEPATH="/home/ec2-user"
  elif [ "$USER" == "root" ]
  then
    OSEPATH="/root"
  else
    OSEPATH=~
  fi
  echo "Setting Origin Working Directory to $OSEPATH"
else
  OSEPATH=$ORIGINWORKDIR
  echo "Setting Origin Working Directory to $OSEPATH"
fi

KUBEDEFAULT=""
if [[ -z "$KUBEWORKDIR" ]]
then
  if [ "$USER" == "ec2-user" ]
  then
    KUBEPATH="/home/ec2-user"
  elif [ "$USER" == "root" ]
  then
    KUBEPATH="/root"  
  else
    KUBEPATH=~
  fi
  echo "Setting Kube Working Directory to $KUBEPATH"
else
  KUBEPATH=$KUBEWORKDIR
  echo "Setting Kube Working Directory to $KUBEPATH"
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
  else
    GOLANGPATH=~
  fi
  echo "Setting GOLANG Default (GOPATH) Working Directory to $GOLANGPATH"
  GODEFAULT="yes"
else
  GOLANGPATH=$SOURCEDIR
  echo "Setting GOLANG (GOPATH) Working Directory to $GOLANGPATH"
fi
echo ""


if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH
else
  $SUDO mkdir -p $GOLANGPATH
  $SUDO -i chmod -R 777 $GOLANGPATH
fi

if [ "$OSEDEFAULt" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [[ "$OSEPATH" =~ /home ]] 
then
  mkdir -p $OSEPATH
else
  $SUDO mkdir -p $OSEPATH
  $SUDO -i chmod -R 777 $OSEPATH
fi

if [ "$KUBEDEFAULt" == "yes" ] || [ "$KUBEPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/root" ] || [[ "$KUBEPATH" =~ /home ]] 
then
  mkdir -p $KUBEPATH
else
  $SUDO mkdir -p $KUBEPATH
  $SUDO -i chmod -R 777 $KUBEPATH
fi

CreateProfiles()
{

  if [ "$SUDO" == "sudo" ] 
  then  
    cd /home/$USER
  else
    cd ~
  fi
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
  #TODO: ALLOW_SECURITY_CONTEXT=true 
  if [ "$ISCLOUD" == "aws" ]
  then
    echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> .bash_profile 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> .bash_profile
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> .bash_profile
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> .bash_profile
    echo "export ZONE=$ZONE" >> .bash_profile

    $SUDO echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> newbashrc 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> newbashrc
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
    echo "export ZONE=$ZONE" >> newbashrc
  fi
    
  echo "" >> newbashrc
  echo "export DIDRUN=yes" >> newbashrc
  echo ""
  echo "#go environment" >> newbashrc
  echo "export GOPATH=$GOLANGPATH/go" >> newbashrc
  echo "GOPATH1=/usr/local/go" >> newbashrc
  echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
  echo "" >> newbashrc
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH

  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> newbashrc
  echo "" >> newbashrc
  echo "export PATH" >> newbashrc

  echo "" >> .bash_profile
  echo "export DIDRUN=yes" >> .bash_profile
  echo ""
  echo "#go environment" >> .bash_profile
  echo "export GOPATH=$GOLANGPATH/go" >> .bash_profile
  echo "GOPATH1=/usr/local/go" >> .bash_profile
  echo "GO_BIN_PATH=/usr/local/go/bin" >> .bash_profile
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH
  echo "" >> .bash_profile
  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> .bash_profile
  echo "" >> .bash_profile
  echo "export PATH" >> .bash_profile


  $SUDO cp .bash_profile /root
  $SUDO cp newbashrc /root/.bashrc
}

CreateConfigs()
{
  echo "...creating config-k8.sh"
  cd $KUBEPATH
  echo "$SUDO cp $GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64/kube*  /usr/bin" > config-k8.sh
  echo "" >> config-k8.sh
  echo ""
  echo "$GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-cluster local --server=http://127.0.0.1:8080 --insecure-skip-tls-verify=true" >> config-k8.sh
  echo "$GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-context local --cluster=local" >> config-k8.sh
  echo "$GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config use-context local" >> config-k8.sh
  chmod +x config-k8.sh

  echo ""
  echo "...creating config-ose.sh"
  cd $OSEPATH
  echo "chmod +r $OSEPATH/openshift.local.config/master/admin.kubeconfig" > config-ose.sh
  echo "oadm groups new myclusteradmingroup admin --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-cluster-role-to-group cluster-admin myclusteradmingroup --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-scc-to-group privileged myclusteradmingroup --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  chmod +x config-ose.sh
  echo ""


  echo "...creating start-ose.sh"
  mkdir -p $OSEPATH/data
  echo "$SUDO rm -rf /usr/bin/kube*" > start-ose.sh
  cd $OSEPATH

  if [ "$ISCLOUD" == "aws" ]
  then
    echo "openshift start --write-config=$OSEPATH/openshift.local.config --public-master=$INTERNALHOST --volume-dir=~/data --loglevel=4  &> openshift.log" >> start-ose.sh
    echo "sed -i '/apiServerArguments: null/,+2d' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i '/  apiLevels: null/a \ \ apiServerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/aws/aws.conf\"\n\ \ controllerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/aws/aws.conf\"' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "echo \"kubeletArguments:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-provider:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"aws\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-config:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"/etc/aws/aws.conf\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "" >> start-ose.sh
    echo "openshift start --master-config=$OSEPATH/openshift.local.config/master/master-config.yaml --node-config=$OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml --loglevel=4 &> openshift.log" >> start-ose.sh
  else  
    echo ""
    echo "openshift start --public-master=$INTERNALHOST --volume-dir=$OSEPATH/data --loglevel=4  &> openshift.log" >> start-ose.sh
  fi
  chmod +x start-ose.sh
  echo ""
  
  echo "...creating stop-ose.sh"
  echo "pkill -x openshift" > stop-ose.sh
  echo "$SUDO docker ps | awk 'index(\$NF,"k8s_")==1 { print \$1 }' | xargs -l -r $SUDO docker stop" >> stop-ose.sh
  echo "mount | grep "openshift.local.volumes" | awk '{ print \$3}' | xargs -l -r sudo umount" >> stop-ose.sh
  echo "mount | grep "nfs1.rhs" | awk '{ print $3}' | xargs -l -r sudo umount" >> stop-ose.sh
  echo "cd $GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64; sudo rm -rf openshift.local.*" >> stop-ose.sh
  echo "cd $GOLANGPATH; sudo rm -rf openshift.local.*" >> stop-ose.sh
  chmod +x stop-ose.sh
  echo ""

  # TODO: maybe create a start-k8.sh script so we can pass in params
  # i.e.  ALLOW_PRIVILEGED=true ALLOW_SECURITY_CONTEXT=true hack/local-up-cluster.sh  


  if [ "$ISCLOUD" == "aws" ]
  then
    cd $GOLANGPATH
    echo "...creating aws cli input"
    echo "$AWSKEY" > myconf.txt
    echo "$AWSSECRET" >> myconf.txt
    echo "$ZONE" >> myconf.txt
    echo "json" >> myconf.txt
    echo ""
  fi

  cp $OSEPATH/config-ose.sh $GOLANGPATH
  cp $OSEPATH/start-ose.sh $GOLANGPATH
  cp $OSEPATH/stop-ose.sh $GOLANGPATH
  cp $KUBEPATH/config-k8.sh $GOLANGPATH

}

CreateTestYamlEC2()
{
  cd $GOLANGPATH/dev-configs
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

  cp *.yaml $OSEPATH/dev-configs
  cp *.yaml $KUBEPATH/dev-configs


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

if [ "$DIDRUN" == "yes" ] || [ -f "$GOLANGPATH/didrun" ]
then
  echo " Skipping subscription services and yum install of software as this script was run once already..."
  echo ""
else
  # Subscription Manager Stuffs - for RHEL 7.X devices
  echo "Setting up subscription services from RHEL..."
  $SUDO subscription-manager register --username=$RHNUSER --password=$RHNPASS
  $SUDO subscription-manager list --available | sed -n '/OpenShift Employee Subscription/,/Pool ID/p' | sed -n '/Pool ID/ s/.*\://p' | sed -e 's/^[ \t]*//' | xargs -i{} $SUDO subscription-manager attach --pool={}
  $SUDO subscription-manager repos --disable="*"> /dev/null
  $SUDO subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.2-rpms"> /dev/null
  echo ""

  # Install software
  echo "...Installing wget, git, net-tools, bind-utils, iptables-services, rpcbind, nfs-utils, glusterfs-client atomic-openshift-utils bridge-utils, gcc, python-virtualenv, bash-completion telnet etcd unzip ... this will take several minutes"
  $SUDO yum install wget git net-tools bind-utils iptables-services rpcbind nfs-utils glusterfs-client atomic-openshift-utils bridge-utils gcc python-virtualenv bash-completion telnet etcd unzip -y> /dev/null
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
    cd ~
    $SUDO wget https://storage.googleapis.com/golang/go1.6.1.linux-amd64.tar.gz
    $SUDO rm -rf /usr/local/go
    $SUDO tar -C /usr/local -xzf go1.6.1.linux-amd64.tar.gz
  fi
  echo ""
fi

# Config .bash_profile and such
echo "Creating directory structure and workspace..."
echo ""
if [ "$GODEFAULT" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH/go/src/github.com
  mkdir -p $GOLANGPATH/go/src/k8s.io
else
  $SUDO mkdir -p $GOLANGPATH/go/src/github.com
  $SUDO mkdir -p $GOLANGPATH/go/src/k8s.io
  $SUDO -i chmod -R 777 $GOLANGPATH
fi

cd $GOLANGPATH/go/src/k8s.io
rm -rf kubernetes
echo "...Cloning Kubernetes, OpenShift Origin and Openshift Ansible"
echo ""
git clone https://github.com/kubernetes/kubernetes.git

if [ "$GODEFAULT" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH/go/src/github.com/openshift
else
  $SUDO mkdir -p $GOLANGPATH/go/src/github.com/openshift
  $SUDO -i chmod -R 777 $GOLANGPATH
fi

cd $GOLANGPATH/go/src/github.com/openshift
rm -rf origin
git clone https://github.com/openshift/origin.git
cd $GOLANGPATH
rm -rf openshift-ansible
git clone https://github.com/openshift/openshift-ansible
echo ""
echo "...Creating bash_profile and configs for user: $USER"

if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH/dev-configs
else
  $SUDO mkdir -p $GOLANGPATH/dev-configs
  $SUDO -i chmod -R 777 $GOLANGPATH
fi

if [ "$OSEDEFAULT" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [[ "$OSEPATH" =~ /home ]] 
then
  mkdir -p $OSEPATH/dev-configs
else
  $SUDO mkdir -p $OSEPATH/dev-configs
  $SUDO -i chmod -R 777 $OSEPATH
fi

if [ "$KUBEDEFAULT" == "yes" ] || [ "$KUBEPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/root" ] || [[ "$KUBEPATH" =~ /home ]] 
then
  mkdir -p $KUBEPATH/dev-configs
else
  $SUDO mkdir -p $KUBEPATH/dev-configs
  $SUDO -i chmod -R 777 $KUBEPATH
fi

CreateProfiles
CreateConfigs

# Install ec2 api tools and ruby
if [ "$ISCLOUD" == "aws" ]
then
  echo "Install ec2 api tools (aws cli)..."
  cd $GOLANGPATH
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  $SUDO ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  echo "...configuring aws"
  aws configure < myconf.txt

  echo "...creating aws.conf file"  
  cd /etc
  $SUDO mkdir aws
  $SUDO -i chmod -R 777 /etc/aws  
  cd /etc/aws
  echo "[Global]" > aws.conf
  echo "Zone = $ZONE" >> aws.conf
  cd $GOLANGPATH
  echo ""
fi
echo ""

# TODO: don't need to do this, just a precaution at this point
echo "disabling SELinux and Firewalls for now..."
sudo setenforce 0
sudo iptables -F
echo "...Creating some K8 yaml file directory ~/dev-configs"
cd $GOLANGPATH/dev-configs
CreateTestYamlEC2
# CreateTestYamlNFS

if [ "$ISCLOUD" == "aws" ]
then 
  # TODO: fix this, just want to run sudo if needed
  # can't get this to work the way I want so doing 2nd approach for now
  # and will come back - for now just removing the function test_docker
  echo "Editing local-up-cluster.sh"
  sed -i '/function test_docker/,+6d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
  sed -i '/test_docker/d' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
  
  # making sure we also have --cloud-config working
  sed -i '/^# You may need to run this as root to allow kubelet to open docker/a CLOUD_CONFIG=${CLOUD_CONFIG:-\"\"}' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null
  sed -i '/      --cloud-provider=/a\ \ \ \ \ \ --cloud-config=\"${CLOUD_CONFIG}\" \\' $GOLANGPATH/go/src/k8s.io/kubernetes/hack/local-up-cluster.sh> /dev/null

fi


if [ "$DIDRUN" == "yes" ] || [ -f "$GOLANGPATH/didrun" ]
then
  echo " Skipping docker install and config as this script was run once already..."
  echo ""
else
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
fi

echo "DIDRUN" > $GOLANGPATH/didrun


echo ""
echo " *******************************************"
echo ""
echo "PreReq SetUp Complete!!!!"
echo ""
echo "At this point we should be ready to run our build"
echo " BUT A FEW STEPS NEEDED "
echo " 1. you must logout of ssh and log back or 'sudo -s' "
echo "    this will pick up your .bash_profile and all your paths"
echo " 2. Now you can build and run K8 or Origin"
echo ""
echo "        K8 "
echo "       -------- "
echo "       cd $GOLANGPATH/go/src/k8s.io/kubernetes/"
echo "       ./hack/local-up-cluster.sh" 
echo ""
echo "        Origin"
echo "       --------"
echo "       cd $GOLANGPATH/go/src/github.com/openshift/origin"
echo "       make clean build (to build source)"
echo "       then run $OSEPATH/start-ose.sh  (to start the openshift process)"
echo "       to stop OSE:  $OSEPATH/stop-ose.sh"
echo ""
echo " 3. If running local VM , you may need to update your /etc/hosts file as normal"
echo ""
echo " 4. Finally, open a 2nd terminal and run: "
echo "        K8 "
echo "       -------- "
echo "       $KUBEPATH/config-k8.sh" 
echo ""
echo "        Origin"
echo "       --------"
echo "       $OSEPATH/config-ose.sh"
echo ""
echo " 5. Now you should be able to interact and use kubectl or openshift as usual"
echo ""
echo "Environment Recap: "
echo "  dev dir (gopath and source): $GOLANGPATH/go/src/k8s.io/kubernetes $GOLANGPATH/go/src/github.com/openshift/origin"
echo ""
echo "  Origin Working Dir: $OSEPATH (configs are in openshift.local.config, log is openshift.log)"
echo "      scripts (start-ose.sh, stop-ose.sh, config-ose.sh)"
echo ""
echo "  Kube Working Dir: $KUBEPATH "
echo "      scripts (config-k8.sh)"
echo ""
echo "  yaml dir (copied to multiple locations): $OSEPATH/dev-configs  $KUBEPATH/dev-configs  /home/$USER/dev-configs or /root/dev-configs"
echo "  need sudo to interact with docker i.e. sudo docker ps unless you have already 'sudo -s'"


