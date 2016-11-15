# Montreal.rb 2016-11-15 Strangler App Talk

This repository is a companion to my talk on the Strangler App pattern that I gave on November 15th, 2016, at Montreal.rb.

## First steps

```sh
vagrant up
vagrant ssh
cd /vagrant
```

## The Strangler Pattern

The [Strangler Pattern](http://martinfowler.com/bliki/StranglerApplication.html) is a pattern that enables you to selectively replace parts of your app.
Instead of scheduling a [big-bang rewrite (which almost never works)](http://www.joelonsoftware.com/articles/fog0000000069.html), you selectively replace
parts of your application, until the application has been completely replaced.

In the context of web applications, we already have a way to address parts of the application: the URL. We can replace portions of the address space of
our application by replacing selective URLs with a new version. Eventually, you will have replaced most of the functionality of your application, and
you can simply stop serving the legacy application.

In this repository, you will find two methods to strangle your app:

* [Strangling by mounting the legacy app as a Rails engine](#strangling-by-mounting-the-legacy-app-as-a-rails-engine)
* [Strangling using a reverse proxy](#strangling-by-reverse-proxying)


## Strangling by mounting the legacy app as a Rails engine

This technique boils down to mounting a Rack application in the URL space of the Rails application. Of course, this
will only work if the legacy application is a Ruby web application and the replacement app is based on Rails. If you
want to replace with an Elixir application instead, you will have to use the
[Strangling by reverse proxying](#strangling-by-reverse-proxying) method.

When I say "Rails engine", I really mean "anything that is Rack based". Since all Ruby web application frameworks execute
with Rack, this essentially means you could mount a legacy Rails application in a Hanami application. The essence of the
pattern remains, even if the details are different. For example, you would mount the Rails application using Rack's `use`
instead of using Hanami's routing infrastructure.

### Turn the legacy app into a Gem

The first thing you must do is turn your legacy application into a Gem. Create a gemspec in your legacy app's root:

```ruby
# coding: utf-8
# ...

Gem::Specification.new do |spec|
  # ...

  # CRITICAL: make sure you require the correct version of Sinatra
  # CRITICAL: if you are strangling a Rails application, you MUST use the same Rails version
  #           this may be undesired, in which case you will have to use the reverse proxy version of the strangler pattern
  spec.add_dependency "sinatra", ">= 2.0.0.beta2"

  # You must also migrate all other dependencies in the gemspec
  # spec.add_dependency "sequel"
  # spec.add_dependency "redis"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
```

Make your `Gemfile` reference the gemspec:

```ruby
source "https://rubygems.org"

# This tells Bundler to load the dependencies using the gemspec
gemspec
```

During the creation of the gemspec, you must migrate all dependencies of your application to the gemspec.
This is required to enable Bundler to take the correct decisions as to what versions of dependencies to use
for both applications. If Bundler is unable to resolve the gemspecs, if you have conflicts, you will have to
use the reverse proxy version of the strangler application pattern.

After you migrated the dependencies, run `bundle install` and make sure all dependencies are correctly resolved.
It would also be a good idea to run any tests you have, as well as make a manual run-through of your application,
to ensure the dependencies are correctly migrated.

### Reference the legacy gem from a fresh Rails application

The next step is to create your new Rails application: `rails new replacement`

In your `Gemfile`, reference the gem we just created:

```ruby
source 'https://rubygems.org'

# Reference the gem using the filesystem
# If you prefer, simply point to a Git repository
gem 'legacy', path: '../legacy'

gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# ...
```

### Mount the legacy app **inside** the Rails application URL space

Next, you want to require and mount your application within the Rails URL space:

```ruby
# config/routes.rb
# require_dependency works because both applications live on the same filesystem, with
# known locations. If you are deploying using a Gem, you will have to change your legacy
# app to be more like a Gem, where you can load the app using a regular require directive.
require_relative '../../legacy/app'

Rails.application.routes.draw do
  mount Sinatra::Application, at: "/"
end
```

At this point, if you boot your Rails application and hit the root URL, you should see the legacy application's
home page. Again, if you run through your application, you should not notice any changes: all requests are
routed to the legacy application.

### Strangling report generation with a Rails engine

Our task today is to replace the reporting section. Maybe there is a new backend, or the schema was optimized. In order
to do that, we have to remember that Rails executes `config/routes.rb` in order: the first URL that matches will be served
first. Since this version only wants to replace the `/report` URL and below, we must tell Rails that the legacy application
will handle anything that the Rails router hasn't already handled.

Create your controller, then link it within `config/routes.rb`:

```ruby
# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  def show
    @id = params[:id]
    render
  end
end

# config/routes.rb
require_relative '../../legacy/app'

Rails.application.routes.draw do
  get '/report(/:id)', to: 'reports#show'

  # Keep this line last, as this will handle anything
  # that is not explicitly handled by the Rails application
  mount Sinatra::Application, at: "/"
end
```

As you can see, this is a classic Rails controller, with a classic route to it. The new reports can be saved, which is
why the ID parameter is optional.

Notice the order in `config/routes.rb`: first, we check if the URL is in the `/report` section, and if so, let the replacement
Rails app handle the requests. If that fails, we let **all** other requests fall-through to the Sinatra-based application.

As you strangle more and more of the application, you will add other routes **above** the legacy app, eventually removing the
reference to the legacy application when you've migrated 100% of your application.


## Strangling by reverse proxying

This technique boils down to using Nginx (or any reverse proxying HTTP server) to route requests to two or more applications.
Initially, we have only one application, and we reverse proxy into the legacy application:

```
upstream app {
  server 127.0.0.1:4000;
}

server {
  listen 80 default;

  location / {
    proxy_pass http://app;
  }
}

```

This block proxies any HTTP requests on port 80 to `127.0.0.1:4000`. We now want to route a portion of the URL space to the
replacement application. We first start by building a new app, and test it in isolation. We will now have two applications:
the legacy application and it's replacement. Both apps are **unaware** of each other. They share no code. The Nginx
configuration will now become:

```
upstream legacy {
  server 127.0.0.1:4000;
}

upstream replacement {
  server 127.0.0.1:4001;
}

server {
  listen 80 default;

  location /report {
    proxy_pass http://replacement;
  }

  location / {
    proxy_pass http://legacy;
  }
}

```

This configuration tells Nginx to route any URL that **starts with** `/report` to `127.0.0.1:4001` and route any other URL
to `127.0.0.1:4000`. Here too order is significate: Nginx interprets this block as a program.


## Evaluation

As with anything, there are pros and cons to each technique:

### Pros of strangling inside a Rails app

The two applications share a single address space: all code is shared between the two applications. This means the Ruby
process itself, but also any models and constants. In memory constrained scenarios, this may be advantageous.

### Cons of strangling inside a Rails app

The two applications share a single address space: if one application tramples over the data structures of the other one,
both applications may crash. This also means that if one of the application crashes the process, both the legacy and the
replacement application will be down. This may decrease your app's availability.

You cannot use conflicting versions of dependencies. If the legacy application uses Active Record 3, you will not be able
to use Active Record 4 or 5 in the replacement application.

### Pros of strangling using a reverse proxy

The two applications are unaware of each other. They share no code, hence if one app crashes, the application will be
partially available. This increases availability of your app.

Using the reverse proxy, the replacement app may be anything: Elixir, Go, Haskell, Clojure, Node, Netcat... The sky's
the limit!

### Cons of strangling using a reverse proxy

There are now two applications running. Both consume resources: memory, database connections, etc. In resource constrained
scenarios, this may be a problem.
