#! /bin/bash
# Some automation to setting up OSE/K8 VM's


# User and Path analysis
cm1='PS1="[\\u@\\h \\W\$(git branch 2> /dev/null'
cm2=" | sed -n 's/^* \(.*\)/ (\1)/p')]"
cm3='\\\$ "'

# install openshift-installer and oc client tools
# 4.0 Install CLI Tools
echo " ... ... installing openshift-installer client tools"
cd ~
$SUDO wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/$CLIENT_TAR >/dev/null 2>&1
$SUDO rm -rf /usr/local/bin/oc		
$SUDO tar -C /usr/local/bin -xzf $CLIENT_TAR >/dev/null 2>&1
echo " ... ... ... ocp installer clients installed!"

echo " ... ... Downloading latest openshift installer"
cd ~
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/$INSTALLER_TAR
tar -xzf $INSTALLER_TAR >/dev/null 2>&1
chmod +x openshift-install
echo " ... ... ... latest ocp installer installed!"



echo " ... ... Configuration and Directory Setup Completed on host $HOSTNAME!"


