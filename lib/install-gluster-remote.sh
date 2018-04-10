#! /bin/bash
# Some automation to setting up OSE/K8 VM's


echo "#! /bin/bash" > rmt-gluster.sh
echo "" >> rmt-gluster.sh


if [ "$DO_GPG" == "Y" ]
then
  echo "rpm --import https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-storage-common/master/RPM-GPG-KEY-CentOS-SIG-Storage" >> rmt-gluster.sh
fi

if [ "$HOSTENV" == "rhel" ]
then  
  if [ "$GFS_VERSION" == "epel" ]
  then
    # latest epel repo
    echo "wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm" >> rmt-gluster.sh
    echo "rpm -ivh epel-release-latest-7.noarch.rpm" >> rmt-gluster.sh

    # install gluster
    echo "yum --enablerepo=epel install glusterfs-server -y" >> rmt-gluster.sh

  elif [ "$GFS_VERSION" == "rhrepo" ]
  then
    # enable default repo from RH and install
    echo "subscription-manager repos --enable=\"rh-gluster-3-for-rhel-7-server-rpms\" --enable=\"rhel-7-fast-datapath-rpms\"> /dev/null" >> rmt-gluster.sh
    
    # install gluster
    echo "yum install glusterfs-server -y" >> rmt-gluster.sh

  elif [ "$GFS_VERSION" == "" ] || [ "$GFS_VERSION" == "default" ] || [ "$GFS_VERSION" == "official" ]
  then
    #default - just normal rhel gluster repo or centos release repo
    # enable default repo from RH and install
    echo "subscription-manager repos --enable=\"rh-gluster-3-for-rhel-7-server-rpms\" --enable=\"rhel-7-fast-datapath-rpms\"> /dev/null" >> rmt-gluster.sh
    
    # install gluster
    echo "yum install glusterfs-server -y" >> rmt-gluster.sh

  elif [ "$GFS_VERSION" == "no-install" ]
  then
    # enable default repo from RH
    echo "subscription-manager repos --enable=\"rh-gluster-3-for-rhel-7-server-rpms\" --enable=\"rhel-7-fast-datapath-rpms\"> /dev/null" >> rmt-gluster.sh

  else
    #specific version is specified, i.e. 3.12

    if [ "$DO_GPG" == "Y" ]
    then
      echo "rpm --import https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-storage-common/master/RPM-GPG-KEY-CentOS-SIG-Storage" >> rmt-gluster.sh
    fi
    echo "basearch=$(rpm -q --qf \"%{arch}\" -f /etc/$distro)" >> rmt-gluster.sh
    echo "echo \"[gluster-$GFS_VERSION]\" > /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
    echo "echo \"name=Gluster $GFS_VERSION\" >> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
    echo "echo \"baseurl=http://mirror.centos.org/centos/7/storage/\$basearch/gluster-$GFS_VERSION/\">> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
    if [ "$NO_GPG" == "N" ]
    then
      echo "echo \"gpgcheck=0\" >> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
    else
      echo "echo \"gpgcheck=1\" >> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
      echo "echo \"gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Storage\" >> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh
    fi
    echo "echo \"enabled=1\" >> /etc/yum.repos.d/Gluster.repo" >> rmt-gluster.sh

    # install gluster
    echo "yum --enablerepo=gluster-$GFS_VERSION install glusterfs-server -y" >> rmt-gluster.sh

  fi

  if [ "$GFS_VERSION" == "no-install" ]
  then
    echo "Gluster not installed - so not starting"
  else
    echo "Enabling and starting GlusterFS..."
    echo "systemctl start glusterd" >> rmt-gluster.sh
    echo "systemctl status glusterd" >> rmt-gluster.sh
    echo "systemctl enable glusterd" >> rmt-gluster.sh
  fi


elif [ "$HOSTENV" == "centos" ]
then

  if [ "$GFS_VERSION" == "epel" ]
  then
    # latest epel repo

    echo "yum install -y centos-release-gluster> /dev/null" >> rmt-gluster.sh
    echo "yum install epel-release -y> /dev/null" >> rmt-gluster.sh
    echo "yum install glusterfs-server -y> /dev/null" >> rmt-gluster.sh
  elif [ "$GFS_VERSION" == "" ] || [ "$GFS_VERSION" == "default" ] || [ "$GFS_VERSION" == "official" ]
  then
    echo "yum install -y centos-release-gluster> /dev/null" >> rmt-gluster.sh
    echo "yum install epel-release -y> /dev/null" >> rmt-gluster.sh
    echo "yum install glusterfs-server -y> /dev/null" >> rmt-gluster.sh
  elif [ "$GFS_VERSION" == "no-install" ]
  then
    # enable repos but do not install
    echo "yum install -y centos-release-gluster> /dev/null" >> rmt-gluster.sh
    echo "yum install epel-release -y> /dev/null" >> rmt-gluster.sh
  else
    #specific version is specified, i.e. 3.12
    echo "yum install -y centos-release-gluster> /dev/null" >> rmt-gluster.sh
    echo "yum install epel-release -y> /dev/null" >> rmt-gluster.sh
    echo "yum install glusterfs-server-$GFS_VERSION -y> /dev/null" >> rmt-gluster.sh
  fi

  if [ "$GFS_VERSION" == "no-install" ]
  then
    echo "Gluster not installed - so not starting"
  else
    echo "Enabling and starting GlusterFS..."
    echo "systemctl start glusterd" >> rmt-gluster.sh
    echo "systemctl status glusterd" >> rmt-gluster.sh
    echo "systemctl enable glusterd" >> rmt-gluster.sh
  fi
  
  # enable firewalls
  echo "firewall-cmd --zone=public --add-service=glusterfs --permanent" >> rmt-gluster.sh
  echo "firewall-cmd --reload" >> rmt-gluster.sh
else
  echo "Unsupported HOSTENV - $HOSTENV"
fi
