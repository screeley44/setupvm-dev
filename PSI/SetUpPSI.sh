#! /bin/bash
# Some automation to setting up OSE/K8 VM's
# For RHEL Environments
# rhosp command to upload custom image: openstack image create --container-format=bare --disk-format=qcow2 --file rhcos-4.2.0-x86_64-openstack.qcow2 my-custom-rhcos


SCRIPT_HOME="$(realpath $(dirname $0))"
MASTER_CONFIG_HOME=""
MASTER_CONFIG_HOME="${HOME}/${USERNAME}-psi-master"

# ---------------------------------
# Openshift 4.0 Installer and Client Params
# ---------------------------------
SKIP_INSTALL="N"
# BASE_DIR="latest"
BASE_DIR="4.2.10"
INSTALLER_TAR="openshift-install-linux-4.2.10.tar.gz"
CLIENT_TAR="openshift-client-linux-4.2.10.tar.gz"

source ${MASTER_CONFIG_HOME}/cluster_config.sh
SUDO=""

#Perform Basic Host Configuration
echo "................................."
echo "     Configuring Host Env"
echo "................................."
CONFIG_HOME2=$HOME/$CLUSTER_NAME
echo " ... $CONFIG_HOME2"
echo " ... $CLUSTER_NAME"
echo " ... ${MASTER_CONFIG_HOME}"

rm -rf ${CONFIG_HOME2}
mkdir -p ${CONFIG_HOME2}

if [ "$SKIP_INSTALL" == "N" ]
then
  # Install Installer and Clients
  echo " Installing openshift-installer client tools"
  cd ~
  echo " ... ... Downloading latest openshift client tools"
  sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$BASE_DIR/$CLIENT_TAR >/dev/null 2>&1
  sudo rm -rf /usr/local/bin/oc		
  sudo tar -C /usr/local/bin -xzf $CLIENT_TAR >/dev/null 2>&1
  echo " ... ... ocp installer clients installed!"

  echo " ... ... Downloading latest openshift installer"
  cd ~
  sudo rm -rf openshift-install
  sudo rm -rf /usr/local/bin/openshift-install
  sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$BASE_DIR/$INSTALLER_TAR >/dev/null 2>&1
  sudo tar -C /usr/local/bin -xzf $INSTALLER_TAR >/dev/null 2>&1
  sudo chmod +x openshift-install
  echo " ... ... latest ocp installer installed!"
  echo ""
fi

# Copy files from our MASTER_CONFIG to new working Directory
echo " Installing run_ocp.sh Script"
cd $CONFIG_HOME2
echo " ... ... changing to directory ${CONFIG_HOME2}"
cp ${MASTER_CONFIG_HOME}/cluster_config.sh .
cp ${MASTER_CONFIG_HOME}/pull-secret.txt .
curl -O https://raw.githubusercontent.com/font/shiftstack-ci/octo/run_ocp.sh >/dev/null 2>&1
chmod 755 run_ocp.sh
echo ""

echo ""
echo " ********************** "
echo " Installing the PSI Cluster...give me a few minutes"
cd ${CONFIG_HOME2}
./run_ocp.sh




