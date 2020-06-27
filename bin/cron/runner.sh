#!/usr/bin/env bash

log='/var/egotter/log/cron.log'
cmd="/usr/local/bin/bundle exec rails runner $1"

SECONDS=0

echo -e "$(date) \e[33m$cmd started\e[m" >>$log 2>&1
cd /var/egotter && RAILS_ENV=production $cmd >>$log 2>&1
echo -e "$(date) \e[33m$cmd finished elapsed=${SECONDS}\e[m" >>$log 2>&1
