#!/usr/bin/env bash

tail -f log/sidekiq_all.log log/development.log | grep -i warn
