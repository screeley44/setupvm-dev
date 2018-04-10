#! /bin/bash
# Some automation to setting up OSE/K8 VM's

# Setting up gluster 3.12

# # yum install centos-release-gluster  (does this give me 3.12 ???)

# rpm --import https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-storage-common/master/RPM-GPG-KEY-CentOS-SIG-Storage
# vi /etc/yum.repos.d/redhat.repo (on AWS and Azure)
# vi /etc/yum.repos.d/epel.repo (on GCE)

# [centos-gluster312]
# name=CentOS-$releasever - Gluster 3.12
# baseurl=http://mirror.centos.org/centos/7/storage/$basearch/gluster-3.12/
# gpgcheck=1
# enabled=1
# gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Storage

# yum install glusterfs-server -y


if [ "$DO_GPG" == "Y" ]
then
  rpm --import https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-storage-common/master/RPM-GPG-KEY-CentOS-SIG-Storage
fi

if [ "$HOSTENV" == "rhel" ]
then  
  if [ "$GFS_VERSION" == "epel" ]
  then
    # latest epel repo
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    rpm -ivh epel-release-latest-7.noarch.rpm

    # install gluster
    yum --enablerepo=epel install glusterfs-server -y

  elif [ "$GFS_VERSION" == "rhrepo" ]
  then
    # enable default repo from RH and install
    subscription-manager repos --enable="rh-gluster-3-for-rhel-7-server-rpms" --enable="rhel-7-fast-datapath-rpms"
    
    # install gluster
    yum install glusterfs-server -y  

  elif [ "$GFS_VERSION" == "" ] || [ "$GFS_VERSION" == "default" ] || [ "$GFS_VERSION" == "official" ]
  then
    #default - just normal rhel gluster repo or centos release repo
    # enable default repo from RH and install
    subscription-manager repos --enable="rh-gluster-3-for-rhel-7-server-rpms" --enable="rhel-7-fast-datapath-rpms"
    
    # install gluster
    yum install glusterfs-server -y  

  elif [ "$GFS_VERSION" == "no-install" ]
  then
    # enable default repo from RH
    subscription-manager repos --enable="rh-gluster-3-for-rhel-7-server-rpms" --enable="rhel-7-fast-datapath-rpms"

  else
    #specific version is specified, i.e. 3.12

    if [ "$DO_GPG" == "Y" ]
    then
      rpm --import https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-storage-common/master/RPM-GPG-KEY-CentOS-SIG-Storage
    fi

    # get $basearch
    basearch=$(rpm -q --qf "%{arch}" -f /etc/$distro)

    # set up the Gluster.repo
    echo "[gluster-$GFS_VERSION]" > /etc/yum.repos.d/Gluster.repo
    echo "name=Gluster" >> /etc/yum.repos.d/Gluster.repo
    echo "baseurl=http://mirror.centos.org/centos/7/storage/\$basearch/gluster-$GFS_VERSION/">> /etc/yum.repos.d/Gluster.repo
    if [ "$NO_GPG" == "N" ]
    then
      echo "gpgcheck=0" >> /etc/yum.repos.d/Gluster.repo
    else
      echo "gpgcheck=1" >> /etc/yum.repos.d/Gluster.repo
      echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Storage" >> /etc/yum.repos.d/Gluster.repo
    fi
    echo "enabled=1" >> /etc/yum.repos.d/Gluster.repo

    # install gluster
    yum --enablerepo=gluster-$GFS_VERSION install glusterfs-server -y
    wait

  fi

  if [ "$GFS_VERSION" == "no-install" ]
  then
    echo "Gluster not installed - so not starting"
  else
    echo "Enabling and starting GlusterFS..."
    systemctl start glusterd
    systemctl status glusterd
    systemctl enable glusterd
  fi
elif [ "$HOSTENV" == "centos" ]
then

  if [ "$GFS_VERSION" == "epel" ]
  then
    # latest epel repo

    yum install -y centos-release-gluster> /dev/null    
    yum install epel-release -y> /dev/null
    yum install glusterfs-server -y> /dev/null 

  elif [ "$GFS_VERSION" == "" ] || [ "$GFS_VERSION" == "default" ] || [ "$GFS_VERSION" == "official" ]
  then
    yum install -y centos-release-gluster> /dev/null    
    yum install epel-release -y> /dev/null
    yum install glusterfs-server -y> /dev/null

  elif [ "$GFS_VERSION" == "no-install" ]
  then
    # enable repos but do not install
    yum install -y centos-release-gluster> /dev/null    
    yum install epel-release -y> /dev/null

  else
    #specific version is specified, i.e. 3.12
    yum install -y centos-release-gluster> /dev/null    
    yum install epel-release -y> /dev/null
    yum install glusterfs-server-$GFS_VERSION -y> /dev/null

  fi

  if [ "$GFS_VERSION" == "no-install" ]
  then
    echo "Gluster not installed - so not starting"
  else
    echo "Enabling and starting GlusterFS..."
    systemctl start glusterd
    systemctl status glusterd
    systemctl enable glusterd
  fi

  echo ""
  echo "Adding Firewall Rules..."
  firewall-cmd --zone=public --add-service=glusterfs --permanent
  firewall-cmd --reload
  
else
  echo "Unsupported HOSTENV - $HOSTENV"
fi
