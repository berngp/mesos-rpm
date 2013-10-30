name              "mesos-rpm-berkplacehodler"
maintainer        "Guavus, Inc."
maintainer_email  "bernardo.palacio@guavus.com"
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

