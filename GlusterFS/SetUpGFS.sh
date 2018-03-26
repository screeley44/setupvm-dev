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
#   HOSTENV=rhel or centos(not tested)
#   OCPVERSION=3.6 or 3.5 or 3.4 (default is 3.6)
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
  echo " *** INSTALLING GLUSTERFS CLUSTER ON RHEL ***"
  echo ""
  echo ""

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
      yum install subscription-manager -y> /dev/null
      subscription-manager register --username=$RHNUSER --password=$RHNPASS
      subscription-manager attach --pool=$POOLID
      subscription-manager repos --disable="*"> /dev/null


      # retrying 5 times, unless success
      for i in {1..5}; do subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-$OCPVERSION-rpms" --enable="rhel-7-fast-datapath-rpms" --enable="rh-gluster-3-for-rhel-7-server-rpms"> /dev/null && break || sleep 15; done


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
      echo "yum install subscription-manager -y> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager register --username=$RHNUSER --password=$RHNPASS> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager attach --pool=$POOLID> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager repos --disable="*"> /dev/null" >> rmt-cmds.sh
      # echo "subscription-manager repos --enable=\"rhel-7-server-rpms\" --enable=\"rhel-7-server-extras-rpms\" --enable=\"rhel-7-server-optional-rpms\" --enable=\"rhel-7-server-ose-3.7-rpms\" --enable=\"rhel-7-fast-datapath-rpms\" --enable=\"rh-gluster-3-for-rhel-7-server-rpms\"> /dev/null" >> rmt-cmds.sh
      echo "for i in {1..5}; do subscription-manager repos --enable=\"rhel-7-server-rpms\" --enable=\"rhel-7-server-extras-rpms\" --enable=\"rhel-7-server-optional-rpms\" --enable=\"rhel-7-server-ose-$OCPVERSION-rpms\" --enable=\"rhel-7-fast-datapath-rpms\" --enable=\"rh-gluster-3-for-rhel-7-server-rpms\"> /dev/null && break || sleep 15; done" >> rmt-cmds.sh
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
else
  echo " *** INSTALLING GLUSTERFS CLUSTER ON CentOS ***"
  echo ""
  echo ""

  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then

      echo "Installing GlusterFS Server and Heketi..."
      yum install -y wget telnet> /dev/null
      yum install -y centos-release-gluster> /dev/null    
      yum install epel-release -y> /dev/null
      yum install glusterfs-server -y> /dev/null
      yum install heketi -y> /dev/null
      yum install heketi-client -y> /dev/null

      echo ""
      echo "Enabling and starting GlusterFS..."
      systemctl start glusterd
      systemctl status glusterd
      systemctl enable glusterd

      echo ""
      echo "Installing heketi-client 5..."
      wget https://github.com/heketi/heketi/releases/download/v5.0.0/heketi-client-v5.0.0.linux.amd64.tar.gz
      mkdir -p /etc/heketi && tar xzvf heketi-client-v5.0.0.linux.amd64.tar.gz -C /etc/heketi

      echo ""
      echo "Adding Firewall Rules..."
      firewall-cmd --permanent --zone=public --add-port=8080/tcp
      firewall-cmd --zone=public --add-service=glusterfs --permanent
      firewall-cmd --reload

      # some heketi key stuff
      ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''> /dev/null
      chown heketi:heketi /etc/heketi/heketi_key*

      HCLI=http://"${gfs[index]}":8080
      
    else
      # Setting up CentOS
      echo ""
      echo "****************"
      echo ""
      echo "Setting Up Host... ${gfs[index]}"

      
      echo "#! /bin/bash" > rmt-cmds.sh
      echo "" >> rmt-cmds.sh

      echo "Gluster Installation Stuff"
      echo "yum install -y wget telnet> /dev/null" >> rmt-cmds.sh
      echo "yum install -y centos-release-gluster> /dev/null" >> rmt-cmds.sh    
      echo "yum install epel-release -y> /dev/null" >> rmt-cmds.sh
      echo "yum install glusterfs-server -y> /dev/null" >> rmt-cmds.sh
      echo "yum install heketi -y> /dev/null" >> rmt-cmds.sh
      echo "yum install heketi-client -y> /dev/null" >> rmt-cmds.sh
      echo "systemctl start glusterd" >> rmt-cmds.sh
      echo "systemctl status glusterd" >> rmt-cmds.sh
      echo "systemctl enable glusterd" >> rmt-cmds.sh
      echo "firewall-cmd --permanent --zone=public --add-port=8080/tcp" >> rmt-cmds.sh
      echo "firewall-cmd --zone=public --add-service=glusterfs --permanent" >> rmt-cmds.sh
      echo "firewall-cmd --reload" >> rmt-cmds.sh
       
      chmod +x rmt-cmds.sh

      echo ""
      echo " Testing Connection to Remote Node..."
      echo "hostname" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"
      echo ""

      scp rmt-cmds.sh root@"${gfs[index]}":~

      echo "chmod +x rmt-cmds.sh;./rmt-cmds.sh" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"

      ssh-copy-id -i /etc/heketi/heketi_key.pub root@"${gfs[index]}"

      echo ""
      echo "   ...Remote CentOS System attached and Software Installed!!!"
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

  # create volume list
  VOLLIST=""
  GVDIR="$GFS_DIR$GFS_BRICK"
  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      VOLLIST="${gfs[index]}:$GVDIR$index" 
    else
      VOLLIST="$VOLLIST ${gfs[index]}:$GVDIR$index" 
    fi
  done

  # Peer Probe
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
  echo ""
  echo ""

  # CREATE VOLUME SETUP
  if [ "$CREATE_VOL" == "Y" ]
  then
    echo "***********************"
    echo "   Volume Mgmt Setup"
    IFS=':' read -r -a gfs <<< "$GFS_LIST"
    for index in "${!gfs[@]}"
    do
      if [ "$index" == 0 ]
      then
      
        result=`eval mkfs.ext4 $GFS_DEVICE`
        mkdir -p $GFS_DIR
        mkdir -p $GFS_DIR$GFS_BRICK$index
        echo '$GFS_DEVICE $GFS_DIR$GFS_BRICK$index xfs defaults 0 0' >> /etc/fstab
        mount -a
      else
        echo "#! /bin/bash" > rmt-cmds2.sh
        echo "" >> rmt-cmds2.sh
      
        echo "mkfs.ext4 $GFS_DEVICE" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR$GFS_BRICK$index" >> rmt-cmds2.sh
        echo "echo '$GFS_DEVICE $GFS_DIR$GFS_BRICK$index xfs defaults 0 0' >> /etc/fstab" >> rmt-cmds2.sh
        echo "mount -a" >> rmt-cmds2.sh
        scp rmt-cmds2.sh root@"${gfs[index]}":~
        echo "chmod +x rmt-cmds2.sh;./rmt-cmds2.sh" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"
      fi
    done
  fi

  # CREATE VOLUME AND START
  if [ "$CREATE_VOL" == "Y" ]
  then
    echo "***********************"
    echo "     Volume Start"
    IFS=':' read -r -a gfs <<< "$GFS_LIST"
    for index in "${!gfs[@]}"
    do
      if [ "$index" == 0 ]
      then
        result=`eval gluster volume create $GFS_VOLNAME replica $REPLICA_COUNT $VOLLIST force`
        wait
        result=`eval gluster volume start $GFS_VOLNAME`
        wait
      fi
    done
  fi
fi
echo ""
echo ""
echo ""
echo "================================================="
echo "    Installation complete..."
echo "================================================="
echo ""
echo " Should have a functioning cluster now, just setup your Trusted Storage Pool manually or using heketi"
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
echo "   ** You may need to export the heketi-cli path for CentOS installations:"
echo ""
echo "          # export PATH=$PATH:/etc/heketi/heketi-client/bin"
echo "	        # heketi-cli --version"
echo ""
