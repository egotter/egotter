#!/usr/bin/env bash

APP_ROOT="/home/ec2-user/egotter"

cd ${APP_ROOT}

# redis
cp /etc/redis.conf /etc/redis.conf.bak
cp ./setup/etc/redis.conf /etc
chkconfig redis on
service redis start

# mysql
chkconfig mysqld off
service mysqld stop

# sidekiq
cp ./setup/etc/init.d/sidekiq* /etc/init.d
# service sidekiq start

# unicorn
cp ./setup/etc/init.d/unicorn /etc/init.d
# service unicorn start

# monit
cp /etc/monit.conf /etc/monit.conf.bak
cp ./setup/etc/monit.conf /etc
chown root:root /etc/monit.conf
cp ./setup/etc/monit.d/sidekiq /etc/monit.d
chkconfig monit on
service monit start

# nginx
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cp ./setup/etc/nginx/nginx.conf /etc/nginx
chkconfig nginx on
service nginx start
# chown -R ec2-user:ec2-user /var/log/nginx

# logrotate
cp -r ./setup/etc/logrotate.d/egotter /etc/logrotate.d/egotter
sed -i '/include \/etc\/logrotate.d/a include \/etc\/logrotate.d\/egotter' /etc/logrotate.conf