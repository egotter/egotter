source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'dotenv-rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4'
# Use Puma as the app server
gem 'puma', '~> 5.6'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 4.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
# gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '>= 2.15'
  # gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  # gem 'webdrivers'
end

gem 'jquery-rails'
gem 'hashie'
gem 'twitter', github: 'egotter/twitter'
gem 'parallel'
gem 'activerecord-import'
gem 'rack-timeout'
gem 'meta-tags'
gem 'mecab', require: false
gem 'natto', require: false
gem 'twitter_with_auto_pagination'
gem 'rack-user_agent'
gem 'haml-rails'
gem 'twitter-text'
gem 'draper'
gem 'oj'
gem 'stripe'
gem 'webpacker', '~> 5.0'
gem 'sitemap_generator'

# Authentication
gem 'devise'
gem 'omniauth-twitter'

# Sidekiq
gem 'sidekiq', '6.5.1'
gem 'unique_job', '0.4.3'
gem 'expire_job', '0.1.5.pre'
gem 'timeout_job'
gem 'sinatra', require: false
gem 'hiredis'
gem 'redis', require: %w[redis redis/connection/hiredis]

# Analytics
gem 'ahoy_matey'
gem 'blazer'

# Google
gem 'google-api-client', require: false

# AWS
gem 'aws-sdk-cloudwatch', require: false
gem 'aws-sdk-s3'
gem 'aws-sdk-ec2', require: false
gem 'aws-sdk-elasticloadbalancingv2', require: false

# Datadog APM
gem 'dogstatsd-ruby', require: false
gem 'ddtrace', require: false

# Slack
gem 'slack-ruby-client', require: false

group :development do
  gem 'annotate'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

