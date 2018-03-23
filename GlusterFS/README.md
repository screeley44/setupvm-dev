# GlusterFS Cluster Setup (RHEL or CentOS):

1.  Prereqs:
      - Choose a single server as your Gluster Master and Heketi-Client Server (where you will run the scripts from)
      - Run as root (sudo -s on AWS after logging in as ec2-user)
      - Setup passwordless ssh between the designated `master/heketi-client` to each node
          - generate public key on master gluster server  ```ssh-keygen -t rsa``` 
          - on AWS copy /root/.ssh/id_rsa.pub into hosts /root/.ssh/authorized_keys file
          - on non AWS ssh-copy-id -i /root/.ssh/id_rsa.pub root@server (you will get prompted for password)

2.  scp the `setupvm.config` , `SetUpGFS.sh`, and `SetUpVM.sh` or clone this repo on the `master` GlusterFS node (pick a single node)

3.  Edit the `setupvm.config` with the following variables defined in `setupvm.config` (everything else in `setupvm.config` can be ignored)
      - HOSTENV=rhel or centos (however-have not tested yet on centos)
      - RHNUSER=rhn-support-account (only needed for rhel)
      - RHNPASS=rhn-password (only needed for rhel)
      - POOLID=The Default Should be fine  (only needed for rhel)
      - SETUP_TYPE="gluster"  (If co-locating dev instance and `master` gluster node use `gluster-dev` for this value)
      - GFS_LIST="glusterfs1.rhs:glusterfs2.rhs:glusterfs.rhs3:..." (Make sure `master` designated node is first in list)


4. Execute SetUpGFS.sh (SetUpVM.sh should call and execute SetUpGFS.sh as well, but again, not tested yet)

    This will setup a basic GlusterFS cluster (no partitions or volumes will be created, that is manual or can be done by Heketi, just vanilla cluster), Heketi Server and Heketi-Client.  Additional config will be required

      - configure /etc/heketi/heketi.json (script will give you values to configure), restart heketi

