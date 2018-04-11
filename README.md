# Set Up OCP, K8, GlusterFS, CNV, etc... VM's or cloud instances
This repo has some scripts to perform various developer type functions to help set up bare metal, local VM or cloud instances of environments that are ready to be used as development environment for testing and whatever else you want to use them for.

## Some Features
- supports RHEL and CentOS
- local-up-cluster.sh K8 node for quick easy development (local or cloud enabled)
- kube-up.sh K8 node to help spin up a multi-node cluster
- base system prereqs and components for OCP production or development instances
- Stand-Up a fully functional GlusterFS cluster with Trusted Storage Pool and Initial Volume.
- CNV, CRS, CNS and Halo support
- and more


## How To Run

1.  Create an instance in AWS or GCE (rhel or centos) or a local VM (or multiple)
2.  Clone this repo or download the desired `setup` scripts from the correct directory repo on your desired install node.
3.  follow the README.md in each of the sub-directory for more detailed instructions, but basically, you configure the `setupvm.config` to pass in parameters and control what you want to install and
    after that execute the associated shell script (i.e. SetUpGFS.sh, SetUpK8.sh, SetUpOrigin.sh, SetUpVM.sh, etc...)


