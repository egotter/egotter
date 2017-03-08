#!/usr/bin/env bash

set -e

USER="ec2-user"
HOME="/home/${USER}"
APP_ROOT="${HOME}/egotter"
LOG_FILE="${HOME}/egotter-install.log"

npipe="/tmp/$$.tmp"
mknod ${npipe} p

tee <${npipe} ${LOG_FILE} &
exec 1>&-
exec 1>${npipe} 2>&1
trap "rm -f ${npipe}" EXIT

if [ $(echo "$UID") != "0" ]; then
  echo 'Operation not permitted'
  exit 1;
fi

sudo_cmd="sudo -u ${USER} -H bash -l -c"

yum update -y
yum groupinstall -y "Development Tools"
yum install -y git tmux dstat htop monit tree mysql-server mysql-devel ruby23-devel nginx
set +e
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
set -e
yum install -y redis --enablerepo=remi
yum install -y colordiff --enablerepo=epel

update-alternatives --set ruby /usr/bin/ruby2.3
${sudo_cmd} "gem install bundler --no-ri --no-rdoc"

git config --global user.email "you@example.com"
git config --global user.name "Your Name"


cd ${HOME}
if [ ! -d "./egotter" ]; then
  ${sudo_cmd} "git clone https://github.com/ts-3156/egotter.git"
fi
cd ${APP_ROOT}
${sudo_cmd} "git checkout master && git pull origin master"
[ ! -f "/usr/bin/mecab" ] && sh ./setup/install_mecab.sh
${sudo_cmd} "bundle install --path .bundle"
${sudo_cmd} "RAILS_ENV=production bundle exec rake assets:precompile"

cd ${APP_ROOT}

# redis
[ ! -f "/etc/redis.conf.bak" ] && cp /etc/redis.conf /etc/redis.conf.bak
cp -f ./setup/etc/redis.conf /etc
chkconfig redis on
service redis start

# mysql
chkconfig mysqld off
service mysqld stop

# sidekiq
cp -f ./setup/etc/init.d/sidekiq* /etc/init.d
# service sidekiq start

# unicorn
cp -f ./setup/etc/init.d/unicorn /etc/init.d
# service unicorn start

# egotter
cp -f ./setup/etc/init.d/egotter /etc/init.d

# monit
[ ! -f "/etc/monit.conf.bak" ] && cp /etc/monit.conf /etc/monit.conf.bak
cp -f ./setup/etc/monit.conf /etc
chown root:root /etc/monit.conf
cp -f ./setup/etc/monit.d/sidekiq /etc/monit.d
chkconfig monit on
service monit stop

# nginx
[ ! -f "/etc/nginx/nginx.conf.bak" ] && cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cp -f ./setup/etc/nginx/nginx.conf /etc/nginx
chkconfig nginx on
service nginx start
# chown -R ec2-user:ec2-user /var/log/nginx

# logrotate
cp -fr ./setup/etc/logrotate.d/egotter /etc/logrotate.d/egotter
sed -i '/include \/etc\/logrotate.d/a include \/etc\/logrotate.d\/egotter' /etc/logrotate.conf


if [ ! -z ${DD_API_KEY+x} ]; then
  echo "DD_API_KEY is set to ${DD_API_KEY}"
  bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
else
  echo "DD_API_KEY is unset"
fi

printf "\033[32m

Create .env:

    cp /path/to/.env ${APP_ROOT}/.env

Write crontab:

    crontab ${APP_ROOT}/setup/var/spool/cron/ec2-user

Run monit:

    sudo service monit start

User settings:

    wget -q -O .bashrc https://gist.githubusercontent.com/ts-3156/5373957/raw/.bashrc
    source .bashrc

\033[0m"
