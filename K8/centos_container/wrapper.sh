#! /bin/bash
# This script will install OCP on AWS
# this is being injected into a container


# Environment Variables and Parameters
CLUSTER_NAME=screeley-test1
BASE_DOMAIN=sysdeseng.com
INSTALLER_VERSION="4.2.2"
INSTALLER_TAR="openshift-install-linux-4.2.2.tar.gz"
CLIENT_TAR="openshift-client-linux-4.2.2.tar.gz"
AWSKEY=<your key>
AWSSECRET=<your secret>
ZONE=us-east-1
pS=$(cat /tmp/cluster/secrets/pullsecret.json)

# create working directory
cd /tmp
mkdir -p /tmp/$CLUSTER_NAME
cd /tmp/$CLUSTER_NAME

# install any prereqs
yum install wget openssh python2-pip python3-pip -y >/dev/null 2>&1

#install and configure aws cli
pip3 install awscli >/dev/null 2>&1
echo "$AWSKEY" > myconf.txt
echo "$AWSSECRET" >> myconf.txt
echo "$ZONE" >> myconf.txt
echo "json" >> myconf.txt
aws configure < myconf.txt >/dev/null 2>&1

export AWS_ACCESS_KEY_ID=$AWSKEY
export AWS_SECRET_ACCESS_KEY=$AWSSECRET

#setup ssh
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
SSHVALUE=$(cat /root/.ssh/id_rsa.pub)

# Get openshift-installer and client
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$INSTALLER_VERSION/$INSTALLER_TAR >/dev/null 2>&1
tar -xzf $INSTALLER_TAR >/dev/null 2>&1
chmod +x openshift-install

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$INSTALLER_VERSION/$CLIENT_TAR >/dev/null 2>&1
rm -rf /usr/local/bin/oc		
tar -C /usr/local/bin -xzf $CLIENT_TAR >/dev/null 2>&1

echo "apiVersion: v1" > install-config.yaml
echo "baseDomain: $BASE_DOMAIN" >> install-config.yaml
echo "compute:" >> install-config.yaml
echo "- hyperthreading: Enabled" >> install-config.yaml
echo "  name: worker" >> install-config.yaml
echo "  platform:" >> install-config.yaml
echo "    aws:" >> install-config.yaml
echo "      type: c5.4xlarge" >> install-config.yaml
echo "      zones:" >> install-config.yaml
echo "      - us-east-1d" >> install-config.yaml
echo "  replicas: 2" >> install-config.yaml
echo "controlPlane:" >> install-config.yaml
echo "  hyperthreading: Enabled" >> install-config.yaml
echo "  name: master" >> install-config.yaml
echo "  platform:" >> install-config.yaml
echo "    aws:" >> install-config.yaml
echo "      zones:" >> install-config.yaml
echo "      - us-east-1d" >> install-config.yaml
echo "  replicas: 1" >> install-config.yaml
echo "metadata:" >> install-config.yaml
echo "  creationTimestamp: null" >> install-config.yaml
echo "  name: $CLUSTER_NAME" >> install-config.yaml
echo "networking:" >> install-config.yaml
echo "  clusterNetwork:" >> install-config.yaml
echo "  - cidr: 10.128.0.0/14" >> install-config.yaml
echo "    hostPrefix: 23" >> install-config.yaml
echo "  machineCIDR: 10.0.0.0/16" >> install-config.yaml
echo "  networkType: OpenshiftSDN" >> install-config.yaml
echo "  serviceNetwork:" >> install-config.yaml
echo "  - 172.30.0.0/16" >> install-config.yaml
echo "platform:" >> install-config.yaml
echo "  aws:" >> install-config.yaml
echo "    region: $ZONE" >> install-config.yaml
echo "pullSecret: '$pS'" >> install-config.yaml
echo "sshKey: \"$SSHVALUE\"" >> install-config.yaml

./openshift-install create cluster --dir /tmp/$CLUSTER_NAME > install-log.txt

