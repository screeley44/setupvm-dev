# GlusterFS Cluster Setup (RHEL or Centos):
This script (a close cousin of the setupvm-dev/GlusterFS script dir) will try to help in some of the repetitive steps for setting up Gluster + Swift + TBD.

1.  Prereqs:
      - Choose a single server as your Gluster Master and Heketi-Client Server (where you will run the scripts from)
      - Run as root (sudo -s)
      - Setup passwordless ssh between the designated `master gluster node` to each node that will join the cluster
          - generate public key on master gluster server  ```ssh-keygen -t rsa``` 
          - on AWS copy /root/.ssh/id_rsa.pub into hosts /root/.ssh/authorized_keys file
          - on non AWS ssh-copy-id -i /root/.ssh/id_rsa.pub root@server (you will get prompted for password)

2.  clone this repo on the `master` GlusterFS node (pick a single node)

	cd /root
	yum install git -y  (if on a fresh VM)
        git clone https://github.com/screeley44/setupvm-dev.git
        cd /root/setupvm-dev/Gluster-Halo

3.  Edit the `setupvm.config` with the following variables defined in `setupvm.config` - file is pretty self explanatory
      - HOSTENV=rhel or centos
      - RHNUSER=rhn-support-account (only needed for rhel)
      - RHNPASS=rhn-password (only needed for rhel)
      - POOLID=The Default Should be fine  (only needed for rhel)
      - SETUP_TYPE="gluster" 
      - GFS_LIST="glusterfs1.rhs:glusterfs2.rhs:glusterfs.rhs3:..." (Make sure `master` designated node is first in list, meaning the node that you are running SetUpGFS.sh from!)

[NOTE] The script by default does not set up the initial volume, you might need to change some values in the setupvm.config to accomodate this for your environment.

4. Execute SetUpGFS.sh

[NOTE] If you set the RERUN=Y flag make sure to configure the setupvm.config script as needed, for example if you want to create a 2nd volume (different from the initial) set CREATE_VOL=Y, PEER_PROBE=N and RERUN=Y and this will not try to reinstall any of the base software or subscription management but will instead try to configure a second volume based on the values from the setupvm.config.


