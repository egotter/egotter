#!/usr/bin/env bash

exec >>top_processes.log 2>&1

for i in `seq 1 59`; do
  echo "-------- start `date`"
  ps aux -L --sort=-%cpu | head -n 5
  echo '-------- end'
  sleep 1
done
