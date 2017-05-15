#! /bin/bash
# Some automation to setting up OSE/K8 VM's


source setupvm.config

if ([ "$SUDO" == "" ] && [ "$ISCLOUD" == "" ] && [ "$GOVERSION" == "" ]) || ([ "$SUDO" == "help" ])
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
  echo "   GOVERSION = 1.6, 1.7 or yum (meaning whatever comes from yum)"
  echo "   ISCLOUD = aws, gce or local"
  echo "   ZONE = if aws, then enter your aws zone i.e. us-west-2a"
  echo "   AWSKEY = the key value"
  echo "   AWSSECRET = the secret key value"
  echo "   RHNUSER = rhn support id - for use with subscription manager"
  echo "   RHNPASS = rhs support password - for use with subscription manager"
  echo "   ORIGINWORKDIR = where you want your OpenShift specific configs and workspace to be located - default is users home directory"
  echo "   KUBEWORKDIR = where you want your K8 specific configs and workspace to be located - default is users home directory"
  echo "   SOURCEDIR = where you want your cloned repos to live (GOPATH) default is home directory /go/src/github.com"
  echo "   SETUP_TYPE=dev, aplo, aploclient (default is dev) - dev will install a working dev environment to build from source, etc..."
  echo "       aplo - normal ose/k8 install minus the cloning of source repos"
  echo "       client - just base with openshift-utils and openshift-client - nothing else"
  echo "       ocp_only - No Kube source is installed, only OCP"
  echo "       kube_only - No OCP source is installed, only Kube"        
  echo "   DOCKERVER= version # OR leave blank and it will get whatever is available/current for your repo sets"
  echo "   ETCD_VER= (3 or default) (default is what is available for repo sets, 3 will trigger version 3.0.4 which is now required with latest K8)"
  exit 1
fi

echo ""

if [ "$ISCLOUD" == "aws" ]
then
  if [ "$AWSKEY" == "" ] || [ "$AWSSECRET" == "" ] || [ "$AWSSECRET" == "local" ] || [ "$AWSKEY" == "local" ]
  then
    echo "You must pass in your AWS KEY and SECRET when using aws"
    exit 1
  fi
fi

if [ "$ZONE" == "" ]
then
  ZONE="us-east1-d"
fi

if [ "$MULTIZONE" == "" ]
then
  MULTIZONE="false"
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
  echo "Setting GOLANG Default (GOPATH) Working Directory to $GOLANGPATH/go"
  GODEFAULT="yes"
else
  GOLANGPATH=$SOURCEDIR
  echo "Setting GOLANG (GOPATH) Working Directory to $GOLANGPATH/go"
fi
echo ""


if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH
else
  $SUDO mkdir -p $GOLANGPATH
  $SUDO chmod -R 777 $GOLANGPATH
fi

