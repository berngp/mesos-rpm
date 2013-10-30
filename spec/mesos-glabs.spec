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
BuildRequires:  automake,autoconf,python >= 2.4,python-devel,gcc,make,libtool,autoconf,libcurl-devel,zlib-devel,openssl-devel,cyrus-sasl-devel
Requires:       openssl,zlib,libcurl,daemonize,cyrus-sasl,cyrus-sasl-plain,cyrus-sasl-md5
Requires(pre):  shadow-utils chkconfig initscripts
Requires(post): chkconfig initscripts

# For now we will disable checks.
# Requires: logrotate, java
# consider adding google performance tools to the build as an optional dependency. ref. http://google-perftools.googlecode.com/svn/trunk/doc/cpuprofile.html
AutoReq:    no

Provides:   mesos

Packager:   Guavus Labs Tech Team <labs@guavus.com>

%description
Cluster manager that provides resource isolation and sharing distributed application frameworks
#@BUILD_DESCRIPTION@

%prep
%setup -q -n %{remote_src_name}

%build
./bootstrap
#autoheader
#libtoolize --force
#aclocal
#automake -a
#autoreconf -vfi
JAVA_HOME=%{jdk_home}; export JAVA_HOME;
%configure
%{__make} %{?_smp_mflags}

%clean
rm -rf %{buildroot}

%check
GLOG_minloglevel=0; export GLOG_minloglevel;
GLOG_logtostderr=true; export GLOG_logtostderr;
%{__make} check

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
%doc LICENSE README
%{_libdir}/libmesos*.so
%{_bindir}/mesos-*
%{_sbindir}/mesos-*
%{_datadir}/mesos/
%{_libexecdir}/mesos/
%{_mesos_sysconfdir}/
%{_mesos_logdir}/

#===============================================================================================
# Master
#===============================================================================================
%package -n mesos-master
Summary: mesos master
Group: Applications/System
Requires: mesos

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
Requires: mesos

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
* Wed Aug 28 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@guavus.com>
- Adding the daemon scripts and init.d setup for mesos-master, mesos-slave and mesos-local.

* Mon Aug 19 2013 Bernardo Gomez Palacio. <bernardo.gomezpalacio@guavus.com>
- Wrote mesos.spec based on Tomothy St. Clair mesos.spec at 
# todo insert git tag description and potentially cat some changelog from the repo.
