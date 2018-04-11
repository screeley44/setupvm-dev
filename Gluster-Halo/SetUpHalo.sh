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

SCRIPT_HOME="$(realpath $(dirname $0))"
CONFIG_HOME=""

if [ -f "$SCRIPT_HOME/setupvm.config" ]
then
  CONFIG_HOME=$SCRIPT_HOME
else
  CONFIG_HOME="/root/setupvm-dev/Gluster-Halo"
fi

source $CONFIG_HOME/setupvm.config

HCLI=""

if [ "$HOSTENV" == "rhel" ] && [ "$RERUN" == "N" ]
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
      echo "Setting Up Local Host... ${gfs[index]}"
      yum install subscription-manager -y> /dev/null
      subscription-manager register --username=$RHNUSER --password=$RHNPASS
      subscription-manager attach --pool=$POOLID
      subscription-manager repos --disable="*"> /dev/null


      # retrying 5 times, unless success
      for i in {1..5}; do subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms"> /dev/null && break || sleep 15; done


      echo ""
      echo " RHEL System attached and repo'd"
      echo ""

      echo "Installing GlusterFS Server and Heketi..."
      source $CONFIG_HOME/../lib/install-gluster-local.sh

      # Swift specific remote commands
      if [ "$INSTALL_SWIFT_LOCAL" == "Y" ]
      then
        echo " ... Installing Swift and Clients on local node ${gfs[index]}"
        source $CONFIG_HOME/../lib/install-swift-local.sh
      fi

      if [ "$INSTALL_HEKETI" == "Y" ]
      then
        source $CONFIG_HOME/../lib/install-heketi.sh
      fi
      
    else
      # Subscription Manager Stuffs - for RHEL 7.X devices
      echo ""
      echo "****************"
      echo ""
      echo "Setting up subscription services from RHEL..."
      echo "Setting Up Remote Host... ${gfs[index]}"

      # base remote commands
      echo " ... Remotely Installing Base Software on ${gfs[index]}"
      echo "#! /bin/bash" > rmt-cmds.sh
      echo "" >> rmt-cmds.sh
      echo "yum install subscription-manager -y> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager register --username=$RHNUSER --password=$RHNPASS> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager attach --pool=$POOLID> /dev/null" >> rmt-cmds.sh
      echo "subscription-manager repos --disable="*"> /dev/null" >> rmt-cmds.sh
      echo "for i in {1..5}; do subscription-manager repos --enable=\"rhel-7-server-rpms\" --enable=\"rhel-7-server-extras-rpms\" --enable=\"rhel-7-server-optional-rpms\"> /dev/null && break || sleep 15; done" >> rmt-cmds.sh  

      #echo ""
      #echo " Testing Connection to Remote Node..."
      #echo "hostname" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
      #echo ""
      chmod +x rmt-cmds.sh
      scp rmt-cmds.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-cmds.sh;./rmt-cmds.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"


      # Gluster and Heketi specific remote commands
      echo " ... Remotely Installing GlusterFS and/or Heketi on ${gfs[index]}"
      source $CONFIG_HOME/../lib/install-gluster-remote.sh
      scp rmt-gluster.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-gluster.sh;./rmt-gluster.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"

      # Swift specific remote commands
      if [ "$INSTALL_SWIFT_REMOTE" == "Y" ]
      then
        echo " ... Remotely Installing Swift and Clients on ${gfs[index]}"
        source $CONFIG_HOME/../lib/install-swift-remote.sh
        scp rmt-swift.sh root@"${gfs[index]}":~
        echo "chmod +x rmt-swift.sh;./rmt-swift.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
      fi

      echo ""
      echo "   ...Remote RHEL System attached and repo'd and Software Installed!!!"
      echo ""
    fi
  done
