#!/usr/bin/env bash

cmd="/usr/local/bin/bundle exec /usr/local/bin/ruby $1"
/var/egotter/bin/cron/start.sh "$cmd"
