#! /bin/bash
# Some automation to setting up OSE/K8 VM's

if [ "$HEKETI_VERSION" == "default" ]
then
  yum install -y heketi heketi-client> /dev/null
else
  echo "Installing heketi-client 5..."
  wget https://github.com/heketi/heketi/releases/download/$HEKETI_VERSION/heketi-client-$HEKETI_VERSION.linux.amd64.tar.gz
  mkdir -p /etc/heketi && tar xzvf heketi-client-$HEKETI_VERSION.linux.amd64.tar.gz -C /etc/heketi
fi

# some heketi key stuff
ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''> /dev/null
chown heketi:heketi /etc/heketi/heketi_key*

HCLI=http://"${gfs[index]}":8080

firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --reload
