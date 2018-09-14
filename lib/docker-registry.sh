#! /bin/bash
# Some automation to setting up OSE/K8 VM's


# Docker Registry Stuff
echo " ... ... Updating the docker config file with insecure-registry"
$SUDO sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
echo ""

# Update the docker-storage-setup
DoBlock
echo ""

echo " ... ... Running docker-storage-setup"
$SUDO docker-storage-setup
$SUDO lvs
echo ""

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
      echo " ... ... docker-storage-setup file updated"
    else
      echo " !!! Let's try again..."
      echo ""
      DoBlock
    fi
  fi
}
