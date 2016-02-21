#!/usr/bin/env bash

sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git tmux dstat monit tree dstat mysql-server mysql-devel ruby22-devel nginx
sudo rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum --enablerepo=remi,epel install -y redis

wget http://dl.fedoraproject.org/pub/epel/5/x86_64/colordiff-1.0.6a-2.el5.noarch.rpm
sudo rpm -Uvh colordiff-1.0.6a-2.el5.noarch.rpm
rm colordiff-1.0.6a-2.el5.noarch.rpm

sudo update-alternatives --set ruby /usr/bin/ruby2.2
gem install --no-ri --no-rdoc bundler
