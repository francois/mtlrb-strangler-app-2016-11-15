# Montreal.rb 2016-11-15 Strangler App Talk

This repository is a companion to my talk on the Strangler App pattern that I will give on November 15th, 2016, at Montreal.rb.

## Usage

```sh
vagrant up
vagrant ssh

# Explore the legacy configuration
sudo puppet apply /vagrant/manifests/nginx-legacy.pp

# Explore the strangled reverse proxied configuration
sudo puppet apply /vagrant/manifests/nginx-strangled.pp

# Explore the strangled Rails engine configuration
sudo puppet apply /vagrant/manifests/sinatra-strangled.pp
```


## Legacy App

This is a regular Sinatra app, reverse proxied using Nginx. The Sinatra app listens on 127.0.0.1:4000. All requests will hit this Sinatra app. The task is to replace the reporting section with a more performant one.


## Reverse Proxying the solution in place

Using Nginx, we will strangle the `/report` URL space to a new app. To this end, we create a new Sinatra app, and tell nginx to proxy to a new upstream:

```
# Declare an upstream to which we can reverse proxy
upstream legacy {
  server 127.0.0.1:4000;
}

# Same thing, except we now have two upstream to which we can proxy requests to
upstream replacement {
  server 127.0.0.1:4001;
}

server {
  listen 80 default;
  server_name 127.0.0.1;

  # Tell Nginx that all paths starting with the /report prefix must go to the replacement upstream
  location /report {
    proxy_pass http://replacement;
  }

  # Everything else should be forwarded to the legacy app
  location / {
    proxy_pass http://legacy;
  }
}
```
