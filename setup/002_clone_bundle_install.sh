#!/usr/bin/env bash

HOME="/home/ec2-user"
USER="ec2-user"

sudo -u ${USER}
cd ${HOME}

git clone https://github.com/ts-3156/egotter.git
cd egotter
bundle install --path .bundle
