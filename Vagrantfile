# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/yakkety64"
  config.vm.box_check_update = true
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.253.233"

  config.vm.provision "shell", inline: <<-EOS
    apt-get update && apt-get upgrade -y && apt-get install -y puppet
  EOS

  config.vm.provision "puppet" do |puppet|
    puppet.environment_path = "puppet/environments"
    puppet.environment      = "production"
    puppet.manifests_path   = "puppet/environments/production/manifests"
    puppet.manifest_file    = "site.pp"
  end
end
