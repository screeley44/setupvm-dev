#! /bin/bash
# Some automation to setting up GlusterFS VMs
# WIP WIP WIP !!!!!!  ONLY SUPPORTS RHEL AT THIS POINT
#
# Prereqs:
#   passwordless ssh setup (ssh-keygen -t rsa and then copy ids or add to authorized_keys on each host)
#   MUST RUN as root right now
#
# Fill out the following from the setupvm.config
#
#   HOSTENV=rhel
#   RHNUSER=rhn-support-account
#   RHNPASS=rhn-password
#   POOLID=just take the default
#   SETUP_TYPE="gluster"
#   GFS_LIST="glusterfs1.rhs:glusterfs2.rhs:glusterfs.rhs3"
#

source setupvm.config

HCLI=""

if [ "$HOSTENV" == "rhel" ]
then


  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      # Subscription Manager Stuffs - for RHEL 7.X devices
      echo ""
      echo "****************"
      echo ""
      echo "Setting up subscription services from RHEL..."
      echo "Setting Up Host... ${gfs[index]}"
      subscription-manager register --username=$RHNUSER --password=$RHNPASS
      subscription-manager attach --pool=$POOLID
      subscription-manager repos --disable="*"> /dev/null
      subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.5-rpms" --enable="rhel-7-fast-datapath-rpms" --enable="rh-gluster-3-for-rhel-7-server-rpms"> /dev/null
      echo ""
      echo " RHEL System attached and repo'd"
      echo ""

      echo "Installing GlusterFS Server and Heketi..."
      yum install -y glusterfs-server heketi heketi-client> /dev/null
      echo ""
      echo "Enabling and starting GlusterFS..."
      systemctl start glusterd
      systemctl status glusterd
      systemctl enable glusterd

      # some heketi key stuff
      ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''> /dev/null
      chown heketi:heketi /etc/heketi/heketi_key*

      HCLI=http://"${gfs[index]}":8080
      
    else
      # Subscription Manager Stuffs - for RHEL 7.X devices
      echo ""
      echo "****************"
      echo ""
      echo "Setting up subscription services from RHEL..."
      echo "Setting Up Host... ${gfs[index]}"

      
      echo "#! /bin/bash" > rmt-cmds.sh
      echo "" >> rmt-cmds.sh
      echo "subscription-manager register --username=$RHNUSER --password=$RHNPASS> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager attach --pool=$POOLID> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager repos --disable="*"> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager repos --enable=\"rhel-7-server-rpms\" --enable=\"rhel-7-server-extras-rpms\" --enable=\"rhel-7-server-optional-rpms\" --enable=\"rhel-7-server-ose-3.5-rpms\" --enable=\"rhel-7-fast-datapath-rpms\" --enable=\"rh-gluster-3-for-rhel-7-server-rpms\"> /dev/null" >> rmt-cmds.sh
      echo "yum install -y glusterfs-server> /dev/null" >> rmt-cmds.sh
      echo "systemctl start glusterd> /dev/null" >> rmt-cmds.sh
      echo "systemctl enable glusterd> /dev/null" >> rmt-cmds.sh
       
      chmod +x rmt-cmds.sh

      echo ""
      echo " Testing Connection to Remote Node..."
      echo "hostname" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"
      echo ""

      scp rmt-cmds.sh root@"${gfs[index]}":~

      echo "chmod +x rmt-cmds.sh;./rmt-cmds.sh" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"

      ssh-copy-id -i /etc/heketi/heketi_key.pub root@"${gfs[index]}"

      echo ""
      echo "   ...Remote RHEL System attached and repo'd and Software Installed!!!"
      echo ""
    fi
  done
fi

if [ "$SETUP_TYPE" == "gluster" ] && [ "$GFS_LIST" != "" ]
then
  echo ""
  echo ""
  echo "********************"
  echo ""
  echo "Configuring GlusterFS..."


  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      echo ""
      echo "first host ${gfs[index]} ... skipping peer probe"
      echo ""
    else
      gluster peer probe "${gfs[index]}"
      echo ""
    fi
  done

  echo ""
  gluster peer status
  echo ""
  echo ""
  gluster pool list

fi
echo ""
echo ""
echo ""
echo "================================================="
echo "    Installation complete..."
echo "================================================="
echo ""
echo "Do not forget (if using heketi and heketi-client) to perform any additional"
echo "configurations (modifying heketi.json, etc...) and restart after you make changes"
echo "    executor: ssh"
echo ""
echo "    sshexec: {"
echo "      keyfile: \"/etc/heketi/heketi_key\","
echo "      user: \"root\","
echo "      port: \"22\","
echo "      fstab: \"/etc/fstab\""
echo ""
echo ""
echo " export the HEKETI_CLI_SERVER: "
echo ""
echo "     export HEKETI_CLI_SERVER=$HCLI"
echo ""
echo " To Verify - curl $HCLI/hello"
echo ""
echo "If you want to manually create your gluster volumes and such here are some examples:"
echo "  lsblk - to show available devices"
echo "  fdisk /dev/xvdb  - this will create partition and prompt you for some stuff"
echo "  mkfs.ext4 /dev/xvdb1"
echo ""
echo "  mkdir -p /data/gluster"
echo "  mount \/dev\/xvdb1 \/data/gluster"
echo ""
echo "  mkdir -p /data/gluster/gv0"
echo "  gluster volume create gv0 replica 3 ip-172-18-15-138.ec2.internal:/data/gluster/gv0 ip-172-18-13-134.ec2.internal:/data/gluster/gv0 ip-172-18-0-125.ec2.internal:/data/gluster/gv0"
echo "  gluster volume start gv0"
echo ""
echo " Alternatively you can use heketi-cli after loading topology file to define your cluster (see Heketi docs for that)"
echo "   heketi-cli volume create --size=10 --replica=3"
echo ""
