#!/usr/bin/env bash

rpm -ivh http://packages.groonga.org/centos/groonga-release-latest.noarch.rpm
yum install -y mecab mecab-devel mecab-ipadic
