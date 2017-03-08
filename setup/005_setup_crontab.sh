#!/usr/bin/env bash

HOME="/home/ec2-user"
USER="ec2-user"

sudo -u ${USER}
cd ${HOME}

crontab ./setup/var/spool/cron/ec2-user