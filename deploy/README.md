# deploy-ruby

A deployment automation tool for engineers who are tired of writing weird DSL.

## Features

### No DSL

You don't have to remember weird DSLs like knife, chef, and galaxy.

### Not exaggerated

Do you manage hundreds of servers? I guess probably not.
All you need is a tool to do `git pull origin master && sudo service your_app restart`.

### Written with Ruby

You can do everything with Ruby you are used to writing.

## Installation

```shell
# Gemfile
gem 'deploy_ruby'

# Download and install
$ bundle install

# Setup
$ bundle exec deploy_ruby --install
```
