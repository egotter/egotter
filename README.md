# egotter

[![Build Status](https://travis-ci.org/ts-3156/egotter.svg?branch=master)](https://travis-ci.org/ts-3156/egotter)

Please enjoy egotter!  ✧*｡٩(ˊᗜˋ*)و✧*｡

### Desktop

<table>
    <tr>
        <td>Top page</td>
        <td>Result page</td>
    </tr>
    <tr>
        <td><img src="docs/001_top_page_desktop.png" width="300" height="324"></td>
        <td><img src="docs/002_result_page_desktop.png" width="300" height="645"></td>
    </tr>
</table>

### Mobile

<table>
    <tr>
        <td>Top page</td>
        <td>Result page</td>
    </tr>
    <tr>
        <td><img src="docs/003_top_page_mobile.png" width="300" height="1181"></td>
        <td><img src="docs/004_result_page_mobile.png" width="300" height="1629"></td>
    </tr>
</table>

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

## Design

## Setup

Read `setup/install_egotter.sh`

```bash
/etc/init.d/egotter start
```

## License

Egotter is released under the [MIT License](http://www.opensource.org/licenses/MIT).
