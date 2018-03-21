#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Install cinder client if k8-dev and cinder_client is listed
if [ "$SETUP_TYPE" == "cnv" ] && [ "$CINDER_CLIENT" == "Y" ] && [ "$HOSTENV" == "centos" ]
then
  echo ""
  echo "Installing cinder client and add-ons..."
  echo ""
  if [ "$INSTALL_COMMON_HOST" == "Y" ]
  then
    yum install ceph-common -y> /dev/null
  fi

  yum install python-pip -y> /dev/null
  pip install python-cinderclient> /dev/null

  echo ""
  echo " *********************************************** "
  echo "" 
  echo "     Cinder Client Setup Completed on host $HOSTNAME!"
  echo ""
  echo " *********************************************** "
fi
