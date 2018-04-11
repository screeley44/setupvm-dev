  echo "#! /bin/bash" > rmt-etcd.sh

  # Install etcd
  echo "if rpm -qa | grep etcd >/dev/null 2>&1" >> rmt-etcd.sh
  echo "then" >> rmt-etcd.sh
  echo "  echo \"already installed...\"" >> rmt-etcd.sh
  echo "else" >> rmt-etcd.sh
  echo "  if [ \"$ETCD_VER\" == \"default\" ] || [ \"$ETCD_VER\" == \"\" ]" >> rmt-etcd.sh
  echo "  then" >> rmt-etcd.sh
  echo "      yum remove etcd -y> /dev/null" >> rmt-etcd.sh
  echo "      rm -rf /usr/bin/etcd" >> rmt-etcd.sh
  echo "      yum install etcd -y> /dev/null" >> rmt-etcd.sh
  echo "  else" >> rmt-etcd.sh
  echo "      wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null" >> rmt-etcd.sh
  echo "      rm -rf /usr/bin/etcd" >> rmt-etcd.sh
  echo "      tar -zxvf etcd-v$ETCD_VER-linux-amd64.tar.gz> /dev/null" >> rmt-etcd.sh
  echo "      cp etcd-v$ETCD_VER-linux-amd64/etcd /usr/bin" >> rmt-etcd.sh
  echo "  fi" >> rmt-etcd.sh
  echo "fi" >> rmt-etcd.sh
