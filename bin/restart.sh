#!/usr/bin/env bash

sudo service sidekiq restart
sleep 3
ps aux | grep sidekiq | grep -v grep

echo -e ''

bundle exec rake unicorn:stop && bundle exec rake unicorn:start
sleep 3
ps aux | grep unicorn | grep -v grep
