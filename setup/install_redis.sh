#!/usr/bin/env bash

set -e

# Amazon Linux 2

yum update -y
amazon-linux-extras install -y epel
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=remi install -y redis

cat << EOS >>/etc/security/limits.conf
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOS

cat << EOS >>/etc/sysctl.conf
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 2048
vm.overcommit_memory = 1
EOS
sysctl -p

echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >>/etc/rc.local

sed -i -e 's/LimitNOFILE=10240/LimitNOFILE=65536/g' /etc/systemd/system/redis.service.d/limit.conf

[ ! -f "/etc/redis.conf.bak" ] && cp /etc/redis.conf /etc/redis.conf.bak
\cp -f ./setup/etc/redis.conf /etc

systemctl daemon-reload
systemctl enable redis.service
systemctl restart redis

# redis-cli
# > replicaof xxx.xxx.xxx.xxx 6379
# > replicaof no one

dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >>/etc/fstab

# Install datadog
