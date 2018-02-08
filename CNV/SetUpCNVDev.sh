#! /bin/bash
# Some automation to setting up OSE/K8 VM's

SCRIPT_HOME="$(realpath $(dirname $0))"
source setupvm.config

# Run On All Systems
echo ""
echo ""
echo "Disabling Firewall..."
echo ""
systemctl disable firewalld> /dev/null
systemctl stop firewalld> /dev/null
systemctl disable NetworkManager> /dev/null
systemctl stop NetworkManager> /dev/null
systemctl enable network> /dev/null
systemctl start network> /dev/null
iptables -F> /dev/null

# Prereqs and Yum Installs
echo ""
echo ""
echo "Installing Software..."
echo ""
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-cinder" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ]
then
  yum install -y yum-utils policycoreutils-python centos-release-openstack-pike ntp ntpdate
  yum update -y
  yum install openstack-packstack -y
  yum-config-manager --enable openstack-pike
  yum install openstack-selinux python-openstackclient -y
fi


if [ "$SETUP_TYPE" == "cnv-ceph" ]
then
  yum -y install ntp ntpdate
fi

if [ "$SETUP_TYPE" == "cnv-k8" ]
then
  yum -y install ntp ntpdate
fi



# SSHD config and Restart
echo ""
echo ""
echo "Configuring sshd and restarting..."
echo ""
sed -i -e 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config> /dev/null
sed -i -e 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config> /dev/null
sed -i -e 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config> /dev/null
systemctl restart sshd



# Installing OpenStack
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-cinder" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ]
then
  echo ""
  echo ""
  echo "Installing OpenStack..."
  echo ""

  cd /root
  packstack --allinone
fi

# configuring Cinder conf
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-cinder" ] || [ "$SETUP_TYPE" == "cnv-cinder-k8" ]
then
  echo ""
  echo ""
  echo "Configuring sshd and restarting..."
  echo ""
  sed -i -e 's/enabled_backends=lvm/enabled_backends=lvm,ceph/g' /etc/cinder/cinder.conf

  echo "" >> /etc/cinder/cinder.conf
  echo "[ceph]" >> /etc/cinder/cinder.conf
  echo "volume_driver = cinder.volume.drivers.rbd.RBDDriver" >> /etc/cinder/cinder.conf
  echo "volume_backend_name = ceph" >> /etc/cinder/cinder.conf
  echo "rbd_pool = volumes" >> /etc/cinder/cinder.conf
  echo "rbd_ceph_conf = /etc/ceph/ceph.conf" >> /etc/cinder/cinder.conf
  echo "rbd_flatten_volume_from_snapshot = false" >> /etc/cinder/cinder.conf
  echo "rbd_max_clone_depth = 5" >> /etc/cinder/cinder.conf
  echo "rbd_store_chunk_size = 4" >> /etc/cinder/cinder.conf
  echo "rados_connect_timeout = -1" >> /etc/cinder/cinder.conf
  echo "rbd_user = admin" >> /etc/cinder/cinder.conf

  # create a script for ceph host to execute
  cd /root
  echo "cd /etc/ceph" > config-ceph.sh
  echo "chmod 644 ceph.client.admin.keyring" >> config-ceph.sh
#  echo "cinder type-key iscsi set volume_backend_name=ceph> /dev/null" >> config-ceph.sh
  echo "" >> config-ceph.sh
  echo "echo \"\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"[client]\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"rbd cache = true\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"rbd cache writethrough until flush = true\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"log file = /var/log/qemu/qemu-guest-$pid.log\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"rbd concurrent management ops = 20\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "echo \"rbd default features = 3\" >> /etc/ceph/ceph.conf" >> config-ceph.sh
  echo "" >> config-ceph.sh
#  echo "service openstack-cinder-volume restart" >> config-ceph.sh
#  echo "service openstack-cinder-api restart" >> config-ceph.sh

  chmod +x config-ceph.sh
  systemctl restart sshd
fi

