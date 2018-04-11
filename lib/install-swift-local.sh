#! /bin/bash

if [ "$HOSTENV" == "rhel" ] && [ "$INSTALL_SWIFT" == "Y" ]
then  
  echo "...Installing OpenStack Swift and Clients"

  # enable full OSE repos for Swift
  subscription-manager repos --enable="rhel-7-server-ose-$OCPVERSION-rpms" 


  yum install openstack-swift-* -y> /dev/null
  yum install python-scandir python-prettytable git -y> /dev/null

  cd /opt
  git clone https://github.com/gluster/gluster-swift
  cd gluster-swift 
  python setup.py install

  mkdir -p /etc/swift/
  cp etc/* /etc/swift/
  cd /etc/swift

  for tmpl in *.conf-gluster ; do cp ${tmpl} ${tmpl%.*}.conf; done
  gluster-swift-gen-builders $GFS_VOLNAME

  # Install swiftclient and memcached
  yum install python-swiftclient memcached -y> /dev/null

  systemctl start memcached
  systemctl enable memcached

  # For security, add -U 0 to OPTIONS in /etc/sysconfig/memcached
  sed -i "s/OPTIONS=\"\"/OPTIONS=\"-U 0\"/" /etc/sysconfig/memcached
  systemctl restart memcached

fi
