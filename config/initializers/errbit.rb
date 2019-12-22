Airbrake.configure do |config|
  config.host = ENV['AIRBRAKE_HOST']
  config.project_id = 1 # required, but any positive integer works
  config.project_key = ENV['AIRBRAKE_PROJECT_KEY']

  config.environment = Rails.env
  config.ignore_environments = %w(test)
end