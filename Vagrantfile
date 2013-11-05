# -*- mode: ruby -*-
# vi: set ft=ruby :
#

user = ENV['USER']
node_name = "mesos-rpm-buildbox-#{user}.local"

Vagrant.configure("2") do |config|
  config.vm.hostname = node_name
  config.vm.box = "Berkshelf-CentOS-6.3-x86_64-minimal"
  config.vm.box_url = "https://dl.dropbox.com/u/31081437/Berkshelf-CentOS-6.3-x86_64-minimal.box"
  config.vm.network :private_network, ip: "33.33.33.10"
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
     vb.customize ["modifyvm", :id, "--memory", "5108"]
  end

  config.vm.provision :chef_solo do |chef|
    chef.json = { }
    #chef.data_bags_path = "spec/data_bags"
    chef.run_list = [ 
        "recipe[yum]",
        "recipe[java]",
        "recipe[mesos-buildbox::packages]" 
    ]

    chef.json = {
        "java" => {
            "jdk_version" =>  "7",
            "oracle" => {
                "accept_oracle_download_terms" => true,
                "install_flavor" => "oracle"
            }
        }
    }

  end

end
