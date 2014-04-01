You can use this build framework to create [Apache Mesos](http://mesos.apache.org/) RPMs.

```
```


The default RPM file is targeted for CentOS and will help you deploy:

* your _masters_ and _slaves_ daemons if working with a cluster.
* your _local_ daemon if working with a single node.
* the _mesos cli_ if you want to build or interact with its _mesos cli_ tools.
* the _mesos development headers_ if you want to build _mesos_ frameworks.

The [spec](spec/mesos-glabs.spec) file has dependencies that can be fulfilled using the EPEL Repo.

Example of running it.

```
export JDK_HOME="/usr/java/jdk1.7.0_51"
export JAVA_HOME="/usr/java/jdk1.7.0_51"
BUILD_NUMBER="${BUILD_NUMBER:-0}" ./mesos-build.sh --qualifier=glabs_h --hashq --buildnumq --command=mock-flow
```

As an example the build will produce the following RPMS

## mesos-cli

Mesos Command Line Utility

## mesos-master

Mesos Master as a Service.

`/sbin/service mesos-master status`


## mesos-slave

Mesos Slave as a Service.

`/sbin/service mesos-slave status`

## mesos-local

Mesos Local as a Service.

`/sbin/service mesos-slave status`
 
## mesos-devel
Headers and static libraries for Mesos

This package contains the libraries and header files needed for
developing with mesos.

# Configuration

Note that the configuration files mentioned have a wild card that '*' will have to be replaced either with 'master', 'slave' or 'local' depending on the daemon that is affecting.

## /etc/sysconfig/mesos-*

Example of `/etc/sysconfig/mesos-master`

```
export JAVA_HOME="/usr/java/jdk1.7.0_51"
export MESOS_USER=root
```
## /etc/mesos/mesos-*.conf


Example of `/etc/mesos/mesos-master`

```
--cluster=Verizion_FiOS_Pineseed
--ip=0.0.0.0
--port=5050
--zk=zk://zk1-verizon-fios-pineseed.guavuslabs.com:2181,zk2-verizon-fios-pineseed.guavuslabs.com:2181,zk3-verizon-fios-pineseed.guavuslabs.com:2181/mesos
--log_dir=/data/var/log/mesos
```

Example of `/etc/mesos/mesos-slave`

```
--frameworks_home=/var/lib/mesos/frameworks
--ip=0.0.0.0
--master=zk://zk1-verizon-fios-pineseed.guavuslabs.com:2181,zk2-verizon-fios-pineseed.guavuslabs.com:2181,zk3-verizon-fios-pineseed.guavuslabs.com:2181/mesos
--port=5051
--recover=reconnect
--work_dir=/tmp/mesos
--log_dir=/data/var/log/mesos
```


# Logfiles

# Example of generated RPMs.

## Source RPM

    mesos-0.19.0-glabs_h.b130.6e7a291.el6.src.rpm

## Binary RPMs

    mesos-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm
    mesos-cli-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm
    mesos-local-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm
    mesos-master-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm
    mesos-slave-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm

## Development Binaries RPMs.

    mesos-debuginfo-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm
    mesos-devel-0.19.0-glabs_h.b130.6e7a291.el6.x86_64.rpm


*NOTE*: It is a work in progress, if you have suggestions feel free to open an issue/enhancement request.
