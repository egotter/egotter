OpenAI.configure do |config|
  config.access_token = ENV['OPENAI_KEY']
  config.timeout = 30
end
