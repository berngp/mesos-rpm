%global remote_src_tar    %(echo "$REMOTE_SRC_TAR")
%global remote_src_name   %(echo "$REMOTE_SRC_NAME")
%global mesos_version     %(echo "$MESOS_VERSION")
%global build_qualifier   %(echo "$BUILD_QUALIFIER")
%global jdk_home          %(echo "$JDK_HOME")
%global jdk_version       %(echo "$JDK_VERSION")

%define _rel_version         %{?build_qualifier}%{?dist}
%define _full_ver            %{mesos_version}-%{rel_version}

%define _mesos_sysconfdir   %{_sysconfdir}/mesos
%define _mesos_logdir       %{_localstatedir}/log/mesos


Name:           mesos
Version:        %{mesos_version}
Release:        %{_rel_version}
Summary:        Cluster manager that provides resource isolation and sharing distributed application frameworks. Build for jdk %{jdk_version} and above.

License:        ASL 2.0
URL:            http://mesos.apache.org
Group:          Applications/System

Source0:        %{remote_src_tar}
Source1:        mesos-env.sh
Source2:        mesos-masterd.sh
Source3:        mesos-slaved.sh
Source4:        mesos-locald.sh
Source5:        mesos-master.conf
Source6:        mesos-slave.conf
Source7:        mesos-local.conf

Prefix:         /usr
    
BuildRoot:      %{_tmppath}/%{name}-%{_full_ver}-root
BuildRequires:  libtool
BuildRequires:  automake
BuildRequires:  autoconf
BuildRequires:  libcurl-devel
BuildRequires:  zlib-devel
BuildRequires:  http-parser-devel
BuildRequires:  gmock-devel
BuildRequires:  gtest-devel
BuildRequires:  gperftools-devel
BuildRequires:  libev-devel
BuildRequires:  leveldb-devel
BuildRequires:  protobuf-devel
BuildRequires:  python
BuildRequires:  python-boto
BuildRequires:  python-setuptools
# Apparently we need protobuf-python 2.4 or above to make the test pass.
#BuildRequires:  protobuf-python
#BuildRequires:  protobuf-java
BuildRequires:  python-devel
BuildRequires:  openssl-devel
BuildRequires:  cyrus-sasl-devel
BuildRequires:  cyrus-sasl-md5
BuildRequires:  cyrus-sasl-plain
#BuildRequires:  java-devel
#BuildRequires:  systemd

Requires:  openssl
Requires:  zlib
Requires:  libcurl  
Requires:  cyrus-sasl
Requires:  cyrus-sasl-md5
Requires:  cyrus-sasl-plain
Requires:  daemonize

Requires(pre):  chkconfig
Requires(pre):  initscripts
Requires(pre):  shadow-utils

# For now we will disable checks.
# Requires: logrotate, java
# consider adding google performance tools to the build as an optional dependency. ref. http://google-perftools.googlecode.com/svn/trunk/doc/cpuprofile.html
AutoReq:    no

Provides:   mesos

Packager:   Bernardo Gomez Palacio <bernardo.gomezpalacio@gmail.com>

%description
Cluster manager that provides resource isolation and sharing distributed application frameworks
#@BUILD_DESCRIPTION@

%prep
%setup -q -n %{remote_src_name}

%build
./bootstrap
JAVA_HOME=%{jdk_home}; export JAVA_HOME;
%configure --disable-static
%{__make} %{?_smp_mflags}

%clean
rm -rf %{buildroot}

%check
MESOS_VERBOSE=1; export MESOS_VERBOSE
GLOG_v=1; export GLOG;
GLOG_logtostderr=true; export GLOG_logtostderr;

# Skipping FsTest since they currently fail in a Mock (Chroot) environment since
# structure describing a mount table (e.g. /etc/mtab or /proc/mounts).
GTEST_FILTER="-FsTest.*"; export GTEST_FILTER

%{__make} check GTEST_FILTER="$GTEST_FILTER"

#TODO - systemd integration
%pre
getent group mesos >/dev/null || groupadd -r mesos
getent passwd mesos >/dev/null || /usr/sbin/useradd --comment "Mesos Daemon User" -r -g mesos -s /sbin/nologin mesos
exit 0

