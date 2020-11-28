#!/usr/bin/env bash

exec >>/var/egotter/log/cron.log 2>&1
cmd="/usr/local/bin/bundle exec ruby $1"

SECONDS=0

echo -e "$(date) \e[35m$cmd started\e[m"
cd /var/egotter && RAILS_ENV=production $cmd
echo -e "$(date) \e[35m$cmd finished elapsed=${SECONDS}\e[m"
