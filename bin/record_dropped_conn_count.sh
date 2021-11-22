#!/usr/bin/env bash

counts=$(netstat -s | egrep 'overflow|drop|embryonic' | tr '\n' ', ')
echo "$(date +'%Y/%m/%d %H:%M') $counts">>/var/egotter/log/dropped_conn_counts.log
