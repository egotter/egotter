#!/usr/bin/env bash

counts=$(netstat -s | grep drop | tr '\n' ' ')
echo "$(date +'%Y/%m/%d %H:%M') $counts">>dropped_conn_counts.log
