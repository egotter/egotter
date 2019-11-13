#!/usr/bin/env bash

set -e

USER="ec2-user"
HOME="/home/${USER}"
APP_PARENT="/var"
APP_ROOT="${APP_PARENT}/egotter"
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
yum install -y git tmux dstat htop monit tree mysql-server mysql-devel nginx
yum install -y openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
set +e
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
set -e
yum install -y redis --enablerepo=remi
yum install -y colordiff --enablerepo=epel

# For unf_ext
yum install -y gcc72-c++.x86_64

# If failed to bundle install
# yum install -y ruby-devel

cat << EOS >>/etc/security/limits.conf
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOS

echo "net.ipv4.tcp_max_syn_backlog = 512" >>/etc/sysctl.conf
echo "net.core.somaxconn = 512" >>/etc/sysctl.conf
echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
sysctl -p

echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >>/etc/rc.local

cd ~
# https://github.com/egotter/egotter/wiki/Install-Ruby
wget http://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz
tar xvfz ruby-2.6.4.tar.gz
cd ruby-2.6.4
./configure && make && make install

git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh

cd ${APP_PARENT}
if [ ! -d "./egotter" ]; then
  git clone https://github.com/egotter/egotter.git
  chown -R ${USER}:${USER} ./egotter
fi
cd ${APP_ROOT}
${sudo_cmd} "git checkout master && git pull origin master"

[ ! -f "/usr/bin/mecab" ] && sh ./setup/install_mecab.sh
# yum remove -y gcc48-c++ && yum install -y gcc72-c++.x86_64

cd ${APP_ROOT}
${sudo_cmd} "/usr/local/bin/bundle install --path .bundle --without test development"

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
cp -f ./setup/etc/init.d/patient_sidekiqctl.rb /etc/init.d
# service sidekiq start

# puma
cp -f ./setup/etc/init.d/puma /etc/init.d
# service puma start

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
chmod +rx /var/log/nginx

# td-agent
[ ! -f "/etc/td-agent/td-agent.conf.bak" ] && cp /etc/td-agent/td-agent.conf /etc/td-agent/td-agent.conf.bak
cp -f ./setup/etc/td-agent/* /etc/td-agent/
/usr/sbin/td-agent-gem install fluent-plugin-slack
/usr/sbin/td-agent-gem install fluent-plugin-rewrite-tag-filter
chkconfig td-agent on
service td-agent start
echo '$FileCreateMode 0644' >>/etc/rsyslog.conf
echo '$DirCreateMode 0755' >>/etc/rsyslog.conf
chmod +r /var/log/messages
/etc/init.d/rsyslog restart

# logrotate
cp -fr ./setup/etc/logrotate.d/egotter /etc/logrotate.d/egotter
sed -i '/include \/etc\/logrotate.d/a include \/etc\/logrotate.d\/egotter' /etc/logrotate.conf


printf "\033[32m

Create .env:

    cp /path/to/.env ${APP_ROOT}/.env
    sed -i -e 's/REDIS_HOST=.\+/REDIS_HOST="xxx.xxx.xxx.xxx"/' .env
    # Copy .google and data/cluster_(good|bad)_words.json

Precompile assets:

    # WARN: There is a possibility of deleting necessary assets
    RAILS_ENV=production bundle exec rake assets:precompile

Write crontab:

    crontab ${APP_ROOT}/setup/var/spool/cron/ec2-user

Setup daemons:

    service nginx stop; chkconfig nginx off
    service redis stop; chkconfig redis off
    service sendmail stop; chkconfig sendmail off
    service monit stop; chkconfig monit off
    service td-agent stop; chkconfig td-agent off
    service sidekiq stop; chkconfig --add sidekiq; chkconfig sidekiq off

Install datadog:

    # https://app.datadoghq.com/account/settings#agent/aws
    sed -i -e 's/# hostname: .\+/hostname: xxx.egotter/' /etc/dd-agent/datadog.conf
    /etc/init.d/datadog-agent restart; chkconfig datadog-agent on
    cp setup/etc/dd-agent/checks.d/sidekiq.py /etc/dd-agent/checks.d/sidekiq.py
    cp setup/etc/dd-agent/conf.d/sidekiq.yaml /etc/dd-agent/conf.d/sidekiq.yaml
    # Enable process_config and logs_enabled

Make swap:

    dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' >>/etc/fstab
    # egrep "Mem|Swap" /proc/meminfo OR swapon -s

# Mount efs:
# 
#     mkdir /efs
#     mount -t nfs4 [NAME]:/ /efs/
#     echo '[NAME]:/ /efs efs defaults,_netdev 0 0' >>/etc/fstab
#     # df -h
    
Install monitoring script:

    # https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/mon-scripts.html
    sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
    curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
    unzip CloudWatchMonitoringScripts-1.2.2.zip && rm CloudWatchMonitoringScripts-1.2.2.zip && cd aws-scripts-mon
    # root's crontab -> */5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --disk-space-util --disk-path=/ --from-cron

User settings:

    wget -q -O .bashrc https://gist.githubusercontent.com/ts-3156/5373957/raw/.bashrc
    source .bashrc >/dev/null 2>&1

\033[0m"
