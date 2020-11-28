#!/usr/bin/env ruby

# Configure the load path
require 'bundler/setup'
require File.expand_path('../../app/lib/secret_file.rb', __FILE__)

puts SecretFile.read("#{ARGV[0]}")
