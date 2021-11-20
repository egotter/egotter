#!/usr/bin/env bash

# yum install -y yum-utils
rpm -ivh http://packages.groonga.org/centos/groonga-release-latest.noarch.rpm
yum install -y mecab mecab-devel mecab-ipadic
