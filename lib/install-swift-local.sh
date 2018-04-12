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

if [ "$ADD_SWIFT3" == "Y" ]
then
  wget https://pypi.python.org/packages/source/s/setuptools/setuptools-7.0.tar.gz --no-check-certificate
  tar xzf setuptools-7.0.tar.gz;  cd setuptools-7.0
  python setup.py install
  wget https://bootstrap.pypa.io/get-pip.py
  python get-pip.py
  pip install --upgrade requests

  git clone https://github.com/openstack/swift3; cd swift3/
  sed -i '1s/.*/ /' requirements.txt
  sed -i '3s/.*/ /' requirements.txt
  python setup.py install
fi

# copy config files
cd /opt/gluster-swift/conf
cp account-server.conf container-server.conf proxy-server.conf object-server.conf /etc/swift/.
cp webhook.py /usr/lib/python2.7/site-packages/swift/common/middleware/.
