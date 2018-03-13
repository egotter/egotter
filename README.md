# egotter

[![Build Status](https://travis-ci.org/ts-3156/egotter.svg?branch=master)](https://travis-ci.org/ts-3156/egotter)

Let's enjoy egotter! ✧*｡٩(ˊᗜˋ*)و✧*｡

```bash
/etc/init.d/egotter start

```

## Architecture

![Server architecture](docs/architecture.png)

## Server Components

### Nginx

[/etc/nginx/nginx.conf](setup/etc/nginx/nginx.conf)

### MySQL
### Rails
### Unicorn

[config/unicorn.rb](config/unicorn.rb)

[/etc/init.d/unicorn](setup/etc/init.d/unicorn)

### Redis

[/etc/redis.conf](setup/etc/redis.conf)

[redis.rb](config/initializers/redis.rb)

### Sidekiq

[/etc/init.d/sidekiq_base](setup/etc/init.d/sidekiq_base)

[sidekiq.rb](config/initializers/sidekiq.rb)

### td-agent

[/etc/td-agent/td-agent.conf.web](setup/etc/td-agent/td-agent.conf.web)

[/etc/td-agent/td-agent.conf.sidekiq](setup/etc/td-agent/td-agent.conf.sidekiq)

### Monit


## Setup

Read `setup/install_egotter.sh`

## License

Egotter is released under the [MIT License](http://www.opensource.org/licenses/MIT).
