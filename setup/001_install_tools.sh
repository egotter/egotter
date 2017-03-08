#!/usr/bin/env bash

USER="ec2-user"

yum update -y
yum groupinstall -y "Development Tools"
yum install -y git tmux dstat htop monit tree mysql-server mysql-devel ruby23-devel nginx
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
yum install -y redis --enablerepo=remi
yum install -y colordiff --enablerepo=epel

update-alternatives --set ruby /usr/bin/ruby2.3
sudo -u ${USER} -H bash -l -c "gem install bundler --no-ri --no-rdoc"