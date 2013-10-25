# Overview

The spec has been tested only on EL6 with the EPEL repo enabled, but should also work on recent Fedoras, too.

# Building
1.  `mock --init`
1.  `mock --copyin /usr/lib/jvm /usr/lib/jvm`
1.  `mock --shell "ln -sf /proc/mounts /etc/fstab"`
1.  `mock --shell "ln -sf /proc/mounts /etc/mtab"`
1.  `spectool -g mesos-glabs.spec`
1.  `mv <hash-file> <tar file>`
1.  `rpmbuild -bs --nodeps --define "_sourcedir ." --define "_srcrpmdir ." mesos-glabs.spec` 
1.  ```mock --resultdir=$HOME/mock/results --uniqueext=$USER --no-clean --no-cleanup-after `pwd`/mesos-<version>.el6.src.rpm```

You can create an alias for mock such that ` `