# Installing Ceph
echo ""
echo ""
echo "Installing Ceph..."
echo ""
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-ceph" ] || [ "$SETUP_TYPE" == "cnv-ceph-k8" ]
then
  set -e

  echo "Setting up ceph"
  echo "[ceph]" > /etc/yum.repos.d/ceph.repo
  echo "name=Ceph packages" >> /etc/yum.repos.d/ceph.repo
  echo "baseurl=https://download.ceph.com/rpm/el7/x86_64" >> /etc/yum.repos.d/ceph.repo
  echo "enabled=1" >> /etc/yum.repos.d/ceph.repo
  echo "gpgcheck=1" >> /etc/yum.repos.d/ceph.repo
  echo "type=rpm-md" >> /etc/yum.repos.d/ceph.repo
  echo "gpgkey=https://download.ceph.com/keys/release.asc" >> /etc/yum.repos.d/ceph.repo
  echo "[ceph-noarch]" >> /etc/yum.repos.d/ceph.repo
  echo "name=Ceph noarch packages" >> /etc/yum.repos.d/ceph.repo
  echo "baseurl=https://download.ceph.com/rpm/el7/noarch" >> /etc/yum.repos.d/ceph.repo
  echo "enabled=1" >> /etc/yum.repos.d/ceph.repo
  echo "gpgcheck=1" >> /etc/yum.repos.d/ceph.repo
  echo "type=rpm-md" >> /etc/yum.repos.d/ceph.repo
  echo "gpgkey=https://download.ceph.com/keys/release.asc" >> /etc/yum.repos.d/ceph.repo
  echo "[ceph-source]" >> /etc/yum.repos.d/ceph.repo
  echo "name=Ceph noarch packages" >> /etc/yum.repos.d/ceph.repo
  echo "baseurl=https://download.ceph.com/rpm/el7/SRPMS" >> /etc/yum.repos.d/ceph.repo
  echo "enabled=1" >> /etc/yum.repos.d/ceph.repo
  echo "gpgcheck=1" >> /etc/yum.repos.d/ceph.repo
  echo "type=rpm-md" >> /etc/yum.repos.d/ceph.repo
  echo "gpgkey=https://download.ceph.com/keys/release.asc" >> /etc/yum.repos.d/ceph.repo

  yum update -y
  yum -y install ceph-deploy

  # Set up ceph-deploy user
  useradd -m -s /bin/bash ceph-deploy
  echo "ceph-deploy ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/ceph-deploy
  chmod 0440 /etc/sudoers.d/ceph-deploy

  # The ceph-deploy tool requires key-based ssh login
  sudo -niu ceph-deploy -- bash -c "cat /dev/zero | ssh-keygen -q -N \"\""
  sudo -niu ceph-deploy -- bash -c "cat /home/ceph-deploy/.ssh/id_rsa.pub >> /home/ceph-deploy/.ssh/authorized_keys"
  chmod 600 /home/ceph-deploy/.ssh/authorized_keys

  # Run ceph-deploy tool
  sudo -niu ceph-deploy -- mkdir /home/ceph-deploy/my-cluster
  echo "$(hostname -I) $HOSTNAME" >> /etc/hosts
  sudo -niu ceph-deploy -- bash -c "ssh-keyscan -t rsa $HOSTNAME >> ~/.ssh/known_hosts"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy new $HOSTNAME"

  # Configure the cluster
  echo "osd pool default size = 2" >> /home/ceph-deploy/my-cluster/ceph.conf
  echo "osd crush chooseleaf type = 0" >> /home/ceph-deploy/my-cluster/ceph.conf

  # Install this node
  sudo -niu ceph-deploy -- ceph-deploy install $HOSTNAME

  # Create ceph mon
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy mon create-initial"

  # Prepare and activate OSDs
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd prepare $HOSTNAME:xvdb"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd prepare $HOSTNAME:xvdc"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd prepare $HOSTNAME:xvdd"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd activate $HOSTNAME:xvdb1"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd activate $HOSTNAME:xvdc1"
  sudo -niu ceph-deploy -- bash -c "cd my-cluster && ceph-deploy osd activate $HOSTNAME:xvdd1"

  # Create volumes pool
  ceph osd pool create volumes 128
fi
echo "Completed Ceph Deploy...now additonal configurations"
echo ""
if [ "$SETUP_TYPE" == "cnv-dev" ] || [ "$SETUP_TYPE" == "cnv-ceph" ] || [ "$SETUP_TYPE" == "cnv-ceph-k8" ]
then
  if [ "$CINDERHOST" = "" ]
  then
    echo " ... No Cinder Host - so skipping any post configs"
  else
    echo "Installing ceph tools on $CINDERHOST"
    ceph-deploy install $CINDERHOST
    scp /etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.conf root@$CINDERHOST:/etc/ceph

    echo "" >> /etc/ceph/ceph.conf
    echo "[client]" >> /etc/ceph/ceph.conf
    echo "rbd cache = true" >> /etc/ceph/ceph.conf
    echo "rbd cache writethrough until flush = true" >> /etc/ceph/ceph.conf
    echo "admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok" >> /etc/ceph/ceph.conf
    echo "log file = /var/log/qemu/qemu-guest-$pid.log" >> /etc/ceph/ceph.conf
    echo "rbd concurrent management ops = 20" >> /etc/ceph/ceph.conf
    echo "rbd default features = 3" >> /etc/ceph/ceph.conf

    cd /etc/ceph
    ceph auth get-or-create client.cinder -o /etc/ceph/ceph.client.cinder.keyring> /dev/null 
    chmod 644 ceph.client.admin.keyring
    scp ceph.client.cinder.keyring root@$CINDERHOST:/etc/ceph
    echo "chmod 644 /etc/ceph/ceph.client.admin.keyring" | ssh -o StrictHostKeyChecking=no root@"${CINDERHOST}"

    echo " Testing Connection to Remote Node..."
    echo "hostname" | ssh -o StrictHostKeyChecking=no root@"${CINDERHOST}"
    echo ""
    echo "Running Additional Configs on Cinder Node"
    echo "cd /root;./config-ceph.sh" | ssh -o StrictHostKeyChecking=no root@"${CINDERHOST}"
    echo ""

    # set Ceph backend on Cinder box
    echo "Setting ceph backend"
    echo "cd /root;source keystonerc_admin;cinder type-key iscsi set volume_backend_name=ceph" | ssh -o StrictHostKeyChecking=no root@"${CINDERHOST}"
    echo ""
   
    # Restarting Services on Cinder
    echo "Restarting Services on Cinder"
    echo "service openstack-cinder-volume restart;service openstack-cinder-api restart" | ssh -o StrictHostKeyChecking=no root@"${CINDERHOST}"
    cd /root
  fi 
fi

echo ""
echo " Checking if Kube and Components need to be setup..."
source $SCRIPT_HOME/SetUpK8.sh

echo ""
echo "INSTALLATION COMPLETED FOR SETUP_TYPE $SETUP_TYPE on $HOSTNAME!!"


