# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder ".", "/home/vagrant/fullstack"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3096"
    vb.name = "django-fullstack"
  end

  config.vm.provision "shell", path: "provision/install.sh"

end
