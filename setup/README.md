## Run redis on mac

`redis-server [project root]/redis.conf`

## Run sidekiq

`bundle exec sidekiq`

## Maintenance mode

1. Write `MAINTENANCE="1"` in .env
1. Change DB host, username and password from production to staging in .env
1. Comment out crontab
1. Restart Unicorn and Sidekiq

## Import tzinfo

```
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
```