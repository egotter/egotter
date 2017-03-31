#!/bin/sh

start() {
  /etc/init.d/sidekiq_delay status >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    /etc/init.d/sidekiq_delay start
  fi
}

stop() {
  /etc/init.d/sidekiq_delay status >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    /etc/init.d/sidekiq_delay stop
  fi
}

fetch_ip() {
  aws ec2 describe-instances --region ap-northeast-1 \
    --filter "Name=tag:Name,Values=${1}" \
    --query 'Reservations[].Instances[].PrivateIpAddress|[0]' | tr -d '"null'
}

# region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
egotter_web=$(fetch_ip egotter_web)
egotter_autoscale=$(fetch_ip egotter_autoscale)

[ -n "${egotter_autoscale}" ] && /bin/ping -w 1 -c 1 ${egotter_autoscale} >/dev/null 2>&1

if [ $? -eq 0 ]; then
  stop
else
  d_status=$(curl -m 1 -s https://egotter.com/delay_status)
  if [ $? -eq 0 ]; then
    set -- ${d_status}
    if [ $1 -ne 0 -o $2 -ne 0 ]; then
      start
    else
      stop
    fi
  else
    echo 'delay_status is not found'
    exit 1
  fi
fi
