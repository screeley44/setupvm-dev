# GlusterFS Cluster Setup (RHEL) Specific For Halo:
This script (a close cousin of the setupvm-dev/GlusterFS script dir) will try to help in some of the repetitive steps for setting up Halo (Gluster + Swift + Other Prereqs).

1.  Prereqs:
      - Choose a single server as your Halo Master (where you will run the scripts from)
      - Run as root (sudo -s)
      - Update `/etc/hosts` if needed adding in each of the nodes (AWS or GCE not needed, but if you are spanning multiple clouds or networks or local VM without DNS you will need this)
      - Setup passwordless ssh between the designated `master halo node` to each node that will join the cluster
          - generate public key on master gluster server  ```ssh-keygen -t rsa``` 
          - on AWS copy /root/.ssh/id_rsa.pub into hosts /root/.ssh/authorized_keys file
          - on non AWS ssh-copy-id -i /root/.ssh/id_rsa.pub root@server (you will get prompted for password)

2.  clone this repo on the `master` Halo node (pick a single node)

	cd /root
	yum install git -y  (if on a fresh VM)
        git clone https://github.com/screeley44/setupvm-dev.git
        cd /root/setupvm-dev/Gluster-Halo

3.  Edit the `setupvm.config` adjusting parameters needed
      - HOSTENV=rhel
      - RHNUSER=rhn-support-account (only needed for rhel)
      - RHNPASS=rhn-password (only needed for rhel)
      - POOLID=The Default Should be fine  (only needed for rhel)
      - SETUP_TYPE="gluster" 
      - GFS_LIST="glusterfs1.rhs:glusterfs2.rhs:glusterfs.rhs3:..." (Make sure `master` designated node is first in list, meaning the node that you are running SetUpGFS.sh from!)

[NOTE] The script by default does not set up the initial volume, you might need to change some values in the setupvm.config to accomodate this for your environment.

4. Execute SetUpHalo.sh

[NOTE] If you set the RERUN=Y flag make sure to configure the setupvm.config script as needed, for example if you want to install swift, but not reconfigure the volumes set INSTALL_LOCAL_SWIFT=Y, CREATE_VOL=N, RERUN=Y


# Use Cases:

## I want to only install base GlusterFS without any peer probe or configuration (Default)

```
# Basic Setup
SETUP_TYPE="gluster"
HOSTENV=rhel
OCPVERSION="3.7"
GFS_VERSION="3.12"
DO_GPG=N
RHNUSER=rhn-support-myaccount
RHNPASS=rhn-mypassword
POOLID="8a85f9833e1404a9013e3cddf95a0599"
GFS_LIST="ip-172-18-4-140.ec2.internal:ip-172-18-4-188.ec2.internal:ip-172-18-14-160.ec2.internal"

# Volume Configuration
PEER_PROBE=N
CREATE_VOL=N
GFS_DIR="/data/gluster/"
GFS_VOLNAME="gv0"
GFS_BRICK="brick"
GFS_DEVICE="/dev/xvdb"
FUSE_BASE="/mnt/glusterfs-storage"
REPLICA_COUNT=3

# Heketi
INSTALL_HEKETI=N
HEKETI_VERSION="default"

# OpenStack Swift
INSTALL_SWIFT_LOCAL=N
INSTALL_SWIFT_REMOTE=N

# K8 Prereqs Docker, ETCD, Go
INSTALL_PREREQ=N
GOVERSION="1.9.2"
DOCKERVER="1.12.6"
ETCD_VER="3.2.16"


# Control Parameters
# RERUN=Y will rerun Volume Configuration without installing gluster or any base software, easy way to automate
# volume creation 
RERUN=N
```

## I want to install base GlusterFS with Volumes and TSP and Swift

```
# Basic Setup
SETUP_TYPE="gluster"
HOSTENV=rhel
OCPVERSION="3.7"
GFS_VERSION="3.12"
DO_GPG=N
RHNUSER=rhn-support-myaccount
RHNPASS=rhn-mypassword
POOLID="8a85f9833e1404a9013e3cddf95a0599"
GFS_LIST="ip-172-18-4-140.ec2.internal:ip-172-18-4-188.ec2.internal:ip-172-18-14-160.ec2.internal"

# Volume Configuration
PEER_PROBE=Y
CREATE_VOL=Y
GFS_DIR="/data/gluster/"
GFS_VOLNAME="gv0"
GFS_BRICK="brick"
GFS_DEVICE="/dev/xvdb"
FUSE_BASE="/mnt/glusterfs-storage"
REPLICA_COUNT=3

# Heketi
INSTALL_HEKETI=N
HEKETI_VERSION="default"

# OpenStack Swift
INSTALL_SWIFT_LOCAL=Y
INSTALL_SWIFT_REMOTE=Y

# K8 Prereqs Docker, ETCD, Go
INSTALL_PREREQ=N
GOVERSION="1.9.2"
DOCKERVER="1.12.6"
ETCD_VER="3.2.16"


# Control Parameters
# RERUN=Y will rerun Volume Configuration without installing gluster or any base software, easy way to automate
# volume creation 
RERUN=N
```

## I want to RERUN after base install of gluster and add in Volume and TSP

```
# Basic Setup
SETUP_TYPE="gluster"
HOSTENV=rhel
OCPVERSION="3.7"
GFS_VERSION="3.12"
DO_GPG=Y
RHNUSER=rhn-support-myaccount
RHNPASS=rhn-mypassword
POOLID="8a85f9833e1404a9013e3cddf95a0599"
GFS_LIST="ip-172-18-4-140.ec2.internal:ip-172-18-4-188.ec2.internal:ip-172-18-14-160.ec2.internal"

# Volume Configuration
PEER_PROBE=Y
CREATE_VOL=Y
GFS_DIR="/data/gluster/"
GFS_VOLNAME="gv0"
GFS_BRICK="brick"
GFS_DEVICE="/dev/xvdb"
FUSE_BASE="/mnt/glusterfs-storage"
REPLICA_COUNT=3


# OpenStack Swift
INSTALL_SWIFT_LOCAL=Y
INSTALL_SWIFT_REMOTE=Y

# K8 Prereqs Docker, ETCD, Go
INSTALL_PREREQ=N
GOVERSION="1.9.2"
DOCKERVER="1.12.6"
ETCD_VER="3.2.16"


# Control Parameters
# RERUN=Y will rerun Volume Configuration without installing gluster or any base software, easy way to automate
# volume creation 
RERUN=Y
```

