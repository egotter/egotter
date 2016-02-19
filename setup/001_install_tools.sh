#!/usr/bin/env bash

sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git tmux dstat monit tree dstat mysql-server mysql-devel ruby22-devel nginx
sudo rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum --enablerepo=remi,epel install -y redis

sudo update-alternatives --set ruby /usr/bin/ruby2.2
gem install --no-ri --no-rdoc bundler
