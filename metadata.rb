name              "mesos-rpm-dummy"
maintainer        "Bernardo Gomez Palacio"
maintainer_email  "bernardo.gomezpalacio@gmail.com"
license           "Apache 2.0"
description       ""
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.0.1"
depends           "yum"
depends           "java"
depends           "mesos-buildbox"

%w{ centos redhat fedora }.each do |os|
  supports os
end

