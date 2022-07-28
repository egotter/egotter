#!/usr/bin/env bash

cmd="/usr/local/bin/bundle exec rails runner $1"
/var/egotter/bin/cron/start.sh "$cmd"
