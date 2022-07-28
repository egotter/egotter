#!/usr/bin/env bash

exec >>/var/egotter/log/cron.log 2>&1
cmd=$1
send_message="/usr/local/bin/bundle exec /usr/local/bin/ruby bin/send_slack_message.rb"

SECONDS=0

echo -e "$(date '+%Y/%m/%d %H:%M:%S') $cmd started"

cd /var/egotter && RAILS_ENV=production $cmd

if [ $? -ne 0 ]; then
  echo -e "$(date '+%Y/%m/%d %H:%M:%S') $cmd failed elapsed=${SECONDS}"
  $send_message cron "$cmd failed"
else
  echo -e "$(date '+%Y/%m/%d %H:%M:%S') $cmd succeeded elapsed=${SECONDS}"
fi
