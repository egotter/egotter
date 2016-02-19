#!/usr/bin/env bash

# redis
sudo cp /etc/redis.conf /etc/redis.conf.bak
sudo cp ./setup/etc/redis.conf /etc/redis.conf
sudo chkconfig redis on
sudo service redis start

# mysql
# sudo chkconfig mysqld on
# sudo service mysqld start

# sidekiq
sudo cp ./setup/etc/init.d/sidekiq /etc/init.d/sidekiq

# monit
sudo cp /etc/monit.conf /etc/monit.conf.bak
sudo cp ./setup/etc/monit.conf /etc/monit.conf
sudo chown root:root /etc/monit.conf
sudo cp ./setup/etc/monit.d/sidekiq /etc/monit.d/sidekiq
sudo service monit start
sudo chkconfig monit on

# nginx
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo cp ./setup/etc/nginx/nginx.conf /etc/nginx/nginx.conf
sudo service nginx
sudo chkconfig nginx on