elif [ "$HOSTENV" == "centos" ] && [ "$RERUN" == "N" ]
then
  echo " *** INSTALLING GLUSTERFS CLUSTER ON CentOS ***"
  echo ""
  echo ""

  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      echo ""
      echo "****************"
      echo ""
      echo "Setting Up Local Host... ${gfs[index]}"
      echo " ... Installing GlusterFS Server and Heketi..."
      source $CONFIG_HOME/../lib/install-gluster-local.sh

      if [ "$INSTALL_HEKETI" == "Y" ]
      then
        source $CONFIG_HOME/../lib/install-heketi.sh
      fi

      echo ""
      # copy heketi keys
      if [ "$INSTALL_HEKETI" == "Y" ]
      then  
        ssh-copy-id -i /etc/heketi/heketi_key.pub root@"${gfs[index]}"
      fi
      
    else
      # Setting up CentOS
      echo ""
      echo "****************"
      echo ""
      echo "Setting Up Remote Host... ${gfs[index]}"

      
      # Install base remote gluster
      echo " ... Remotely Installing Base Software on ${gfs[index]}"
      echo "#! /bin/bash" > rmt-cmds.sh
      echo "" >> rmt-cmds.sh
      #echo ""
      #echo " Testing Connection to Remote Node..."
      #echo "hostname" | ssh -o StrictHostKeyChecking=no root@"${gfs[index]}"
      #echo ""
      chmod +x rmt-cmds.sh
      scp rmt-cmds.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-cmds.sh;./rmt-cmds.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
      wait

      # Installing Gluster and Heketi specific remote commands
      echo " ... Remotely Installing Gluster and/or Heketi on ${gfs[index]}"
      source $CONFIG_HOME/../lib/install-gluster-remote.sh
      scp rmt-gluster.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-gluster.sh;./rmt-gluster.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
      wait

      echo ""
      echo "   ...Remote CentOS System attached and Software Installed!!!"
      echo ""
    fi
  done
else
  echo "RERUNNING SCRIPT FOR PROBE AND VOLUME CONFIGURATION"
  echo "     or HOSTENV is misconfigured - $HOSTENV"
  echo "==================================================="
fi



# Swift Reruns
if [ "$INSTALL_SWIFT_LOCAL" == "Y" ] && [ "$RERUN" == "Y" ]
then
  echo " ... Installing Swift and Clients on local node ${gfs[index]}"
  source $CONFIG_HOME/../lib/install-swift-local.sh
fi

# Swift Reruns
if [ "$INSTALL_SWIFT_REMOTE" == "Y" ] && [ "$RERUN" == "Y" ] && [ "$GFS_LIST" != "" ]
then
  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      echo "skipping local host..."
    else
      echo " ... Remotely Installing Swift and Clients on ${gfs[index]}"
      source $CONFIG_HOME/../lib/install-swift-remote.sh
      scp rmt-swift.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-swift.sh;./rmt-swift.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
    fi
  done
fi

# Docker, GO, ETCD
if [ "$INSTALL_PREREQ" == "Y" ] && [ "$RERUN" == "Y" ] && [ "$GFS_LIST" != "" ]
then
  IFS=':' read -r -a gfs <<< "$GFS_LIST"
  for index in "${!gfs[@]}"
  do
    if [ "$index" == 0 ]
    then
      # Install core software (go, etcd, docker, etc...)
      source $CONFIG_HOME/../lib/install-go.sh
      source $CONFIG_HOME/../lib/install-etcd.sh
      source $CONFIG_HOME/../lib/docker-base.sh

      # restart docker
      source $CONFIG_HOME/../lib/docker-restart.sh
    else
      echo " ... Remotely Installing PreReqs (Docker, Go, ETCD) on ${gfs[index]}"
      source $CONFIG_HOME/../lib/install-go-remote.sh
      scp rmt-go.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-go.sh;./rmt-go.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"

      source $CONFIG_HOME/../lib/install-docker-remote.sh
      scp rmt-docker.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-docker.sh;./rmt-docker.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"

      source $CONFIG_HOME/../lib/install-etcd-remote.sh
      scp rmt-etcd.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-etcd.sh;./rmt-etcd.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"

      source $CONFIG_HOME/../lib/docker-restart-remote.sh
      scp rmt-docker-restart.sh root@"${gfs[index]}":~
      echo "chmod +x rmt-docker-restart.sh;./rmt-docker-restart.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
    fi
  done
fi



