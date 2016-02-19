#!/usr/bin/env bash

bundle exec rake db:create db:migrate
bundle exec rails s --binding=0.0.0.0