if [ "$OSEDEFAULt" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [[ "$OSEPATH" =~ /home ]] 
then
  mkdir -p $OSEPATH
else
  $SUDO mkdir -p $OSEPATH
  $SUDO chmod -R 777 $OSEPATH
fi

if [ "$KUBEDEFAULt" == "yes" ] || [ "$KUBEPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/root" ] || [[ "$KUBEPATH" =~ /home ]] 
then
  mkdir -p $KUBEPATH
else
  $SUDO mkdir -p $KUBEPATH
  $SUDO chmod -R 777 $KUBEPATH
fi

GCENODEPATH="c.openshift-gce-devel.internal"

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
  if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ] || [ "$ISCLOUD" == "vsphere" ]
  then
    echo "...Creating Cloud bash profiles"
    echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> .bash_profile 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> .bash_profile

    if [ "$ISCLOUD" == "vsphere" ]
    then
      echo "export CLOUD_PROVIDER=/etc/vsphere/vsphere.conf" >> .bash_profile
    fi

    if [ "$MULTIZONE" == "true" ]
    then
      if [ "$ISCLOUD" == "aws" ]
      then
        echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> .bash_profile
      fi
      if [ "$ISCLOUD" == "gce" ]
      then
        echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> .bash_profile
      fi
      echo "export MULTIZONE=$MULTIZONE" >> .bash_profile    
    fi
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> .bash_profile
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> .bash_profile
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> .bash_profile
    echo "export ZONE=$ZONE" >> .bash_profile
    if [ "$ISCLOUD" == "gce" ] || [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "vsphere" ]
    then
      echo "export HOSTNAME_OVERRIDE=$INTERNALHOST" >> .bash_profile
    fi
    if [ "$ISCLOUD" == "gce" ]
    then
      echo "source '/home/$USER/Downloads/google-cloud-sdk/path.bash.inc'" >> .bash_profile
      echo "source '/home/$USER/Downloads/google-cloud-sdk/completion.bash.inc'" >> .bash_profile
    fi

    $SUDO echo "# AWS Stuff (Update accordingly and log back in each terminal0" >> newbashrc 
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export CLOUD_PROVIDER=$ISCLOUD" >> newbashrc
    if [ "$MULTIZONE" == "true" ]
    then
      if [ "$ISCLOUD" == "aws" ]
      then
        echo "export CLOUD_CONFIG=/etc/aws/aws.conf" >> newbashrc
      fi
      if [ "$ISCLOUD" == "gce" ]
      then
        echo "export CLOUD_CONFIG=/etc/gce/gce.conf" >> newbashrc
      fi
      echo "export MULTIZONE=$MULTIZONE" >> newbashrc
    fi
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> newbashrc
    echo "export AWS_ACCESS_KEY_ID=$AWSKEY" >> newbashrc
    echo "export AWS_SECRET_ACCESS_KEY=$AWSSECRET" >> newbashrc
    echo "export ZONE=$ZONE" >> newbashrc
    if [ "$ISCLOUD" == "gce" ] || [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "vsphere" ]
    then
      echo "export HOSTNAME_OVERRIDE=$INTERNALHOST" >> newbashrc
    fi
    if [ "$ISCLOUD" == "gce" ]
    then
      echo "source '/home/$USER/Downloads/google-cloud-sdk/path.bash.inc'" >> newbashrc
      echo "source '/home/$USER/Downloads/google-cloud-sdk/completion.bash.inc'" >> newbashrc
    fi
  else
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> newbashrc
    echo "export HOSTNAME_OVERRIDE=$INTERNALHOST" >> newbashrc
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> newbashrc
    echo "export KUBERNETES_PROVIDER=$ISCLOUD" >> .bash_profile
    echo "export HOSTNAME_OVERRIDE=$INTERNALHOST" >> .bash_profile
    echo "export INTERNALDNSHOST=$INTERNALHOST" >> .bash_profile
  fi

  if [ "$SETUP_TYPE" == "kubeadm" ] || [ "$SETUP_TYPE" == "kubeadm15" ]
  then
    echo "export KUBECONFIG=$HOME/admin.conf" >> newbashrc
    echo "export KUBECONFIG=$HOME/admin.conf" >> .bash_profile
  fi     
    
  echo "" >> newbashrc
  # echo "export DIDRUN=yes" >> newbashrc
  echo ""
  echo "#go environment" >> newbashrc
  echo "export GOPATH=$GOLANGPATH/go" >> newbashrc
  echo "GOPATH1=/usr/local/go" >> newbashrc
  echo "GO_BIN_PATH=/usr/local/go/bin" >> newbashrc
  echo "" >> newbashrc
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH

  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> newbashrc
  echo "" >> newbashrc
  echo "export PATH" >> newbashrc

  echo "" >> .bash_profile
  # echo "export DIDRUN=yes" >> .bash_profile
  echo ""
  echo "#go environment" >> .bash_profile
  echo "export GOPATH=$GOLANGPATH/go" >> .bash_profile
  echo "GOPATH1=/usr/local/go" >> .bash_profile
  echo "GO_BIN_PATH=/usr/local/go/bin" >> .bash_profile
  #TODO: set up KPATH as well
  # export KPATH=$GOPATH/src/k8s.io/kubernetes
  # export PATH=$KPATH/_output/local/bin/linux/amd64:/home/tsclair/scripts/:$GOPATH/bin:$PATH
  echo "" >> .bash_profile
  echo "PATH=\$PATH:$HOME/bin:/usr/local/bin/aws:/usr/local/go/bin:$GOLANGPATH/go/bin:$GOLANGPATH/go/src/github.com/openshift/origin/_output/local/bin/linux/amd64:$GOLANGPATH/go/src/k8s.io/kubernetes/_output/local/bin/linux/amd64" >> .bash_profile
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
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-cluster local --server=http://127.0.0.1:8080 --insecure-skip-tls-verify=true" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-context local --cluster=local" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config use-context local" >> config-k8.sh
  echo "" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/apiserver.crt" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-credentials myself --username=admin --password=admin" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config use-context local" >> config-k8.sh
  echo "" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/apiserver.crt" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself" >> config-k8.sh
  echo "# $GOLANGPATH/go/src/k8s.io/kubernetes/cluster/kubectl.sh config use-context local" >> config-k8.sh
  echo "# export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig" >> config-k8.sh  
  echo "" >> config-k8.sh
  echo "kubectl config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt" >> config-k8.sh
  echo "kubectl config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt" >> config-k8.sh
  echo "kubectl config set-context local --cluster=local --user=myself" >> config-k8.sh
  echo "kubectl config use-context local" >> config-k8.sh



  chmod +x config-k8.sh

  echo ""
  echo "...creating config-ose.sh"
  cd $OSEPATH
  echo "chmod +r $OSEPATH/openshift.local.config/master/admin.kubeconfig" > config-ose.sh
  echo "# create namespaces/projects" >> config-ose.sh
  echo "oadm new-project dev1project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm new-project dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "" >> config-ose.sh
  echo "# create groups" >> config-ose.sh
  echo "oadm groups new myclusteradmingroup admin --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups new mystorageadmingroup screeley --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups new mydevgroup1 dev11 --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups new mydevgroup2 dev21 --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "" >> config-ose.sh
  echo "# add policy roles to groups" >> config-ose.sh
  echo "oadm policy add-cluster-role-to-group cluster-admin myclusteradmingroup --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-cluster-role-to-group storage-admin mystorageadmingroup --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-group basic-user mydevgroup1 -n dev1project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-group basic-user mydevgroup2 -n dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-group view mydevgroup1 -n dev1project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-group view mydevgroup2 -n dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-group edit mydevgroup2 -n dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-user basic-user jdoe -n default --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-user view jdoe -n default --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm policy add-role-to-user edit jdoe -n default --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "" >> config-ose.sh
  echo "# add some scc policy as well" >> config-ose.sh
  echo "oadm policy add-scc-to-group privileged myclusteradmingroup --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "" >> config-ose.sh
  echo "# add additional users to the groups" >> config-ose.sh
  echo "oadm groups add-users mydevgroup1 dev12 -n dev1project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups add-users mydevgroup1 dev13 --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups add-users mydevgroup2 dev22 -n dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups add-users mydevgroup2 dev23 -n dev2project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  echo "oadm groups add-users mydevgroup1 dev23 -n dev1project --config=$OSEPATH/openshift.local.config/master/admin.kubeconfig" >> config-ose.sh
  chmod +x config-ose.sh
  echo ""

  echo "creating config-ose-prod.sh..."
  echo "# create groups" > config-ose-prod.sh
  echo "oadm groups new myclusteradmingroup admin" >> config-ose-prod.sh
  echo "oadm groups new mystorageadmingroup screeley" >> config-ose-prod.sh
  echo "" >> config-ose-prod.sh
  echo "# add policy roles to groups" >> config-ose-prod.sh
  echo "oadm policy add-cluster-role-to-group cluster-admin myclusteradmingroup" >> config-ose-prod.sh
  echo "oadm policy add-cluster-role-to-group storage-admin mystorageadmingroup" >> config-ose-prod.sh
  echo "oadm policy add-role-to-user basic-user jdoe -n default" >> config-ose-prod.sh
  echo "oadm policy add-role-to-user view jdoe -n default" >> config-ose-prod.sh
  echo "oadm policy add-role-to-user edit jdoe -n default" >> config-ose-prod.sh
  echo "" >> config-ose-prod.sh
  echo "# add some scc policy as well" >> config-ose-prod.sh
  echo "oadm policy add-scc-to-group privileged myclusteradmingroup" >> config-ose-prod.sh
  # if [ "$ISCLOUD" == "aws" ]
  # then
  #   echo "" >> config-ose-prod.sh
  #   echo "echo AWS_ACCESS_KEY_ID=$AWSKEY >> /etc/sysconfig/atomic-openshift-master" >> config-ose-prod.sh
  #   echo "echo AWS_SECRET_ACCESS_KEY=$AWSSECRET >> /etc/sysconfig/atomic-openshift-master" >> config-ose-prod.sh
  #   echo "echo AWS_ACCESS_KEY_ID=$AWSKEY >> /etc/sysconfig/atomic-openshift-node" >> config-ose-prod.sh
  #   echo "echo AWS_SECRET_ACCESS_KEY=$AWSSECRET >> /etc/sysconfig/atomic-openshift-node" >> config-ose-prod.sh
  # fi
  chmod +x config-ose-prod.sh
  echo ""

  echo "...creating start-ose.sh"
  mkdir -p $OSEPATH/data
  echo "$SUDO rm -rf /usr/bin/kube*" > start-ose.sh
  cd $OSEPATH

  if [ "$ISCLOUD" == "aws" ]
  then
    echo "openshift start --write-config=$OSEPATH/openshift.local.config --public-master=$INTERNALHOST --volume-dir=~/data --loglevel=4  &> openshift.log" >> start-ose.sh
    echo "sed -i '/apiServerArguments:/,+5d' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i '/  apiLevels: null/a \ \ apiServerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/aws/aws.conf\"\n\ \ \ \ storage-backend:\n\ \ \ \ \ - \"etcd3\"\n\ \ \ \ storage-media-type:\n\ \ \ \ \ - \"application/vnd.kubernetes.protobuf\"\n\ \ controllerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"aws\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ \ - \"/etc/aws/aws.conf\"' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i 's/\ \ ingressIPNetworkCIDR:.*/\ \ ingressIPNetworkCIDR: ""/' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "echo \"kubeletArguments:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-provider:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"aws\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-config:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"/etc/aws/aws.conf\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "" >> start-ose.sh
    echo "openshift start --master-config=$OSEPATH/openshift.local.config/master/master-config.yaml --node-config=$OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml --loglevel=5 &> openshift.log" >> start-ose.sh
  elif [ "$ISCLOUD" == "gce" ]
  then
    echo "openshift start --write-config=$OSEPATH/openshift.local.config --public-master=$INTERNALHOST --volume-dir=~/data --loglevel=4  &> openshift.log" >> start-ose.sh
    echo "sed -i '/apiServerArguments: null/,+2d' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i '/  apiLevels: null/a \ \ apiServerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"gce\"\n\ \ \ \ storage-backend:\n\ \ \ \ \ - \"etcd3\"\n\ \ \ \ storage-media-type:\n\ \ \ \ \ - \"application/vnd.kubernetes.protobuf\"\n\ \ controllerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"gce\"' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i 's/\ \ ingressIPNetworkCIDR:.*/\ \ ingressIPNetworkCIDR: ""/' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "echo \"kubeletArguments:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST.$GCENODEPATH/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-provider:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST.$GCENODEPATH/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"gce\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST.$GCENODEPATH/node-config.yaml" >> start-ose.sh
    echo "" >> start-ose.sh
    echo "openshift start --master-config=$OSEPATH/openshift.local.config/master/master-config.yaml --node-config=$OSEPATH/openshift.local.config/node-$INTERNALHOST.$GCENODEPATH/node-config.yaml --loglevel=5 &> openshift.log" >> start-ose.sh    
  elif [ "$ISCLOUD" == "vsphere" ]
  then
    echo "openshift start --write-config=$OSEPATH/openshift.local.config --public-master=$INTERNALHOST --volume-dir=~/data --loglevel=4  &> openshift.log" >> start-ose.sh
    echo "sed -i '/apiServerArguments:/,+5d' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i '/  apiLevels: null/a \ \ apiServerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"vsphere\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ - \"/etc/vsphere/vsphere.conf\"\n\ \ \ \ storage-backend:\n\ \ \ \ \ - \"etcd3\"\n\ \ \ \ storage-media-type:\n\ \ \ \ \ - \"application/vnd.kubernetes.protobuf\"\n\ \ controllerArguments:\n\ \ \ \ cloud-provider:\n\ \ \ \ \ \ - \"vsphere\"\n\ \ \ \ cloud-config:\n\ \ \ \ \ \ - \"/etc/vsphere/vsphere.conf\"' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "sed -i 's/\ \ ingressIPNetworkCIDR:.*/\ \ ingressIPNetworkCIDR: ""/' $OSEPATH/openshift.local.config/master/master-config.yaml> /dev/null" >> start-ose.sh
    echo "echo \"kubeletArguments:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    # echo "echo \"  max-pods:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    # echo "echo \"    - \\\'100\\\'\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-provider:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"vsphere\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"  cloud-config:\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "echo \"    - \\\"/etc/vsphere/vsphere.conf\\\"\" >> $OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml" >> start-ose.sh
    echo "" >> start-ose.sh
    echo "openshift start --master-config=$OSEPATH/openshift.local.config/master/master-config.yaml --node-config=$OSEPATH/openshift.local.config/node-$INTERNALHOST/node-config.yaml --loglevel=5 &> openshift.log" >> start-ose.sh
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
  echo "cd $OSEPATH; sudo rm -rf openshift.local.*" >> stop-ose.sh
  echo "# remove the file below if you are switching between kube and ocp" >> stop-ose.sh
  echo "# sudo rm -rf ~/.kube/" >> stop-ose.sh
  chmod +x stop-ose.sh
  echo ""

  #TODO: incorporate this for kube-up-local.sh (hyperconverged kube)
  ## This is for the kube-up-local.sh which" > clean-k8.sh
  ## creates a functioning all in one cluster" >> clean-k8.sh
  ## hyperconverged - running Docker

  ## kill all services
  #kubectl delete services --all"
  #kubectl delete rc --all"
  #kubectl delete pods --all"

  ## kill all docker containers
  #sudo docker ps | awk 'index($NF,k8s_)==1 { print $1 }' | xargs -l -r sudo docker stop"

  ## undo all mounts
  # mount | grep openshift.local.volumes | awk '{ print $3}' | xargs -l -r sudo umount"
  # mount | grep nfs1.rhs | awk '{ print }' | xargs -l -r sudo umount"


  # TODO: maybe create a start-k8.sh script so we can pass in params
  # i.e.  ALLOW_PRIVILEGED=true ALLOW_SECURITY_CONTEXT=true hack/local-up-cluster.sh  


  if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
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
  # TODO:
  #cp $KUBEPATH/clean-hyperkube.sh $GOLANGPATH

}

