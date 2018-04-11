  echo "#! /bin/bash" > rmt-go.sh
  echo "yum install wget -y> /dev/null" >> rmt-go.sh
  echo "if [ \"$GOVERSION\" == \"yum\" ] || [ \"$GOVERSION\" == \"\" ]" >> rmt-go.sh
  echo "then" >> rmt-go.sh
  echo "  yum install go -y> /dev/null" >> rmt-go.sh
  echo "else" >> rmt-go.sh
  echo "  cd ~" >> rmt-go.sh
  echo "  wget https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz> /dev/null" >> rmt-go.sh
  echo "  rm -rf /usr/local/go" >> rmt-go.sh
  echo "  rm -rf /bin/go" >> rmt-go.sh		
  echo "  tar -C /usr/local -xzf go$GOVERSION.linux-amd64.tar.gz> /dev/null" >> rmt-go.sh
  echo "fi" >> rmt-go.sh
