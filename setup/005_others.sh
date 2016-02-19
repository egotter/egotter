#!/usr/bin/env bash

# https://gist.githubusercontent.com/ts-3156/5373957/raw/e179785a48f88e120285be6978f0ea578d308628/.bashrc
# bot.json, cluster_bad_words.json, cluster_good_words.json, .env

# 0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58 * * * * /bin/bash -l -c 'cd /home/ec2-user/egotter && RAILS_ENV=development bundle exec rake update_job_dispatcher:run --silent >> /home/ec2-user/egotter/log/crontab.log 2>&1'

# https://app.datadoghq.com/account/settings#agent/aws
# cp ./setup/etc/rsyslog.d/sidekiq /etc/rsyslog.d/sidekiq

# https://papertrailapp.com/systems/setup
