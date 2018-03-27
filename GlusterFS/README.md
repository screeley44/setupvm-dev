# GlusterFS Cluster Setup (RHEL or CentOS):

1.  Prereqs:
      - Choose a single server as your Gluster Master and Heketi-Client Server (where you will run the scripts from)
      - Run as root (sudo -s on AWS after logging in as ec2-user)
      - Setup passwordless ssh between the designated `master/heketi-client` to each node
          - generate public key on master gluster server  ```ssh-keygen -t rsa``` 
          - on AWS copy /root/.ssh/id_rsa.pub into hosts /root/.ssh/authorized_keys file
          - on non AWS ssh-copy-id -i /root/.ssh/id_rsa.pub root@server (you will get prompted for password)

2.  clone this repo on the `master` GlusterFS node (pick a single node)

	cd /root
	yum install git -y  (if on a fresh VM)
        git clone https://github.com/screeley44/setupvm-dev.git
        cd /root/setupvm-dev/GlusterFS

3.  Edit the `setupvm.config` with the following variables defined in `setupvm.config` (everything else in `setupvm.config` can be ignored)
      - HOSTENV=rhel or centos (however-have not tested yet on centos)
      - RHNUSER=rhn-support-account (only needed for rhel)
      - RHNPASS=rhn-password (only needed for rhel)
      - POOLID=The Default Should be fine  (only needed for rhel)
      - SETUP_TYPE="gluster" 
      - GFS_LIST="glusterfs1.rhs:glusterfs2.rhs:glusterfs.rhs3:..." (Make sure `master` designated node is first in list)

[NOTE] The script by default will set up the initial volume, you might need to change some values in the setupvm.config to accomodate this for your environment.

4. Execute SetUpGFS.sh

    This will setup a fully functional GlusterFS cluster, Heketi Server and Heketi-Client.  Additional config will be required

      - configure /etc/heketi/heketi.json (script will give you values to configure), restart heketi