# Initial Volume Management OR rerun scenario (installing in staggered or post base install order)
if [ "$SETUP_TYPE" == "gluster" ] && [ "$GFS_LIST" != "" ]
then
  echo ""
  echo ""
  echo "********************"
  echo ""
  echo "Configuring GlusterFS..."

  if [ "$CREATE_VOL" == "Y" ] && [ "$PEER_PROBE" == "N" ]
  then
    echo "!!!!  MISCONFIGURATION - can't create volumes without peer probe first to create TSP !!!!"
    exit 1
  fi

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
  if [ "$PEER_PROBE" == "Y" ]
  then
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
  fi

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
      
        mkfs.ext4 $GFS_DEVICE
        wait
        mkdir -p $GFS_DIR
        mkdir -p $GFS_DIR$GFS_BRICK$index
        mkdir -p $FUSE_BASE/$GFS_VOLNAME
        echo "$GFS_DEVICE $GFS_DIR$GFS_BRICK$index ext4 defaults 0 0" >> /etc/fstab
        mount -a
      else
        echo "#! /bin/bash" > rmt-cmds2.sh
        echo "" >> rmt-cmds2.sh
      
        echo "mkfs.ext4 $GFS_DEVICE" >> rmt-cmds2.sh
        echo "wait" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR$GFS_BRICK$index" >> rmt-cmds2.sh
        echo "mkdir -p $FUSE_BASE/$GFS_VOLNAME" >> rmt-cmds2.sh
        echo "echo '$GFS_DEVICE $GFS_DIR$GFS_BRICK$index ext4 defaults 0 0' >> /etc/fstab" >> rmt-cmds2.sh
        echo "mount -a" >> rmt-cmds2.sh

        scp rmt-cmds2.sh root@"${gfs[index]}":~
        echo "chmod +x rmt-cmds2.sh;./rmt-cmds2.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
      fi
    done
  else
    IFS=':' read -r -a gfs <<< "$GFS_LIST"
    for index in "${!gfs[@]}"
    do
      if [ "$index" == 0 ]
      then
        mkdir -p $GFS_DIR
        mkdir -p $GFS_DIR$GFS_BRICK$index
        mkdir -p $FUSE_BASE/$GFS_VOLNAME
      else
        echo "#! /bin/bash" > rmt-cmds2.sh
        echo "" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR" >> rmt-cmds2.sh
        echo "mkdir -p $GFS_DIR$GFS_BRICK$index" >> rmt-cmds2.sh
        echo "mkdir -p $FUSE_BASE/$GFS_VOLNAME" >> rmt-cmds2.sh

        scp rmt-cmds2.sh root@"${gfs[index]}":~
        echo "chmod +x rmt-cmds2.sh;./rmt-cmds2.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
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

# Strange the above works without adding bricks, I guess because my initial volume assumes BRICK??
# for reference command to add brick
#  gluster volume add-brick gv0 replica 3 aze-storage1:/data/brick1/gv0 aze-storage2:/data/brick1/gv0 aze-storage3:/data/brick1/gv0

  # PERFORM FUSE MOUNT
  if [ "$CREATE_VOL" == "Y" ]
  then
    echo "***********************"
    echo "   Volume Mgmt Setup"
    IFS=':' read -r -a gfs <<< "$GFS_LIST"
    for index in "${!gfs[@]}"
    do
      if [ "$index" == 0 ]
      then
        echo "${gfs[index]}:$GFS_VOLNAME $FUSE_BASE/$GFS_VOLNAME glusterfs defaults,_netdev 0 0" >> /etc/fstab
        wait
        mount -a
      else
        echo "#! /bin/bash" > rmt-cmds3.sh
        echo "" >> rmt-cmds3.sh
        echo "echo '${gfs[index]}:$GFS_VOLNAME $FUSE_BASE/$GFS_VOLNAME glusterfs defaults,_netdev 0 0' >> /etc/fstab" >> rmt-cmds3.sh
        echo "wait" >> rmt-cmds3.sh
        echo "mount -a" >> rmt-cmds3.sh

        scp rmt-cmds3.sh root@"${gfs[index]}":~
        echo "chmod +x rmt-cmds3.sh;./rmt-cmds3.sh" | ssh -T -o StrictHostKeyChecking=no root@"${gfs[index]}"
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
echo "--------------------"
echo "GLUSTER INFORMATION"
echo "--------------------"
if [ "$CREATE_VOL" == "Y" ]
then
  echo "Initial Gluster Volume $GFS_VOLNAME was created with Replica Count of $REPLICA_COUNT and can be accessed from: "
  echo "  $FUSE_BASE/$GFS_VOLNAME"
  echo ""
  echo " -------------"
  echo " -- VERSION --"
  echo " -------------"
  gluster --version
  echo ""
  echo " --------------"
  echo " -- VOL INFO --"
  echo " --------------"
  gluster volume info
else
  echo "Initial Gluster Volume WAS NOT created per configuration setting of CREATE_VOL=N"
  echo ""
  gluster --version
  echo ""
  gluster volume info
fi
echo ""
echo "--------------------"
echo "HEKETI CONFIGURATION"
echo "--------------------"
if [ "$INSTALL_HEKETI" == "Y" ]
then
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
else
  echo "Heketi Not Installed per configuration option INSTALL_HEKETI=N"
  echo "If you need Heketi, you should install manually"
fi
echo ""
echo "--------------------"
echo "ADDITIONAL GLUSTER CONFIGURATION"
echo "--------------------"
if [ "$CREATE_VOL" == "Y" ]
then
  echo "None at this time - you can manually add volumes and peers"
  echo ""
else
  echo "Initial Gluster Volume WAS NOT created per configuration setting of CREATE_VOL=N"
  echo ""
  echo "If you want to manually create additonal gluster volumes and such here are some examples:"
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
fi
