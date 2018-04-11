#! /bin/bash

if [ "$HOSTENV" == "rhel" ] && [ "$INSTALL_SWIFT" == "Y" ]
then  
  echo "...Remotely Installing OpenStack Swift and Clients"

  # enable full OSE repos for Swift
  echo "subscription-manager repos --enable=\"rhel-7-server-ose-$OCPVERSION-rpms\"> /dev/null" >> rmt-swift.sh 

  echo "yum install openstack-swift-* -y> /dev/null" >> rmt-swift.sh
  echo "yum install python-scandir python-prettytable git -y> /dev/null" >> rmt-swift.sh

  echo "cd /opt" >> rmt-swift.sh
  echo "git clone https://github.com/gluster/gluster-swift" >> rmt-swift.sh
  echo "cd gluster-swift" >> rmt-swift.sh
  echo "python setup.py install" >> rmt-swift.sh

  echo "mkdir -p /etc/swift/" >> rmt-swift.sh
  echo "cp etc/* /etc/swift/" >> rmt-swift.sh
  echo "cd /etc/swift" >> rmt-swift.sh

  echo "for tmpl in *.conf-gluster ; do cp \${tmpl} \${tmpl%.*}.conf; done" >> rmt-swift.sh
  echo "gluster-swift-gen-builders $GFS_VOLNAME" >> rmt-swift.sh

  # Install swiftclient and memcached
  echo "yum install python-swiftclient memcached -y> /dev/null" >> rmt-swift.sh

  echo "systemctl start memcached" >> rmt-swift.sh
  echo "systemctl enable memcached" >> rmt-swift.sh

  # For security, add -U 0 to OPTIONS in /etc/sysconfig/memcached
  echo "sed -i \"s/OPTIONS=\"\"/OPTIONS=\"-U 0\"/\" /etc/sysconfig/memcached" >> rmt-swift.sh
  echo "systemctl restart memcached" >> rmt-swift.sh

fi
