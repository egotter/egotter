#!/usr/bin/env bash

for i in `seq 1 60`; do
  echo "-------- start `date`"
  ps aux -L --sort=-%cpu | head -n 50 >>top_processes.log
  echo '-------- end'
  sleep 1
done
