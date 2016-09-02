#!/usr/bin/env bash

sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git tmux dstat htop monit tree mysql-server mysql-devel ruby23-devel nginx
sudo rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum install -y redis --enablerepo=remi
sudo yum install -y colordiff --enablerepo=epel

sudo update-alternatives --set ruby /usr/bin/ruby2.3
gem install bundler --no-ri --no-rdoc
