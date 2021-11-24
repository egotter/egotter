#!/usr/bin/env bash

counts=$(netstat -nt | awk "/^tcp/{print \$6}" | sort | uniq -c | sed -e 's/^ \+//' | sort -rV | tr '\n' ', ')
echo "$(date +'%Y/%m/%d %H:%M') $counts">>/var/egotter/log/used_port_counts.log

aaa

