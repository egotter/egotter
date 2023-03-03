namespace :bots do
  task invalidate_credentials: :environment do
    verbose = ENV['VERBOSE']

    Bot.where(enabled: true).find_each do |bot|
      bot.invalidate_credentials
      print '.' if verbose
      sleep 0.5
    end
  end
end