CreateTestYamlEC2()
{
  cd $GOLANGPATH/dev-configs/aws
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

  echo "kind: StorageClass" > aws-storage-class1.yaml
  echo "apiVersion: storage.k8s.io/v1beta1" >> aws-storage-class1.yaml
  echo "metadata:" >> aws-storage-class1.yaml
  echo "  name: slow" >> aws-storage-class1.yaml
  echo "provisioner: kubernetes.io/aws-ebs" >> aws-storage-class1.yaml
  echo "parameters:" >> aws-storage-class1.yaml
  echo "  type: gp2" >> aws-storage-class1.yaml
  echo "  zone: us-east-1d" >> aws-storage-class1.yaml

  echo "apiVersion: v1" > aws-pvc-storage-class.yaml
  echo "kind: PersistentVolumeClaim" >> aws-pvc-storage-class.yaml
  echo "metadata:" >> aws-pvc-storage-class.yaml
  echo " name: ebs-claim" >> aws-pvc-storage-class.yaml
  echo " annotations:" >> aws-pvc-storage-class.yaml
  echo "   volume.beta.kubernetes.io/storage-class: slow" >> aws-pvc-storage-class.yaml
  echo "spec:" >> aws-pvc-storage-class.yaml
  echo " accessModes:" >> aws-pvc-storage-class.yaml
  echo "  - ReadWriteOnce" >> aws-pvc-storage-class.yaml
  echo " resources:" >> aws-pvc-storage-class.yaml
  echo "   requests:" >> aws-pvc-storage-class.yaml
  echo "     storage: 5Gi" >> aws-pvc-storage-class.yaml

  echo "apiVersion: v1" > aws-pv-storageclass.yaml
  echo "kind: PersistentVolume" >> aws-pv-storageclass.yaml
  echo "metadata:" >> aws-pv-storageclass.yaml
  echo " name: silver.east" >> aws-pv-storageclass.yaml
  echo " annotations:" >> aws-pv-storageclass.yaml
  echo "   volume.beta.kubernetes.io/storage-class: silver.east" >> aws-pv-storageclass.yaml
  echo "spec:" >> aws-pv-storageclass.yaml
  echo " capacity:" >> aws-pv-storageclass.yaml
  echo "   storage: 10Gi" >> aws-pv-storageclass.yaml
  echo " accessModes:" >> aws-pv-storageclass.yaml
  echo "   - ReadWriteOnce" >> aws-pv-storageclass.yaml
  echo " awsElasticBlockStore:" >> aws-pv-storageclass.yaml
  echo "   volumeID: vol-26eaa981" >> aws-pv-storageclass.yaml
  echo "   fsType: ext4" >> aws-pv-storageclass.yaml

  echo "apiVersion: v1" > aws-pvc-storageclass.yaml
  echo "kind: PersistentVolumeClaim" >> aws-pvc-storageclass.yaml
  echo "metadata:" >> aws-pvc-storageclass.yaml
  echo " name: ebs-claim-silver" >> aws-pvc-storageclass.yaml
  echo " annotations:" >> aws-pvc-storageclass.yaml
  echo "   volume.beta.kubernetes.io/storage-class: silver.east" >> aws-pvc-storageclass.yaml
  echo "spec:" >> aws-pvc-storageclass.yaml
  echo " accessModes:" >> aws-pvc-storageclass.yaml
  echo "  - ReadWriteOnce" >> aws-pvc-storageclass.yaml
  echo " resources:" >> aws-pvc-storageclass.yaml
  echo "   requests:" >> aws-pvc-storageclass.yaml
  echo "     storage: 10Gi" >> aws-pvc-storageclass.yaml


  cd $GOLANGPATH/dev-configs/gce
  echo "apiVersion: v1" > busybox-gce.yaml
  echo "kind: Pod" >> busybox-gce.yaml
  echo "metadata:"  >> busybox-gce.yaml
  echo "  name: gce-bb-pod1"  >> busybox-gce.yaml
  echo "spec:"  >> busybox-gce.yaml
  echo "  containers:"  >> busybox-gce.yaml
  echo "  - name: gce-bb-pod1"  >> busybox-gce.yaml
  echo "    image: busybox"  >> busybox-gce.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-gce.yaml
  echo "    volumeMounts:"  >> busybox-gce.yaml
  echo "    - mountPath: /usr/share/busybox"  >> busybox-gce.yaml
  echo "      name: gcevol"  >> busybox-gce.yaml
  echo "  volumes:"  >> busybox-gce.yaml
  echo "  - name: gcevol"  >> busybox-gce.yaml
  echo "    gcePersistentDisk:"  >> busybox-gce.yaml
  echo "      readOnly: false" >> busybox-gce.yaml
  echo "      pdName: yourdisk"  >> busybox-gce.yaml
  echo "      fsType: ext4"  >> busybox-gce.yaml

  echo "apiVersion: v1" > gce-pv.yaml
  echo "kind: PersistentVolume" >> gce-pv.yaml
  echo "metadata:" >> gce-pv.yaml
  echo " name: pv-gce" >> gce-pv.yaml
  echo "spec:" >> gce-pv.yaml
  echo " capacity:" >> gce-pv.yaml
  echo "   storage: 1Gi" >> gce-pv.yaml
  echo " accessModes:" >> gce-pv.yaml
  echo "   - ReadWriteOnce" >> gce-pv.yaml
  echo " gcePersistentDisk:" >> gce-pv.yaml
  echo "   readOnly: false" >> gce-pv.yaml
  echo "   pdName: yourdisk" >> gce-pv.yaml
  echo "   fsType: ext4" >> gce-pv.yaml


  echo "apiVersion: v1" > gce-pvc.yaml
  echo "kind: PersistentVolumeClaim" >> gce-pvc.yaml
  echo "metadata:" >> gce-pvc.yaml
  echo " name: gce-claim" >> gce-pvc.yaml
  echo "spec:" >> gce-pvc.yaml
  echo " accessModes:" >> gce-pvc.yaml
  echo "  - ReadWriteOnce" >> gce-pvc.yaml
  echo " resources:" >> gce-pvc.yaml
  echo "   requests:" >> gce-pvc.yaml
  echo "     storage: 1Gi" >> gce-pvc.yaml

  echo "apiVersion: v1" > busybox-gce-pvc.yaml
  echo "kind: Pod" >> busybox-gce-pvc.yaml
  echo "metadata:" >> busybox-gce-pvc.yaml
  echo "  name: gce-bb-pod2" >> busybox-gce-pvc.yaml
  echo "spec:" >> busybox-gce-pvc.yaml
  echo "  containers:" >> busybox-gce-pvc.yaml
  echo "  - name: gce-bb-pod2" >> busybox-gce-pvc.yaml
  echo "    image: busybox" >> busybox-gce-pvc.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-gce-pvc.yaml
  echo "    volumeMounts:" >> busybox-gce-pvc.yaml
  echo "    - mountPath: /usr/share/busybox" >> busybox-gce-pvc.yaml
  echo "      name: gcevol" >> busybox-gce-pvc.yaml
  echo "  volumes:" >> busybox-gce-pvc.yaml
  echo "    - name: gcevol" >> busybox-gce-pvc.yaml
  echo "      persistentVolumeClaim:" >> busybox-gce-pvc.yaml
  echo "        claimName: gce-claim" >> busybox-gce-pvc.yaml

  echo "kind: StorageClass" > gce-storage-class1.yaml
  echo "apiVersion: storage.k8s.io/v1beta1" >> gce-storage-class1.yaml
  echo "metadata:" >> gce-storage-class1.yaml
  echo "  name: slow" >> gce-storage-class1.yaml
  echo "provisioner: kubernetes.io/gce-pd" >> gce-storage-class1.yaml
  echo "parameters:" >> gce-storage-class1.yaml
  echo "  type: pd-standard" >> gce-storage-class1.yaml
  echo "  zone: us-central1-a" >> gce-storage-class1.yaml

  echo "apiVersion: v1" > gce-pvc-storage-class.yaml
  echo "kind: PersistentVolumeClaim" >> gce-pvc-storage-class.yaml
  echo "metadata:" >> gce-pvc-storage-class.yaml
  echo " name: gce-claim-storageclass" >> gce-pvc-storage-class.yaml
  echo " annotations:" >> gce-pvc-storage-class.yaml
  echo "   volume.beta.kubernetes.io/storage-class: slow" >> gce-pvc-storage-class.yaml
  echo "spec:" >> gce-pvc-storage-class.yaml
  echo " accessModes:" >> gce-pvc-storage-class.yaml
  echo "  - ReadWriteOnce" >> gce-pvc-storage-class.yaml
  echo " resources:" >> gce-pvc-storage-class.yaml
  echo "   requests:" >> gce-pvc-storage-class.yaml
  echo "     storage: 5Gi" >> gce-pvc-storage-class.yaml

  cd $GOLANGPATH/dev-configs/nfs
  echo "apiVersion: v1" > busybox-nfs.yaml
  echo "kind: Pod" >> busybox-nfs.yaml
  echo "metadata:"  >> busybox-nfs.yaml
  echo "  name: nfs-bb-pod1"  >> busybox-nfs.yaml
  echo "spec:"  >> busybox-nfs.yaml
  echo "  containers:"  >> busybox-nfs.yaml
  echo "  - name: nfs-bb-pod1"  >> busybox-nfs.yaml
  echo "    image: busybox"  >> busybox-nfs.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-nfs.yaml
  echo "    volumeMounts:"  >> busybox-nfs.yaml
  echo "    - mountPath: /usr/share/busybox"  >> busybox-nfs.yaml
  echo "      name: nfsvol"  >> busybox-nfs.yaml
  echo "  volumes:"  >> busybox-nfs.yaml
  echo "  - name: nfsvol"  >> busybox-nfs.yaml
  echo "    nfs:"  >> busybox-nfs.yaml
  echo "      path: /opt/data12" >> busybox-nfs.yaml
  echo "      server: nfs1.rhs"  >> busybox-nfs.yaml

  echo "apiVersion: v1" > nfs-pv.yaml
  echo "kind: PersistentVolume" >> nfs-pv.yaml
  echo "metadata:" >> nfs-pv.yaml
  echo " name: pv-nfs" >> nfs-pv.yaml
  echo "spec:" >> nfs-pv.yaml
  echo " capacity:" >> nfs-pv.yaml
  echo "   storage: 1Gi" >> nfs-pv.yaml
  echo " accessModes:" >> nfs-pv.yaml
  echo "   - ReadWriteOnce" >> nfs-pv.yaml
  echo " nfs:" >> nfs-pv.yaml
  echo "   path: /opt/data12" >> nfs-pv.yaml
  echo "   server: nfs1.rhs" >> nfs-pv.yaml
  echo " persistentVolumeReclaimPolicy: Retain" >> nfs-pv.yaml

  echo "apiVersion: v1" > nfs-pv-gid.yaml
  echo "kind: PersistentVolume" >> nfs-pv-gid.yaml
  echo "metadata:" >> nfs-pv-gid.yaml
  echo " annotations:" >> nfs-pv-gid.yaml
  echo "  pv.beta.kubernetes.io/gid: \"1234\"" >> nfs-pv-gid.yaml
  echo " name: pv-nfs" >> nfs-pv-gid.yaml
  echo "spec:" >> nfs-pv-gid.yaml
  echo " capacity:" >> nfs-pv-gid.yaml
  echo "   storage: 1Gi" >> nfs-pv-gid.yaml
  echo " accessModes:" >> nfs-pv-gid.yaml
  echo "   - ReadWriteOnce" >> nfs-pv-gid.yaml
  echo " nfs:" >> nfs-pv-gid.yaml
  echo "   path: /opt/data12" >> nfs-pv-gid.yaml
  echo "   server: nfs1.rhs" >> nfs-pv-gid.yaml
  echo " persistentVolumeReclaimPolicy: Retain" >> nfs-pv-gid.yaml

  echo "apiVersion: v1" > nfs-pvc.yaml
  echo "kind: PersistentVolumeClaim" >> nfs-pvc.yaml
  echo "metadata:" >> nfs-pvc.yaml
  echo " name: nfs-claim" >> nfs-pvc.yaml
  echo "spec:" >> nfs-pvc.yaml
  echo " accessModes:" >> nfs-pvc.yaml
  echo "  - ReadWriteOnce" >> nfs-pvc.yaml
  echo " resources:" >> nfs-pvc.yaml
  echo "   requests:" >> nfs-pvc.yaml
  echo "     storage: 1Gi" >> nfs-pvc.yaml

  echo "apiVersion: v1" > busybox-nfs-pvc.yaml
  echo "kind: Pod" >> busybox-nfs-pvc.yaml
  echo "metadata:" >> busybox-nfs-pvc.yaml
  echo "  name: nfs-bb-pod2" >> busybox-nfs-pvc.yaml
  echo "spec:" >> busybox-nfs-pvc.yaml
  echo "  containers:" >> busybox-nfs-pvc.yaml
  echo "  - name: nfs-bb-pod2" >> busybox-nfs-pvc.yaml
  echo "    image: busybox" >> busybox-nfs-pvc.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-nfs-pvc.yaml
  echo "    volumeMounts:" >> busybox-nfs-pvc.yaml
  echo "    - mountPath: /usr/share/busybox" >> busybox-nfs-pvc.yaml
  echo "      name: nfsvol" >> busybox-nfs-pvc.yaml
  echo "  volumes:" >> busybox-nfs-pvc.yaml
  echo "    - name: nfsvol" >> busybox-nfs-pvc.yaml
  echo "      persistentVolumeClaim:" >> busybox-nfs-pvc.yaml
  echo "        claimName: nfs-claim" >> busybox-nfs-pvc.yaml

  cd $GOLANGPATH/dev-configs/glusterfs
  echo "apiVersion: v1" > glusterfs-endpoints.yaml
  echo "kind: Endpoints" >> glusterfs-endpoints.yaml
  echo "metadata:" >> glusterfs-endpoints.yaml
  echo " name: glusterfs-cluster" >> glusterfs-endpoints.yaml
  echo "subsets:" >> glusterfs-endpoints.yaml
  echo " - addresses:" >> glusterfs-endpoints.yaml
  echo "   - ip: 192.168.1.200" >> glusterfs-endpoints.yaml
  echo "   ports:" >> glusterfs-endpoints.yaml
  echo "   - port: 1" >> glusterfs-endpoints.yaml
  echo "     protocol: TCP" >> glusterfs-endpoints.yaml
  echo " - addresses:" >> glusterfs-endpoints.yaml
  echo "   - ip: 192.168.1.201" >> glusterfs-endpoints.yaml
  echo "   ports:" >> glusterfs-endpoints.yaml
  echo "   - port: 1" >> glusterfs-endpoints.yaml
  echo "     protocol: TCP" >> glusterfs-endpoints.yaml

  echo "apiVersion: v1" > busybox-glusterfs.yaml
  echo "kind: Pod" >> busybox-glusterfs.yaml
  echo "metadata:"  >> busybox-glusterfs.yaml
  echo "  name: glusterfs-bb-pod1"  >> busybox-glusterfs.yaml
  echo "spec:"  >> busybox-glusterfs.yaml
  echo "  containers:"  >> busybox-glusterfs.yaml
  echo "  - name: glusterfs-bb-pod1"  >> busybox-glusterfs.yaml
  echo "    image: busybox"  >> busybox-glusterfs.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-glusterfs.yaml
  echo "    volumeMounts:"  >> busybox-glusterfs.yaml
  echo "    - mountPath: /usr/share/busybox"  >> busybox-glusterfs.yaml
  echo "      name: glusterfsvol"  >> busybox-glusterfs.yaml
  echo "  volumes:"  >> busybox-glusterfs.yaml
  echo "  - name: glusterfsvol"  >> busybox-glusterfs.yaml
  echo "    glusterfs:"  >> busybox-glusterfs.yaml
  echo "      endpoints: glusterfs-cluster" >> busybox-glusterfs.yaml
  echo "      path: myVol1" >> busybox-glusterfs.yaml
  echo "      readOnly: false" >> busybox-glusterfs.yaml

  echo "apiVersion: v1" > glusterfs-pv.yaml
  echo "kind: PersistentVolume" >> glusterfs-pv.yaml
  echo "metadata:" >> glusterfs-pv.yaml
  echo " name: pv-gce" >> glusterfs-pv.yaml
  echo "spec:" >> glusterfs-pv.yaml
  echo " capacity:" >> glusterfs-pv.yaml
  echo "   storage: 1Gi" >> glusterfs-pv.yaml
  echo " accessModes:" >> glusterfs-pv.yaml
  echo "   - ReadWriteMany" >> glusterfs-pv.yaml
  echo " glusterfs:" >> glusterfs-pv.yaml
  echo "   endpoints: glusterfs-cluster" >> glusterfs-pv.yaml
  echo "   path: myVol1" >> glusterfs-pv.yaml
  echo "   readOnly: false" >> glusterfs-pv.yaml
  echo " persistentVolumeReclaimPolicy: Retain" >> glusterfs-pv.yaml

  echo "apiVersion: v1" > glusterfs-pvc.yaml
  echo "kind: PersistentVolumeClaim" >> glusterfs-pvc.yaml
  echo "metadata:" >> glusterfs-pvc.yaml
  echo " name: glusterfs-claim" >> glusterfs-pvc.yaml
  echo "spec:" >> glusterfs-pvc.yaml
  echo " accessModes:" >> glusterfs-pvc.yaml
  echo "  - ReadWriteMany" >> glusterfs-pvc.yaml
  echo " resources:" >> glusterfs-pvc.yaml
  echo "   requests:" >> glusterfs-pvc.yaml
  echo "     storage: 1Gi" >> glusterfs-pvc.yaml

  echo "apiVersion: v1" > busybox-glusterfs-pvc.yaml
  echo "kind: Pod" >> busybox-glusterfs-pvc.yaml
  echo "metadata:" >> busybox-glusterfs-pvc.yaml
  echo "  name: glusterfs-bb-pod2" >> busybox-glusterfs-pvc.yaml
  echo "spec:" >> busybox-glusterfs-pvc.yaml
  echo "  containers:" >> busybox-glusterfs-pvc.yaml
  echo "  - name: glusterfs-bb-pod2" >> busybox-glusterfs-pvc.yaml
  echo "    image: busybox" >> busybox-glusterfs-pvc.yaml
  echo "    command: [\"sleep\", \"600000\"]" >> busybox-glusterfs-pvc.yaml
  echo "    volumeMounts:" >> busybox-glusterfs-pvc.yaml
  echo "    - mountPath: /usr/share/busybox" >> busybox-glusterfs-pvc.yaml
  echo "      name: glusterfsvol" >> busybox-glusterfs-pvc.yaml
  echo "  volumes:" >> busybox-glusterfs-pvc.yaml
  echo "    - name: glusterfsvol" >> busybox-glusterfs-pvc.yaml
  echo "      persistentVolumeClaim:" >> busybox-glusterfs-pvc.yaml
  echo "        claimName: glusterfs-claim" >> busybox-glusterfs-pvc.yaml

  echo "apiVersion: v1" > nginx-glusterfs-pvc.yaml
  echo "kind: Pod" >> nginx-glusterfs-pvc.yaml
  echo "metadata:" >> nginx-glusterfs-pvc.yaml
  echo "  name: nginx-pod2" >> nginx-glusterfs-pvc.yaml
  echo "spec:" >> nginx-glusterfs-pvc.yaml
  echo "  containers:" >> nginx-glusterfs-pvc.yaml
  echo "    - name: nginx-pod2" >> nginx-glusterfs-pod1.yaml
  echo "      image: nginx" >> nginx-glusterfs-pod1.yaml
  echo "      ports:" >> nginx-glusterfs-pod1.yaml
  echo "        - name: web" >> nginx-glusterfs-pod1.yaml
  echo "          containerPort: 80" >> nginx-glusterfs-pod1.yaml
  echo "    volumeMounts:" >> nginx-glusterfs-pvc.yaml
  echo "    - mountPath: /usr/share/busybox/html/test" >> nginx-glusterfs-pvc.yaml
  echo "      name: glusterfsvol" >> nginx-glusterfs-pvc.yaml
  echo "  volumes:" >> nginx-glusterfs-pvc.yaml
  echo "    - name: glusterfsvol" >> nginx-glusterfs-pvc.yaml
  echo "      persistentVolumeClaim:" >> nginx-glusterfs-pvc.yaml
  echo "        claimName: glusterfs-claim" >> nginx-glusterfs-pvc.yaml

  echo "kind: Service" > glusterfs-service.yaml
  echo "apiVersion: v1" >> glusterfs-service.yaml
  echo "metadata:" >> glusterfs-service.yaml
  echo "  name: glusterfs-cluster" >> glusterfs-service.yaml
  echo "spec:" >> glusterfs-service.yaml
  echo "  ports:" >> glusterfs-service.yaml
  echo "  - port: 1" >> glusterfs-service.yaml

  echo "apiVersion: v1" > nginx-glusterfs-pod1.yaml
  echo "kind: Pod" >> nginx-glusterfs-pod1.yaml
  echo "metadata:" >> nginx-glusterfs-pod1.yaml
  echo "  name: nginx-pod1" >> nginx-glusterfs-pod1.yaml
  echo "  labels:" >> nginx-glusterfs-pod1.yaml
  echo "    name: nginx-pod1" >> nginx-glusterfs-pod1.yaml
  echo "spec:" >> nginx-glusterfs-pod1.yaml
  echo "  containers:" >> nginx-glusterfs-pod1.yaml
  echo "    - name: nginx-pod1" >> nginx-glusterfs-pod1.yaml
  echo "      image: nginx" >> nginx-glusterfs-pod1.yaml
  echo "      ports:" >> nginx-glusterfs-pod1.yaml
  echo "        - name: web" >> nginx-glusterfs-pod1.yaml
  echo "          containerPort: 80" >> nginx-glusterfs-pod1.yaml
  echo "      volumeMounts:" >> nginx-glusterfs-pod1.yaml
  echo "        - name: glustervol" >> nginx-glusterfs-pod1.yaml
  echo "          mountPath: /usr/share/nginx/html/test" >> nginx-glusterfs-pod1.yaml
  echo "      securityContext:" >> nginx-glusterfs-pod1.yaml
  echo "        supplementalGroups: [10003]" >> nginx-glusterfs-pod1.yaml
  echo "        privileged: true" >> nginx-glusterfs-pod1.yaml
  echo "  volumes:" >> nginx-glusterfs-pod1.yaml
  echo "    - name: glustervol" >> nginx-glusterfs-pod1.yaml
  echo "      glusterfs:" >> nginx-glusterfs-pod1.yaml
  echo "        endpoints: glusterfs-cluster" >> nginx-glusterfs-pod1.yaml
  echo "        path: myVol1" >> nginx-glusterfs-pod1.yaml
  echo "        readOnly: false" >> nginx-glusterfs-pod1.yaml

  echo "kind: StorageClass" > glusterfs-storageclass-v34.yaml
  echo "apiVersion: storage.k8s.io/v1beta1" >> glusterfs-storageclass-v34.yaml
  echo "metadata:" >> glusterfs-storageclass-v34.yaml
  echo "  name: gluster34" >> glusterfs-storageclass-v34.yaml
  echo "provisioner: kubernetes.io/glusterfs" >> glusterfs-storageclass-v34.yaml
  echo "parameters:" >> glusterfs-storageclass-v34.yaml
  echo "  endpoint: \"glusterfs-cluster\"" >> glusterfs-storageclass-v34.yaml  
  echo "  resturl: \"http://glusterclient2.rhs:8080\"" >> glusterfs-storageclass-v34.yaml  
  echo "  restauthenabled: \"false\"" >> glusterfs-storageclass-v34.yaml  
  echo "  restuser: \"admin\"" >> glusterfs-storageclass-v34.yaml  
  echo "  restuserkey: \"My Secret\"" >> glusterfs-storageclass-v34.yaml

  echo "kind: StorageClass" > glusterfs-storageclass-v35.yaml
  echo "apiVersion: storage.k8s.io/v1beta1" >> glusterfs-storageclass-v35.yaml
  echo "metadata:" >> glusterfs-storageclass-v35.yaml
  echo "  name: gluster35" >> glusterfs-storageclass-v35.yaml
  echo "provisioner: kubernetes.io/glusterfs" >> glusterfs-storageclass-v35.yaml
  echo "parameters:" >> glusterfs-storageclass-v35.yaml
  echo "  resturl: \"http://glusterclient2:8080\"" >> glusterfs-storageclass-v35.yaml  
  echo "  restauthenabled: \"false\"" >> glusterfs-storageclass-v35.yaml  
  echo "  # volumetype: \"replicate:2\"" >> glusterfs-storageclass-v35.yaml  

  echo "kind: StorageClass" > glusterfs-storageclass-v36.yaml
  echo "apiVersion: storage.k8s.io/v1beta1" >> glusterfs-storageclass-v36.yaml
  echo "metadata:" >> glusterfs-storageclass-v36.yaml
  echo "  name: slow" >> glusterfs-storageclass-v36.yaml
  echo "provisioner: kubernetes.io/glusterfs" >> glusterfs-storageclass-v36.yaml
  echo "parameters:" >> glusterfs-storageclass-v36.yaml  
  echo "  resturl: \"http://glusterclient2:8080\"" >> glusterfs-storageclass-v36.yaml  
  echo "  restauthenabled: \"false\"" >> glusterfs-storageclass-v36.yaml  
  echo "  volumetype: \"replicate:2\"" >> glusterfs-storageclass-v36.yaml

  echo "apiVersion: v1" > glusterfs-pvc-storageclass.yaml
  echo "kind: PersistentVolumeClaim" >> glusterfs-pvc-storageclass.yaml
  echo "metadata:" >> glusterfs-pvc-storageclass.yaml
  echo " name: gluster-dyn-pvc" >> glusterfs-pvc-storageclass.yaml
  echo " annotations:" >> glusterfs-pvc-storageclass.yaml
  echo "   volume.beta.kubernetes.io/storage-class: gluster35" >> glusterfs-pvc-storageclass.yaml
  echo "spec:" >> glusterfs-pvc-storageclass.yaml
  echo " accessModes:" >> glusterfs-pvc-storageclass.yaml
  echo "  - ReadWriteOnce" >> glusterfs-pvc-storageclass.yaml
  echo " resources:" >> glusterfs-pvc-storageclass.yaml
  echo "   requests:" >> glusterfs-pvc-storageclass.yaml
  echo "     storage: 30Gi" >> glusterfs-pvc-storageclass.yaml


  cp -R $GOLANGPATH/dev-configs/* $OSEPATH/dev-configs
  cp -R $GOLANGPATH/dev-configs/* $KUBEPATH/dev-configs


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
echo "   -golang and configure GOPATH"
echo "   -github source repos"
echo "   -if cloud - aws cli and configurations or gce sdk"
echo "   -working directory structures"
echo "   -sample yaml for aws, gce, nfs and gluster"
echo "   -docker from yum and docker registry configuration"
echo "   -and misc tools and configuration scripts to help run the projects"
echo ""

# if [ "$DIDRUN" == "yes" ] || [ -f "$GOLANGPATH/didrun" ] || [ -f /root/didrun ] || [ -f ~/didrun ]
if [ -f "$GOLANGPATH/didrun" ] || [ -f /root/didrun ] || [ -f ~/didrun ]
then
  echo " Skipping subscription services and yum install of software as this script was run once already..."
  echo ""
else
  if [ "$ISCLOUD" == "gce" ] || [ "$ISCLOUD" == "aws" ]
  then
    if [ "$HOSTENV" == "rhel" ]
    then
      # Installing subscription manager on CLOUD INSTANCE
      echo "...Checking to make sure subscription manager is installed..."
      $SUDO yum install subscription-manager -y> /dev/null
    fi
  fi

  if [ "$HOSTENV" == "rhel" ]
  then
    # Subscription Manager Stuffs - for RHEL 7.X devices
    echo "Setting up subscription services from RHEL..."
    $SUDO subscription-manager register --username=$RHNUSER --password=$RHNPASS
  fi

  if [ "$SETUP_TYPE" == "dev" ] || [ "$SETUP_TYPE" == "kubeadm" ] || [ "$SETUP_TYPE" == "kubeadm15" ]
  then
    if [ "$HOSTENV" == "rhel" ] && [ "$POOLID" == "" ]
    then
        $SUDO subscription-manager list --available | sed -n '/OpenShift Employee Subscription/,/Pool ID/p' | sed -n '/Pool ID/ s/.*\://p' | sed -e 's/^[ \t]*//' | xargs -i{} $SUDO subscription-manager attach --pool={}
        $SUDO subscription-manager list --available | sed -n '/OpenShift Container Platform/,/Pool ID/p' | sed -n '/Pool ID/ s/.*\://p' | sed -e 's/^[ \t]*//' | xargs -i{} $SUDO subscription-manager attach --pool={}
    elif [ "$HOSTENV" == "rhel" ]
    then
      echo "Using Predefined POOLID..."
      $SUDO subscription-manager attach --pool=$POOLID
    else
      echo "..."
    fi 
  fi

  if [ "$SETUP_TYPE" == "aplo" ]
  then
    if [ "$HOSTENV" == "rhel" ] && [ "$POOLID" == "" ]
    then
      # FOR APLO
      $SUDO subscription-manager list --available | sed -n '/OpenShift Container Platform/,/Pool ID/p' | sed -n '/Pool ID/ s/.*\://p' | sed -e 's/^[ \t]*//' | xargs -i{} $SUDO subscription-manager attach --pool={}
    elif [ "$HOSTENV" == "rhel" ]
    then
      $SUDO subscription-manager attach --pool=$POOLID
    else
      echo "..."
    fi
  fi

  if [ "$HOSTENV" == "rhel" ]
  then
    # FOR ALL
    if [ "$OCPVERSION" == "3.5" ]
    then
      echo "Enabling rhel 7 rpms..."
      $SUDO subscription-manager repos --disable="*"> /dev/null
      $SUDO subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.5-rpms" --enable="rhel-7-fast-datapath-rpms" --enable="rh-gluster-3-for-rhel-7-server-rpms"> /dev/null
      echo ""
    elif [ "$OCPVERSION" == "3.4" ]
    then
      echo "Enabling rhel 7 rpms..."
      $SUDO subscription-manager repos --disable="*"> /dev/null
      $SUDO subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.4-rpms" --enable="rh-gluster-3-for-rhel-7-server-rpms"> /dev/null
      echo ""
    else
      echo "Enabling rhel 7 rpms..."
      $SUDO subscription-manager repos --disable="*"> /dev/null
      $SUDO subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.5-rpms" --enable="rhel-7-fast-datapath-rpms" --enable="rh-gluster-3-for-rhel-7-server-rpms"> /dev/null
      echo ""
    fi
  fi

  # Install software
  if [ "$SETUP_TYPE" == "dev" ] || [ "$SETUP_TYPE" == "aplo" ]
  then  
    echo "...Installing wget, git, net-tools, bind-utils, iptables-services, rpcbind, nfs-utils, glusterfs-client bridge-utils, gcc, python-virtualenv, bash-completion telnet unzip ... this will take several minutes"
    $SUDO yum install wget git net-tools bind-utils iptables-services rpcbind nfs-utils glusterfs-client bridge-utils gcc python-virtualenv bash-completion telnet unzip -y> /dev/null
    $SUDO yum update -y> /dev/null
    if [ "$HOSTENV" == "rhel" ]
    then
      if [ "$SETUP_TYPE" == "aplo" ]
      then
        echo "...Installing openshift utils, clients and atomic-openshift for APLO setup type..."
        $SUDO yum install atomic-openshift-utils atomic-openshift-clients atomic-openshift -y> /dev/null
        $SUDO yum install heketi-client heketi-templates -y> /dev/null
      else
        echo "...Installing openshift utils for DEV setup type..."
        $SUDO yum install atomic-openshift-utils -y> /dev/null
      fi
    fi
    echo ""

    # Install Go and do other config
    # 1.6.1, 1.7.3, etc...
    if [ "$GOVERSION" == "yum" ] || [ "$GOVERSION" == "" ]
    then
      echo "Installing go1.X whatever version yum installs..."
      $SUDO yum install go -y> /dev/null
    else
      echo "Installing go$GOVERSION ..."
      cd ~
      $SUDO wget https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz
      $SUDO rm -rf /usr/local/go
      $SUDO rm -rf /bin/go		
      $SUDO tar -C /usr/local -xzf go$GOVERSION.linux-amd64.tar.gz
    fi
    echo ""
    echo "Installing latest ansible..."
    $SUDO rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    $SUDO yum install ansible -y> /dev/null

    $SUDO rm -rf /usr/share/ansible
    $SUDO rm -rf /usr/share/ansible_plugins
    echo ""
  else
    if [ "$SETUP_TYPE" == "kubeadm" ] || [ "$SETUP_TYPE" == "kubeadm15" ]
    then
      echo "...Installing wget, git, net-tools, bind-utils, iptables-services, bridge-utils, gcc, python-virtualenv, bash-completion, telnet, unzip for KUBEADM setup type  ... this will take several minutes"
      $SUDO yum install wget git net-tools bind-utils iptables-services bridge-utils gcc python-virtualenv bash-completion telnet unzip -y> /dev/null
      $SUDO yum update -y> /dev/null

      # Install Go and do other config
      # 1.6.1, 1.7.3, 1.8.1, etc...
      if [ "$GOVERSION" == "yum" ] || [ "$GOVERSION" == "" ]
      then
        echo "Installing go1.X whatever version yum installs..."
        $SUDO yum install go -y> /dev/null
      else
        echo "Installing go$GOVERSION ..."
        cd ~
        $SUDO wget https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz
        $SUDO rm -rf /usr/local/go
        $SUDO rm -rf /bin/go		
        $SUDO tar -C /usr/local -xzf go$GOVERSION.linux-amd64.tar.gz
      fi
      echo ""
      echo "Installing latest ansible..."
      $SUDO rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
      $SUDO yum install ansible -y> /dev/null
      echo ""

      if [ "$SETUP_TYPE" == "kubeadm15" ]
      then
        echo "...creating Kube 1.5 Repo..."
        $SUDO echo "[kubernetes]" > /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "name=Kubernetes" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "enabled=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "repo_gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
      else      
        echo "...creating Kube 1.6 Repo..."
        $SUDO echo "[kubernetes]" > /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "name=Kubernetes" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "enabled=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "repo_gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
        $SUDO echo "       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
      fi

      if [ "$HOSTENV" == "centos" ] || [ "$HOSTENV" == "fedora" ]
      then
        echo ""
        echo "Installing glusterfs-client..."
        $SUDO yum install glusterfs-client -y> /dev/null
        $SUDO modprobe fuse
      fi

      echo ""
      echo "Disabling SELinux for now..."
      $SUDO setenforce 0

      echo ""
      if [ "$SETUP_TYPE" == "kubeadm15" ]
      then
        echo "Installing version 1.5 of kubelet, kubeadm, kubectl and kubernetes-cni..."    
        $SUDO yum install yum-versionlock kubectl-1.5.4-0 kubelet-1.5.4-0 kubernetes-cni-0.3.0.1-0.07a8a2 -y> /dev/null
        $SUDO yum install http://yum.kubernetes.io/pool/082436e6e6cad1852864438b8f98ee6fa3b86b597554720b631876db39b8ef04-kubeadm-1.6.0-0.alpha.0.2074.a092d8e0f95f52.x86_64.rpm -y> /dev/null
        $SUDO yum versionlock add kubectl kubelet kubernetes-cni kubeadm -y> /dev/null
      else
        echo "Installing latest (1.6) version of kubelet, kubeadm, kubectl and kubernetes-cni..."
        $SUDO yum install kubelet kubeadm kubectl kubernetes-cni -y> /dev/null
      fi
    else
      echo "...Installing wget, git, net-tools, bind-utils, iptables-services, bridge-utils, gcc, python-virtualenv, bash-completion, telnet, unzip for CLIENT setup type  ... this will take several minutes"
      $SUDO yum install wget git net-tools bind-utils iptables-services bridge-utils gcc python-virtualenv bash-completion telnet unzip -y> /dev/null
      $SUDO yum update -y> /dev/null
      if [ "$HOSTENV" == "rhel" ]
      then
        $SUDO yum install atomic-openshift-utils atomic-openshift-clients atomic-openshift -y> /dev/null
        $SUDO yum install heketi-client heketi-templates -y> /dev/null
      fi
      echo ""
    fi  
  fi

  # Install etcd
  if rpm -qa | grep etcd >/dev/null 2>&1
  then
    echo ""
    echo " --- etcd version info ---"
    etcd --version
    echo " -------------------------"
    echo ""
    echo "etcd is already installed...do you want to fresh install anyway with your specified version from setupvm.config? (y/n)"
    read isaccepted3
    if [ "$isaccepted3" == "$yval1" ] || [ "$isaccepted3" == "$yval2" ]
    then
      if [ "$ETCD_VER" == "default" ] || [ "$ETCD_VER" == "" ]
      then
        echo "installing default etcd per rhel repo configuration..."
        $SUDO yum remove etcd -y> /dev/null
        $SUDO rm -rf /usr/bin/etcd
        $SUDO yum install etcd -y> /dev/null
      else
        echo "installing specific etcd version - etcd-v$ETCD_VER..."
        $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz
        $SUDO rm -rf /usr/bin/etcd
        $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz
        $SUDO cp etcd-vETCD_VER-linux-amd64/etcd /usr/bin
      fi
    fi
  else
    if [ "$ETCD_VER" == "default" ] || [ "$ETCD_VER" == "" ]
    then
      echo "installing default etcd per rhel repo configuration..."
      $SUDO yum remove etcd -y> /dev/null
      $SUDO rm -rf /usr/bin/etcd
      $SUDO yum install etcd -y> /dev/null
    else
      echo "installing specific etcd version - etcd-v$ETCD_VER..."
      $SUDO wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz
      $SUDO rm -rf /usr/bin/etcd
      $SUDO tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz
      $SUDO cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin
    fi
  fi

  echo "DIDRUN" > $GOLANGPATH/didrun
  echo "DIDRUN" > ~/didrun
fi

if [ "$SETUP_TYPE" == "client" ]
then
  cd ~
  wget http://download.eng.bos.redhat.com/brewroot/packages/heketi/2.0.6/1.el7rhgs/x86_64/heketi-client-2.0.6-1.el7rhgs.x86_64.rpm
  $SUDO yum install heketi-client-2.0.6-1.el7rhgs.x86_64.rpm -y> /dev/null

  wget http://download.eng.bos.redhat.com/brewroot/packages/heketi/2.0.6/1.el7rhgs/x86_64/heketi-templates-2.0.6-1.el7rhgs.x86_64.rpm
  $SUDO yum install heketi-templates-2.0.6-1.el7rhgs.x86_64.rpm -y> /dev/null

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
  $SUDO chmod -R 777 $GOLANGPATH
fi

if [ "$SETUP_TYPE" == "dev" ]
then
  if [ "$SKIPSOURCECLONE" == "no" ]
  then
    cd $GOLANGPATH/go/src/k8s.io
    rm -rf kubernetes
    echo "...Cloning Kubernetes, OpenShift Origin, Openshift Ansible and gluster-kubernetes"
    echo ""
    git clone https://github.com/kubernetes/kubernetes.git

    if [ "$GODEFAULT" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
    then
      mkdir -p $GOLANGPATH/go/src/github.com/openshift
    else
      $SUDO mkdir -p $GOLANGPATH/go/src/github.com/openshift
      $SUDO chmod -R 777 $GOLANGPATH
    fi

    cd $GOLANGPATH/go/src/github.com/openshift
    rm -rf origin
    git clone https://github.com/openshift/origin.git
    cd $GOLANGPATH
    rm -rf openshift-ansible
    git clone https://github.com/openshift/openshift-ansible

    cd $GOLANGPATH
    rm -rf gluster-kubernetes
    https://github.com/gluster/gluster-kubernetes.git
  fi
fi
  
echo ""
echo "...Creating bash_profile and configs for user: $USER"

if [ "$GODEFAULt" == "yes" ] || [ "$GOLANGPATH" == "/home/ec2-user" ] || [ "$GOLANGPATH" == "/root" ] || [[ "$GOLANGPATH" =~ /home ]] 
then
  mkdir -p $GOLANGPATH/dev-configs
  mkdir -p $GOLANGPATH/dev-configs/aws
  mkdir -p $GOLANGPATH/dev-configs/gce
  mkdir -p $GOLANGPATH/dev-configs/nfs
  mkdir -p $GOLANGPATH/dev-configs/glusterfs
else
  $SUDO mkdir -p $GOLANGPATH/dev-configs
  $SUDO mkdir -p $GOLANGPATH/dev-configs/aws
  $SUDO mkdir -p $GOLANGPATH/dev-configs/gce
  $SUDO mkdir -p $GOLANGPATH/dev-configs/nfs
  $SUDO mkdir -p $GOLANGPATH/dev-configs/glusterfs
  $SUDO chmod -R 777 $GOLANGPATH
fi

if [ "$OSEDEFAULT" == "yes" ] || [ "$OSEPATH" == "/home/ec2-user" ] || [ "$OSEPATH" == "/root" ] || [[ "$OSEPATH" =~ /home ]] 
then
  mkdir -p $OSEPATH/dev-configs
  mkdir -p $OSEPATH/dev-configs/aws
  mkdir -p $OSEPATH/dev-configs/gce
  mkdir -p $OSEPATH/dev-configs/nfs
  mkdir -p $OSEPATH/dev-configs/glusterfs
else
  $SUDO mkdir -p $OSEPATH/dev-configs
  $SUDO mkdir -p $OSEPATH/dev-configs/aws
  $SUDO mkdir -p $OSEPATH/dev-configs/gce
  $SUDO mkdir -p $OSEPATH/dev-configs/nfs
  $SUDO mkdir -p $OSEPATH/dev-configs/glusterfs
  $SUDO chmod -R 777 $OSEPATH
fi

if [ "$KUBEDEFAULT" == "yes" ] || [ "$KUBEPATH" == "/home/ec2-user" ] || [ "$KUBEPATH" == "/root" ] || [[ "$KUBEPATH" =~ /home ]] 
then
  mkdir -p $KUBEPATH/dev-configs
  mkdir -p $KUBEPATH/dev-configs/aws
  mkdir -p $KUBEPATH/dev-configs/gce
  mkdir -p $KUBEPATH/dev-configs/nfs
  mkdir -p $KUBEPATH/dev-configs/glusterfs
else
  $SUDO mkdir -p $KUBEPATH/dev-configs
  $SUDO mkdir -p $KUBEPATH/dev-configs/aws
  $SUDO mkdir -p $KUBEPATH/dev-configs/gce
  $SUDO mkdir -p $KUBEPATH/dev-configs/nfs
  $SUDO mkdir -p $KUBEPATH/dev-configs/glusterfs
  $SUDO chmod -R 777 $KUBEPATH
fi

CreateProfiles
CreateConfigs

# Install ec2 api tools and ruby
if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
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
  $SUDO chmod -R 777 /etc/aws  
  cd /etc/aws
  echo "[Global]" > aws.conf
  # echo "multizone = $MULTIZONE" >> aws.conf
  echo "Zone = $ZONE" >> aws.conf
  cd $GOLANGPATH
  echo ""
  # TODO: create the /etc/sysconfig/atomic-openshift-master files with the keys
  #  AWS_ACCESS_KEY_ID=key
  #  AWS_SECRET_ACCESS_KEY=key



  echo "...creating gce.conf file"  
  cd /etc
  $SUDO mkdir gce
  $SUDO chmod -R 777 /etc/gce  
  cd /etc/gce
  echo "[Global]" > gce.conf
  echo "multizone = $MULTIZONE" >> gce.conf
  echo "Zone = $ZONE" >> gce.conf
  cd $GOLANGPATH
  echo ""

  # echo "Install GCE tools (gcloud)..."
  # cd /home/$USER
  # curl "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-113.0.0-linux-x86_64.tar.gz" -o "google-cloud-sdk-113.0.0-linux-x86_64.tar.gz"
  # tar -zxvf google-cloud-sdk-113.0.0-linux-x86_64.tar.gz
  # $SUDO ./google-cloud-sdk/install.sh
elif [ "$ISCLOUD" == "vsphere" ]
then
  echo "...creating vSphere conf template"
  cd /etc
  $SUDO mkdir vsphere
  $SUDO chmod -R 777 /etc/vsphere
  cd /etc/vsphere

#TODO: change to this format
#[Global]
#  user = administrator@vsphere.local
#  password = 100Root-
#  server = 10.19.114.25
#  port = 443
#  insecure-flag = true
#  datacenter = Boston
#  datastore = ose3-vmware
#  working-dir = /Boston/vm/ocp
#[Disk]
#  scsicontrollertype = pvscsi
  
  echo "[Global]" > vsphere.conf
  echo "  user = administrator@vsphere.local" >> vsphere.conf
  echo "  password = mypassword" >> vsphere.conf
  echo "  server = myipaddr" >> vsphere.conf
  echo "  port = 443" >> vsphere.conf
  echo "  insecure-flag = true" >> vsphere.conf
  echo "  datacenter = mydatacenter" >> vsphere.conf
  echo "  datastore = mydatastore" >> vsphere.conf
  echo "  working-dir=/mypath/vm/ocp" >> vsphere.conf
  echo "[Disk]" >> vsphere.conf
  echo "  scsicontrollertype = pvscsi" >> vsphere.conf
  cd $GOLANGPATH
  echo ""
fi
echo ""

# TODO: don't need to do this, just a precaution at this point
echo "disabling SELinux and Firewalls for now..."
$SUDO setenforce 0
$SUDO iptables -F
echo "...Creating some K8 yaml file directory ~/dev-configs"
cd $GOLANGPATH/dev-configs
CreateTestYamlEC2
# CreateTestYamlNFS

if [ "$ISCLOUD" == "aws" ] || [ "$ISCLOUD" == "gce" ]
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

#TODO: I might have broken this, need to test at some point
if [ -f "$GOLANGPATH/didcomplete" ]
then
  echo " Skipping docker install and config as this script was run once already..."
  echo ""
else
  if [ "$SETUP_TYPE" == "dev" ] || [ "$SETUP_TYPE" == "aplo" ]
  then
    echo "DOCKER Setup for DEV or APLO...checking if docker was already installed..."
    # TODO: determine if someone is using an AMI with docker already installed and skip
    if rpm -qa | grep docker >/dev/null 2>&1
    then
      echo "docker previously installed..."
      echo " --- docker version info ---"
      docker version
      echo " -------------------------"
      echo ""
      echo "docker is already installed...do you want to fresh install anyway with your specified version from setupvm.config? (y/n)"
      read isaccepted2
      if [ "$isaccepted2" == "$yval1" ] || [ "$isaccepted2" == "$yval2" ]
      then    
        # Removing existing docker if it exists
        $SUDO yum remove docker -y> /dev/null
        $SUDO rm -rf /usr/bin/docker

        echo "...Installing Docker"
        if [ "$DOCKERVER" == "" ] || [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "yum" ]
        then
          if [ "$HOSTENV" == "rhel" ]
          then
            $SUDO yum install docker -y> /dev/null
          elif [ "$HOSTENV" == "centos" ]
          then
            # set up a docker repo
            # echo "[virt7-docker-common-release]" > virt7-docker-common-release
            # echo "name=virt7-docker-common-release" >> virt7-docker-common-release
            # echo "baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/" >> virt7-docker-common-release
            # echo "gpgcheck=0" >> virt7-docker-common-release

            echo "[docker]" > /etc/yum.repos.d/docker.repo
            echo "name=Docker Repository" >> /etc/yum.repos.d/docker.repo
            echo "baseurl=https://yum.dockerproject.org/repo/main/centos/7/" >> /etc/yum.repos.d/docker.repo
            echo "enabled=1" >> /etc/yum.repos.d/docker.repo
            echo "gpgcheck=1" >> /etc/yum.repos.d/docker.repo
            echo "gpgkey=https://yum.dockerproject.org/gpg" >> /etc/yum.repos.d/docker.repo
            
            # $SUDO yum install --enablerepo=virt7-docker-common-release docker flannel -y> /dev/null
            $SUDO yum install docker-engine docker-engine-selinux -y> /dev/null
          fi
        else
          cd ~
          $SUDO wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-$DOCKERVER-1.el7.centos.x86_64.rpm
          $SUDO wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-$DOCKERVER-1.el7.centos.noarch.rpm
          $SUDO yum install docker-engine-selinux-$DOCKERVER-1.el7.centos.noarch.rpm -y> /dev/null
          $SUDO yum install docker-engine-$DOCKERVER-1.el7.centos.x86_64.rpm -y> /dev/null
        fi
        echo ""
      fi

      # Docker Registry Stuff
      echo "...Updating the docker config file with insecure-registry"
      # $SUDO sed -i "s/OPTIONS='--selinux-enabled'/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker
      # $SUDO sed -i "s/OPTIONS='--selinux-enabled/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16 /" /etc/sysconfig/docker
      $SUDO sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
      echo ""

      if [ "$HOSTENV" == "centos" ] || [ "$HOSTENV" == "fedora" ]
      then
         cd ~
         $SUDO wget https://github.com/projectatomic/docker-storage-setup/blob/master/docker-storage-setup.sh
         $SUDO cp docker-storage-setup.sh /etc/sysconfig/
         $SUDO chmod +x /etc/sysconfig/docker-storage-setup.sh
      fi

      # Update the docker-storage-setup
      DoBlock
      echo ""

      $SUDO cat /etc/sysconfig/docker-storage-setup
      echo "...Running docker-storage-setup"
      if [ "$DOCKERVER" == "" ] || [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "yum" ]
      then
        $SUDO docker-storage-setup
        $SUDO lvs
        echo ""
      else
        $SUDO chmod +x /etc/sysconfig/docker-storage-setup
        $SUDO ./etc/sysconfig/docker-storage-setup
        $SUDO lvs
        echo ""
      fi

      # Restart Docker
      echo "...Restarting Docker"
      $SUDO groupadd docker
      $SUDO gpasswd -a ${USER} docker
      $SUDO systemctl stop docker
      $SUDO rm -rf /var/lib/docker/*
      $SUDO systemctl restart docker
      $SUDO systemctl enable docker
    else
      # Install Docker
      if [ "$SETUP_TYPE" == "dev" ] || [ "$SETUP_TYPE" == "aplo" ]
      then
        echo "Docker not installed...will install now..."
        # Removing existing docker if it exists
        $SUDO yum remove docker -y> /dev/null
        $SUDO rm -rf /usr/bin/docker

        echo "...Installing Docker"
        if [ "$DOCKERVER" == "" ] || [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "yum" ]
        then
          if [ "$HOSTENV" == "rhel" ]
          then
            $SUDO yum install docker -y> /dev/null
          elif [ "$HOSTENV" == "centos" ]
          then
            # set up a docker repo
            echo "[docker]" > /etc/yum.repos.d/docker.repo
            echo "name=Docker Repository" >> /etc/yum.repos.d/docker.repo
            echo "baseurl=https://yum.dockerproject.org/repo/main/centos/7/" >> /etc/yum.repos.d/docker.repo
            echo "enabled=1" >> /etc/yum.repos.d/docker.repo
            echo "gpgcheck=1" >> /etc/yum.repos.d/docker.repo
            echo "gpgkey=https://yum.dockerproject.org/gpg" >> /etc/yum.repos.d/docker.repo
            $SUDO yum install docker-engine-selinux docker-engine -y> /dev/null
          fi
        else
          cd ~
          $SUDO wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-$DOCKERVER-1.el7.centos.x86_64.rpm
          $SUDO wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-$DOCKERVER-1.el7.centos.noarch.rpm
          $SUDO yum install docker-engine-selinux-$DOCKERVER-1.el7.centos.noarch.rpm -y> /dev/null
          $SUDO yum install docker-engine-$DOCKERVER-1.el7.centos.x86_64.rpm -y> /dev/null
        fi
        echo ""
  
        # Docker Registry Stuff
        echo "...Updating the docker config file with insecure-registry"
        # $SUDO sed -i "s/OPTIONS='--selinux-enabled'/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker
        $SUDO sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
        echo ""

        if [ "$HOSTENV" == "centos" ] || [ "$HOSTENV" == "fedora" ]
        then
          cd ~
          $SUDO wget https://github.com/projectatomic/docker-storage-setup/blob/master/docker-storage-setup.sh
          $SUDO cp docker-storage-setup.sh /etc/sysconfig/
          $SUDO chmod +x /etc/sysconfig/docker-storage-setup.sh
        fi

        # Update the docker-storage-setup
        DoBlock
        echo ""

        $SUDO cat /etc/sysconfig/docker-storage-setup
        echo "...Running docker-storage-setup"
        if [ "$DOCKERVER" == "" ] || [ "$DOCKERVER" == "default" ] || [ "$DOCKERVER" == "yum" ]
        then
          $SUDO docker-storage-setup
          $SUDO lvs
          echo ""
        else
          $SUDO chmod +x /etc/sysconfig/docker-storage-setup
          $SUDO ./etc/sysconfig/docker-storage-setup
          $SUDO lvs
          echo ""
        fi

        # Restart Docker
        echo "...Restarting Docker"
        $SUDO groupadd docker
        $SUDO gpasswd -a ${USER} docker
        $SUDO systemctl stop docker
        $SUDO rm -rf /var/lib/docker/*
        $SUDO systemctl restart docker
        $SUDO systemctl enable docker
      fi
    fi
  fi
fi

# SETUP DOCKER FOR KUBEADM SETUP
if [ -f "$GOLANGPATH/didcomplete" ]
then
  echo " Skipping docker install and config as this script was run once already..."
  echo ""
else
  if [ "$SETUP_TYPE" == "kubeadm" ] || [ "$SETUP_TYPE" == "kubeadm15" ]
  then
    echo "Installing docker for KUBEADM setup..."
    $SUDO yum install docker -y> /dev/null
  fi
fi


#TODO: temp fix for the gobindata
#cd $GOLANGPATH/go/src/k8s.io/kubernetes/
#export GOPATH=$GOLANGPATH/go
#$SUDO go get -u github.com/jteeuwen/go-bindata/go-bindata

echo "DIDRUN" > $GOLANGPATH/didcomplete

if [ "$SETUP_TYPE" == "kubeadm" ] || [ "$SETUP_TYPE" == "kubeadm15" ]
then
  echo "removing /etc/kubernetes contents if they exist..."
  $SUDO rm -rf /etc/kubernetes/*
  cd /etc/kubernetes
  echo ""

  if [ "$SETUP_TYPE" == "kubeadm15" ]
  then
    echo "downloading flannel and weave CNI network overlay for kube-dns..."
    $SUDO wget https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml
    $SUDO wget https://git.io/weave-kube
  else
    echo "downloading flannel and weave CNI network overlay for kube-dns..."
    $SUDO wget https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml
    $SUDO wget https://git.io/weave-kube-1.6
  fi
  echo ""

  echo " Starting kubelet and docker"
  $SUDO systemctl enable kubelet
  $SUDO systemctl start kubelet
  $SUDO systemctl enable docker
  $SUDO systemctl start docker

  echo " Permanently disabling firewall/iptables..."
  $SUDO systemctl stop firewalld
  $SUDO systemctl stop iptables
  $SUDO iptables -F
  $SUDO chkconfig iptables off
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  if [ "$SETUP_TYPE" == "kubeadm15" ]
  then  
     echo ""
     echo "kubeadm15 is version (1.5.6), must specifiy   kubeadm init --use-kubernetes-version=v1.5.6"  
  else
     echo ""
     echo "latest version (1.6)  kubeadm init"
  fi  
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo "Now proceed to this link: http://kubernetes.io/docs/getting-started-guides/kubeadm/ and follow steps 2 through 4"
  echo "HaVE FUN!!!"
  echo ""
  echo "Note: do not join the nodes before you have kube-dns up and running...the instructions are a little jumpy..."
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
else
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
  echo ""
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
  echo "       ./hack/local-up-cluster.sh (I typically run kube as root - from cloud sudo -s before building, etc...)"
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
  echo ""
  echo ""
  echo ""
  echo "*** OTHER NOTES ***"
  echo " Dirty Kube 1.6 - issue with local-up-cluster.sh  see https://github.com/kubernetes/kubernetes/issues/40459 - should be fixed now"

fi

