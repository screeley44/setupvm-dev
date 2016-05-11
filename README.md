# setupvm-ose-dev
Simple shell script to provision/configure local or cloud based instance to run single node development cluster from source code for OpenShift/Kubernetes

For RHEL 7.x instances

# How To Run

1.  create RHEL 7.2 AWS instance (t2.Large) (don't forget to add 2nd storage volume for docker registry) - you will run out of memory on builds without t2.large, at least my experience
2.  create unattached volume for use with our pod - note the volumeID
3.  scp the attached script to your VM (I base everything out of /home/ec2-user)
4.  run the script (it's messy right now, so you just pass in some params)

           ./SetUpVM.sh <internal dns name> <sudo or root>  <Y(go1.4) or N(go1.6)> <aws or local> <zone i.e. us-west-2a> <AWS KEY> <AWS Secret> <rhn user> <rhn pass>

           i.e.
           ./SetUpVM.sh ip-172-30-0-191.us-west-2.compute.internal sudo N aws us-west-2a JSHDFLJDSFSDFOERLMDF YT/D0mqkK/4FsP76slkjerojlsjdfp0nCe5LsBtf98 my-rhn-user my-rhn-pass

5.  Script takes about (8 to 10 minutes total) but about 7 minutes in, it will ask to setup docker registry - so look for that as it expects some input
6.  after completion
      - sudo -s   (to work as root and also pick up .bashrc/.bash_profile exports)
      - cd /home/ec2-user/go/src/github.com/kubernetes
      - ./hack/local-up-cluster.sh

      or

      - sudo -s
      - cd /home/ec2-user/go/src/github.com/openshift/origin
      - make clean build
      

7.  open 2nd terminal
      - run ./config-k8.sh  or  ./config-ose.sh
      - cd /home/ec2-user/dev-configs
      - update busybox-ebs.yaml with correct volumeID
      - try to run it
