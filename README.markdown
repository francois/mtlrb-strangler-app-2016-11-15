# Montreal.rb 2016-11-15 Strangler App Talk

This repository is a companion to my talk on the Strangler App pattern that I will give on November 15th, 2016, at Montreal.rb.

## Usage

```sh
vagrant up
vagrant ssh

# Explore the legacy configuration
sudo puppet apply /vagrant/manifests/nginx-legacy.pp

# Explore the strangled configuration
sudo puppet apply /vagrant/manifests/nginx-strangled.pp

# Explore the Sinatra legacy application
sudo puppet apply /vagrant/manifests/sinatra-legacy.pp

# Explore the Sinatra strangled application
sudo puppet apply /vagrant/manifests/sinatra-strangled.pp
```
