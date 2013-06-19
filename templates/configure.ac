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

# Generated with autoscan, then modified appropriately.
# Process this file with autoconf to produce a configure script.
AC_PREREQ([2.61])
AC_INIT([incubator-mesos-rpm], [0.1.0])

AC_ARG_VAR([MESOS_VERSION],
           ["Version of Mesos that we are going to use. e.g 0.11.0-incubating-RC3"])

if test -z "$MESOS_VERSION"; then
    AC_MSG_ERROR(["Please give us a MESOS_VERSION"])
else
    RPM_MESOS_VERSION="`echo $MESOS_VERSION| sed -e 's/-/_/g'`"
fi

AC_ARG_VAR([RPM_SOURCE_URL],
           ["URL used to pull the sources from, defaults to https://github.com/apache/incubator-mesos/archive/release-$MESOS_VERSION.zip"])

if test "x$RPM_SOURCE_URL" = "x"; then
    RPM_SOURCE_URL="incubator-mesos-$MESOS_VERSION.zip"
fi

AC_SUBST(MESOS_VERSION)
AC_SUBST(RPM_MESOS_VERSION)
AC_SUBST(RPM_SOURCE_URL)

AC_CONFIG_FILES([apache-mesos.spec])

AC_OUTPUT
