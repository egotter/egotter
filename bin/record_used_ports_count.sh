#!/usr/bin/env bash

counts=$(netstat -ant | wc -l)
echo "$(date +'%Y/%m/%d %H:%M'): $counts">>used_port_counts.log