%install
%make_install
rm -rf %{buildroot}%{_libdir}/*.la
install -p -D -m 755  %{S:1} %{buildroot}%{_sbindir}/mesos-env.sh 
install -p -D -m 755  %{S:2} %{buildroot}%{_sbindir}/mesos-masterd.sh 
install -p -D -m 755  %{S:3} %{buildroot}%{_sbindir}/mesos-slaved.sh 
install -p -D -m 755  %{S:4} %{buildroot}%{_sbindir}/mesos-locald.sh 
install -p -D -m 444  %{S:5} %{buildroot}%{_mesos_sysconfdir}/templates/mesos-master.conf
install -p -D -m 444  %{S:6} %{buildroot}%{_mesos_sysconfdir}/templates/mesos-slave.conf
install -p -D -m 444  %{S:7} %{buildroot}%{_mesos_sysconfdir}/templates/mesos-local.conf

install -d -m 755 %{buildroot}%{_mesos_logdir}

# TODO: Determine the best home for the deployment templates. 
mv -f %{buildroot}%{_var}/mesos/deploy %{buildroot}%{_datadir}/mesos/

%files
%defattr(-,root,root,-)
%doc LICENSE README.md
%{_libdir}/libmesos*.so
%{_bindir}/mesos-*
%{_bindir}/mesos-*
%{_sbindir}/mesos-*
%{_datadir}/mesos/
%{_libexecdir}/mesos/
%{_mesos_sysconfdir}/
%{_mesos_logdir}/

#===============================================================================================
# Command Tool
#===============================================================================================
%package -n mesos-cli
Summary: Mesos Command Line Utility
Group: Applications/System
Requires: mesos

%description -n mesos-cli
Mesos Command Line Utility

%files -n mesos-cli
%defattr(-, root, root, -)
%{_bindir}/mesos


#===============================================================================================
# Master
#===============================================================================================
%package -n mesos-master
Summary: mesos master
Group: Applications/System
Requires: mesos-cli

%description -n mesos-master
Mesos Master as a Service.

%files -n mesos-master
%defattr(-, root, root, -)

%post -n mesos-master
/bin/ln -sf %{_sbindir}/mesos-masterd.sh %{_initddir}/mesos-master
/sbin/chkconfig --add mesos-master
/bin/mkdir %{_mesos_logdir}/mesos-master
/bin/chown -R mesos:mesos %{_mesos_logdir}

%preun -n mesos-master 
if [ $1 = 0 ] ; then
    /sbin/service mesos-master stop >/dev/null 2>&1
    /sbin/chkconfig --del mesos-master
fi

%postun -n mesos-master
if [ "$1" -ge "1" ] ; then
    /sbin/service mesos-master condrestart >/dev/null 2>&1 || :
fi

#===============================================================================================
# Slave
#===============================================================================================
%package -n mesos-slave
Summary: slave
Group: Applications/System
Requires: mesos

%description -n mesos-slave
Mesos Slave as a Service.

%files -n mesos-slave
%defattr(-, root, root, -)

%post -n mesos-slave
/bin/ln -sf %{_sbindir}/mesos-slaved.sh %{_initddir}/mesos-slave
/sbin/chkconfig --add mesos-slave
/bin/mkdir %{_mesos_logdir}/mesos-slave
/bin/chown -R mesos:mesos %{_mesos_logdir}

%preun -n mesos-slave
if [ $1 = 0 ] ; then
    /sbin/service mesos-slave stop >/dev/null 2>&1
    /sbin/chkconfig --del mesos-slave
fi

%postun -n mesos-slave
if [ "$1" -ge "1" ] ; then
    /sbin/service mesos-slave condrestart >/dev/null 2>&1 || :
fi

#===============================================================================================
# Local Install
#===============================================================================================
%package -n mesos-local
Summary: mesos-local
Group: Applications/System
Requires: mesos-cli

%description -n mesos-local
Mesos Local as a Service.

%files -n mesos-local
%defattr(-, root, root, -)

%post -n mesos-local
/bin/ln -sf %{_sbindir}/mesos-locald.sh %{_initddir}/mesos-local
/sbin/chkconfig --add mesos-local
/bin/mkdir %{_mesos_logdir}/mesos-local
/bin/chown -R mesos:mesos %{_mesos_logdir}

%preun -n mesos-local
if [ $1 = 0 ] ; then
    /sbin/service mesos-local stop >/dev/null 2>&1
    /sbin/chkconfig --del mesos-local
fi

%postun -n mesos-local
if [ "$1" -ge "1" ] ; then
    /sbin/service mesos-local condrestart >/dev/null 2>&1 || :
fi
 
#===============================================================================================
# Dev Install
#===============================================================================================
%package -n mesos-devel
Summary: Headers and static libraries for Mesos
Group: Development/Libraries
Requires: gcc

%description -n mesos-devel
This package contains the libraries and header files needed for
developing with mesos.

%files -n mesos-devel
%defattr(-, root, root, -)
%{_includedir}/mesos/


%changelog
* Mon Nov 5 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@gmail.com>
- Added the Mesos CLI tool as is now available in version 0.16.0. This means that this spec works with Mesos versions 0.16.0 and above.

* Mon Nov 4 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@gmail.com>
- Package restructuring based on the work that Timothy St. Clair <tstclair@redhat.com> put into <https://github.com/timothysc/mesos-rpm>

* Wed Aug 28 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@gmail.com>
- Adding the daemon scripts and init.d setup for mesos-master, mesos-slave and mesos-local.

* Mon Aug 19 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@gmail.com>
- Wrote mesos.spec based on Tomothy St. Clair mesos.spec at 
# todo insert git tag description and potentially cat some changelog from the repo.
