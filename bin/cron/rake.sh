#!/usr/bin/env bash

cmd="/usr/local/bin/bundle exec rake $1"
/var/egotter/bin/cron/start.sh "$cmd"
