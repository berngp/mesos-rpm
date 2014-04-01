#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a wrapper for running mesos-slave before it is installed
# that first sets up environment variables as appropriate.


# mesos-slaved - Startup script for Mesos Slave

# chkconfig: 35 85 15
# description: 
# processname: mesos-slave
# config: /etc/mesos-slave.conf
# pidfile: /var/run/mesos-slaved.pid

. /etc/rc.d/init.d/functions

# NOTE: if you change any OPTIONS here, you get what you pay for:
# this script assumes all options are in the config file.

PRG="$0"

declare -i do_daemonize=1

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

# Establish which Command we are going to run.
mesosd=`which mesos-slave`
if [ ! -n "$mesosd" ]; then
   echo $"ERROR: It appears that the file $mesosd is unreachable or unexecutable."
   exit -1
fi
prog=$(basename $mesosd)

# Source the default environment variables.
ENV="$PRGDIR/mesos-env.sh"
if [ -f "$ENV" ]; then
    source $ENV
else
    echo "ERROR Environment file $ENV is missing!"
    exit -1
fi

function start()
{
    [ -x $mesosd ] || exit 5
    echo -n $"Starting Mesos Slave ($mesosd):"

    if [[ $do_daemonize -eq 1 ]]; then
      daemonize -a -e "$OUT_FILE" -o "$OUT_FILE" -p "$PIDFILE" -l "$LOCKFILE" -u "$MESOS_USER" $NUMACTL $mesosd $OPTIONS
      
      RETVAL=$?
      if [ $RETVAL -eq 0 ]; then
          touch "$LOCKFILE"
          success
      else
          failure
      fi

    else
      su -u "$MESOS_USER" -c "$NUMACTL $mesosd $OPTIONS"
    fi

    echo
    return $RETVAL
}

function stop()
{
    echo -n $"Stopping Mesos Slave ($mesosd): "
    killproc $prog -SIGTERM
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f $LOCKFILE
    echo
    return $RETVAL
}


function restart()
{
    stop
    start
}

function reload()
{
    echo -n $"Reloading $prog: "
    killproc $prog -HUP
    RETVAL=$?
    echo
    return $RETVAL
}

function force_reload()
{
    restart
}
 
function rh_status()
{
    status $prog
}
 
function rh_status_q()
{
    rh_status >/dev/null 2>&1
}

ulimit -n 12000
RETVAL=0

while test $# -gt 0; do
  case "$1" in
    --no-daemonize)
      do_daemonize=0 && shift ;;
    start)
      start
      ;;
    stop)
      stop
      ;;
    restart|reload|force-reload)
      restart
      ;;
    condrestart)
      [ -f "$LOCKFILE" ] && restart || :
      ;;
    status)
      status $mesosd
      RETVAL=$?
      ;;
    *)
      echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
      RETVAL=1
  esac
done


exit $RETVAL
