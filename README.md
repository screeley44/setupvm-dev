# setupvm-ose-dev
Simple shell script to provision/configure local or cloud based instance to run single node development cluster from source code for OpenShift/Kubernetes

For RHEL 7.x instances

# How To Run

1.  create RHEL 7.2 AWS instance (t2.Large) (don't forget to add 2nd storage volume for docker registry) - you will run out of memory on builds without t2.large, at least my experience
2.  create unattached volume for use with our pod - note the volumeID
3.  scp the attached scripts (SetUpVM.sh and setupvm.config) to your VM (I base everything out of /home/$USER, i.e. /home/ec2-user if running on cloud, typically /root if running local VM)
4.  edit or modify the setupvm.config as these are the params used to run the SetUpVM.sh script
5.  run the script

           ./SetUpVM.sh 

6.  Script takes about (8 to 10 minutes total) but about 7 minutes in, it will ask to setup docker registry - so look for that as it expects some input
7.  after completion
      - sudo -s   (to work as root and also pick up .bashrc/.bash_profile exports)
      - cd /home/ec2-user/go/src/github.com/kubernetes
      - ./hack/local-up-cluster.sh   (note:  this will build and run the K8 process in this terminal, to stop ctrl+C)

      or

      - sudo -s
      - cd /home/ec2-user/go/src/github.com/openshift/origin
      - make clean build
      - after completion, cd back to your home directory where all the scripts are stored
        
           cd /home/ec2-user or cd /root   (depending on what user you used to run the script)
      
      - ./start-ose.sh   (this will run openshift as a process - logging is in home dir at openshift.log)

8.  open 2nd terminal
      - run ./config-k8.sh  or  ./config-ose.sh
      - cd /home/ec2-user/dev-configs
      - update busybox-ebs.yaml with correct volumeID
      - try to run it

# Some Things To Note:

1.  By default, if you did not specify particular work directories in the .config, then everything will go into the current users home directory at the time the script was run.
    All tasks, scripts and configurations (openshift in particular) will be located there.

2.  
