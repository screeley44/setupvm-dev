# setupvm-ose-dev
Simple shell script to provision/configure local or cloud based instance to run single node development cluster from source code for OpenShift/Kubernetes.  This
script will setup and configure a complete dev environment and allow developers to change/update source and switch between K8 and Origin.

For RHEL 7.x instances using normal dev type setup (i.e. hack/local-up-cluster.sh for K8 and openshift start for origin) - Will also begin investigating ansible and vagrant as alternative??)

# How To Run

1.  create RHEL 7.2 AWS instance (t2.Large) or a local VM or GCE Instance (don't forget to add 2nd storage volume for docker registry) - you will run out of memory on builds without t2.large, at least my experience
2.  create unattached volume for use with our pod (if cloud based setup) - note the volumeID or identifier
3.  scp the attached scripts (SetUpVM.sh and setupvm.config) to your VM (I base everything out of /home/$USER, i.e. /home/ec2-user if running on cloud, typically /root if running local VM)
4.  edit or modify the setupvm.config as these are the params used to run the SetUpVM.sh script and allows you to customize your source paths, gopath, etc...
5.  run the script

           ./SetUpVM.sh 

6.  Script takes about (8 to 10 minutes total) but about 7 minutes in, it will ask to setup docker registry - so look for that as it expects some input on what block device to use
7.  after completion
      - sudo -s or exit and log back in or execute the bash profiles  (to work as root and also pick up .bashrc/.bash_profile exports)
      - Change to your source kubernetes directory (based on KUBEWORKDIR parameter) (default if no param was entered is users home directory i.e. /home/ec2-user/go/src/github.com/kubernetes)
      - ./hack/local-up-cluster.sh   (note:  this will build and run the K8 process in this terminal, to stop ctrl+C)

      or

      - sudo -s
      - cd to your source working directory specified in .config file for OSEWORKDIR (default if no param was entered is users home directory i.e. /home/ec2-user/go/src/github.com/openshift/origin)
      - make clean build
      - after completion, you will need to run the start-ose.sh script (these scripts are found in home directory or in your openshift working dir)
      - ./start-ose.sh   (this will run openshift as a process - logging is in home dir or openshift working dir at openshift.log)

8.  open 2nd terminal
      - run ./config-k8.sh  or  ./config-ose.sh
      - cd /home/ec2-user/dev-configs or in one of your working directories (sample files are copied to 3 common locations)
      - update busybox-ebs.yaml with correct volumeID (for ebs)
      - try to run it

# Some Things To Note:

1.  By default, if you did not specify particular work directories in the .config, then everything will go into the current users home directory at the time the script was run.
    All tasks, scripts and configurations (openshift in particular) will be located there.

2.  
