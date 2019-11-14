source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'dotenv-rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
# Use Puma as the app server
gem 'puma'
gem 'puma_worker_killer'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Use CoffeeScript for .coffee assets and views
# gem 'coffee-rails', '~> 4.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'hashie'
gem 'devise'
gem 'omniauth-twitter'
gem 'twitter'
gem 'parallel'
gem 'memoist'
gem 'activerecord-import'
gem 'sidekiq', '< 6'
# gem 'sidekiq-unique-jobs'
gem 'sidekiq-benchmark'
# gem 'sidekiq-status'
gem 'sinatra', require: false
gem 'redis'
gem 'hiredis'
gem 'newrelic_rpm'
gem 'scout_apm'
gem 'kaminari'
gem 'httparty'
gem 'rack-timeout'
gem 'meta-tags'
gem 'mecab', require: false
gem 'twitter_with_auto_pagination'
gem 'rack-user_agent'
gem 'stackprof'
gem 'haml-rails'
gem 'rails_autolink'
gem 'draper'
gem 'rollbar'
gem 'oj'
gem 'gretel'
gem 'google-api-client', require: false
gem 'aws-sdk-cloudwatch', require: false
gem 'aws-sdk-dynamodb'
gem 'aws-sdk-s3'
gem 'stripe'
gem 'ahoy_matey'

# Datadog APM
gem 'dogstatsd-ruby'
gem 'ddtrace'

group :development, :production do
  gem 'blazer'
  gem 'sitemap_generator' # Be required at runtime
  gem 'rb-readline' # Must
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13.0'
  gem 'selenium-webdriver'

  gem 'pry-rails'
  gem 'annotate'
  gem 'whenever', :require => false
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
