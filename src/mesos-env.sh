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

# This file is meant to be sourced.
# It sets environment variables so Mesos will search for uninstalled
# dependencies (such as the WebUI) rather than looking in installed locations.

#prefix=@prefix@
#exec_prefix=@exec_prefix@

# Load external environments if available. 
if   [ -e "$HOME/.mesos/$prog" ] ; then
    MESOS_ENV_SH="$HOME/.mesos/$prog"
elif [ -e "/etc/sysconfig/$prog" ] ; then
    MESOS_ENV_SH="/etc/sysconfig/$prog"
fi

if [ -e "$MESOS_ENV_SH" ]; then
    echo "MESOS Env found at [${MESOS_ENV_SH}]"
    source "$MESOS_ENV_SH"
fi

# Account used to start the process.
MESOS_USER=${MESOS_USER-mesos}
MESOS_GROUP=${MESOS_GROUP-mesos}

# Make sure a log file is defined.
LOG_DIR=${LOG_DIR:="/var/log/mesos/$prog"}
if [ ! -d "$LOG_DIR" ]; then
    echo "Making $LOG_DIR"
    mkdir -p "$LOG_DIR"
    chown -R "$MESOS_USER:$MESOS_GROUP" "$LOG_DIR"
fi
# Setup Configuration Directory
if [ -f "/etc/mesos/$prog.conf"  ]; then
    CONFIGFILE="/etc/mesos/$prog.conf"
else
    CONFIGFILE=""
fi
# Initialize the _Command_ options.
#OPTIONS="--log_dir=$LOG_DIR"
OPTIONS=""
if [ -n "$CONFIGFILE" ]; then
    OPTIONS_F=`paste -d " " <(cat "${CONFIGFILE}" | grep -e "^[--]" )`
    if [ -n "$OPTIONS_F" ]; then
        OPTIONS="$OPTIONS $OPTIONS_F"
    fi
fi

# NUMA
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
    NUMACTL="`which numactl` $NUMACTL_ARGS"
else
    NUMACTL=""
fi

# Make sure pid and lock files are defined.
LOCKFILE=${LOCKFILE:-"/var/lock/subsys/$prog"}
PIDFILE=${PIDFILE:-"/var/run/$prog.pid"}

OUT_FILE="${LOG_DIR}/$prog.out"

