#!/usr/bin/env bash

exec >>top_processes.log 2>&1

for i in `seq 1 60`; do
  echo "-------- start `date`"
  ps aux -L --sort=-%cpu | head -n 50
  echo '-------- end'
  sleep 1
done
