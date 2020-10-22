#!/usr/bin/env bash

counts=$(netstat -s | egrep 'overflow|drop|embryonic' | tr '\n' ', ')
echo "$(date +'%Y/%m/%d %H:%M') $counts">>dropped_conn_counts.log
