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
sudo service sidekiq start

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
sudo service nginx start
sudo chkconfig nginx on
sudo chown -R ec2-user:ec2-user /var/log/nginx

# logrotate
sudo cp -r ./setup/etc/logrotate.d/egotter /etc/logrotate.d/egotter
sudo sed -i '/include \/etc\/logrotate.d/a include \/etc\/logrotate.d\/egotter' /etc/logrotate.conf