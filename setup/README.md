## Install egotter

`sudo bash -c "$(curl -L https://raw.githubusercontent.com/ts-3156/egotter/master/setup/install_egotter.sh)"`

## Run Rails

```
bundle exec rake db:create db:migrate
bundle exec rails s --binding=0.0.0.0
```

## Run Redis on mac

`redis-server [project root]/redis.conf`

## Run Sidekiq

`bundle exec sidekiq -C config/sidekiq.yml`

## Maintenance mode

1. Write `MAINTENANCE="1"` in .env
1. Change DB host, username and password from production to staging in .env
1. Comment out crontab
1. Restart Puma and Sidekiq
