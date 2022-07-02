#!/usr/bin/env bash

exec >>/var/egotter/log/cron.log 2>&1
cmd="/usr/local/bin/bundle exec /usr/local/bin/ruby $1"

SECONDS=0

echo -e "$(date '+%Y/%m/%d %H:%M:%S') $cmd started"
cd /var/egotter && RAILS_ENV=production $cmd
echo -e "$(date '+%Y/%m/%d %H:%M:%S') $cmd finished elapsed=${SECONDS}"
