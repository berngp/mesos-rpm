# -*- mode: ruby -*-
# vi: set ft=ruby :
#

user = ENV['USER']
node_name = "mesos-debox-#{user}.local"

Vagrant.configure("2") do |config|
  config.vm.hostname = node_name
  config.vm.box = "opscode_centos-6.5_chef-provisionerless"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box"
  config.vm.boot_timeout = 120
  config.ssh.forward_agent = true
  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []
  
  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []
  
  config.vm.provider :virtualbox do |vb|
     vb.customize ["modifyvm", :id, "--memory", "4096"]
  end

  config.vm.provision :chef_solo do |chef|
    chef.json = { }
    #chef.data_bags_path = "spec/data_bags"
    chef.run_list = [ 
        "recipe[yum]",
        "recipe[yum-epel]",
        "recipe[java]",
        "recipe[maven]",
        "recipe[mesos-buildbox::packages]"
    ]

    chef.json = {
        "java" => {
            "jdk_version" =>  "8",
            "install_flavor" => "oracle",
            "oracle" => {
                "accept_oracle_download_terms" => true,
                "install_flavor" => "oracle"
            }
        }
    }

  end

end
